"""Controlled private backfill of verified participant-content provenance for legacy submissions."""
import hashlib
import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

from test_evaluation_submission import (
    HISTORICAL,
    canonical,
    frozen_public_pair,
    historical_package,
    pre_snapshot_store,
    synthetic,
)

from src.backend.evaluation.backfill import BackfillError
from src.backend.evaluation.cli import backfill_provenance, export
from src.backend.evaluation.content import content_snapshot, load_participant_package
from src.backend.evaluation.service import Config, StudyService

APP_ROOT = Path(__file__).resolve().parents[1]
RAW_COLUMNS = 'submission_id, digest, submission_json, receipt, release'
# The version-3 additions, as published before the backfill, to model stores written by that release.
SCHEMA_3 = (
    'CREATE TABLE participant_content_snapshots (digest TEXT PRIMARY KEY NOT NULL, digest_algorithm TEXT NOT NULL, '
    'identity_version INTEGER NOT NULL, canonicalisation TEXT NOT NULL, canonicalisation_version INTEGER NOT NULL, '
    'package_schema_version INTEGER NOT NULL, instrument_version TEXT NOT NULL, content_version TEXT NOT NULL, '
    'study_version TEXT NOT NULL, canonical_content BLOB NOT NULL)',
    'ALTER TABLE submissions ADD COLUMN content_digest TEXT REFERENCES participant_content_snapshots(digest)',
    "ALTER TABLE submissions ADD COLUMN content_provenance TEXT NOT NULL DEFAULT 'legacy_unavailable' "
    "CHECK (content_provenance IN ('snapshot', 'legacy_unavailable'))",
    'CREATE TRIGGER submissions_provenance_immutable BEFORE UPDATE OF content_digest, content_provenance '
    "ON submissions BEGIN SELECT RAISE(ABORT, 'Submission content provenance is immutable'); END",
)


def with_digest(package):
    """Recompute a synthetic package's canonical public digest after its content was edited."""
    package['identity']['digest'] = hashlib.sha256(canonical(
        {'packageSchemaVersion': package['packageSchemaVersion'], 'content': package['content']}).encode()).hexdigest()
    return package


def worded_historical_package():
    """A synthetic earlier release whose own wording and rules differ from the installed package."""
    package = historical_package()
    package['content']['fields'][0]['prompt'] += ' (historical synthetic wording)'
    return with_digest(package)


def rows(path, columns=RAW_COLUMNS):
    db = sqlite3.connect(path)
    try:
        return db.execute(f'SELECT {columns} FROM submissions ORDER BY submission_id').fetchall()
    finally:
        db.close()


