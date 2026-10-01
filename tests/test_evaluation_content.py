"""Participant boundary and survey contract; no collection API."""
import json
import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from src.backend.api.app import create_app
from src.backend.evaluation.content import participant_content, validate_answers
from src.backend.evaluation.service import Config


class EvaluationContentTests(unittest.TestCase):
    def test_verified_public_package_exposes_explicit_membership_roles_and_controls(self):
        evaluation = Path(__file__).parents[1] / 'src/backend/evaluation'
        self.assertTrue((evaluation / 'participant-package-v2.json').is_file())
        self.assertFalse((evaluation / 'participant-content.json').exists())
        content = participant_content()
        self.assertEqual(content['packageSchemaVersion'], 2)
        self.assertEqual(content['packageIdentity']['digest'],
                         'b5715a6db30237ad31f50377862d62f832a7f312ccc9650e933975f541d33c7c')
        self.assertEqual(content['membership']['consent'], [f'C{i}' for i in range(1, 7)])
        self.assertEqual(content['membership']['pre'], [field_id for section in content['preSections']
                                                       for field_id in section['fields']])
        self.assertEqual([block['role'] for section in content['information'] for block in section['blocks']
                          if block.get('role') in ('study-purpose', 'submission-guidance')],
                         ['study-purpose', 'submission-guidance'])
        self.assertEqual(next(field for field in content['fields'] if field['id'] == 'T2a')['presentation'],
                         {'control': 'select'})
        self.assertEqual(set(content), {'packageSchemaVersion', 'packageIdentity', 'instrumentVersion',
                                        'contentVersion', 'studyVersion', 'scales', 'fields', 'preSections',
                                        'postSections', 'tasks', 'taskIntroduction', 'information', 'membership',
                                        'journey', 'glossary', 'messages'})
        self.assertNotIn('[Joe/Joel to confirm', json.dumps(content))

    def test_revised_response_types_reject_old_codes(self):
        def a(value):
            return {'status': 'answered', 'value': value}
        for stage, field, value in [('post', 'Q8', [1, 2, 3]), ('T4', 'T4c', 5),
                                    ('T5', 'T5a', 'Two instructions merge into one'), ('T5', 'T5c', 5),
                                    ('post', 'Q20', 5)]:
            self.assertEqual(validate_answers(stage, {field: a(value)}), {})
        for value in [1, [1, 4], [4, 4], []]:
            self.assertIn('Q8', validate_answers('post', {'Q8': a(value)}))
        self.assertIn('T4c', validate_answers('T4', {'T4c': {'status': 'not_applicable', 'value': None}}))
        self.assertIn('T5a', validate_answers('T5', {'T5a': a(1)}))

    def test_t5_target_is_source_mapped_and_has_qualified_merge(self):
        from src.backend.api import QueryService
        service = QueryService()
        task = next(t for t in participant_content()['tasks'] if t['id'] == 'T5')
        setup = task['setup']
        example, left, right = setup['example'], setup['left']['ordinal'], setup['right']['ordinal']
        function = next(f for f in service.ir(example, right)['functions'] if f['name'] == setup['function'])
        line = next(i for i, text in enumerate(service.source(example)['text'].splitlines(), 1)
                    if 'if (a[j] <= pivot)' in text)
        mappings = service.source_mappings(example, right, function['id'])['mappings']
        ids = {m['instructionId'] for m in mappings if m['location']['line'] == line}
        targets = [i for b in function['blocks'] for i in b['instructions']
                   if i['id'] in ids and i['opcode'] == 'getelementptr']
        self.assertEqual(len(targets), 1)
        links = [link for link in service.comparison_report(example, left, right)['links']
                 if targets[0]['id'] in link['toNodeIds']]
        self.assertEqual(len(links), 1)
        self.assertEqual((links[0]['relation'], links[0]['confidence']), ('merged', 'approximate'))
        self.assertEqual((len(links[0]['fromNodeIds']), len(links[0]['toNodeIds'])), (2, 1))

    def test_t2a_options_follow_the_shipped_score_timeline(self):
        from src.backend.api import QueryService
        states = QueryService().list_states('score')['states']
        derived = [
            {
                'value': 100 + state['ordinal'],
                'label': f"State {state['ordinal']} · produced by {state['step']['passName']}",
            }
            for state in states
            if state['step'] and state['step']['kind'] == 'derived'
        ]
        t2a = next(field for field in participant_content()['fields'] if field['id'] == 'T2a')
        self.assertEqual(t2a['options'], derived + [
            {'value': 198, 'label': 'It was already gone at State 0 (the unoptimised version)'},
            {'value': 199, 'label': 'I could not work this out'},
        ])
        self.assertEqual(t2a['optionStatuses'], {'199': 'could_not_work_out'})

    def test_v011_task_copy_and_identity_match_current_runsheet(self):
        content = participant_content()
        self.assertEqual((content['instrumentVersion'], content['contentVersion'], content['studyVersion']),
                         ('v0.11', 'v0.11-preview-3', 'v0.11-synthetic-1'))
        tasks = {task['id']: task for task in content['tasks']}
        self.assertIn('State 0 is the unoptimised baseline compiled with -O0', content['taskIntroduction'][1])
        self.assertIn('T0 is the orientation; the six tasks are T1–T6', content['taskIntroduction'][2])
        self.assertIn('State 13 is compiled separately with -O3', content['taskIntroduction'][1])
        self.assertIn('not an unaided test', content['taskIntroduction'][2])
        self.assertIn('Answer at your own level of detail', content['taskIntroduction'][2])
        self.assertIn('navigation does not submit them', content['taskIntroduction'][3])
        role_blocks = [block for section in content['information'] for block in section['blocks']]
        self.assertIn('evaluates how useful irexplorer is',
                      next(block['text'] for block in role_blocks if block.get('role') == 'study-purpose'))
        self.assertIn('navigation does not send them',
                      next(block['text'] for block in role_blocks if block.get('role') == 'submission-guidance'))
        self.assertIn('A brief or partial answer is fine', tasks['T1']['instructions'])
        t2a = next(field for field in content['fields'] if field['id'] == 'T2a')
        self.assertIn('Which State is the first in which this arithmetic is absent', t2a['prompt'])
        self.assertIn('which pass produced that State', t2a['prompt'])
        self.assertEqual(tasks['T2']['setup']['left']['ordinal'], 0)
        self.assertEqual(tasks['T5']['setup']['right']['ordinal'], 9)
        self.assertIn('confidence wording appears beside the link', tasks['T5']['instructions'])
        self.assertIn('Keep the link’s confidence separate', tasks['T5']['instructions'])
        self.assertEqual(tasks['T6']['entryWorkspace']['selection'], 'clear')

    def test_public_content_is_preview_only_and_participant_only(self):
        with tempfile.TemporaryDirectory() as directory, TestClient(create_app(
            study_config=Config(Path(directory), collection_mode='preview')
        )) as client:
            response = client.get('/api/study/content')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.headers['cache-control'], 'no-store')
            content = response.json()
            self.assertEqual(content, {**participant_content(), 'collectionMode': 'preview',
                                       'submissionEnabled': True})
            self.assertEqual(content['collectionMode'], 'preview')
            self.assertTrue(content['submissionEnabled'])
            self.assertEqual(len(content['fields']), 60)
            allowed = {'id', 'prompt', 'type', 'required', 'options', 'scale', 'notApplicableLabel', 'maxLength',
                       'exclusiveValue', 'optionStatuses', 'condition', 'inabilityLabel', 'presentation'}
            for field in content['fields']:
                self.assertLessEqual(set(field), allowed)
            self.assertEqual(content['packageSchemaVersion'], 2)
            self.assertEqual(content['packageIdentity'], participant_content()['packageIdentity'])
            for forbidden in ['(R)', 'stratification', 'reverse-scored', 'marking key', 'expected answer']:
                self.assertNotIn(forbidden, response.text)
            for path in ['/participant-content.json', '/src/backend/evaluation/participant-content.json',
                         '/tests/private-fixture.json']:
                self.assertEqual(client.get(path).status_code, 404)
            self.assertIn(client.post('/api/study/submissions', json={'pre': {}}).status_code, (403,))

    def test_required_optional_and_separate_nonanswer_states(self):
        def answered(value):
            return {'status': 'answered', 'value': value}
        self.assertEqual(validate_answers('pre', {}), {})
        self.assertEqual(set(validate_answers('pre', {}, complete=True)), {'P1'})
        self.assertEqual(validate_answers('pre', {'P1': answered(5)}, complete=True), {})
        self.assertEqual(validate_answers('post', {}, complete=True), {})
        self.assertEqual(validate_answers('post', {'Q1': {'status': 'not_applicable', 'value': None}}), {})
        self.assertEqual(validate_answers('pre', {'P2': {'status': 'not_applicable', 'value': None}}), {})
        for field, answer in [('Q19', {'status': 'not_applicable', 'value': None}), ('Q1', answered(0)),
                              ('Q1', answered(True)), ('Q1', answered(6)),
                              ('Q1', {'status': 'unanswered', 'value': 3})]:
            self.assertIn(field, validate_answers('post', {field: answer}))
        self.assertIn('P2', validate_answers('pre', {'P2': answered(6)}))

    def test_common_browser_server_response_examples(self):
        examples = json.loads((Path(__file__).parent / 'data/study-validation-examples.json').read_text())
        for example in examples:
            with self.subTest(example=example['name']):
                answers = json.loads(json.dumps(example['answers']))
                for answer in answers.values():
                    if 'repeat' in answer:
                        answer['value'] = answer.pop('repeat') * answer.pop('times')
                errors = validate_answers(example['section'], answers, complete=example.get('complete', False))
                self.assertEqual(sorted(errors), sorted(example['errorFields']))

    def test_exclusive_choices_and_conditional_details(self):
        def a(value):
            return {'status': 'answered', 'value': value}
        for value in [0, 10, True, '1', [], [1, 1], [1, 8]]:
            self.assertIn('P3', validate_answers('pre', {'P3': a(value)}))
        self.assertEqual(validate_answers('pre', {'P3': a([1])}), {})
        self.assertIn('P3_other_name', validate_answers('pre', {'P3_other_name': a('Course')}))
        self.assertIn('P12.detail', validate_answers('pre', {'P12': a(1), 'P12.detail': a('Detail')}))
        self.assertEqual(validate_answers('pre', {'P12': a(2), 'P12.detail': a('Detail')}), {})

    def test_v011_course_selections_combine_status_and_distinguish_none_from_missing(self):
        content = participant_content()
        self.assertEqual((content['instrumentVersion'], content['contentVersion'], content['studyVersion']),
                         ('v0.11', 'v0.11-preview-3', 'v0.11-synthetic-1'))
        course = next(field for field in content['fields'] if field['id'] == 'P3')
        self.assertEqual(course['type'], 'multiple')
        self.assertEqual([option['value'] for option in course['options']], list(range(1, 10)))
        self.assertEqual(course['exclusiveValue'], 8)
        labels = [option['label'] for option in course['options'] if option['value'] <= 7]
        self.assertEqual(labels, [
            'CSSE1001 — Introduction to Software Engineering / ENGG1001 — Programming for Engineers',
            'CSSE2002 — Programming in the Large', 'CSSE2010 — Introduction to Computer Systems',
            'CSSE2310 — Computer Systems Principles and Programming', 'COMP3506 — Algorithms & Data Structures',
            'COMP3301 — Operating Systems Architecture', 'COMP4403 — Compilers and Interpreters',
        ])
        self.assertEqual(len(labels), 7)
        def a(value):
            return {'status': 'answered', 'value': value}
        self.assertEqual(validate_answers('pre', {'P3': a([1, 7])}), {})
        self.assertEqual(validate_answers('pre', {'P3': {'status': 'unanswered', 'value': None}}), {})
        self.assertEqual(validate_answers('pre', {'P3': a([8])}), {})
        self.assertIn('P3', validate_answers('pre', {'P3': a([1, 8])}))
        self.assertIn('P3_other_name', validate_answers('pre', {'P3_other_name': a('Other course')}))
        self.assertEqual(validate_answers('pre', {'P3': a([9]), 'P3_other_name': a('Other course')}), {})
        self.assertIn('P3_other_name', validate_answers('pre', {'P1': a(1), 'P3': a([9])}, complete=True))
        self.assertIn('P3_other_name', validate_answers('pre', {'P3_other_name': a('Synthetic course')}))
        self.assertEqual(validate_answers('pre', {'P3': a([9]), 'P3_other_name': a('Synthetic course')}), {})
        self.assertIn('P3_other_name', validate_answers('pre', {'P3_other_name': a('')}))

    def test_text_bounds_raw_unicode_and_unknown_keys(self):
        text = '🙂' * 4000
        def a(value):
            return {'status': 'answered', 'value': value}
        self.assertEqual(validate_answers('post', {'Q14': a(text)}), {})
        self.assertIn('Q14', validate_answers('post', {'Q14': a(text + 'x')}))
        self.assertIn('Q14', validate_answers('post', {'Q14': a('  \n ')}))
        self.assertIn('researcherScore', validate_answers('post', {'researcherScore': a(5)}))
        self.assertIn('Q14', validate_answers('post', {'Q14': {'status': 'answered', 'value': 'x', 'extra': True}}))
        self.assertEqual(validate_answers('post', {'Q14': a('  <script>\n=SUM(A1)  ')}), {})

    def test_task_inventory_setups_and_revised_response_structure(self):
        content = participant_content()
        self.assertEqual([t['id'] for t in content['tasks']], [f'T{i}' for i in range(7)])
        tasks = {t['id']: t for t in content['tasks']}
        self.assertEqual(tasks['T0']['fields'], [])
        self.assertEqual(tasks['T1']['fields'], ['T1a', 'T1b'])
        self.assertEqual(tasks['T5']['fields'], ['T5a', 'T5b', 'T5c'])
        self.assertEqual(tasks['T6']['fields'], ['T6a', 'T6b', 'T6c'])
        self.assertEqual(tasks['T6']['setup'], {})
        self.assertEqual(tasks['T6']['entryWorkspace'], {'inherit': 'previous', 'selection': 'clear'})
        self.assertTrue(all(task['entryWorkspace']['selection'] == 'clear' for task in content['tasks']))
        self.assertEqual(content['membership']['T5'], tasks['T5']['fields'])
        self.assertEqual(tasks['T1']['setup']['right']['ordinal'], 12)
        self.assertEqual(tasks['T2']['setup']['left']['ordinal'], 0)
        self.assertEqual(tasks['T2']['setup']['right']['ordinal'], 0)
        self.assertEqual(tasks['T3']['setup']['left'], {'ordinal': 3, 'view': 'ir'})
        self.assertEqual(tasks['T3']['setup']['right'], {'ordinal': 3, 'view': 'cfg'})
        self.assertEqual(tasks['T4']['setup']['left'], {'ordinal': 6, 'view': 'cfg'})
        self.assertEqual(tasks['T4']['setup']['right'], {'ordinal': 7, 'view': 'cfg'})
        self.assertEqual(tasks['T5']['setup']['right']['ordinal'], 9)
        self.assertEqual(tasks['T5']['setup']['left']['ordinal'], 8)
        self.assertEqual(tasks['T5']['setup']['function'], 'partition')
        self.assertEqual([f['id'] for f in content['fields'] if f.get('scale') == 'confidence'],
                         ['T1b', 'T2c', 'T3c', 'T4d'])
        for task in tasks.values():
            expected_keys = {'id', 'title', 'goal', 'instructions', 'fields', 'setup', 'entryWorkspace'}
            self.assertIn(set(task), (expected_keys, expected_keys | {'inheritWorkspace'}))
            self.assertTrue(task['goal'])
            self.assertTrue(task['instructions'])
            self.assertLessEqual(set(task['setup']), {'example', 'function', 'left', 'right'})
            for side in ('left', 'right'):
                if side in task['setup']:
                    self.assertEqual(set(task['setup'][side]), {'ordinal', 'view'})

    def test_task_partial_answers_inability_and_not_applicable(self):
        def a(value):
            return {'status': 'answered', 'value': value}
        t2a = next(field for field in participant_content()['fields'] if field['id'] == 'T2a')
        self.assertEqual(t2a['options'][4], {'value': 105, 'label': 'State 5 · produced by instcombine,simplifycfg'})
        self.assertEqual(validate_answers('T2', {'T2a': a(102)}), {})
        for stage in [f'T{i}' for i in range(7)]:
            self.assertEqual(validate_answers(stage, {}, complete=True), {})
        for task, field, status in [('T2', 'T2a', 'could_not_work_out'), ('T3', 'T3a', 'could_not_work_out'),
                                    ('T4', 'T4a', 'could_not_work_out'), ('T5', 'T5a', 'could_not_work_out')]:
            self.assertEqual(validate_answers(task, {field: {'status': status, 'value': None}}), {})
        for task, field, answer in [('T2', 'T2a', a(12)), ('T2', 'T2a', {'status': 'not_applicable', 'value': None}),
                                    ('T4', 'T4d', a(True)), ('T5', 'T5a', a(4)),
                                    ('T6', 'T6a', {'status': 'could_not_work_out', 'value': None})]:
            self.assertIn(field, validate_answers(task, {field: answer}))
        self.assertIn('T1a', validate_answers('T0', {'T1a': a('No orientation answers')}))
        self.assertIn('T5confidence', validate_answers('T5', {'T5confidence': a(5)}))
        self.assertEqual(validate_answers('T6', {'T6a': a('Synthetic\n<script>\n=SUM(A1)')}), {})
        self.assertEqual(validate_answers('T3', {'T3a': a('🙂' * 256)}), {})
        self.assertIn('T3a', validate_answers('T3', {'T3a': a('🙂' * 257)}))
        self.assertIn('T6a', validate_answers('T6', {'T6a': a('x' * 4001)}))
