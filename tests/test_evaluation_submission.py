"""Synthetic final-only submission failures, persistence, and research export."""
import csv
import hashlib
import json
import sqlite3
import tempfile
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.api.app import create_app
from src.backend.evaluation.cli import backup, export, open_db
from src.backend.evaluation.content import participant_content
from src.backend.evaluation.service import MAX_BODY, Config, StudyError, StudyService, canonical


def synthetic():
    c = participant_content()
    def answers(section):
        return {field_id: {'status': 'unanswered', 'value': None} for field_id in c['membership'][section]}
    p = {k: c[k] for k in ('studyVersion', 'contentVersion', 'instrumentVersion')}
    p.update(submissionId=str(uuid.uuid4()), participantCode=str(uuid.uuid4()),
             consent={'version': c['contentVersion'],
                      'acknowledgements': {field_id: True for field_id in c['membership']['consent']}},
             pre=answers('pre'), post=answers('post'),
             tasks=[{'id': task['id'], 'status': 'completed', 'durationMs': 1234,
                     'interrupted': False, 'answers': answers(task['id'])} for task in c['tasks']])
    p['pre']['P1'] = {'status': 'answered', 'value': 5}
    return p


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

    def test_submission_store_uses_v2_name_and_submission_json_schema(self):
        self.assertEqual(self.config.path.name, 'submissions.sqlite3')
        self.assertEqual(self.post().status_code, 201)
        db = sqlite3.connect(self.config.path)
        try:
            self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0], 2)
            self.assertEqual(db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchone()[0],
                             'submissions')
            self.assertEqual({row[1] for row in db.execute('PRAGMA table_info(submissions)')},
                             {'submission_id', 'digest', 'submission_json', 'receipt', 'release'})
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
                payload = synthetic()
                answers = json.loads(json.dumps(example['answers']))
                for answer in answers.values():
                    if 'repeat' in answer:
                        answer['value'] = answer.pop('repeat') * answer.pop('times')
                section = example['section']
                if section in ('pre', 'post'):
                    payload[section].update(answers)
                else:
                    task = next(item for item in payload['tasks'] if item['id'] == section)
                    task['answers'].update(answers)
                response = self.post(payload)
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
        db=open_db(restored)
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
        self.assertEqual(book['versions']['instrumentVersion'], 'v0.11')
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
            payload = deepcopy(self.payload)
            mutate(payload)
            with self.assertRaises(StudyError):
                self.service.submit(payload)

        submission = deepcopy(self.payload)
        submission['tasks'][1].update(status='skipped', durationMs=950)
        submission['tasks'][1]['answers']['T1a'] = {
            'status': 'answered', 'value': 'Stopped before the requested comparison'}
        self.assertEqual(self.post(submission).status_code, 201)

    def test_legacy_export_keeps_absent_setup_unknown(self):
        self.service.submit(self.payload)
        # Model an already-stored v0.5 JSON record; the current submission API rejects it.
        legacy = deepcopy(self.payload)
        legacy.update(instrumentVersion='v0.5', contentVersion='v0.5-preview-1', studyVersion='v0.5-synthetic-1')
        legacy['pre'] = {key: value for key, value in legacy['pre'].items() if not key.startswith('P3_')}
        legacy['pre']['P3'] = {'status': 'answered', 'value': [2, 5]}
        legacy['pre']['P3.other'] = {'status': 'unanswered', 'value': None}
        db = sqlite3.connect(self.config.path)
        try:
            with db:
                db.execute('UPDATE submissions SET submission_json=?', (json.dumps(legacy),))
        finally:
            db.close()
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
        self.service.submit(current_record)
        db = sqlite3.connect(self.config.path)
        try:
            for version in ('v0.8', 'v0.9', 'v0.10'):
                stored_record = deepcopy(current_record)
                stored_record.update(instrumentVersion=version,
                                     contentVersion=f'{version}-preview-1', studyVersion=f'{version}-synthetic-1')
                stored_record['pre']['P3_COMP4403'] = {'status': 'answered', 'value': 2}
                with db:
                    db.execute('UPDATE submissions SET submission_json=?', (json.dumps(stored_record),))
                destination = Path(self.tmp.name) / f'legacy-{version}'
                export(self.config.path, destination)
                record = json.loads((destination / 'submissions.json').read_text())[0]['submission']
                self.assertEqual(record['instrumentVersion'], version)
                self.assertEqual(record['pre']['P3_COMP4403'], {'status': 'answered', 'value': 2})
                codebook = json.loads((destination / 'codebook.json').read_text())
                self.assertEqual(codebook['instrumentDefinitions'][version]['courseItems']['P3_COMP4403'], 'COMP4403')
                with open(destination / 'submissions.csv', newline='') as handle:
                    rows = list(csv.DictReader(handle))
                course = next(row for row in rows if row['itemId'] == 'P3_COMP4403')
                self.assertEqual((course['instrumentVersion'], course['value'], course['status']),
                                 (version, '2', 'answered'))
        finally:
            db.close()

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
        legacy_db.execute('CREATE TABLE responses (submission_id TEXT PRIMARY KEY, digest TEXT NOT NULL, '
                          'payload TEXT NOT NULL, receipt TEXT NOT NULL, release TEXT NOT NULL)')
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
            self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0], 2)
            self.assertEqual(db.execute('SELECT submission_json, receipt, release FROM submissions').fetchone(),
                             (original_payload, receipt_json, release_json))
            self.assertNotIn('payload', {row[1] for row in db.execute('PRAGMA table_info(submissions)')})
            self.assertEqual(self.service.submit(self.payload), (receipt, False))
        finally:
            db.close()
        self.assertFalse(legacy_path.exists())
        self.assertTrue(self.config.path.exists())

    def test_backup_and_restore_accept_v1_stores(self):
        legacy = Path(self.tmp.name) / 'legacy-v1.sqlite3'
        db = sqlite3.connect(legacy)
        db.execute('CREATE TABLE responses (submission_id TEXT PRIMARY KEY, digest TEXT NOT NULL, '
                   'payload TEXT NOT NULL, receipt TEXT NOT NULL, release TEXT NOT NULL)')
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
        checked = open_db(copy)
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

    def test_retired_study_mode_environment_name_fails_clearly(self):
        with (patch.dict('os.environ', {'IREXPLORER_STUDY_MODE': 'preview'}, clear=True),
              self.assertRaisesRegex(ValueError, 'IREXPLORER_STUDY_MODE.*IREXPLORER_COLLECTION_MODE')):
            Config.environment()
        with patch.dict('os.environ', {'IREXPLORER_COLLECTION_MODE': 'local'}, clear=True):
            self.assertEqual(Config.environment().collection_mode, 'local')


if __name__ == '__main__':
    unittest.main()
