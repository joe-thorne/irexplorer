"""Synthetic final-only submission failures, persistence, and research export."""
import csv
import hashlib
import json
import os
import sqlite3
import subprocess
import sys
import tempfile
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.api.app import create_app
from src.backend.evaluation import content as study_content
from src.backend.evaluation.cli import backup, export, open_db
from src.backend.evaluation.content import (
    SUBMISSION_IDENTITY_KEYS,
    content_snapshot,
    load_participant_package,
    participant_content,
)
from src.backend.evaluation.service import (
    MAX_BODY,
    PROVENANCE_LEGACY_UNAVAILABLE,
    PROVENANCE_SNAPSHOT,
    Config,
    StudyError,
    StudyService,
    canonical,
)

# The retired version-1 response table, recreated to model stores written by earlier releases.
RETIRED_V1_SCHEMA = ('CREATE TABLE responses (submission_id TEXT PRIMARY KEY, digest TEXT NOT NULL, '
                     'payload TEXT NOT NULL, receipt TEXT NOT NULL, release TEXT NOT NULL)')


def synthetic(c=None):
    """A valid all-optional submission for `c`, the installed participant content by default."""
    c = c or participant_content()
    def answers(section):
        return {field_id: {'status': 'unanswered', 'value': None} for field_id in c['membership'][section]}
    p = {k: c[k] for k in SUBMISSION_IDENTITY_KEYS}
    p.update(submissionId=str(uuid.uuid4()), participantCode=str(uuid.uuid4()),
             consent={'version': c['contentVersion'],
                      'acknowledgements': {field_id: True for field_id in c['membership']['consent']}},
             pre=answers('pre'), post=answers('post'),
             tasks=[{'id': task['id'], 'status': 'completed', 'durationMs': 1234,
                     'interrupted': False, 'answers': answers(task['id'])} for task in c['tasks']])
    p['pre']['P1'] = {'status': 'answered', 'value': 5}
    return p


