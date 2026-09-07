"""E4 participant boundary and survey contract; no collection API."""
import unittest
from fastapi.testclient import TestClient
from src.backend.api.app import create_app
from src.backend.evaluation.content import participant_content, validate_answers


class EvaluationContentTests(unittest.TestCase):
    def test_public_content_is_preview_only_and_participant_only(self):
        with TestClient(create_app()) as client:
            response = client.get('/api/study/content')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.headers['cache-control'], 'no-store')
            content = response.json()
            self.assertEqual(content, participant_content())
            self.assertEqual(content['mode'], 'preview')
            self.assertFalse(content['submissionEnabled'])
            self.assertEqual(len(content['fields']), 42)
            allowed = {'id', 'prompt', 'type', 'required', 'options', 'scale', 'notApplicableLabel', 'maxLength', 'exclusiveValue', 'optionStatuses', 'condition'}
            for field in content['fields']:
                self.assertLessEqual(set(field), allowed)
            for forbidden in ['(R)', '[confirm', 'stratification', 'reverse-scored', 'marking key', 'expected answer', 'T2a']:
                self.assertNotIn(forbidden, response.text)
            for path in ['/participant-content.json', '/src/backend/evaluation/participant-content.json', '/docs/evaluation-captures/e0-task-evidence.json']:
                self.assertEqual(client.get(path).status_code, 404)
            self.assertIn(client.post('/api/study/submissions', json={'pre': {}}).status_code, (404, 405))

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
