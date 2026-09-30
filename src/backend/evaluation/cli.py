"""Private researcher export, provenance backfill, SQLite backup/restore, and retention operations."""
import argparse
import csv
import json
import os
import sqlite3
import sys
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

from .backfill import BackfillError, link_verified_records, load_backfill_input
from .content import stored_snapshot, strict_json_loads
from .researcher_packs import ResearcherPackError, join_researcher_packs
from .service import (
    PROVENANCE_LEGACY_UNAVAILABLE,
    PROVENANCE_SNAPSHOT,
    SCHEMA_VERSION,
    SNAPSHOT_COLUMNS,
    SNAPSHOT_TABLE,
    Config,
    canonical,
    migrate,
)

# Stored legacy_unavailable provenance is exported with this explicit marker.
UNAVAILABLE_PROVENANCE = {
    'status': 'unavailable',
    'codebook': None,
    'reason': ('Stored before participant-content snapshots were recorded; the exact participant content for '
               'this record is not available and current content must not be substituted.'),
}


@dataclass(frozen=True)
class StoreLayout:
    """Where one supported SQLite schema version keeps its submissions."""
    version: int
    table: str
    submission_json: str

    @property
    def has_snapshots(self):
        return self.version >= 3

    @property
    def has_backfill(self):
        return self.version >= 4

    @property
    def backfill_column(self):
        """The backfill-evidence column to select, or NULL for a layout without one."""
        return 'provenance_backfill' if self.has_backfill else 'NULL'


LAYOUTS = {1: StoreLayout(1, 'responses', 'payload'), 2: StoreLayout(2, 'submissions', 'submission_json'),
           3: StoreLayout(3, 'submissions', 'submission_json'),
           SCHEMA_VERSION: StoreLayout(SCHEMA_VERSION, 'submissions', 'submission_json')}


def private_path(path):
    path = Path(path).resolve()
    Config(path.parent)  # Reject public/project output locations.
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    return path


def open_db(path, *, verify_snapshots=True):
    """Open a supported store read-only after integrity (and, by default, snapshot) verification."""
    db = sqlite3.connect(f'{Path(path).resolve().as_uri()}?mode=ro', uri=True)
    try:
        layout = LAYOUTS.get(db.execute('PRAGMA user_version').fetchone()[0])
        tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        if (layout is None or layout.table not in tables
                or db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok'
                or (verify_snapshots and layout.has_snapshots and not snapshots_verified(db, layout))):
            raise ValueError('Unsupported or damaged study database')
    except BaseException:
        db.close()
        raise
    return db, layout


def snapshots_verified(db, layout):
    """Check every snapshot against its digest and identity, and every submission's provenance link.

    Backfill evidence may only accompany a snapshot link.
    """
    try:
        for row in db.execute(f"SELECT {', '.join(SNAPSHOT_COLUMNS)} FROM {SNAPSHOT_TABLE}"):
            stored_snapshot(row)
    except (ValueError, TypeError, sqlite3.Error):
        return False
    return not db.execute(
        f'SELECT 1 FROM submissions s LEFT JOIN {SNAPSHOT_TABLE} c ON c.digest = s.content_digest '
        'WHERE NOT ((s.content_provenance = ? AND c.digest IS NOT NULL) '
        f'OR (s.content_provenance = ? AND s.content_digest IS NULL AND {layout.backfill_column} IS NULL)) LIMIT 1',
        (PROVENANCE_SNAPSHOT, PROVENANCE_LEGACY_UNAVAILABLE)).fetchone()