def pre_snapshot_store(path, submissions, *, version=2):
    """Write submissions in the schema-2 `submissions` layout, without snapshot columns.

    `version` only stamps `user_version`: 2 models a store written by the previous release, while
    other values model unsupported stores. Returns the stored rows.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path)
    db.execute('CREATE TABLE submissions (submission_id TEXT PRIMARY KEY, digest TEXT NOT NULL, '
               'submission_json TEXT NOT NULL, receipt TEXT NOT NULL, release TEXT NOT NULL)')
    rows = []
    for submission in submissions:
        raw = json.dumps(submission, ensure_ascii=False, separators=(',', ':'))
        receipt = json.dumps({'receiptId': str(uuid.uuid4()), 'participantCode': submission['participantCode'],
                              'submissionId': submission['submissionId'], 'studyVersion': submission['studyVersion']})
        release = json.dumps({'schemaVersion': 2, 'canonicalVersion': 1, 'mode': 'preview',
                              'appRevision': 'legacy', 'artefactSha256': 'fixture'})
        rows.append((submission['submissionId'], hashlib.sha256(canonical(submission).encode()).hexdigest(),
                     raw, receipt, release))
    db.executemany('INSERT INTO submissions VALUES (?, ?, ?, ?, ?)', rows)
    db.execute(f'PRAGMA user_version={version}')
    db.commit()
    db.close()
    return rows


UPGRADED = {'instrumentVersion': 'v0.12', 'contentVersion': 'v0.12-preview-1', 'studyVersion': 'v0.12-synthetic-1'}


@contextmanager
def upgraded_release():
    """Install a synthetic later participant package, as a deployed application upgrade would.

    Only the package changes: its identities and one prompt are revised and its canonical digest
    recomputed, so the running code is the same while current-instrument validation now names
    the upgraded release. Services created inside the block model the restarted application.
    """
    package = deepcopy(load_participant_package())
    package['content'].update(UPGRADED)
    package['content']['fields'][0]['prompt'] += ' (upgraded synthetic wording)'
    package['identity'].update(UPGRADED)
    package['identity']['digest'] = hashlib.sha256(json.dumps(
        {'packageSchemaVersion': package['packageSchemaVersion'], 'content': package['content']},
        sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    snapshot = content_snapshot(package)
    with (patch.object(study_content, '_installed_package', lambda: package),
          patch('src.backend.evaluation.service.participant_snapshot', lambda: snapshot)):
        yield snapshot


HISTORICAL = {'instrumentVersion': 'v0.10', 'contentVersion': 'v0.10-preview-9', 'studyVersion': 'v0.10-synthetic-9'}
HISTORICAL_OPTION = {'value': 6, 'label': 'Synthetic historical role'}


def historical_package():
    """A synthetic earlier participant package whose own rules differ from the installed one.

    Its identities differ, Q20 is not a member, and P1 offers an extra option, so admissibility
    under its rules is observably different from the current package's.
    """
    package = deepcopy(load_participant_package())
    content = package['content']
    content.update(HISTORICAL)
    content['fields'] = [field for field in content['fields'] if field['id'] != 'Q20']
    for section in content['postSections']:
        if 'fields' in section:
            section['fields'] = [field_id for field_id in section['fields'] if field_id != 'Q20']
    for owner in ('post', 'post.section3'):
        content['membership'][owner].remove('Q20')
    next(field for field in content['fields'] if field['id'] == 'P1')['options'].append(HISTORICAL_OPTION)
    package['identity'].update(HISTORICAL)
    package['identity']['digest'] = hashlib.sha256(json.dumps(
        {'packageSchemaVersion': package['packageSchemaVersion'], 'content': content},
        sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    return package


def frozen_public_pair(directory, package):
    """Write `package` as the two-file public pair the thesis `--package-public` export produces."""
    directory.mkdir(parents=True)
    data = (json.dumps(package, ensure_ascii=False, indent=2) + '\n').encode()
    (directory / 'participant-package-v2.json').write_bytes(data)
    (directory / 'public-manifest.json').write_text(json.dumps({
        'manifestSchemaVersion': 1, 'packageSchemaVersion': package['packageSchemaVersion'],
        'identity': package['identity'],
        'artifact': {'file': 'participant-package-v2.json', 'sha256': hashlib.sha256(data).hexdigest()}}))
    return directory


class SubmissionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.config = Config(Path(self.tmp.name), origin='http://testserver')
        self.service = StudyService(self.config)
        self.client = TestClient(create_app(study_config=self.config))
        self.addCleanup(self.client.close)
        self.payload = synthetic()

    def post(self, p=None, **kwargs):
        return self.client.post('/api/study/submissions', json=p or self.payload, headers={'Origin': 'http://testserver'},
                                **kwargs)

    def stored(self, sql, *args, path=None):
        """Rows from a private store, read directly to inspect preserved bytes and schema."""
        db = sqlite3.connect(path or self.config.path)
        try:
            return db.execute(sql, args).fetchall()
        finally:
            db.close()

    def test_storage_boundary_is_independent_of_parent_checkout(self):
        # A standalone checkout may share its parent with a legitimate data directory.
        checkout = Path(self.tmp.name).resolve() / 'application'
        checkout.mkdir()
        with patch('src.backend.evaluation.service.ROOT', checkout):
            sibling = Path(self.tmp.name) / 'data'
            self.assertEqual(Config(sibling).directory, sibling)
            for directory in (checkout, checkout / 'data', checkout / 'src/frontend/data'):
                with self.subTest(directory=directory), self.assertRaises(ValueError):
                    Config(directory)
            alias = Path(self.tmp.name) / 'alias'
            alias.symlink_to(checkout, target_is_directory=True)
            with self.assertRaises(ValueError):
                Config(alias / 'data')

    def test_submission_store_uses_v3_name_and_submission_json_schema(self):
        self.assertEqual(self.config.path.name, 'submissions.sqlite3')
        self.assertEqual(self.post().status_code, 201)
        db = sqlite3.connect(self.config.path)
        try:
            self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0], 3)
            self.assertEqual({row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")},
                             {'submissions', 'participant_content_snapshots'})
            self.assertEqual({row[1] for row in db.execute('PRAGMA table_info(submissions)')},
                             {'submission_id', 'digest', 'submission_json', 'receipt', 'release',
                              'content_digest', 'content_provenance'})
            serialized = json.loads(db.execute('SELECT submission_json FROM submissions').fetchone()[0])
        finally:
            db.close()
        self.assertEqual(set(serialized), {'submissionId', 'participantCode', 'studyVersion', 'contentVersion',
                                           'instrumentVersion', 'consent', 'pre', 'post', 'tasks'})

    def test_commit_retry_conflict_restart_and_minimal_receipt(self):
        first = self.post()
        self.assertEqual(first.status_code, 201)
        self.assertEqual(set(first.json()), {'receiptId', 'participantCode', 'submissionId', 'studyVersion'})
        retry = self.post()
        self.assertEqual(retry.status_code, 200)
        self.assertEqual(first.json(), retry.json())
        receipt, created = StudyService(self.config).submit(self.payload)
        self.assertFalse(created)
        self.assertEqual(receipt, first.json())
        changed = deepcopy(self.payload)
        changed['tasks'][0]['durationMs'] += 1
        self.assertEqual(self.post(changed).status_code, 409)
        self.assertNotIn('1234', self.post(changed).text)

    def test_invalid_consent_versions_ids_fields_statuses_and_bounds(self):
        mutations = [lambda p: p.pop('consent'), lambda p: p['consent']['acknowledgements'].update(C1=False),
            lambda p: p['pre'].pop('P1'), lambda p: p['pre'].update(P1={'status':'unanswered','value':None}),
            lambda p: p.update(studyVersion='old'), lambda p: p.update(mode='live'),
            lambda p: p.update(participantCode='name'), lambda p: p['post'].update(Q99={'status':'answered','value':3}),
            lambda p: p['post'].update(Q1={'status':'answered','value':True}),
            lambda p: p['tasks'].reverse(), lambda p: p['tasks'][0].update(status='skipped'),
            lambda p: p['tasks'][2].update(durationMs=0.3), lambda p: p['tasks'][2].update(durationMs=86400001),
            lambda p: p['tasks'][2].update(durationMs=True), lambda p: p['tasks'][2].update(status='pending'),
            lambda p: p['post'].update(Q18={'status':'answered','value':'x'*4001})]
        for mutate in mutations:
            p = deepcopy(self.payload)
            mutate(p)
            with self.subTest(p=p):
                self.assertEqual(self.post(p).status_code, 422)
        self.assertFalse(self.config.path.exists())

    def test_common_browser_server_examples_match_authoritative_submission_acceptance(self):
        examples = json.loads((Path(__file__).parent / 'data/study-validation-examples.json').read_text())
        for example in examples:
            with self.subTest(example=example['name']):
                submission = synthetic()
                answers = json.loads(json.dumps(example['answers']))
                for answer in answers.values():
                    if 'repeat' in answer:
                        answer['value'] = answer.pop('repeat') * answer.pop('times')
                section = example['section']
                if section in ('pre', 'post'):
                    submission[section].update(answers)
                else:
                    task = next(item for item in submission['tasks'] if item['id'] == section)
                    task['answers'].update(answers)
                response = self.post(submission)
                expected_status = 422 if example['errorFields'] else 201
                self.assertEqual(response.status_code, expected_status)

    def test_origin_content_type_body_limit_and_malformed_json(self):
        url = '/api/study/submissions'
        self.assertEqual(self.client.post(url,json=self.payload).status_code,403)
        self.assertEqual(self.client.post(url,json=self.payload,headers={'Origin':'https://evil.test'}).status_code,403)
        self.assertEqual(self.client.post(url,content='{}',headers={'Origin':'http://testserver'}).status_code,415)
        headers={'Origin':'http://testserver','Content-Type':'application/json'}
        self.assertEqual(self.client.post(url,content=b'x'*(MAX_BODY+1),headers=headers).status_code,413)
        for body in ('{', '{"x":NaN}', '{"x":1,"x":2}', '['*1100):
            self.assertEqual(self.client.post(url,content=body,headers=headers).status_code,422)
        self.assertEqual(self.client.post(url,content=iter([b'x'*70000,b'x'*70000]),headers=headers).status_code,413)

    def test_concurrent_participants_and_same_id(self):
        with ThreadPoolExecutor(max_workers=6) as pool:
            results = list(pool.map(self.service.submit, [self.payload]*6))
        self.assertEqual(sum(created for _, created in results),1)
        self.assertEqual(len({r['receiptId'] for r,_ in results}),1)
        with ThreadPoolExecutor(max_workers=6) as pool:
            results = list(pool.map(self.service.submit, [synthetic() for _ in range(6)]))
        self.assertTrue(all(created for _,created in results))

    def test_write_failure_sanitised_and_retryable(self):
        with (patch.object(StudyService, 'connect',
                           side_effect=sqlite3.OperationalError('secret /private/path synthetic-answer')),
              self.assertNoLogs('src.backend.evaluation', level='DEBUG')):
            failed = self.post()
        self.assertEqual(failed.status_code,503)
        self.assertNotIn('secret',failed.text)
        self.assertEqual(self.post().status_code,201)

    def test_export_fidelity_and_backup_restore(self):
        self.payload['post']['Q18']={'status':'answered','value':'  =SUM(1,2)\n"café", synthetic'}
        self.payload['post']['Q1']={'status':'not_applicable','value':None}
        submission_data = self.payload['pre']
        submission_data['P3']={'status':'answered','value':[7]}
        self.payload['tasks'][3]['status']='skipped'
        self.service.submit(self.payload)
        reordered = deepcopy(self.payload)
        reordered['pre'] = dict(reversed(list(reordered['pre'].items())))
        self.assertFalse(self.service.submit(reordered)[1])
        self.service.submit(synthetic())
        destination=Path(self.tmp.name)/'export'
        self.assertEqual(export(self.config.path,destination),2)
        raw=json.loads((destination/'submissions.json').read_text())
        record=next(r for r in raw if r['submission']['submissionId']==self.payload['submissionId'])
        self.assertEqual(record['submission']['post'],self.payload['post'])
        self.assertEqual(record['release']['schemaVersion'], 2)
        self.assertEqual(record['release']['mode'],'preview')
        with open(destination/'submissions.csv',newline='') as f:
            rows=list(csv.DictReader(f))
        self.assertIn('section', rows[0])
        self.assertNotIn('stage', rows[0])
        cell=next(r for r in rows if r['submissionId']==self.payload['submissionId'] and r['itemId']=='Q18')
        self.assertEqual(cell['value'],"'"+self.payload['post']['Q18']['value'])
        self.assertEqual(next(r for r in rows
                              if r['itemId']=='Q1' and r['submissionId']==self.payload['submissionId'])['status'],
                         'not_applicable')
        copy=Path(self.tmp.name)/'backup.sqlite3'
        restored=Path(self.tmp.name)/'restored.sqlite3'
        backup(self.config.path,copy)
        backup(copy,restored)
        db, _ = open_db(restored)
        self.assertEqual(db.execute('SELECT COUNT(*) FROM submissions').fetchone()[0],2)
        db.close()
        with self.assertRaises(FileExistsError):
            backup(copy,restored)

    def test_pre_comparison_outcomes_validate_and_export_without_setup_measure(self):
        for task, status in zip(self.payload['tasks'][1:3], ['skipped', 'could_not_work_out'], strict=True):
            task.update(status=status, durationMs=0)
        self.payload['post']['Q8'] = {'status': 'answered', 'value': [3, 1]}
        self.payload['tasks'][4]['answers']['T4c'] = {'status': 'answered', 'value': 3}
        self.payload['tasks'][5]['answers']['T5a'] = {'status': 'answered',
                                                      'value': 'Two inputs merge into one result.'}
        self.assertEqual(self.post().status_code, 201)
        destination = Path(self.tmp.name) / 'early-export'
        export(self.config.path, destination)
        book = json.loads((destination / 'codebook.json').read_text())
        [versions] = [entry['versions'] for entry in book['codebooks'].values()]
        self.assertEqual(versions['instrumentVersion'], 'v0.11')
        self.assertIn('Q3 only', book['analysis'])
        self.assertIn('section', book['csv'])
        self.assertIn('task presentation', book['durationMs'])
        self.assertIn('must not be pooled', book['durationMs'])
        self.assertIn('not collected', book['setupReached'])
        with open(destination / 'submissions.csv', newline='') as handle:
            rows = list(csv.DictReader(handle))
        early = next(r for r in rows if r['itemId'] == 'T1')
        self.assertEqual((early['setupReached'], early['durationMs'], early['status']), ('', '0', 'skipped'))
        self.assertEqual(next(r for r in rows if r['itemId'] == 'Q8')['value'], '[1,3]')

    def test_setup_field_and_old_versions_are_rejected(self):
        for mutate in [
            lambda p: p['tasks'][0].update(status='skipped'),
            lambda p: p['tasks'][1].update(setupReached=False, status='skipped'),
            lambda p: p['tasks'][1].update(presented=False),
            lambda p: p.update(instrumentVersion='v0.1'),
        ]:
            submission = synthetic()
            mutate(submission)
            with self.assertRaises(StudyError):
                self.service.submit(submission)

        submission = deepcopy(self.payload)
        submission['tasks'][1].update(status='skipped', durationMs=950)
        submission['tasks'][1]['answers']['T1a'] = {
            'status': 'answered', 'value': 'Stopped before the requested comparison'}
        self.assertEqual(self.post(submission).status_code, 201)

    def test_legacy_export_keeps_absent_setup_unknown(self):
        # Model an already-stored v0.5 JSON record; the current submission API rejects it.
        legacy = deepcopy(self.payload)
        legacy.update(instrumentVersion='v0.5', contentVersion='v0.5-preview-1', studyVersion='v0.5-synthetic-1')
        legacy['pre'] = {key: value for key, value in legacy['pre'].items() if not key.startswith('P3_')}
        legacy['pre']['P3'] = {'status': 'answered', 'value': [2, 5]}
        legacy['pre']['P3.other'] = {'status': 'unanswered', 'value': None}
        pre_snapshot_store(self.config.path, [legacy])
        destination = Path(self.tmp.name) / 'legacy-export'
        export(self.config.path, destination)
        codebook = json.loads((destination / 'codebook.json').read_text())
        self.assertIn('P3 combines completed and current enrolment', codebook['coding'])
        self.assertEqual(codebook['instrumentDefinitions']['v0.5']['P3']['values']['5'], 'COMP4403')
        definitions = codebook['instrumentDefinitions']
        self.assertEqual(set(definitions), {'v0.5', 'v0.6', 'v0.7', 'v0.8', 'v0.9', 'v0.10', 'v0.11'})
        self.assertEqual(definitions['v0.11']['courseOptions']['8'], 'None of these')
        self.assertIn('unanswered P3 is unknown', definitions['v0.11']['otherCourse'])
        current_courses = next(field for field in participant_content()['fields'] if field['id'] == 'P3')
        expected_options = {str(option['value']): option['label'] for option in current_courses['options']}
        self.assertEqual(definitions['v0.11']['courseOptions'], expected_options)
        for version in ('v0.6', 'v0.7', 'v0.8', 'v0.9', 'v0.10'):
            with self.subTest(version=version):
                self.assertEqual(definitions[version]['courseStatusOptions']['3'], 'Neither')
                self.assertEqual(definitions[version]['courseItems']['P3_COMP4403'], 'COMP4403')
                self.assertEqual(definitions[version], definitions['v0.6'])
        exported = json.loads((destination / 'submissions.json').read_text())[0]['submission']
        self.assertEqual(exported['pre']['P3'], {'status': 'answered', 'value': [2, 5]})
        with open(destination / 'submissions.csv', newline='') as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(next(r for r in rows if r['itemId'] == 'T1')['setupReached'], '')
        self.assertTrue(all(r['instrumentVersion'] == 'v0.5' for r in rows))

    def test_v08_through_v010_course_responses_export_as_raw_historical_values(self):
        current_record = synthetic()
        for version in ('v0.8', 'v0.9', 'v0.10'):
            stored_record = deepcopy(current_record)
            stored_record.update(instrumentVersion=version,
                                 contentVersion=f'{version}-preview-1', studyVersion=f'{version}-synthetic-1')
            stored_record['pre']['P3_COMP4403'] = {'status': 'answered', 'value': 2}
            store = Path(self.tmp.name) / f'legacy-{version}.sqlite3'
            pre_snapshot_store(store, [stored_record])
            destination = Path(self.tmp.name) / f'legacy-{version}'
            export(store, destination)
            exported = json.loads((destination / 'submissions.json').read_text())[0]
            record = exported['submission']
            self.assertEqual(record['instrumentVersion'], version)
            self.assertEqual(record['pre']['P3_COMP4403'], {'status': 'answered', 'value': 2})
            self.assertEqual(exported['contentProvenance']['status'], 'unavailable')
            codebook = json.loads((destination / 'codebook.json').read_text())
            self.assertEqual(codebook['instrumentDefinitions'][version]['courseItems']['P3_COMP4403'], 'COMP4403')
            with open(destination / 'submissions.csv', newline='') as handle:
                rows = list(csv.DictReader(handle))
            course = next(row for row in rows if row['itemId'] == 'P3_COMP4403')
            self.assertEqual((course['instrumentVersion'], course['value'], course['status'],
                              course['contentProvenance'], course['contentDigest']),
                             (version, '2', 'answered', 'unavailable', ''))

    def test_pilot_mode_and_private_http_boundary(self):
        for mode in ('pilot',):
            service=StudyService(Config(Path(self.tmp.name),collection_mode=mode))
            self.assertFalse(service.content()['submissionEnabled'])
            with self.assertRaises(StudyError) as caught:
                service.submit(self.payload)
            self.assertEqual(caught.exception.status,503)
            self.assertFalse(service.config.path.exists())
        for path in ('/submissions.sqlite3','/api/study/submissions','/api/study/export',
                     '/src/backend/evaluation/service.py'):
            self.assertIn(self.client.get(path).status_code,(404,405))
        schema=self.client.get('/openapi.json').json()
        for path, methods in schema['paths'].items():
            self.assertEqual(set(methods), {'post'} if path=='/api/study/submissions' else {'get'})
        self.assertEqual(self.client.post('/api/examples',json=self.payload).status_code,405)

    def test_shipped_live_configuration_rejects_submissions(self):
        live = StudyService(Config(
            Path(self.tmp.name), collection_mode='live', origin='https://study.example.test',
            app_revision='0.1.1-webproject.1',
        ))

        self.assertFalse(live.content()['submissionEnabled'])
        with self.assertRaises(StudyError) as caught:
            live.submit(self.payload)
        self.assertEqual((caught.exception.status, caught.exception.code), (503, 'collection_disabled'))
        self.assertFalse(live.config.path.exists())

    def test_schema_fail_closed(self):
        self.service.submit(self.payload)
        db=sqlite3.connect(self.config.path)
        db.execute('PRAGMA user_version=99')
        db.close()
        self.assertEqual(self.post().status_code,503)

    def test_local_collection_is_separate_and_records_server_release(self):
        local = Config(Path(self.tmp.name), collection_mode='local', origin='http://testserver',
                       app_revision='0.1.0+tested-source')
        with TestClient(create_app(study_config=local)) as client:
            self.assertEqual(client.get('/api/study/content').json()['collectionMode'], 'local')
            first = client.post('/api/study/submissions', json=self.payload,
                                headers={'Origin': local.origin})
            self.assertEqual(first.status_code, 201)
            release = client.get('/api/release')
            self.assertEqual(release.status_code, 200)
            self.assertEqual(release.headers['cache-control'], 'no-store')
            self.assertIn('version', release.json())
            self.assertNotIn('files', release.json())
        self.assertFalse(self.config.path.exists())
        self.assertEqual(StudyService(local).submit(self.payload), (first.json(), False))
        destination = Path(self.tmp.name) / 'local-export'
        self.assertEqual(export(local.path, destination), 1)
        record = json.loads((destination / 'submissions.json').read_text())[0]
        self.assertEqual(record['release']['mode'], 'local')
        self.assertEqual(record['release']['appRevision'], '0.1.0+tested-source')

    def test_v1_response_store_migrates_in_place_without_changing_answers(self):
        legacy_path = self.config.directory / 'preview' / 'responses.sqlite3'
        legacy_path.parent.mkdir(parents=True)
        legacy_db = sqlite3.connect(legacy_path)
        legacy_db.execute(RETIRED_V1_SCHEMA)
        original_payload = json.dumps(self.payload, ensure_ascii=False, separators=(',', ':'))
        receipt = {'receiptId': str(uuid.uuid4()), 'participantCode': self.payload['participantCode'],
                   'submissionId': self.payload['submissionId'], 'studyVersion': self.payload['studyVersion']}
        release = {'schemaVersion': 2, 'canonicalVersion': 1, 'mode': 'preview', 'appRevision': 'legacy',
                   'artefactSha256': 'fixture'}
        receipt_json, release_json = json.dumps(receipt), json.dumps(release)
        legacy_db.execute('INSERT INTO responses VALUES (?, ?, ?, ?, ?)',
                          (self.payload['submissionId'], hashlib.sha256(
                              canonical(self.payload).encode()).hexdigest(), original_payload,
                           receipt_json, release_json))
        legacy_db.execute('PRAGMA user_version=1')
        legacy_db.commit()
        legacy_db.close()

        db = self.service.connect()
        try:
            self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0], 3)
            self.assertEqual(db.execute('SELECT submission_json, receipt, release, content_digest, '
                                        'content_provenance FROM submissions').fetchone(),
                             (original_payload, receipt_json, release_json, None, PROVENANCE_LEGACY_UNAVAILABLE))
            self.assertNotIn('payload', {row[1] for row in db.execute('PRAGMA table_info(submissions)')})
            self.assertEqual(self.service.submit(self.payload), (receipt, False))
        finally:
            db.close()
        self.assertFalse(legacy_path.exists())
        self.assertTrue(self.config.path.exists())

    def test_backup_and_restore_accept_v1_stores(self):
        legacy = Path(self.tmp.name) / 'legacy-v1.sqlite3'
        db = sqlite3.connect(legacy)
        db.execute(RETIRED_V1_SCHEMA)
        raw_submission = canonical(self.payload)
        db.execute('INSERT INTO responses VALUES (?, ?, ?, ?, ?)', (
            self.payload['submissionId'], hashlib.sha256(raw_submission.encode()).hexdigest(), raw_submission,
            canonical({'receiptId': str(uuid.uuid4()), 'participantCode': self.payload['participantCode'],
                       'submissionId': self.payload['submissionId'], 'studyVersion': self.payload['studyVersion']}),
            canonical({'schemaVersion': 2, 'canonicalVersion': 1, 'mode': 'preview', 'appRevision': 'legacy',
                       'artefactSha256': 'fixture'})))
        db.execute('PRAGMA user_version=1')
        db.commit()
        db.close()
        copy = Path(self.tmp.name) / 'legacy-copy.sqlite3'
        backup(legacy, copy)
        checked, _ = open_db(copy)
        self.assertEqual(checked.execute('PRAGMA user_version').fetchone()[0], 1)
        self.assertEqual(checked.execute('SELECT payload FROM responses').fetchone()[0], raw_submission)
        checked.close()
        old_export = Path(self.tmp.name) / 'legacy-export'
        self.assertEqual(export(copy, old_export), 1)
        self.assertEqual(json.loads((old_export / 'submissions.json').read_text())[0]['submission'], self.payload)
        with (old_export / 'submissions.csv').open(newline='') as handle:
            self.assertIn('section', csv.DictReader(handle).fieldnames)
        restored = Path(self.tmp.name) / 'legacy-restored.sqlite3'
        backup(copy, restored)
        restored_db = sqlite3.connect(restored)
        self.assertEqual(restored_db.execute('PRAGMA user_version').fetchone()[0], 1)
        self.assertEqual(restored_db.execute('SELECT payload FROM responses').fetchone()[0], raw_submission)
        restored_db.close()

    def test_submission_links_exact_served_participant_content_snapshot(self):
        served = self.client.get('/api/study/content').json()
        submission = synthetic()
        self.assertEqual(self.post(submission).status_code, 201)
        self.assertEqual(self.stored('PRAGMA user_version'), [(3,)])
        [(provenance, linked)] = self.stored('SELECT content_provenance, content_digest FROM submissions')
        self.assertEqual((provenance, linked), (PROVENANCE_SNAPSHOT, served['packageIdentity']['digest']))
        [(*identity, canonical_content)] = self.stored(
            'SELECT digest, digest_algorithm, identity_version, canonicalisation, canonicalisation_version, '
            'package_schema_version, instrument_version, content_version, study_version, canonical_content '
            'FROM participant_content_snapshots')
        # Reconstruct the public definition from the HTTP response alone: every served key except
        # the package identity and the deployment-dependent collection flags.
        definition = {key: value for key, value in served.items() if key not in {
            'packageSchemaVersion', 'packageIdentity', 'collectionMode', 'submissionEnabled'}}
        expected = json.dumps({'packageSchemaVersion': served['packageSchemaVersion'], 'content': definition},
                              sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()
        self.assertEqual(canonical_content, expected)
        self.assertEqual(hashlib.sha256(canonical_content).hexdigest(), linked)
        self.assertEqual(tuple(identity), (linked, 'sha256', 1, 'sorted-json-utf8-v1', 1, 2,
                                        'v0.11', 'v0.11-preview-2', 'v0.11-synthetic-1'))
        for secret in (submission['participantCode'], submission['submissionId'], b'collectionMode',
                       b'submissionEnabled'):
            self.assertNotIn(secret.encode() if isinstance(secret, str) else secret, canonical_content)
        self.assertEqual(self.config.path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.config.path.parent.stat().st_mode & 0o777, 0o700)
        # Collection mode and enabled status do not enter public identity.
        local = Config(Path(self.tmp.name), collection_mode='local', origin='http://testserver')
        StudyService(local).submit(synthetic())
        self.assertEqual(self.stored('SELECT digest, canonical_content FROM participant_content_snapshots',
                                     path=local.path), [(linked, expected)])

    def test_client_supplied_definitions_cannot_register_snapshots(self):
        served = self.client.get('/api/study/content').json()
        forged = deepcopy(served)
        forged['fields'][0]['prompt'] = 'Forged wording'
        for extra in ({'participantContent': forged}, {'packageIdentity': served['packageIdentity']},
                      {'contentDigest': hashlib.sha256(b'forged').hexdigest()}):
            with self.subTest(extra=set(extra)):
                self.assertEqual(self.post({**synthetic(), **extra}).status_code, 422)
        self.assertFalse(self.config.path.exists())
        self.assertEqual(self.post().status_code, 201)
        self.assertEqual(self.stored('SELECT digest FROM participant_content_snapshots'),
                         [(served['packageIdentity']['digest'],)])

    def test_storage_failure_rolls_back_snapshot_registration_and_withholds_receipt(self):
        self.service.connect().close()
        db = sqlite3.connect(self.config.path)
        db.execute('CREATE TRIGGER synthetic_disk_failure BEFORE INSERT ON submissions '
                   "BEGIN SELECT RAISE(ABORT, 'synthetic storage failure'); END")
        db.commit()
        db.close()
        frozen = synthetic()
        failed = self.post(frozen)
        self.assertEqual((failed.status_code, failed.json()['error']['code']), (503, 'storage_unavailable'))
        self.assertNotIn('receiptId', failed.text)
        self.assertNotIn('synthetic storage failure', failed.text)
        self.assertEqual(self.stored('SELECT COUNT(*) FROM participant_content_snapshots'), [(0,)])
        self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions'), [(0,)])
        db = sqlite3.connect(self.config.path)
        db.execute('DROP TRIGGER synthetic_disk_failure')
        db.commit()
        db.close()
        # The retained frozen submission then commits with its snapshot, and a restart finds both.
        first = self.post(frozen)
        self.assertEqual(first.status_code, 201)
        self.assertEqual(StudyService(self.config).submit(frozen), (first.json(), False))
        self.assertEqual(self.stored('SELECT COUNT(*) FROM participant_content_snapshots'), [(1,)])

    def test_same_digest_with_different_definition_bytes_fails_without_replacement(self):
        self.service.connect().close()
        digest = self.service.snapshot.digest
        altered = self.service.snapshot.canonical_content.replace(b'v0.11-preview-2', b'v0.11-preview-X', 1)
        self.assertNotEqual(altered, self.service.snapshot.canonical_content)
        db = sqlite3.connect(self.config.path)
        db.execute('INSERT INTO participant_content_snapshots VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                   (digest, 'sha256', 1, 'sorted-json-utf8-v1', 1, 2, 'v0.11', 'v0.11-preview-2',
                    'v0.11-synthetic-1', altered))
        db.commit()
        db.close()
        failed = self.post()
        self.assertEqual((failed.status_code, failed.json()['error']['code']), (503, 'storage_unavailable'))
        self.assertEqual(self.stored('SELECT canonical_content FROM participant_content_snapshots'), [(altered,)])
        self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions'), [(0,)])
        with self.assertRaises(ValueError):
            open_db(self.config.path)
        with self.assertRaises(ValueError):
            backup(self.config.path, Path(self.tmp.name) / 'damaged-copy.sqlite3')
        self.assertFalse((Path(self.tmp.name) / 'damaged-copy.sqlite3').exists())

    def test_store_rejects_unlinked_rows_and_snapshot_replacement(self):
        self.assertEqual(self.post().status_code, 201)
        db = sqlite3.connect(self.config.path)
        try:
            other = synthetic()
            for digest, provenance in ((None, PROVENANCE_SNAPSHOT), ('0' * 64, PROVENANCE_SNAPSHOT),
                                       (None, PROVENANCE_LEGACY_UNAVAILABLE), (None, 'other')):
                with self.subTest(provenance=provenance, digest=digest), self.assertRaises(sqlite3.DatabaseError):
                    db.execute('INSERT INTO submissions VALUES (?, ?, ?, ?, ?, ?, ?)',
                               (other['submissionId'], 'x', canonical(other), '{}', '{}', digest, provenance))
            for statement in ("UPDATE participant_content_snapshots SET canonical_content = x'00'",
                              'DELETE FROM participant_content_snapshots',
                              "UPDATE submissions SET content_provenance = 'legacy_unavailable', "
                              'content_digest = NULL',
                              "UPDATE submissions SET content_provenance = 'other'"):
                with self.subTest(statement=statement), self.assertRaises(sqlite3.DatabaseError):
                    db.execute(statement)
        finally:
            db.rollback()
            db.close()
        # The stored row is intact: an identical retry of the first submission still returns its receipt.
        self.assertEqual(self.post().status_code, 200)

    def test_v2_store_migrates_with_explicit_unavailable_provenance(self):
        legacy = synthetic()
        [row] = pre_snapshot_store(self.config.path, [legacy])
        for _ in range(2):  # Repeated initialisation is a no-op after the first migration.
            StudyService(self.config).connect().close()
        self.assertEqual(self.stored('PRAGMA user_version'), [(3,)])
        self.assertEqual(self.stored('SELECT submission_id, digest, submission_json, receipt, release, '
                                     'content_digest, content_provenance FROM submissions'),
                         [(*row, None, PROVENANCE_LEGACY_UNAVAILABLE)])
        retry = self.post(legacy)
        self.assertEqual((retry.status_code, retry.json()), (200, json.loads(row[3])))
        changed = deepcopy(legacy)
        changed['tasks'][1]['durationMs'] += 1
        conflict = self.post(changed)
        self.assertEqual(conflict.status_code, 409)
        self.assertNotIn(legacy['participantCode'], conflict.text)
        current = synthetic()
        self.assertEqual(self.post(current).status_code, 201)
        # A registered snapshot cannot be attached to a legacy row after the fact.
        db = sqlite3.connect(self.config.path)
        try:
            with self.assertRaises(sqlite3.DatabaseError):
                db.execute('UPDATE submissions SET content_provenance = ?, content_digest = ? WHERE submission_id = ?',
                           (PROVENANCE_SNAPSHOT, self.service.snapshot.digest, legacy['submissionId']))
        finally:
            db.rollback()
            db.close()
        destination = Path(self.tmp.name) / 'mixed-export'
        self.assertEqual(export(self.config.path, destination), 2)
        records = {record['submission']['submissionId']: record
                   for record in json.loads((destination / 'submissions.json').read_text())}
        self.assertEqual(records[legacy['submissionId']]['submission'], json.loads(row[2]))
        self.assertEqual(records[legacy['submissionId']]['contentProvenance']['status'], 'unavailable')
        digest = self.service.snapshot.digest
        self.assertEqual(records[current['submissionId']]['contentProvenance'], {
            'status': 'snapshot', 'digest': digest, 'instrumentVersion': 'v0.11',
            'contentVersion': 'v0.11-preview-2', 'studyVersion': 'v0.11-synthetic-1',
            'codebook': digest, 'snapshotFile': f'snapshots/{digest}.json'})
        codebook = json.loads((destination / 'codebook.json').read_text())
        self.assertEqual(list(codebook['codebooks']), [digest])
        self.assertEqual(codebook['unavailableDefinitions']['submissionIds'], [legacy['submissionId']])
        self.assertIn('no codebook entry may be applied', codebook['contentProvenance'])
        with open(destination / 'submissions.csv', newline='') as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual({(r['submissionId'], r['contentProvenance'], r['contentDigest']) for r in rows}, {
            (legacy['submissionId'], 'unavailable', ''),
            (current['submissionId'], 'snapshot', self.service.snapshot.digest)})

    def test_unsupported_schemas_fail_clearly_without_change(self):
        for version in (4, 99):
            with self.subTest(version=version):
                store = Path(self.tmp.name) / f'schema-{version}.sqlite3'
                pre_snapshot_store(store, [synthetic()], version=version)
                with patch.object(Config, 'path', store):
                    self.assertEqual(self.post().status_code, 503)
                with self.assertRaises(ValueError):
                    open_db(store)
                self.assertEqual(self.stored('PRAGMA user_version', path=store), [(version,)])
                self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions', path=store), [(1,)])

    def test_concurrent_first_deliveries_register_one_snapshot(self):
        retried = synthetic()
        submissions = [retried] * 4 + [synthetic() for _ in range(4)]
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(lambda item: StudyService(self.config).submit(item), submissions))
        self.assertEqual(sum(created for _, created in results), 5)
        self.assertEqual(len({r['receiptId'] for r, _ in results[:4]}), 1)
        self.assertEqual(self.stored('SELECT COUNT(*) FROM participant_content_snapshots'), [(1,)])
        self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions WHERE content_provenance=? '
                                     'AND content_digest=?', PROVENANCE_SNAPSHOT, self.service.snapshot.digest), [(5,)])

    def test_private_operations_on_snapshot_store(self):
        kept, withdrawn = synthetic(), synthetic()
        withdrawn['post']['Q18'] = {'status': 'answered', 'value': 'Withdrawn synthetic observation ζ'}
        for submission in (kept, withdrawn):
            self.assertEqual(self.post(submission).status_code, 201)
        snapshot = self.stored('SELECT canonical_content FROM participant_content_snapshots')[0][0]
        for respondent_value in (kept['participantCode'], withdrawn['participantCode'], 'Withdrawn synthetic'):
            self.assertNotIn(respondent_value.encode(), snapshot)

        def cli(*args):
            return subprocess.run([sys.executable, '-m', 'src.backend.evaluation.cli', *map(str, args)],
                                  cwd=Path(__file__).resolve().parents[1], capture_output=True, text=True,
                                  check=False)
        tmp = Path(self.tmp.name)
        self.assertEqual(cli('backup', self.config.path, tmp / 'backup.sqlite3').returncode, 0)
        self.assertEqual(cli('restore', tmp / 'backup.sqlite3', tmp / 'restored.sqlite3').returncode, 0)
        restored = tmp / 'restored.sqlite3'
        snapshots = 'SELECT digest, canonical_content FROM participant_content_snapshots'
        self.assertEqual(self.stored(snapshots, path=restored), self.stored(snapshots))
        self.assertEqual(cli('delete-participant', restored, withdrawn['participantCode'], '--confirm').returncode, 0)
        self.assertEqual(self.stored('SELECT submission_id FROM submissions', path=restored),
                         [(kept['submissionId'],)])
        self.assertEqual(self.stored('SELECT canonical_content FROM participant_content_snapshots', path=restored),
                         [(snapshot,)])
        self.assertNotIn(b'Withdrawn synthetic', restored.read_bytes())
        self.assertEqual(cli('export', restored, tmp / 'restored-export').returncode, 0)
        [record] = json.loads((tmp / 'restored-export/submissions.json').read_text())
        self.assertEqual(record['contentProvenance']['digest'], self.service.snapshot.digest)
        self.assertEqual(record['submission'], json.loads(canonical(kept)))
        self.assertEqual(cli('purge', restored, tmp / 'restored-export/submissions.csv', '--confirm').returncode, 0)
        self.assertFalse(restored.exists())

    def test_withdrawal_proceeds_when_snapshot_verification_fails(self):
        kept, withdrawn = synthetic(), synthetic()
        for submission in (kept, withdrawn):
            self.assertEqual(self.post(submission).status_code, 201)
        db = sqlite3.connect(self.config.path)
        db.execute('DROP TRIGGER snapshots_immutable')
        db.execute("UPDATE participant_content_snapshots SET canonical_content = x'00'")
        db.commit()
        db.close()
        with self.assertRaises(ValueError):
            open_db(self.config.path)
        result = subprocess.run(
            [sys.executable, '-m', 'src.backend.evaluation.cli', 'delete-participant', str(self.config.path),
             withdrawn['participantCode'], '--confirm'],
            cwd=Path(__file__).resolve().parents[1], capture_output=True, text=True, check=False)
        # Withdrawal completes; the unrelated snapshot failure is reported separately and without responses.
        self.assertEqual(result.returncode, 3)
        self.assertIn('Deleted 1 records', result.stdout)
        self.assertIn('snapshot verification failed', result.stderr.lower())
        self.assertNotIn(withdrawn['participantCode'], result.stdout + result.stderr)
        self.assertEqual(self.stored('SELECT submission_id FROM submissions'), [(kept['submissionId'],)])

    def test_changed_public_wording_changes_snapshot_identity(self):
        package = load_participant_package()
        original = content_snapshot(package)
        revised = deepcopy(package)
        revised['content']['fields'][0]['prompt'] += ' (revised wording)'
        with self.assertRaises(ValueError):  # The old identity no longer names the revised wording.
            content_snapshot(revised)
        revised['identity']['digest'] = hashlib.sha256(json.dumps(
            {'packageSchemaVersion': revised['packageSchemaVersion'], 'content': revised['content']},
            sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
        self.assertNotEqual(content_snapshot(revised).digest, original.digest)
        self.assertIn(b'(revised wording)', content_snapshot(revised).canonical_content)

    def test_committed_receipt_recovers_after_package_upgrade_and_restart(self):
        committed = synthetic()
        committed['post']['Q8'] = {'status': 'answered', 'value': [3, 1]}
        first = self.post(committed)
        self.assertEqual(first.status_code, 201)
        uncommitted_old_draft = synthetic()
        columns = 'SELECT submission_id, digest, submission_json, receipt, release, content_digest FROM submissions'
        before = self.stored(columns)
        with upgraded_release() as upgraded, TestClient(create_app(study_config=self.config)) as restarted:
            def post(submission):
                return restarted.post('/api/study/submissions', json=submission,
                                      headers={'Origin': 'http://testserver'})
            self.assertEqual(restarted.get('/api/study/content').json()['contentVersion'], 'v0.12-preview-1')
            # The lost response is retried after the upgrade: the original receipt, shape and status return.
            retry = post(committed)
            self.assertEqual((retry.status_code, retry.json()), (200, first.json()))
            reordered = deepcopy(committed)
            reordered['post']['Q8']['value'] = [1, 3]
            reordered_retry = post(reordered)
            self.assertEqual((reordered_retry.status_code, reordered_retry.json()), (200, first.json()))
            with ThreadPoolExecutor(max_workers=6) as pool:
                results = list(pool.map(lambda item: StudyService(self.config).submit(item), [committed] * 6))
            self.assertEqual(results, [(first.json(), False)] * 6)
            # An uncommitted draft from the previous release is a first delivery the upgrade no longer accepts.
            rejected = post(uncommitted_old_draft)
            self.assertEqual((rejected.status_code, rejected.json()['error']['code']), (422, 'unsupported_instrument'))
            # Changed content or identities under the committed ID conflict without disclosing answers.
            changed_answer = deepcopy(committed)
            changed_answer['tasks'][1]['durationMs'] += 1
            changed_identity = deepcopy(committed)
            changed_identity.update(UPGRADED)
            changed_identity['consent']['version'] = UPGRADED['contentVersion']
            not_canonical = deepcopy(committed)
            not_canonical['tasks'] = 'not a task list'
            for conflicting in (changed_answer, changed_identity, not_canonical):
                conflict = post(conflicting)
                self.assertEqual((conflict.status_code, conflict.json()['error']['code']),
                                 (409, 'submission_conflict'))
                for stored_value in (committed['participantCode'], first.json()['receiptId'], '1234'):
                    self.assertNotIn(stored_value, conflict.text)
            self.assertEqual(self.stored(columns), before)
            # A first delivery under the upgraded release is linked to the upgraded snapshot.
            current = synthetic()
            self.assertEqual(post(current).status_code, 201)
            self.assertEqual(self.stored('SELECT content_digest FROM submissions WHERE submission_id=?',
                                         current['submissionId']), [(upgraded.digest,)])
        self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions'), [(2,)])

    def test_committed_lookup_keeps_request_safeguards(self):
        committed = synthetic()
        first = self.post(committed)
        self.assertEqual(first.status_code, 201)
        url, body = '/api/study/submissions', json.dumps(committed)
        with upgraded_release(), TestClient(create_app(study_config=self.config)) as client:
            json_headers = {'Origin': 'http://testserver', 'Content-Type': 'application/json'}
            for status, kwargs in (
                (403, {'content': body, 'headers': {'Content-Type': 'application/json'}}),
                (403, {'content': body, 'headers': {**json_headers, 'Origin': 'https://evil.test'}}),
                (403, {'content': body, 'headers': {**json_headers, 'Sec-Fetch-Site': 'cross-site'}}),
                (415, {'content': body, 'headers': {'Origin': 'http://testserver'}}),
                (413, {'content': body[:-1] + ',"padding":"' + 'x' * MAX_BODY + '"}', 'headers': json_headers}),
                (422, {'content': body[:-1] + ',"submissionId":"' + committed['submissionId'] + '"}',
                       'headers': json_headers}),
            ):
                with self.subTest(status=status, headers=kwargs['headers']):
                    response = client.post(url, **kwargs)
                    self.assertEqual(response.status_code, status)
                    self.assertNotIn(first.json()['receiptId'], response.text)
            for mode in ('pilot', 'live'):
                disabled = StudyService(Config(self.config.directory, collection_mode=mode))
                with self.assertRaises(StudyError) as caught:
                    disabled.submit(committed)
                self.assertEqual(caught.exception.code, 'collection_disabled')
                self.assertFalse(disabled.config.path.exists())

    def test_legacy_receipts_recover_under_original_canonicalisation(self):
        def historical(version):
            record = synthetic()
            record.update(instrumentVersion=version, contentVersion=f'{version}-preview-1',
                          studyVersion=f'{version}-synthetic-1')
            record['consent']['version'] = record['contentVersion']
            record['pre']['P3_COMP4403'] = {'status': 'answered', 'value': 2}
            record['post']['Q8'] = {'status': 'answered', 'value': [1, 3]}  # Stored under canonical version 1.
            return record
        recoverable, unknown_contract = historical('v0.10'), historical('v0.9')
        rows = pre_snapshot_store(self.config.path, [recoverable, unknown_contract])
        unknown_release = json.dumps({**json.loads(rows[1][4]), 'canonicalVersion': 2})
        db = sqlite3.connect(self.config.path)
        db.execute('UPDATE submissions SET release = ? WHERE submission_id = ?',
                   (unknown_release, unknown_contract['submissionId']))
        db.commit()
        db.close()
        legacy_v1 = historical('v0.8')
        local = Config(self.config.directory, collection_mode='local', origin='http://testserver')
        legacy_path = local.path.with_name('responses.sqlite3')
        legacy_path.parent.mkdir(parents=True)
        v1_receipt = {'receiptId': str(uuid.uuid4()), 'participantCode': legacy_v1['participantCode'],
                      'submissionId': legacy_v1['submissionId'], 'studyVersion': legacy_v1['studyVersion']}
        db = sqlite3.connect(legacy_path)
        db.execute(RETIRED_V1_SCHEMA)
        db.execute('INSERT INTO responses VALUES (?, ?, ?, ?, ?)', (
            legacy_v1['submissionId'], hashlib.sha256(canonical(legacy_v1).encode()).hexdigest(),
            canonical(legacy_v1), canonical(v1_receipt),
            canonical({'schemaVersion': 2, 'canonicalVersion': 1, 'mode': 'local', 'appRevision': 'legacy',
                       'artefactSha256': 'fixture'})))
        db.execute('PRAGMA user_version=1')
        db.commit()
        db.close()

        retried = deepcopy(recoverable)
        retried['post']['Q8']['value'] = [3, 1]  # Multi-choice order carries no meaning under version 1.
        retry = self.post(retried)
        self.assertEqual((retry.status_code, retry.json()), (200, json.loads(rows[0][3])))
        self.assertEqual(StudyService(local).submit(legacy_v1), (v1_receipt, False))
        self.assertFalse(legacy_path.exists())
        # Without the original canonicalisation contract, identity cannot be established.
        unknown = self.post(unknown_contract)
        self.assertEqual((unknown.status_code, unknown.json()['error']['code']), (409, 'submission_conflict'))
        changed = deepcopy(recoverable)
        changed['pre']['P3_COMP4403']['value'] = 1
        conflict = self.post(changed)
        self.assertEqual(conflict.status_code, 409)
        self.assertNotIn(recoverable['participantCode'], conflict.text)
        self.assertEqual(self.stored('SELECT submission_id, digest, submission_json, receipt, release '
                                     'FROM submissions ORDER BY rowid'),
                         [rows[0], (*rows[1][:4], unknown_release)])

    def test_unreadable_committed_record_is_a_storage_fault_without_receipt(self):
        committed = synthetic()
        self.assertEqual(self.post(committed).status_code, 201)
        db = sqlite3.connect(self.config.path)
        db.execute("UPDATE submissions SET release = '[]'")
        db.commit()
        db.close()
        failed = self.post(committed)
        self.assertEqual((failed.status_code, failed.json()['error']['code']), (503, 'storage_unavailable'))
        self.assertNotIn(committed['participantCode'], failed.text)
        self.assertEqual(self.stored('SELECT release FROM submissions'), [('[]',)])

    def test_unconfigured_older_first_delivery_is_unsupported_and_stores_nothing(self):
        older = synthetic(historical_package()['content'])
        sent = deepcopy(older)
        rejected = self.post(older)
        self.assertEqual((rejected.status_code, rejected.json()['error']['code']), (422, 'unsupported_instrument'))
        self.assertNotIn(older['participantCode'], rejected.text)
        self.assertEqual(older, sent)
        self.assertFalse(self.config.path.exists())  # Nothing was stored, so no store exists.
        current = synthetic()
        self.assertEqual(self.post(current).status_code, 201)
        # The same ID is still unsupported once a store exists; no row is written under it.
        again = self.post(older)
        self.assertEqual((again.status_code, again.json()['error']['code']), (422, 'unsupported_instrument'))
        self.assertEqual(self.stored('SELECT submission_id FROM submissions'), [(current['submissionId'],)])
        # A submission that names the current identities is judged by current rules, not reported unsupported.
        malformed = synthetic()
        malformed['pre']['P1'] = {'status': 'answered', 'value': HISTORICAL_OPTION['value']}
        invalid = self.post(malformed)
        self.assertEqual((invalid.status_code, invalid.json()['error']['code']), (422, 'invalid_submission'))

    def test_enabled_older_instrument_is_accepted_under_its_own_rules(self):
        package = historical_package()
        historical = content_snapshot(package)
        config = Config(Path(self.tmp.name), origin='http://testserver',
                        accepted_instruments=(frozen_public_pair(Path(self.tmp.name) / 'v0.10', package),))
        older = synthetic(package['content'])
        older['pre']['P1'] = {'status': 'answered', 'value': HISTORICAL_OPTION['value']}
        with TestClient(create_app(study_config=config)) as client:
            def post(submission):
                return client.post('/api/study/submissions', json=submission, headers={'Origin': 'http://testserver'})
            # The content served to new participants is still only the installed package.
            self.assertEqual(client.get('/api/study/content').json()['contentVersion'],
                             participant_content()['contentVersion'])
            self.assertEqual(post(synthetic()).status_code, 201)
            first = post(older)
            self.assertEqual(first.status_code, 201)
            self.assertEqual(first.json()['studyVersion'], HISTORICAL['studyVersion'])
            # The older release's own membership and options decide admissibility, not the current ones.
            with_current_member = synthetic(package['content'])
            with_current_member['post']['Q20'] = {'status': 'unanswered', 'value': None}
            without_own_option = synthetic(package['content'])
            without_own_option['pre']['P1'] = {'status': 'answered', 'value': 7}
            current_without_member = synthetic()
            del current_without_member['post']['Q20']
            for invalid in (with_current_member, without_own_option, current_without_member):
                rejected = post(invalid)
                self.assertEqual((rejected.status_code, rejected.json()['error']['code']), (422, 'invalid_submission'))
        # The accepted older submission is linked to its own snapshot and keeps its own identities.
        self.assertEqual(self.stored('SELECT content_digest, content_provenance FROM submissions WHERE submission_id=?',
                                     older['submissionId']), [(historical.digest, PROVENANCE_SNAPSHOT)])
        self.assertEqual(self.stored('SELECT canonical_content, instrument_version FROM participant_content_snapshots '
                                     'WHERE digest=?', historical.digest),
                         [(historical.canonical_content, HISTORICAL['instrumentVersion'])])
        stored = json.loads(self.stored('SELECT submission_json FROM submissions WHERE submission_id=?',
                                        older['submissionId'])[0][0])
        self.assertEqual({key: stored[key] for key in HISTORICAL}, HISTORICAL)
        self.assertNotIn('Q20', stored['post'])
        self.assertEqual(self.stored('SELECT COUNT(*) FROM submissions'), [(2,)])
        # After the older release is disabled again, its committed submission still recovers its receipt,
        # while a new first delivery from it is unsupported.
        retry = self.post(older)
        self.assertEqual((retry.status_code, retry.json()), (200, first.json()))
        another = synthetic(package['content'])
        disabled = self.post(another)
        self.assertEqual((disabled.status_code, disabled.json()['error']['code']), (422, 'unsupported_instrument'))

    def test_accepted_instruments_are_verified_server_configuration(self):
        root = Path(self.tmp.name)
        with patch.dict('os.environ', {}, clear=True):
            self.assertEqual(Config.environment().accepted_instruments, ())
        first, second = root / 'first', root / 'second'
        with patch.dict('os.environ', {'IREXPLORER_ACCEPTED_INSTRUMENTS': f'{first}{os.pathsep}{second}'},
                        clear=True):
            self.assertEqual(Config.environment().accepted_instruments, (first, second))
        with self.assertRaises(ValueError):
            Config(root, accepted_instruments=(Path('relative/release'),))
        with self.assertRaises(FileNotFoundError):
            StudyService(Config(root, accepted_instruments=(root / 'missing',)))
        tampered = frozen_public_pair(root / 'tampered', historical_package())
        package_file = tampered / 'participant-package-v2.json'
        package_file.write_bytes(package_file.read_bytes().replace(b'Synthetic historical role', b'Altered role'))
        with self.assertRaises(ValueError):
            StudyService(Config(root, accepted_instruments=(tampered,)))
        # A configured package with the installed identities, or two with one identity, is ambiguous.
        with self.assertRaises(ValueError):
            StudyService(Config(root, accepted_instruments=(
                frozen_public_pair(root / 'installed-again', load_participant_package()),)))
        duplicate = [frozen_public_pair(root / name, historical_package()) for name in ('one', 'two')]
        with self.assertRaises(ValueError):
            StudyService(Config(root, accepted_instruments=tuple(duplicate)))

    def test_retired_study_mode_environment_name_fails_clearly(self):
        with (patch.dict('os.environ', {'IREXPLORER_STUDY_MODE': 'preview'}, clear=True),
              self.assertRaisesRegex(ValueError, 'IREXPLORER_STUDY_MODE.*IREXPLORER_COLLECTION_MODE')):
            Config.environment()
        with patch.dict('os.environ', {'IREXPLORER_COLLECTION_MODE': 'local'}, clear=True):
            self.assertEqual(Config.environment().collection_mode, 'local')


if __name__ == '__main__':
    unittest.main()
