"""Private mixed-release export: exact historical definitions, codebooks, and researcher-pack joins."""
import csv
import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient
from test_evaluation_submission import pre_snapshot_store, synthetic, upgraded_release

from src.backend.api.app import create_app
from src.backend.evaluation import cli as export_module
from src.backend.evaluation import content as study_content
from src.backend.evaluation.cli import export
from src.backend.evaluation.researcher_packs import ResearcherPackError
from src.backend.evaluation.service import Config

APP_ROOT = Path(__file__).resolve().parents[1]
SERVED_FLAGS = {'packageSchemaVersion', 'packageIdentity', 'collectionMode', 'submissionEnabled'}


def canonical_bytes(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()


def formatted_bytes(value):
    """The frozen-release file format written by the thesis instrument compiler."""
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()


def identity_of(value):
    return {'identityVersion': 1, 'algorithm': 'sha256', 'canonicalisation': 'sorted-json-utf8-v1',
            'canonicalisationVersion': 1, 'digest': hashlib.sha256(canonical_bytes(value)).hexdigest()}


def write_release(directory, package, *, note='synthetic researcher note'):
    """Write a synthetic frozen instrument release in the thesis layout and return its researcher pack.

    The release holds the public package and public manifest, a researcher pack linked to the
    package's public identity, and a private manifest declaring both identities and file hashes.
    """
    directory.mkdir(parents=True)
    public = package['identity']
    unsigned = {
        'researcherSchemaVersion': 1,
        'publicIdentity': deepcopy(public),
        'material': {
            'notes': note,
            'relationships': [{'id': 'expectation-pair', 'items': ['P13', 'Q14'], 'interpretation': 'qualitative'}],
            'transformations': [{'item': 'Q3', 'operation': 'reverse-five-point', 'applyTo': 'answered',
                                 'expression': '6 - raw value',
                                 'missing': 'Retain unanswered and not_applicable; never transform null.'}],
        },
        'codebook': {
            'formatVersion': 1, 'publicIdentity': deepcopy(public),
            'taskOutcomes': {'participant': ['completed', 'skipped', 'could_not_work_out'],
                             'researcher': ['correct', 'partial', 'incorrect', 'skipped', 'unable']},
        },
    }
    pack = {**unsigned, 'identity': identity_of(unsigned)}
    files = {
        'participant-package-v2.json': formatted_bytes(package),
        'researcher-pack.json': formatted_bytes(pack),
    }
    package_hash = hashlib.sha256(files['participant-package-v2.json']).hexdigest()
    files['public-manifest.json'] = formatted_bytes({
        'manifestSchemaVersion': 1, 'packageSchemaVersion': 2, 'identity': public,
        'artifact': {'file': 'participant-package-v2.json', 'sha256': package_hash}})
    manifest = {
        'manifestSchemaVersion': 1,
        'freezeIdentity': identity_of({'publicIdentity': public, 'researcherIdentity': pack['identity']}),
        'public': {'packageSchemaVersion': 2, 'identity': public, 'artifact': 'participant-package-v2.json'},
        'researcher': {'schemaVersion': 1, 'identity': pack['identity'], 'publicIdentity': public,
                       'artifacts': ['researcher-pack.json']},
        'artifacts': {name: hashlib.sha256(data).hexdigest() for name, data in files.items()},
    }
    files['researcher-manifest.json'] = formatted_bytes(manifest)
    for name, data in files.items():
        (directory / name).write_bytes(data)
    return pack


def rewrite(directory, name, change):
    """Edit one release file and re-declare its hash, so only the deeper provenance check can fail."""
    path = directory / name
    value = json.loads(path.read_bytes())
    change(value)
    path.write_bytes(formatted_bytes(value))
    manifest_path = directory / 'researcher-manifest.json'
    manifest = json.loads(manifest_path.read_bytes())
    manifest['artifacts'][name] = hashlib.sha256(path.read_bytes()).hexdigest()
    manifest_path.write_bytes(formatted_bytes(manifest))


class MixedReleaseExportTests(unittest.TestCase):
    """A store holding a legacy row, a current-release row, and a later-release row."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.config = Config(self.root / 'study', origin='http://testserver')
        self.legacy = synthetic()
        self.legacy.update(instrumentVersion='v0.10', contentVersion='v0.10-preview-1',
                           studyVersion='v0.10-synthetic-1')
        pre_snapshot_store(self.config.path, [self.legacy])
        self.current_package = deepcopy(study_content.load_participant_package())
        self.current = synthetic()
        self.current['post']['Q3'] = {'status': 'answered', 'value': 2}
        self.current['post']['Q1'] = {'status': 'not_applicable', 'value': None}
        self.current['tasks'][2]['status'] = 'skipped'
        with TestClient(create_app(study_config=self.config)) as client:
            self.served = client.get('/api/study/content').json()
            response = client.post('/api/study/submissions', json=self.current,
                                   headers={'Origin': 'http://testserver'})
            self.assertEqual(response.status_code, 201)
        with upgraded_release() as upgraded:
            self.upgraded_package = deepcopy(study_content._installed_package())
            self.later = synthetic()
            self.later['tasks'][4]['status'] = 'could_not_work_out'
            with TestClient(create_app(study_config=self.config)) as client:
                self.served_later = client.get('/api/study/content').json()
                response = client.post('/api/study/submissions', json=self.later,
                                       headers={'Origin': 'http://testserver'})
                self.assertEqual(response.status_code, 201)
        self.current_digest = self.current_package['identity']['digest']
        self.later_digest = upgraded.digest
        self.assertNotEqual(self.current_digest, self.later_digest)

    def export(self, name, packs=()):
        destination = self.root / name
        self.assertEqual(export(self.config.path, destination, researcher_packs=packs), 3)
        return destination

    def read(self, destination, name):
        return json.loads((destination / name).read_text(encoding='utf-8'))

    def records(self, destination):
        return {r['submission']['submissionId']: r for r in self.read(destination, 'submissions.json')}

    def test_every_referenced_snapshot_is_exported_with_exact_served_wording(self):
        destination = self.export('export')
        snapshots = destination / 'snapshots'
        self.assertEqual(sorted(p.name for p in snapshots.iterdir()),
                         sorted(f'{d}.json' for d in (self.current_digest, self.later_digest)))
        for digest, served in ((self.current_digest, self.served), (self.later_digest, self.served_later)):
            data = (snapshots / f'{digest}.json').read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), digest)
            definition = {k: v for k, v in served.items() if k not in SERVED_FLAGS}
            self.assertEqual(data, canonical_bytes({'packageSchemaVersion': 2, 'content': definition}))
        self.assertEqual(snapshots.stat().st_mode & 0o777, 0o700)
        self.assertEqual((snapshots / f'{self.current_digest}.json').stat().st_mode & 0o777, 0o600)

    def test_each_record_links_its_version_specific_codebook(self):
        destination = self.export('export')
        records = self.records(destination)
        codebook = self.read(destination, 'codebook.json')
        self.assertEqual(codebook['schemaVersion'], 4)
        self.assertEqual(set(codebook['codebooks']), {self.current_digest, self.later_digest})
        for record_id, package in ((self.current['submissionId'], self.current_package),
                                   (self.later['submissionId'], self.upgraded_package)):
            provenance = records[record_id]['contentProvenance']
            digest = package['identity']['digest']
            self.assertEqual(provenance, {
                'status': 'snapshot', 'digest': digest, 'codebook': digest, 'snapshotFile': f'snapshots/{digest}.json',
                **{k: package['identity'][k] for k in ('instrumentVersion', 'contentVersion', 'studyVersion')}})
            book = codebook['codebooks'][provenance['codebook']]
            content = package['content']
            self.assertEqual(book['contentDigest'], digest)
            self.assertEqual(book['snapshotFile'], provenance['snapshotFile'])
            self.assertEqual(book['versions'], {k: content[k] for k in
                                                ('studyVersion', 'instrumentVersion', 'contentVersion')})
            for key in ('fields', 'scales', 'membership'):
                self.assertEqual(book[key], content[key])
            self.assertIsNone(book['researcherPack'])
        later_prompt = codebook['codebooks'][self.later_digest]['fields'][0]['prompt']
        self.assertIn('upgraded synthetic wording', later_prompt)
        current_prompt = codebook['codebooks'][self.current_digest]['fields'][0]['prompt']
        self.assertNotIn('upgraded synthetic wording', current_prompt)
        # Current definitions are never presented as a store-wide codebook.
        for key in ('fields', 'scales', 'versions', 'contentDigest'):
            self.assertNotIn(key, codebook)
        with open(destination / 'submissions.csv', newline='', encoding='utf-8') as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual({(r['submissionId'], r['contentProvenance'], r['contentDigest']) for r in rows}, {
            (self.legacy['submissionId'], 'unavailable', ''),
            (self.current['submissionId'], 'snapshot', self.current_digest),
            (self.later['submissionId'], 'snapshot', self.later_digest)})

    def test_legacy_records_receive_explicit_unavailable_definition_markers(self):
        destination = self.export('export')
        provenance = self.records(destination)[self.legacy['submissionId']]['contentProvenance']
        self.assertEqual(provenance['status'], 'unavailable')
        self.assertIsNone(provenance['codebook'])
        self.assertNotIn('digest', provenance)
        self.assertIn('must not be substituted', provenance['reason'])
        unavailable = self.read(destination, 'codebook.json')['unavailableDefinitions']
        self.assertEqual(unavailable['submissionIds'], [self.legacy['submissionId']])
        self.assertEqual(unavailable['marker'], provenance)

    def test_changing_packaged_content_cannot_change_exported_history(self):
        baseline = self.export('baseline')
        def unavailable():
            raise AssertionError('export consulted the currently packaged participant content')
        with (patch.object(study_content, '_installed_package', unavailable),
              patch.object(study_content, 'participant_snapshot', unavailable),
              patch.object(study_content, 'participant_content', unavailable)):
            without_package = self.export('without-package')
        with upgraded_release():
            after_upgrade = self.export('after-upgrade')
        self.assertFalse({'participant_content', 'participant_snapshot'} & set(vars(export_module)))
        for other in (without_package, after_upgrade):
            for name in ('codebook.json', 'submissions.json', 'submissions.csv',
                         f'snapshots/{self.current_digest}.json', f'snapshots/{self.later_digest}.json'):
                self.assertEqual((other / name).read_bytes(), (baseline / name).read_bytes(), name)

    def test_legacy_only_store_exports_no_current_definitions(self):
        store = self.root / 'legacy-only.sqlite3'
        pre_snapshot_store(store, [synthetic()])
        destination = self.root / 'legacy-only'
        self.assertEqual(export(store, destination), 1)
        codebook = self.read(destination, 'codebook.json')
        self.assertEqual(codebook['codebooks'], {})
        self.assertEqual(list((destination / 'snapshots').iterdir()), [])
        [record] = self.read(destination, 'submissions.json')
        self.assertEqual((record['contentProvenance']['status'], record['contentProvenance']['codebook']),
                         ('unavailable', None))

    def test_verified_researcher_packs_join_without_changing_raw_answers(self):
        current_pack = write_release(self.root / 'releases/current', self.current_package, note='current notes')
        later_pack = write_release(self.root / 'releases/later', self.upgraded_package, note='later notes')
        plain = self.export('plain')
        destination = self.export('joined', packs=[self.root / 'releases/later', self.root / 'releases/current'])
        self.assertFalse((plain / 'researcher-codebooks.json').exists())
        for name in ('submissions.json', 'submissions.csv', f'snapshots/{self.current_digest}.json'):
            self.assertEqual((destination / name).read_bytes(), (plain / name).read_bytes(), name)
        codebook = self.read(destination, 'codebook.json')
        researcher = self.read(destination, 'researcher-codebooks.json')
        self.assertEqual(set(researcher['packs']), {self.current_digest, self.later_digest})
        for digest, pack in ((self.current_digest, current_pack), (self.later_digest, later_pack)):
            joined = researcher['packs'][digest]
            self.assertEqual(codebook['codebooks'][digest]['researcherPack'], pack['identity']['digest'])
            self.assertEqual(joined['researcherIdentity'], pack['identity'])
            self.assertEqual(joined['publicIdentity'], pack['publicIdentity'])
            self.assertEqual((joined['material'], joined['codebook']), (pack['material'], pack['codebook']))
        self.assertEqual(researcher['packs'][self.later_digest]['material']['notes'], 'later notes')
        # Raw answers stay raw: the answered-only transform and pairing remain researcher declarations.
        record = self.records(destination)[self.current['submissionId']]['submission']
        self.assertEqual(record['post']['Q3'], {'status': 'answered', 'value': 2})
        self.assertEqual(record['post']['Q1'], {'status': 'not_applicable', 'value': None})
        self.assertEqual(record['tasks'][2]['status'], 'skipped')
        transform = researcher['packs'][self.current_digest]['material']['transformations'][0]
        self.assertEqual((transform['item'], transform['applyTo']), ('Q3', 'answered'))
        participant_fields = codebook['codebooks'][self.current_digest]['fields']
        self.assertFalse(any('transformations' in field or 'relationships' in field for field in participant_fields))
        outcomes = researcher['packs'][self.current_digest]['codebook']['taskOutcomes']
        self.assertNotEqual(outcomes['participant'], outcomes['researcher'])
        self.assertIn('raw', researcher['rawAnswers'])
        self.assertIn('participant', researcher['taskOutcomes'])
        self.assertEqual((destination / 'researcher-codebooks.json').stat().st_mode & 0o777, 0o600)

    def test_mismatched_researcher_packs_fail_clearly_before_writing(self):
        def tamper_bytes(directory):
            path = directory / 'researcher-pack.json'
            path.write_bytes(path.read_bytes().replace(b'synthetic researcher note', b'edited researcher note'))

        def researcher_identity(directory):
            rewrite(directory, 'researcher-pack.json', lambda pack: pack['material'].update(notes='edited'))

        def public_link(directory):
            def relink(pack):
                pack['publicIdentity']['contentVersion'] = 'v0.11-preview-9'
                pack['identity'] = identity_of({k: v for k, v in pack.items() if k != 'identity'})
            rewrite(directory, 'researcher-pack.json', relink)
            rewrite(directory, 'researcher-manifest.json', lambda manifest: manifest['researcher'].update(
                identity=json.loads((directory / 'researcher-pack.json').read_bytes())['identity']))

        def freeze_identity(directory):
            rewrite(directory, 'researcher-manifest.json',
                    lambda manifest: manifest['freezeIdentity'].update(digest='0' * 64))

        def public_wording(directory):
            # Edited wording under the original public identity, with every file hash re-declared.
            rewrite(directory, 'participant-package-v2.json',
                    lambda package: package['content']['fields'][0].update(prompt='Edited wording'))
            package_hash = hashlib.sha256((directory / 'participant-package-v2.json').read_bytes()).hexdigest()
            rewrite(directory, 'public-manifest.json',
                    lambda manifest: manifest['artifact'].update(sha256=package_hash))

        def unreferenced(directory):
            package = deepcopy(self.current_package)
            package['content']['fields'][0]['prompt'] += ' (never collected)'
            package['identity']['digest'] = hashlib.sha256(canonical_bytes(
                {'packageSchemaVersion': 2, 'content': package['content']})).hexdigest()
            for path in directory.iterdir():
                path.unlink()
            directory.rmdir()
            write_release(directory, package)

        cases = {'changed pack bytes': tamper_bytes, 'researcher identity': researcher_identity,
                 'public link': public_link, 'freeze identity': freeze_identity,
                 'public wording': public_wording, 'unreferenced snapshot': unreferenced}
        for label, damage in cases.items():
            with self.subTest(label):
                release = self.root / 'bad' / label.replace(' ', '-')
                write_release(release, self.current_package)
                damage(release)
                destination = self.root / f'rejected-{label.replace(" ", "-")}'
                with self.assertRaises(ResearcherPackError):
                    export(self.config.path, destination, researcher_packs=[release])
                self.assertFalse(destination.exists())
        with self.subTest('missing release'), self.assertRaises(ResearcherPackError):
            export(self.config.path, self.root / 'rejected-missing', researcher_packs=[self.root / 'absent'])
        with self.subTest('duplicate public identity'):
            write_release(self.root / 'dup/a', self.current_package, note='first')
            write_release(self.root / 'dup/b', self.current_package, note='second')
            with self.assertRaises(ResearcherPackError):
                export(self.config.path, self.root / 'rejected-dup',
                       researcher_packs=[self.root / 'dup/a', self.root / 'dup/b'])
        with self.subTest('inside application repository'), \
                patch('src.backend.evaluation.researcher_packs.ROOT', self.root):
            write_release(self.root / 'inside', self.current_package)
            with self.assertRaises(ResearcherPackError):
                export(self.config.path, self.root / 'rejected-inside', researcher_packs=[self.root / 'inside'])

    def test_cli_joins_packs_and_reports_mismatch_without_private_material(self):
        write_release(self.root / 'releases/current', self.current_package, note='private coding note λ')
        write_release(self.root / 'releases/later', self.upgraded_package)

        def cli(*args):
            return subprocess.run([sys.executable, '-m', 'src.backend.evaluation.cli', *map(str, args)],
                                  cwd=APP_ROOT, capture_output=True, text=True, check=False)
        joined = cli('export', self.config.path, self.root / 'cli-joined',
                     '--researcher-pack', self.root / 'releases/current',
                     '--researcher-pack', self.root / 'releases/later')
        self.assertEqual((joined.returncode, joined.stdout.strip()), (0, 'Exported 3 sessions.'))
        self.assertTrue((self.root / 'cli-joined/researcher-codebooks.json').exists())
        rewrite(self.root / 'releases/current', 'researcher-pack.json',
                lambda pack: pack['material'].update(notes='private coding note λ, edited'))
        rejected = cli('export', self.config.path, self.root / 'cli-rejected',
                       '--researcher-pack', self.root / 'releases/current')
        self.assertEqual(rejected.returncode, 1)
        self.assertIn('Researcher pack rejected', rejected.stderr)
        self.assertIn('researcher identity', rejected.stderr)
        self.assertNotIn('private coding note', rejected.stdout + rejected.stderr)
        self.assertFalse((self.root / 'cli-rejected').exists())


class ResearcherPackBoundaryTests(unittest.TestCase):
    def test_researcher_packs_are_never_served_or_packaged(self):
        with tempfile.TemporaryDirectory() as tmp, \
                TestClient(create_app(study_config=Config(Path(tmp), origin='http://testserver'))) as client:
            for path in ('/api/study/export', '/api/study/codebook', '/api/study/researcher-pack',
                         '/researcher-pack.json', '/researcher-manifest.json', '/researcher-codebooks.json'):
                self.assertIn(client.get(path).status_code, (404, 405), path)
            served = json.dumps(client.get('/api/study/content').json())
            for private_key in ('"researcherSchemaVersion"', '"transformations"', '"rubrics"', '"taskOutcomes"'):
                self.assertNotIn(private_key, served)
        packaged = {p.name for p in (APP_ROOT / 'src').rglob('*')}
        self.assertTrue({'researcher-pack.json', 'researcher-manifest.json', 'researcher-mapping.json',
                         'researcher-codebooks.json'}.isdisjoint(packaged))


if __name__ == '__main__':
    unittest.main()