class ProvenanceBackfillTests(unittest.TestCase):
    """A pre-snapshot store holding a verifiable historical record, a verifiable current-release
    record collected before snapshots existed, and a record no frozen artefact describes."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.store = Config(self.root / 'study').path
        self.historical = worded_historical_package()
        self.current = deepcopy(load_participant_package())
        self.verifiable = synthetic(self.historical['content'])
        self.early_current = synthetic()
        self.unknown = synthetic()
        self.unknown.update(instrumentVersion='v0.9', contentVersion='v0.9-preview-1', studyVersion='v0.9-synthetic-1')
        self.unknown['consent']['version'] = 'v0.9-preview-1'
        stored = pre_snapshot_store(self.store, [self.verifiable, self.early_current, self.unknown])
        self.digests = {row[0]: row[1] for row in stored}
        self.historical_release = frozen_public_pair(self.root / 'releases/historical', self.historical)
        self.current_release = frozen_public_pair(self.root / 'releases/current', self.current)

    def links(self, *claims, name='links.json'):
        """Write the explicit private operation input: one link per (submission, content digest) claim."""
        path = self.root / name
        path.write_text(json.dumps({'backfillSchemaVersion': 1, 'links': [
            {'submissionId': submission['submissionId'],
             'submissionDigest': self.digests.get(submission['submissionId'], '0' * 64),
             'contentDigest': package['identity']['digest']} for submission, package in claims]}))
        return path

    def backfill(self, destination, links, releases=None):
        releases = [self.historical_release, self.current_release] if releases is None else releases
        return backfill_provenance(self.store, self.root / destination, releases, links)

    def exported(self, store, name):
        destination = self.root / name
        export(store, destination)
        records = {r['submission']['submissionId']: r
                   for r in json.loads((destination / 'submissions.json').read_text(encoding='utf-8'))}
        return destination, records

    def test_verified_legacy_records_link_to_exact_historical_wording(self):
        source_bytes = self.store.read_bytes()
        links = self.links((self.verifiable, self.historical), (self.early_current, self.current))
        result = self.backfill('backfilled.sqlite3', links)
        self.assertEqual((result.linked, result.unchanged), (2, 0))
        backfilled = self.root / 'backfilled.sqlite3'
        # The source store is untouched, and the copy keeps every raw column byte for byte.
        self.assertEqual(self.store.read_bytes(), source_bytes)
        self.assertEqual(rows(backfilled), rows(self.store))
        self.assertEqual(backfilled.stat().st_mode & 0o777, 0o600)

        destination, records = self.exported(backfilled, 'export')
        codebook = json.loads((destination / 'codebook.json').read_text(encoding='utf-8'))
        for submission, package in ((self.verifiable, self.historical), (self.early_current, self.current)):
            digest = package['identity']['digest']
            provenance = records[submission['submissionId']]['contentProvenance']
            self.assertEqual({k: provenance[k] for k in ('status', 'digest', 'codebook', 'snapshotFile')},
                             {'status': 'snapshot', 'digest': digest, 'codebook': digest,
                              'snapshotFile': f'snapshots/{digest}.json'})
            self.assertEqual(provenance['backfill'], {'backfillVersion': 1, 'evidence': 'frozen-public-package'})
            self.assertEqual((destination / provenance['snapshotFile']).read_bytes(),
                             content_snapshot(package).canonical_content)
            self.assertEqual(codebook['codebooks'][digest]['fields'], package['content']['fields'])
            self.assertEqual(records[submission['submissionId']]['submission'],
                             json.loads(json.dumps(submission, ensure_ascii=False)))
        historical_prompt = codebook['codebooks'][self.historical['identity']['digest']]['fields'][0]['prompt']
        self.assertIn('(historical synthetic wording)', historical_prompt)
        # A record no frozen artefact was supplied for keeps its explicit unavailable marker.
        self.assertEqual(records[self.unknown['submissionId']]['contentProvenance']['status'], 'unavailable')
        self.assertEqual(codebook['unavailableDefinitions']['submissionIds'], [self.unknown['submissionId']])


    def test_repeating_the_backfill_keeps_established_links(self):
        links = self.links((self.verifiable, self.historical), (self.early_current, self.current))
        self.backfill('first.sqlite3', links)
        first = self.root / 'first.sqlite3'
        result = backfill_provenance(first, self.root / 'second.sqlite3',
                                     [self.historical_release, self.current_release], links)
        self.assertEqual((result.linked, result.unchanged), (0, 2))
        linkage = f'{RAW_COLUMNS}, content_provenance, content_digest, provenance_backfill'
        self.assertEqual(rows(self.root / 'second.sqlite3', linkage), rows(first, linkage))

    def test_conflicting_existing_provenance_fails_without_replacement(self):
        self.backfill('linked.sqlite3', self.links((self.verifiable, self.historical)))
        linked = self.root / 'linked.sqlite3'
        # A record submitted with its snapshot, stored alongside the backfilled one.
        native = synthetic()
        config = Config(self.root / 'native')
        config.path.parent.mkdir(parents=True)
        config.path.write_bytes(linked.read_bytes())
        StudyService(config).submit(native)
        self.digests.update(rows(config.path, 'submission_id, digest'))
        linkage = f'{RAW_COLUMNS}, content_provenance, content_digest, provenance_backfill'
        before = rows(config.path, linkage)
        for label, claim in (('backfilled record relinked', (self.verifiable, self.current)),
                             ('submitted record relinked', (native, self.historical))):
            with self.subTest(label):
                destination = self.root / label.replace(' ', '-')
                with self.assertRaisesRegex(BackfillError, 'already links different participant content'):
                    backfill_provenance(config.path, destination, [self.historical_release, self.current_release],
                                        self.links(claim, name=f'{label}.json'))
                self.assertFalse(destination.exists())
                self.assertEqual(rows(config.path, linkage), before)
        # A submitted record named with its own snapshot is already linked: nothing changes.
        result = backfill_provenance(config.path, self.root / 'same.sqlite3', [self.current_release],
                                     self.links((native, self.current), name='same.json'))
        self.assertEqual((result.linked, result.unchanged), (0, 1))
        self.assertEqual(rows(self.root / 'same.sqlite3', linkage), before)

    def test_unverifiable_or_ambiguous_records_stay_unavailable(self):
        relabelled = synthetic()  # Current wording and membership under an earlier release's labels.
        relabelled.update(HISTORICAL)
        relabelled['consent']['version'] = HISTORICAL['contentVersion']
        [row] = pre_snapshot_store(self.root / 'relabelled.sqlite3', [relabelled])
        self.digests[row[0]] = row[1]
        same_labels = deepcopy(self.historical)
        same_labels['content']['fields'][0]['prompt'] += ' (another wording under the same labels)'
        same_labels_release = frozen_public_pair(self.root / 'releases/same-labels', with_digest(same_labels))
        tampered = frozen_public_pair(self.root / 'releases/tampered', self.historical)
        package_file = tampered / 'participant-package-v2.json'
        package_file.write_bytes(package_file.read_bytes().replace(b'historical synthetic wording', b'edited wording'))
        cases = {
            'version label only': (self.links((self.unknown, self.historical), name='label.json'), None,
                                   'different study/content/instrument identities'),
            'labels without matching rules': (self.links((relabelled, self.historical), name='rules.json'),
                                              'relabelled.sqlite3',
                                              "not admissible under the release's own rules"),
            'ambiguous identities': (self.links((self.verifiable, self.historical), name='ambiguous.json'),
                                     [self.historical_release, same_labels_release], 'ambiguous'),
            'undeclared content': (self.links((self.verifiable, self.historical), name='undeclared.json'),
                                   [self.current_release],
                                   'no supplied frozen release'),
            'tampered release': (self.links((self.verifiable, self.historical), name='tampered.json'), [tampered],
                                 'release 1: the frozen public package does not verify'),
            'unknown submission': (self.links((synthetic(), self.current), name='unknown.json'), None,
                                   'not in the store'),
        }
        wrong_digest = self.links((self.verifiable, self.historical), name='wrong-digest.json')
        claims = json.loads(wrong_digest.read_text())
        claims['links'][0]['submissionDigest'] = '0' * 64
        wrong_digest.write_text(json.dumps(claims))
        cases['submission digest'] = (wrong_digest, None, 'submission digest does not match')
        for label, (links, variant, message) in cases.items():
            with self.subTest(label):
                source = self.root / variant if isinstance(variant, str) else self.store
                releases = variant if isinstance(variant, list) else None
                destination = self.root / f'rejected-{label.replace(" ", "-")}'
                source_bytes = source.read_bytes()
                with self.assertRaisesRegex(BackfillError, message):
                    backfill_provenance(source, destination,
                                        releases or [self.historical_release, self.current_release], links)
                self.assertFalse(destination.exists())
                self.assertEqual(source.read_bytes(), source_bytes)
        _, records = self.exported(self.store, 'still-unavailable')
        self.assertEqual({r['contentProvenance']['status'] for r in records.values()}, {'unavailable'})

    def test_record_whose_json_no_longer_matches_its_digest_is_not_linked(self):
        drifted = self.root / 'drifted.sqlite3'
        drifted.write_bytes(self.store.read_bytes())
        db = sqlite3.connect(drifted)
        changed = deepcopy(self.verifiable)
        changed['tasks'][1]['durationMs'] += 1
        db.execute('UPDATE submissions SET submission_json = ? WHERE submission_id = ?',
                   (json.dumps(changed), self.verifiable['submissionId']))
        db.commit()
        db.close()
        with self.assertRaisesRegex(BackfillError, 'does not match its stored submission digest'):
            backfill_provenance(drifted, self.root / 'drifted-backfilled.sqlite3', [self.historical_release],
                                self.links((self.verifiable, self.historical)))
        self.assertFalse((self.root / 'drifted-backfilled.sqlite3').exists())

    def test_links_file_must_be_explicit_and_strict(self):
        valid = json.loads(self.links((self.verifiable, self.historical)).read_text())
        link = valid['links'][0]
        cases = {'duplicate key': b'{"backfillSchemaVersion": 1, "backfillSchemaVersion": 1, "links": []}',
                 'no links': json.dumps({**valid, 'links': []}).encode(),
                 'unknown version': json.dumps({**valid, 'backfillSchemaVersion': 2}).encode(),
                 'label instead of digest': json.dumps({**valid, 'links': [
                     {'submissionId': link['submissionId'], 'submissionDigest': link['submissionDigest'],
                      'instrumentVersion': 'v0.10'}]}).encode(),
                 'repeated record': json.dumps({**valid, 'links': [link, link]}).encode()}
        for label, data in cases.items():
            with self.subTest(label):
                path = self.root / f'{label}.json'
                path.write_bytes(data)
                with self.assertRaises(BackfillError):
                    self.backfill(f'rejected-{label.replace(" ", "-")}', path)
                self.assertFalse((self.root / f'rejected-{label.replace(" ", "-")}').exists())


    def test_store_permits_only_the_verified_backfill_change(self):
        self.backfill('linked.sqlite3', self.links((self.verifiable, self.historical)))
        config = Config(self.root / 'guarded')
        config.path.parent.mkdir(parents=True)
        config.path.write_bytes((self.root / 'linked.sqlite3').read_bytes())
        native = synthetic()
        StudyService(config).submit(native)
        current = self.current['identity']['digest']
        evidence = canonical({'backfillVersion': 1, 'evidence': 'frozen-public-package'})
        linkage = f'{RAW_COLUMNS}, content_provenance, content_digest, provenance_backfill'
        before = rows(config.path, linkage)
        backfilled, submitted, legacy = (self.verifiable['submissionId'], native['submissionId'],
                                         self.early_current['submissionId'])
        rejected = [
            (backfilled, "content_provenance = 'legacy_unavailable', content_digest = NULL, "
                         'provenance_backfill = NULL'),
            (backfilled, f"content_digest = '{current}'"),
            (backfilled, "provenance_backfill = '{}'"),
            (submitted, "content_provenance = 'legacy_unavailable', content_digest = NULL"),
            (submitted, f"provenance_backfill = '{evidence}'"),
            (legacy, f"content_provenance = 'snapshot', content_digest = '{current}'"),
            (legacy, f"content_provenance = 'snapshot', content_digest = '{'0' * 64}', "
                     f"provenance_backfill = '{evidence}'"),
            (legacy, f"provenance_backfill = '{evidence}'"),
            (legacy, "content_provenance = 'other'"),
            *((record, f"{column} = {column} || ''") for record in (legacy, backfilled, submitted)
              for column in ('submission_id', 'digest', 'submission_json', 'receipt', 'release')),
        ]
        db = sqlite3.connect(config.path)
        try:
            for record, assignment in rejected:
                with self.subTest(record=record, assignment=assignment), self.assertRaises(sqlite3.DatabaseError):
                    db.execute(f'UPDATE submissions SET {assignment} WHERE submission_id = ?', (record,))
            other = synthetic()
            with self.assertRaises(sqlite3.DatabaseError):
                db.execute('INSERT INTO submissions VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                           (other['submissionId'], 'x', canonical(other), '{}', '{}', current, 'snapshot', evidence))
            self.assertEqual(rows(config.path, linkage), before)
            # Exactly one change remains permitted: a legacy row to a registered snapshot, with backfill evidence.
            db.execute('UPDATE submissions SET content_provenance = ?, content_digest = ?, provenance_backfill = ? '
                       'WHERE submission_id = ?', ('snapshot', current, evidence, legacy))
        finally:
            db.rollback()
            db.close()

    def test_backfilled_store_supports_backup_restore_export_and_withdrawal(self):
        self.verifiable['post']['Q18'] = {'status': 'answered', 'value': 'Withdrawn synthetic observation ζ'}
        store = self.root / 'withdrawal/study.sqlite3'
        [row] = pre_snapshot_store(store, [self.verifiable])
        self.digests[row[0]] = row[1]
        backfilled = self.root / 'withdrawal/backfilled.sqlite3'
        backfill_provenance(store, backfilled, [self.historical_release],
                            self.links((self.verifiable, self.historical)))
        snapshot = content_snapshot(self.historical).canonical_content
        for respondent_value in (self.verifiable['participantCode'], 'Withdrawn synthetic'):
            self.assertNotIn(respondent_value.encode(), snapshot)

        def cli(*args):
            return subprocess.run([sys.executable, '-m', 'src.backend.evaluation.cli', *map(str, args)],
                                  cwd=APP_ROOT, capture_output=True, text=True, check=False)
        copy, restored = self.root / 'withdrawal/backup.sqlite3', self.root / 'withdrawal/restored.sqlite3'
        self.assertEqual(cli('backup', backfilled, copy).returncode, 0)
        self.assertEqual(cli('restore', copy, restored).returncode, 0)
        _, records = self.exported(restored, 'restored-export')
        self.assertEqual(records[self.verifiable['submissionId']]['contentProvenance']['digest'],
                         self.historical['identity']['digest'])
        deleted = cli('delete-participant', restored, self.verifiable['participantCode'], '--confirm')
        self.assertEqual((deleted.returncode, deleted.stderr), (0, ''))
        self.assertEqual(rows(restored), [])
        self.assertNotIn(b'Withdrawn synthetic', restored.read_bytes())
        db = sqlite3.connect(restored)
        try:
            self.assertEqual(db.execute('SELECT canonical_content FROM participant_content_snapshots').fetchall(),
                             [(snapshot,)])
        finally:
            db.close()

    def test_cli_reports_counts_and_rejections_without_stored_answers(self):
        self.verifiable['post']['Q18'] = {'status': 'answered', 'value': 'Private synthetic answer λ'}
        store = self.root / 'cli/study.sqlite3'
        [row] = pre_snapshot_store(store, [self.verifiable])
        self.digests[row[0]] = row[1]

        def cli(destination, *releases, links):
            options = [arg for release in releases for arg in ('--release', release)]
            return subprocess.run([sys.executable, '-m', 'src.backend.evaluation.cli', 'backfill-provenance',
                                   str(store), str(destination), *map(str, options), '--links', str(links)],
                                  cwd=APP_ROOT, capture_output=True, text=True, check=False)
        linked = cli(self.root / 'cli/linked.sqlite3', self.historical_release,
                     links=self.links((self.verifiable, self.historical), name='cli.json'))
        self.assertEqual(linked.returncode, 0, linked.stderr)
        self.assertIn('Linked 1 records; 0 already linked.', linked.stdout)
        rejected = cli(self.root / 'cli/rejected.sqlite3', self.current_release,
                       links=self.links((self.verifiable, self.current), name='cli-mismatch.json'))
        self.assertEqual(rejected.returncode, 1)
        self.assertIn('Provenance backfill rejected: link 1:', rejected.stderr)
        self.assertIn('Nothing was written.', rejected.stderr)
        for private in (self.verifiable['participantCode'], self.verifiable['submissionId'], 'Private synthetic'):
            self.assertNotIn(private, rejected.stdout + rejected.stderr)
        self.assertFalse((self.root / 'cli/rejected.sqlite3').exists())
        existing = cli(self.root / 'cli/linked.sqlite3', self.historical_release,
                       links=self.links((self.verifiable, self.historical), name='cli.json'))
        self.assertEqual(existing.returncode, 1)  # A destination is never overwritten.

    def test_schema_3_store_is_migrated_and_backfilled_without_changing_records(self):
        config = Config(self.root / 'v3')
        pre_snapshot_store(config.path, [self.verifiable])
        db = sqlite3.connect(config.path)
        for statement in SCHEMA_3:
            db.execute(statement)
        db.execute('PRAGMA user_version=3')
        db.commit()
        db.close()
        self.digests.update(rows(config.path, 'submission_id, digest'))
        linkage = f'{RAW_COLUMNS}, content_provenance, content_digest'
        before = rows(config.path, linkage)
        _, records = self.exported(config.path, 'v3-export')  # Version-3 stores remain readable as they are.
        self.assertEqual(records[self.verifiable['submissionId']]['contentProvenance']['status'], 'unavailable')
        backfilled = self.root / 'v3-backfilled.sqlite3'
        backfill_provenance(config.path, backfilled, [self.historical_release],
                            self.links((self.verifiable, self.historical)))
        self.assertEqual(rows(config.path, linkage), before)
        self.assertEqual(rows(backfilled, RAW_COLUMNS), [row[:5] for row in before])
        for _ in range(2):  # First use migrates in place; repeating is a no-op.
            StudyService(config).connect().close()
        self.assertEqual(rows(config.path, linkage), before)
        db = sqlite3.connect(config.path)
        try:
            self.assertEqual(db.execute('PRAGMA user_version').fetchone(), (4,))
        finally:
            db.close()


if __name__ == '__main__':
    unittest.main()
