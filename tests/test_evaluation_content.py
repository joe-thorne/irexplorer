"""E4 participant boundary and survey contract; no collection API."""
import unittest
from pathlib import Path
import tempfile
from fastapi.testclient import TestClient
from src.backend.api.app import create_app
from src.backend.evaluation.content import participant_content, validate_answers
from src.backend.evaluation.service import Config


class EvaluationContentTests(unittest.TestCase):
    def test_public_content_is_preview_only_and_participant_only(self):
        with tempfile.TemporaryDirectory() as directory, TestClient(create_app(
            study_config=Config(Path(directory), mode='preview')
        )) as client:
            response = client.get('/api/study/content')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.headers['cache-control'], 'no-store')
            content = response.json()
            self.assertEqual(content, {**participant_content(), 'submissionEnabled': True})
            self.assertEqual(content['mode'], 'preview')
            self.assertTrue(content['submissionEnabled'])
            self.assertEqual(len(content['fields']), 60)
            allowed = {'id', 'prompt', 'type', 'required', 'options', 'scale', 'notApplicableLabel', 'maxLength', 'exclusiveValue', 'optionStatuses', 'condition', 'inabilityLabel'}
            for field in content['fields']:
                self.assertLessEqual(set(field), allowed)
            for forbidden in ['(R)', '[confirm', 'stratification', 'reverse-scored', 'marking key', 'expected answer']:
                self.assertNotIn(forbidden, response.text)
            for path in ['/participant-content.json', '/src/backend/evaluation/participant-content.json', '/docs/evaluation-captures/e0-task-evidence.json']:
                self.assertEqual(client.get(path).status_code, 404)
            self.assertIn(client.post('/api/study/submissions', json={'pre': {}}).status_code, (403,))

    def test_required_optional_and_separate_nonanswer_states(self):
        answered = lambda value: {'status': 'answered', 'value': value}
        self.assertEqual(validate_answers('pre', {}), {})
        self.assertEqual(set(validate_answers('pre', {}, complete=True)), {'P1'})
        self.assertEqual(validate_answers('pre', {'P1': answered(5)}, complete=True), {})
        self.assertEqual(validate_answers('post', {}, complete=True), {})
        self.assertEqual(validate_answers('post', {'Q1': {'status': 'not_applicable', 'value': None}}), {})
        self.assertEqual(validate_answers('pre', {'P2': {'status': 'not_applicable', 'value': None}}), {})
        for field, answer in [('Q19', {'status': 'not_applicable', 'value': None}), ('Q1', answered(0)), ('Q1', answered(True)), ('Q1', answered(6)), ('Q1', {'status': 'unanswered', 'value': 3})]:
            self.assertIn(field, validate_answers('post', {field: answer}))
        self.assertIn('P2', validate_answers('pre', {'P2': answered(6)}))

    def test_exclusive_choices_and_conditional_details(self):
        a = lambda value: {'status': 'answered', 'value': value}
        for values in [[6, 1], [1, 1], [], [True], ['1']]:
            self.assertIn('P3', validate_answers('pre', {'P3': a(values)}))
        self.assertEqual(validate_answers('pre', {'P3': a([1, 7]), 'P3.other': a('Synthetic course')}), {})
        self.assertIn('P3.other', validate_answers('pre', {'P3': a([6]), 'P3.other': a('Synthetic course')}))
        self.assertIn('P12.detail', validate_answers('pre', {'P12': a(1), 'P12.detail': a('Detail')}))
        self.assertEqual(validate_answers('pre', {'P12': a(2), 'P12.detail': a('Detail')}), {})

    def test_text_bounds_raw_unicode_and_unknown_keys(self):
        text = '🙂' * 4000
        a = lambda value: {'status': 'answered', 'value': value}
        self.assertEqual(validate_answers('post', {'Q14': a(text)}), {})
        self.assertIn('Q14', validate_answers('post', {'Q14': a(text + 'x')}))
        self.assertIn('Q14', validate_answers('post', {'Q14': a('  \n ')}))
        self.assertIn('researcherScore', validate_answers('post', {'researcherScore': a(5)}))
        self.assertIn('Q14', validate_answers('post', {'Q14': {'status': 'answered', 'value': 'x', 'extra': True}}))
        self.assertEqual(validate_answers('post', {'Q14': a('  <script>\n=SUM(A1)  ')}), {})

    def test_task_inventory_setups_and_original_response_structure(self):
        content = participant_content()
        self.assertEqual([t['id'] for t in content['tasks']], [f'T{i}' for i in range(7)])
        tasks = {t['id']: t for t in content['tasks']}
        self.assertEqual(tasks['T0']['fields'], [])
        self.assertEqual(tasks['T1']['fields'], ['T1a', 'T1b'])
        self.assertEqual(tasks['T5']['fields'], ['T5a', 'T5b', 'T5c'])
        self.assertEqual(tasks['T6']['fields'], ['T6a', 'T6b', 'T6c'])
        self.assertEqual(tasks['T6']['setup'], {})
        self.assertEqual(tasks['T1']['setup']['right']['ordinal'], 12)
        self.assertEqual(tasks['T2']['setup']['left']['ordinal'], 0)
        self.assertEqual(tasks['T2']['setup']['right']['ordinal'], 0)
        self.assertEqual(tasks['T3']['setup']['left'], {'ordinal': 3, 'view': 'ir'})
        self.assertEqual(tasks['T3']['setup']['right'], {'ordinal': 3, 'view': 'cfg'})
        self.assertEqual(tasks['T4']['setup']['left'], {'ordinal': 6, 'view': 'cfg'})
        self.assertEqual(tasks['T4']['setup']['right'], {'ordinal': 7, 'view': 'cfg'})
        self.assertEqual(tasks['T5']['setup']['right']['ordinal'], 9)
        self.assertEqual([f['id'] for f in content['fields'] if f.get('scale') == 'confidence'], ['T1b', 'T2c', 'T3c', 'T4d'])
        for task in tasks.values():
            self.assertEqual(set(task), {'id', 'title', 'goal', 'instructions', 'fields', 'setup'})
            self.assertTrue(task['goal'])
            self.assertTrue(task['instructions'])
            self.assertLessEqual(set(task['setup']), {'example', 'left', 'right'})
            for side in ('left', 'right'):
                if side in task['setup']:
                    self.assertEqual(set(task['setup'][side]), {'ordinal', 'view'})

    def test_task_partial_answers_inability_and_not_applicable(self):
        a = lambda value: {'status': 'answered', 'value': value}
        for stage in [f'T{i}' for i in range(7)]:
            self.assertEqual(validate_answers(stage, {}, complete=True), {})
        for task, field, status in [('T2', 'T2a', 'could_not_work_out'), ('T3', 'T3a', 'could_not_work_out'), ('T4', 'T4a', 'could_not_work_out'), ('T4', 'T4c', 'not_applicable')]:
            self.assertEqual(validate_answers(task, {field: {'status': status, 'value': None}}), {})
        for task, field, answer in [('T2', 'T2a', a(11)), ('T2', 'T2a', {'status': 'not_applicable', 'value': None}), ('T4', 'T4d', a(True)), ('T5', 'T5a', a(4)), ('T6', 'T6a', {'status': 'could_not_work_out', 'value': None})]:
            self.assertIn(field, validate_answers(task, {field: answer}))
        self.assertIn('T1a', validate_answers('T0', {'T1a': a('No orientation answers')}))
        self.assertIn('T5confidence', validate_answers('T5', {'T5confidence': a(5)}))
        self.assertEqual(validate_answers('T6', {'T6a': a('Synthetic\n<script>\n=SUM(A1)')}), {})
        self.assertEqual(validate_answers('T3', {'T3a': a('🙂' * 256)}), {})
        self.assertIn('T3a', validate_answers('T3', {'T3a': a('🙂' * 257)}))
        self.assertIn('T6a', validate_answers('T6', {'T6a': a('x' * 4001)}))