def backup(source, destination):
    destination = private_path(destination)
    # Exclusive creation prevents an accidental overwrite of a live database.
    fd = os.open(destination, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    os.close(fd)
    src = dst = None
    try:
        src, _ = open_db(source)
        dst = sqlite3.connect(destination)
        src.backup(dst)
    except Exception:
        destination.unlink()
        raise
    finally:
        if src:
            src.close()
        if dst:
            dst.close()


def backfill_provenance(source, destination, releases, links):
    """Write a verified copy of SOURCE whose explicitly linked legacy records name their exact content.

    The frozen releases and links are verified before anything is written (see backfill). The
    copy is migrated to the current schema, and every link is applied in one transaction; on any
    failure the new DESTINATION is removed and SOURCE is never modified. Returns a BackfillResult.
    """
    backfill_input = load_backfill_input(releases, links)
    backup(source, destination)
    destination = private_path(destination)
    try:
        db = sqlite3.connect(destination)
        try:
            db.execute('BEGIN IMMEDIATE')
            migrate(db)
            result = link_verified_records(db, backfill_input)
            db.commit()
        finally:
            db.rollback()
            db.close()
        check, _ = open_db(destination)
        check.close()
    except BaseException:
        destination.unlink()
        raise
    return result


def safe_cell(value):
    if isinstance(value, (dict, list)):
        value = canonical(value)
    if isinstance(value, str) and (value.lstrip().startswith(('=', '+', '-', '@'))
                                   or value.startswith(('\t', '\r', '\n'))):
        return "'" + value
    return value


@contextmanager
def private_file(path, mode, **options):
    """Open an export file readable only by its owner; callers pass an exclusive-create (x) mode."""
    with open(path, mode, **({'encoding': 'utf-8'} if 'b' not in mode else {}), **options) as f:
        os.chmod(path, 0o600)
        yield f


def snapshot_file(digest):
    """The export path of a snapshot's exact canonical bytes; the file's SHA-256 is the digest."""
    return f'snapshots/{digest}.json'


def read_store(source):
    """Read exported rows in submission-ID order and every verified snapshot they reference, by digest.

    Each row is (submission JSON, receipt, release, content digest, backfill evidence JSON).
    """
    db, layout = open_db(source)
    try:
        if not layout.has_snapshots:
            rows = [(*row, None, None) for row in db.execute(
                f'SELECT {layout.submission_json}, receipt, release FROM {layout.table} ORDER BY submission_id')]
            return rows, {}
        rows = db.execute(f'SELECT {layout.submission_json}, receipt, release, content_digest, '
                          f'{layout.backfill_column} FROM {layout.table} ORDER BY submission_id').fetchall()
        snapshots = [stored_snapshot(row) for row in db.execute(
            f"SELECT {', '.join(SNAPSHOT_COLUMNS)} FROM {SNAPSHOT_TABLE} "
            f'WHERE digest IN (SELECT content_digest FROM {layout.table}) ORDER BY digest')]
    finally:
        db.close()
    return rows, {snapshot.digest: snapshot for snapshot in snapshots}


def record_provenance(snapshot, backfill=None):
    """A record's machine-readable link to its exact snapshot and codebook, or the unavailable marker.

    A link established later by the verified provenance backfill, rather than at submission,
    carries that operation's stored evidence under `backfill`.
    """
    if snapshot is None:
        return dict(UNAVAILABLE_PROVENANCE)
    provenance = {'status': PROVENANCE_SNAPSHOT, 'digest': snapshot.digest,
                  'instrumentVersion': snapshot.instrument_version, 'contentVersion': snapshot.content_version,
                  'studyVersion': snapshot.study_version, 'codebook': snapshot.digest,
                  'snapshotFile': snapshot_file(snapshot.digest)}
    if backfill is not None:
        provenance['backfill'] = json.loads(backfill)
    return provenance


def snapshot_codebook(snapshot, pack):
    """Participant definitions read only from the stored snapshot, never from the running package."""
    content = strict_json_loads(snapshot.canonical_content)['content']
    return {
        'contentDigest': snapshot.digest, 'snapshotFile': snapshot_file(snapshot.digest),
        'packageSchemaVersion': snapshot.package_schema_version,
        'versions': {'studyVersion': snapshot.study_version, 'instrumentVersion': snapshot.instrument_version,
                     'contentVersion': snapshot.content_version},
        'fields': content['fields'], 'scales': content['scales'], 'membership': content['membership'],
        'researcherPack': None if pack is None else pack.identity['digest'],
    }


def researcher_codebooks(packs):
    """Private researcher interpretation, kept apart from participant definitions and raw answers."""
    return {
        'schemaVersion': 1,
        'rawAnswers': (
            'submissions.json and submissions.csv keep raw codes, statuses, and text. Researcher transforms such as '
            'answered-only reverse-coding, and qualitative pairings, are declarations to apply in separate '
            'analysis files; they are never applied to exported answers.'
        ),
        'taskOutcomes': (
            'Task status in the submissions is the participant-reported completion, skip, or inability. Researcher '
            'task outcome and correctness use the researcher vocabulary in each pack codebook and are coded '
            'separately; no correctness is derived from participant status.'
        ),
        'packs': {digest: {
            'researcherIdentity': pack.identity, 'publicIdentity': pack.public_identity,
            'freezeIdentity': pack.freeze_identity, 'researcherSchemaVersion': pack.schema_version,
            'codebook': pack.codebook, 'material': pack.material,
        } for digest, pack in sorted(packs.items())},
    }


def export(source, directory, researcher_packs=()):
    """Export records with the exact snapshots and codebooks that describe them.

    Researcher packs (frozen release directories) are verified against the exported snapshots
    before anything is written; a mismatch raises ResearcherPackError.
    """
    rows, snapshots = read_store(source)
    packs = join_researcher_packs(researcher_packs, snapshots)
    directory = private_path(Path(directory) / 'placeholder').parent
    records = [{'submission': json.loads(p), 'receipt': json.loads(r), 'release': json.loads(v),
                'contentProvenance': record_provenance(snapshots.get(digest), backfill)}
               for p, r, v, digest, backfill in rows]
    def write(name, value):
        with private_file(directory / name, 'x') as f:
            json.dump(value, f, ensure_ascii=False, indent=2)
    write('submissions.json', records)
    (directory / 'snapshots').mkdir(mode=0o700)
    for digest, snapshot in snapshots.items():
        with private_file(directory / snapshot_file(digest), 'xb') as f:
            f.write(snapshot.canonical_content)
    if packs:
        write('researcher-codebooks.json', researcher_codebooks(packs))
    historical_course_status_definition = {
        'courseStatusOptions': {'1': 'Completed', '2': 'Currently enrolled', '3': 'Neither'},
        'courseItems': {
            'P3_CSSE1001_ENGG1001': 'CSSE1001/ENGG1001', 'P3_CSSE2002': 'CSSE2002',
            'P3_CSSE2010': 'CSSE2010', 'P3_CSSE2310': 'CSSE2310', 'P3_COMP3506': 'COMP3506',
            'P3_COMP3301': 'COMP3301', 'P3_COMP4403': 'COMP4403',
        },
        'otherCourse': (
            'P3_other_name is an optional name; P3_other_status uses courseStatusOptions. '
            'A named course without a status is unknown; unanswered is never Neither.'
        ),
    }
    write('codebook.json', {
        'schemaVersion': 4,
        'codebooks': {digest: snapshot_codebook(snapshot, packs.get(digest))
                      for digest, snapshot in snapshots.items()},
        'unavailableDefinitions': {
            'marker': dict(UNAVAILABLE_PROVENANCE),
            'submissionIds': [r['submission']['submissionId'] for r in records
                              if r['contentProvenance']['codebook'] is None],
        },
        'contentProvenance': (
            'codebooks holds one entry per participant-content snapshot referenced by an exported record, keyed '
            'by its digest and read from the stored snapshot, never from the running application. Each record\'s '
            'contentProvenance.codebook names its entry and snapshotFile the exact canonical public bytes, whose '
            'SHA-256 is the digest. A record whose codebook is null has unavailable participant-content '
            'provenance and is listed under unavailableDefinitions; no codebook entry may be applied to it.'
        ),
        'instrumentDefinitions': {
            'v0.5': {
                'P3': {
                    'meaning': ('Selected UQ courses completed or currently enrolled in; the response does not '
                                'distinguish those statuses.'),
                    'values': {'1': 'CSSE2010', '2': 'CSSE2310', '3': 'COMP3506', '4': 'CSSE3200',
                               '5': 'COMP4403', '6': 'None of these', '7': 'Other relevant course'},
                    'otherCourse': 'P3.other contains the optional course name when value 7 is selected.',
                },
            },
            'v0.6': historical_course_status_definition,
            'v0.7': historical_course_status_definition,
            'v0.8': historical_course_status_definition,
            'v0.9': historical_course_status_definition,
            'v0.10': historical_course_status_definition,
            'v0.11': {
                'meaning': (
                    'Selected UQ courses are ones the participant is studying or has studied; '
                    'current enrolment and completion are intentionally combined.'
                ),
                'courseOptions': {
                    '1': 'CSSE1001 — Introduction to Software Engineering / ENGG1001 — Programming for Engineers',
                    '2': 'CSSE2002 — Programming in the Large', '3': 'CSSE2010 — Introduction to Computer Systems',
                    '4': 'CSSE2310 — Computer Systems Principles and Programming',
                    '5': 'COMP3506 — Algorithms & Data Structures', '6': 'COMP3301 — Operating Systems Architecture',
                    '7': 'COMP4403 — Compilers and Interpreters', '8': 'None of these',
                    '9': 'Other relevant course',
                },
                'otherCourse': (
                    'P3_other_name is the required name shown when P3 value 9 is selected. '
                    'An unanswered P3 is unknown; answered value 8 explicitly means none '
                    'of the listed courses.'
                ),
            },
        },
        'csv': (
            'Long format uses section to identify consent, survey, or task. Value is the raw numeric code, '
            'JSON array, or text. Empty value with status is '
            'missing, never zero. Formula-like strings have a leading apostrophe; JSON preserves original '
            'text.'
        ),
        'durationMs': (
            'Rounded once to nearest integer millisecond at submission; 0–86400000. For v0.8–v0.11, visible time '
            'starts at task presentation and includes reading, exploration, and answering; hidden tabs, explicit '
            'pause, and reload downtime are excluded. This task-presentation measure is distinct from the v0.5/v0.6 '
            'post-setup duration and must not be pooled with it. Neither measure is total task or pure comprehension '
            'time. T1c is T1 durationMs.'
        ),
        'setupReached': (
            'Legacy v0.5/v0.6 outcome field: whether a usable comparison was reached at least once; it did not '
            'verify the instructed configuration. It is not collected in v0.8–v0.11 and is not an analysed outcome. '
            'Blank in a v0.8–v0.11 CSV row means not collected. Missing in older legacy records means unknown, '
            'not false.'
        ),
        'definitionScope': (
            'Each codebooks entry describes only records that name it. instrumentDefinitions are historical '
            'notes by instrumentVersion, not exact definitions. Separate records by instrumentVersion. '
            'Consult the matching historical instrument for records with unavailable definitions; never apply '
            'current definitions to legacy answers.'
        ),
        'interrupted': (
            'Coarse pause/hide/route/recovery flag, not an event log. Abrupt termination may lose time since '
            'the last successful one-second checkpoint.'
        ),
        'taskStatus': ['completed', 'skipped', 'could_not_work_out'],
        'answerStatus': ['answered', 'unanswered', 'could_not_work_out', 'not_applicable'],
        'analysis': (
            'Raw values unchanged. For v0.5 reverse-score answered Q3 only as 6-value; Q8 is multiple choice '
            'and Q10 is positive. Historical v0.1 reverse-scored Q3/Q8/Q10. Pair P13/Q14 qualitatively by '
            'participantCode; count unanswered, not_applicable, skip and inability separately. No automatic '
            'correctness coding. Incomplete/abandoned sessions are excluded.'
        ),
        'coding': (
            'Keep researcher coding in a separate file joined on participantCode and item/task ID. '
            'Separate records by instrumentVersion. v0.5 P3 combines completed and current enrolment; '
            'v0.6–v0.10 course items distinguish Completed (1), Currently enrolled (2), and Neither (3), with '
            'unanswered unknown. v0.11 P3 combines courses currently or previously studied; value 8 explicitly '
            'means none, while unanswered remains unknown. Do not recode or pool v0.5 P3 as later statuses, or '
            'v0.6–v0.10 status rows as v0.11 selections. Course exposure alone '
            'does not establish expertise. Use non-exclusive non-expert/compiler-exposed/out-of-audience '
            'flags; report overlap and unknown where missing data do not establish a flag.'
        ),
    })
    columns = ['participantCode', 'submissionId', 'receiptId', 'studyVersion', 'contentVersion', 'instrumentVersion',
               'consentVersion', 'schemaVersion', 'canonicalVersion', 'mode', 'appRevision', 'artefactSha256',
               'section', 'itemId', 'status', 'value', 'durationMs', 'interrupted', 'setupReached',
               'contentProvenance', 'contentDigest']
    with private_file(directory / 'submissions.csv', 'x', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for record in records:
            p = record['submission']
            base = {k: p[k] for k in
                    ('participantCode', 'submissionId', 'studyVersion', 'contentVersion', 'instrumentVersion')}
            base['consentVersion'] = p['consent']['version']
            base.update(record['release'])
            base['receiptId'] = record['receipt']['receiptId']
            base['contentProvenance'] = record['contentProvenance']['status']
            base['contentDigest'] = record['contentProvenance'].get('digest')
            def row(**values):
                writer.writerow({k: safe_cell(v) for k, v in {**base, **values}.items()})  # noqa: B023 - called only within this iteration
            for key, value in p['consent']['acknowledgements'].items():
                row(section='consent', itemId=key, status='acknowledged', value=value)
            for section in ('pre', 'post'):
                for key, answer in p[section].items():
                    row(section=section, itemId=key, **answer)
            for t in p['tasks']:
                row(section=t['id'], itemId=t['id'], status=t['status'], durationMs=t['durationMs'],
                    interrupted=t['interrupted'], setupReached=t.get('setupReached'))
                for key, answer in t['answers'].items():
                    row(section=t['id'], itemId=key, **answer)
    return len(records)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    for name in ('export', 'backup', 'restore'):
        p = sub.add_parser(name)
        p.add_argument('source', type=Path)
        p.add_argument('destination', type=Path)
        if name == 'export':
            p.add_argument('--researcher-pack', dest='researcher_packs', type=Path, action='append', default=[],
                           metavar='RELEASE_DIR',
                           help='frozen instrument release whose researcher pack is verified and joined')
    p = sub.add_parser('backfill-provenance')
    p.add_argument('source', type=Path)
    p.add_argument('destination', type=Path)
    p.add_argument('--release', dest='releases', type=Path, action='append', required=True, metavar='PUBLIC_PAIR_DIR',
                   help='frozen public participant package whose content a linked record used')
    p.add_argument('--links', type=Path, required=True, help='explicit record-to-content links (JSON)')
    p = sub.add_parser('delete-participant')
    p.add_argument('source', type=Path)
    p.add_argument('participant_code')
    p.add_argument('--confirm', action='store_true', required=True)
    p = sub.add_parser('purge')
    p.add_argument('paths', type=Path, nargs='+')
    p.add_argument('--confirm', action='store_true', required=True)
    args = parser.parse_args()
    try:
        if args.command == 'export':
            print(f'Exported {export(args.source, args.destination, args.researcher_packs)} sessions.')
        elif args.command == 'backfill-provenance':
            result = backfill_provenance(args.source, args.destination, args.releases, args.links)
            print(f'Linked {result.linked} records; {result.unchanged} already linked. Verify the copy, then '
                  'replace the store only while collection is stopped.')
        elif args.command in ('backup', 'restore'):
            backup(args.source, args.destination)
            check, _ = open_db(args.destination)
            check.close()
            print('Verified copy complete. Keep collection stopped during restore.')
        elif args.command == 'delete-participant':
            # Withdrawal needs only a sound SQLite file. A snapshot failure is reported after
            # deletion rather than blocking it; snapshots hold no respondent data.
            check, layout = open_db(args.source, verify_snapshots=False)
            snapshots_ok = not layout.has_snapshots or snapshots_verified(check, layout)
            check.close()
            db = sqlite3.connect(args.source)
            try:
                db.execute('PRAGMA secure_delete=ON')
                with db:
                    rows = db.execute(f'SELECT submission_id, {layout.submission_json} FROM {layout.table}').fetchall()
                    ids = [(sid,) for sid, p in rows if json.loads(p)['participantCode'] == args.participant_code]
                    db.executemany(f'DELETE FROM {layout.table} WHERE submission_id=?', ids)
                db.execute('VACUUM')
            finally:
                db.close()
            print(f'Deleted {len(ids)} records. Apply deletion to backups and replace exports separately.')
            if not snapshots_ok:
                print('Warning: snapshot verification failed for this store. The deletion above completed; do not '
                      'export or back up this store until it is restored from a verified backup.', file=sys.stderr)
                sys.exit(3)  # distinct from argparse usage errors (2): deletion did complete
        else:
            for path in args.paths:
                path = private_path(path)
                if path.suffix not in ('.sqlite3', '.json', '.csv'):
                    raise ValueError('Only explicit study database/export files can be purged')
                path.unlink()
                if path.suffix == '.sqlite3':
                    for suffix in ('-wal', '-shm', '-journal'):
                        Path(str(path) + suffix).unlink(missing_ok=True)
            print('Named files removed. Check backup, export, and host snapshot inventory.')
    except BackfillError as error:
        # The message names the failed check and link position only; the source is unchanged.
        parser.exit(1, f'Provenance backfill rejected: {error}. Nothing was written.\n')
    except ResearcherPackError as error:
        # The message names the failed provenance check only; nothing was exported.
        parser.exit(1, f'Researcher pack rejected: {error}. Nothing was exported.\n')
    except (OSError, ValueError, sqlite3.Error):
        parser.exit(1, 'Operation failed. Check private paths, schema, permissions, and destination existence.\n')


if __name__ == '__main__':
    main()
