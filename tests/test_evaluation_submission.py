"""Synthetic final-only submission failures, persistence, and research export."""
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import csv
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest.mock import patch
import uuid
from fastapi.testclient import TestClient
from src.backend.api.app import create_app
from src.backend.evaluation.content import participant_content
from src.backend.evaluation.service import Config, StudyService, StudyError, MAX_BODY
from src.backend.evaluation.cli import export, backup, open_db


def synthetic():
    c = participant_content()
    def answers(prefix):
        return {f['id']: {'status': 'unanswered', 'value': None} for f in c['fields'] if f['id'].startswith(prefix)}
    p = {k: c[k] for k in ('studyVersion', 'contentVersion', 'instrumentVersion')}
    p.update(submissionId=str(uuid.uuid4()), participantCode=str(uuid.uuid4()),
             consent={'version': c['contentVersion'], 'acknowledgements': {f['id']: True for f in c['fields'] if f['id'].startswith('C')}},
             pre=answers('P'), post=answers('Q'),
             tasks=[{'id': f'T{i}', 'status': 'completed', 'durationMs': 1234, 'interrupted': False, 'answers': answers(f'T{i}')} for i in range(7)])
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
        return self.client.post('/api/study/submissions', json=p or self.payload, headers={'Origin': 'http://testserver'}, **kwargs)

    def test_commit_retry_conflict_restart_and_minimal_receipt(self):
        first = self.post(); self.assertEqual(first.status_code, 201)
        self.assertEqual(set(first.json()), {'receiptId', 'participantCode', 'submissionId', 'studyVersion'})
        retry = self.post(); self.assertEqual(retry.status_code, 200); self.assertEqual(first.json(), retry.json())
        receipt, created = StudyService(self.config).submit(self.payload)
        self.assertFalse(created); self.assertEqual(receipt, first.json())
        changed = deepcopy(self.payload); changed['tasks'][0]['durationMs'] += 1
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
            p = deepcopy(self.payload); mutate(p)
            with self.subTest(p=p): self.assertEqual(self.post(p).status_code, 422)
        self.assertFalse(self.config.path.exists())

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
        with patch.object(StudyService, 'connect', side_effect=sqlite3.OperationalError('secret /private/path synthetic-answer')):
            with self.assertNoLogs('src.backend.evaluation', level='DEBUG'):
                failed = self.post()
        self.assertEqual(failed.status_code,503)
        self.assertNotIn('secret',failed.text)
        self.assertEqual(self.post().status_code,201)

    def test_export_fidelity_and_backup_restore(self):
        self.payload['post']['Q18']={'status':'answered','value':'  =SUM(1,2)\n"café", synthetic'}
        self.payload['post']['Q1']={'status':'not_applicable','value':None}
        self.payload['pre']['P3']={'status':'answered','value':[2,1]}
        self.payload['tasks'][3]['status']='skipped'
        self.service.submit(self.payload)
        reordered = deepcopy(self.payload); reordered['pre']['P3']['value']=[1,2]
        self.assertFalse(self.service.submit(reordered)[1])
        self.service.submit(synthetic())
        destination=Path(self.tmp.name)/'export'
        self.assertEqual(export(self.config.path,destination),2)
        raw=json.loads((destination/'responses.json').read_text())
        record=next(r for r in raw if r['response']['submissionId']==self.payload['submissionId'])
        self.assertEqual(record['response']['post'],self.payload['post'])
        self.assertEqual(record['release']['mode'],'preview')
        with open(destination/'responses.csv',newline='') as f: rows=list(csv.DictReader(f))
        cell=next(r for r in rows if r['submissionId']==self.payload['submissionId'] and r['itemId']=='Q18')
        self.assertEqual(cell['value'],"'"+self.payload['post']['Q18']['value'])
        self.assertEqual(next(r for r in rows if r['itemId']=='Q1' and r['submissionId']==self.payload['submissionId'])['status'],'not_applicable')
        copy=Path(self.tmp.name)/'backup.sqlite3'; restored=Path(self.tmp.name)/'restored.sqlite3'
        backup(self.config.path,copy); backup(copy,restored)
        db=open_db(restored)
        self.assertEqual(db.execute('SELECT COUNT(*) FROM responses').fetchone()[0],2);db.close()
        with self.assertRaises(FileExistsError): backup(copy,restored)

    def test_disabled_modes_and_private_http_boundary(self):
        for mode in ('pilot','live'):
            service=StudyService(Config(Path(self.tmp.name),mode=mode))
            self.assertFalse(service.content()['submissionEnabled'])
            with self.assertRaises(StudyError) as caught: service.submit(self.payload)
            self.assertEqual(caught.exception.status,503)
            self.assertFalse(service.config.path.exists())
        for path in ('/responses.sqlite3','/api/study/submissions','/api/study/export','/src/backend/evaluation/service.py'):
            self.assertIn(self.client.get(path).status_code,(404,405))
        schema=self.client.get('/openapi.json').json()
        for path, methods in schema['paths'].items():
            self.assertEqual(set(methods), {'post'} if path=='/api/study/submissions' else {'get'})
        self.assertEqual(self.client.post('/api/examples',json=self.payload).status_code,405)

    def test_schema_fail_closed(self):
        self.service.submit(self.payload)
        db=sqlite3.connect(self.config.path);db.execute('PRAGMA user_version=99');db.close()
        self.assertEqual(self.post().status_code,503)


if __name__ == '__main__': unittest.main()
