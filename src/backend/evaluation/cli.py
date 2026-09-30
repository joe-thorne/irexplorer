"""Private researcher export, SQLite backup/restore, and retention operations."""
import argparse
import csv
import hashlib
import json
import os
import sqlite3
from pathlib import Path

from .content import participant_content, participant_snapshot
from .service import SCHEMA_VERSION, Config, canonical

UNAVAILABLE_DEFINITION = {
    'status': 'unavailable',
    'reason': ('Stored before participant-content snapshots were recorded; the exact participant content for '
               'this record is not available and current content must not be substituted.'),
}


def private_path(path):
    path = Path(path).resolve()
    Config(path.parent)  # Reject public/project output locations.
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    return path


def open_db(path):
    db = sqlite3.connect(f'{Path(path).resolve().as_uri()}?mode=ro', uri=True)
    try:
        version = db.execute('PRAGMA user_version').fetchone()[0]
        table = {1: 'responses', 2: 'submissions', SCHEMA_VERSION: 'submissions'}.get(version)
        tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        if (table not in tables or db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok'
                or (version == SCHEMA_VERSION and not snapshots_verified(db))):
            raise ValueError('Unsupported or damaged study database')
    except (ValueError, sqlite3.Error):
        db.close()
        raise
    return db


def snapshots_verified(db):
    """Check every snapshot's bytes against its digest and identity, and every submission link."""
    if 'participant_content' not in {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}:
        return False
    for digest, algorithm, package_schema, instrument, content, study, data in db.execute(
            'SELECT digest, digest_algorithm, package_schema_version, instrument_version, content_version, '
            'study_version, canonical_content FROM participant_content'):
        if algorithm != 'sha256' or not isinstance(data, bytes) or hashlib.sha256(data).hexdigest() != digest:
            return False
        try:
            public = json.loads(data)
            definition = public['content']
            if (public['packageSchemaVersion'], definition['instrumentVersion'], definition['contentVersion'],
                    definition['studyVersion']) != (package_schema, instrument, content, study):
                return False
        except (ValueError, TypeError, KeyError):
            return False
    return not db.execute(
        'SELECT 1 FROM submissions s LEFT JOIN participant_content c ON c.digest = s.content_digest '
        "WHERE NOT ((s.content_provenance = 'snapshot' AND c.digest IS NOT NULL) "
        "OR (s.content_provenance = 'legacy_unavailable' AND s.content_digest IS NULL)) LIMIT 1").fetchone()


def submission_storage_columns(db):
    return ('responses', 'payload') if db.execute('PRAGMA user_version').fetchone()[0] == 1 else (
        'submissions', 'submission_json')


def backup(source, destination):
    destination = private_path(destination)
    # Exclusive creation prevents an accidental overwrite of a live database.
    fd = os.open(destination, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    os.close(fd)
    src = dst = None
    try:
        src = open_db(source)
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


def safe_cell(value):
    if isinstance(value, (dict, list)):
        value = canonical(value)
    if isinstance(value, str) and (value.lstrip().startswith(('=', '+', '-', '@'))
                                   or value.startswith(('\t', '\r', '\n'))):
        return "'" + value
    return value


def export(source, directory):
    directory = private_path(Path(directory) / 'placeholder').parent
    db = open_db(source)
    try:
        table, submission_json = submission_storage_columns(db)
        if db.execute('PRAGMA user_version').fetchone()[0] == SCHEMA_VERSION:
            rows = db.execute(
                f'SELECT s.{submission_json}, s.receipt, s.release, c.digest, c.instrument_version, '
                f'c.content_version, c.study_version FROM {table} s '
                'LEFT JOIN participant_content c ON c.digest = s.content_digest ORDER BY s.submission_id').fetchall()
        else:
            rows = [(*row, None, None, None, None) for row in db.execute(
                f'SELECT {submission_json}, receipt, release FROM {table} ORDER BY submission_id')]
    finally:
        db.close()
    records = [{'submission': json.loads(p), 'receipt': json.loads(r), 'release': json.loads(v),
                'contentProvenance': UNAVAILABLE_DEFINITION if digest is None else {
                    'status': 'snapshot', 'digest': digest, 'instrumentVersion': instrument,
                    'contentVersion': content_version, 'studyVersion': study}}
               for p, r, v, digest, instrument, content_version, study in rows]
    def write(name, value):
        path = directory / name
        with open(path, 'x', encoding='utf-8') as f:
            os.chmod(path, 0o600)
            json.dump(value, f, ensure_ascii=False, indent=2)
    write('submissions.json', records)
    content = participant_content()
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
        'schemaVersion': 3, 'fields': content['fields'], 'scales': content['scales'],
        'versions': {k: content[k] for k in ('studyVersion', 'instrumentVersion', 'contentVersion')},
        'contentDigest': participant_snapshot().digest,
        'contentProvenance': (
            'fields and scales are the currently packaged participant content identified by contentDigest. '
            'They describe only records whose contentDigest matches. A record with contentProvenance '
            'unavailable was stored before snapshots were recorded: its exact definition is not available '
            'here, and these current definitions must not be applied to it.'
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
            'Fields/scales describe only the versions named here. Separate records by instrumentVersion. '
            'Consult the matching historical instrument for older versions; never apply current definitions '
            'to legacy answers.'
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
    path = directory / 'submissions.csv'
    with open(path, 'x', encoding='utf-8', newline='') as f:
        os.chmod(path, 0o600)
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
            print(f'Exported {export(args.source, args.destination)} sessions.')
        elif args.command in ('backup', 'restore'):
            backup(args.source, args.destination)
            check = open_db(args.destination)
            check.close()
            print('Verified copy complete. Keep collection stopped during restore.')
        elif args.command == 'delete-participant':
            check = open_db(args.source)
            check.close()
            db = sqlite3.connect(args.source)
            try:
                db.execute('PRAGMA secure_delete=ON')
                with db:
                    table, submission_json = submission_storage_columns(db)
                    rows = db.execute(f'SELECT submission_id, {submission_json} FROM {table}').fetchall()
                    ids = [(sid,) for sid, p in rows if json.loads(p)['participantCode'] == args.participant_code]
                    db.executemany(f'DELETE FROM {table} WHERE submission_id=?', ids)
                db.execute('VACUUM')
            finally:
                db.close()
            print(f'Deleted {len(ids)} records. Apply deletion to backups and replace exports separately.')
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
    except (OSError, ValueError, sqlite3.Error):
        parser.exit(1, 'Operation failed. Check private paths, schema, permissions, and destination existence.\n')


if __name__ == '__main__':
    main()
