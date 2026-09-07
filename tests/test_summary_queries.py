import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.api import QueryService, create_app
from src.backend.analysis.compare import summarise_correspondence
from src.backend.toolchain import curated


class SummaryQueriesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.service = QueryService()

    def test_all_examples_comparison_modes_resolve_existing_evidence(self):
        service = self.service
        for example in curated.list_examples():
            loaded = service._example(example)
            for lower, higher in [(n, n + 1) for n in range(13)] + [(0, 9), (0, 13), (4, 6)]:
                with self.subTest(example=example, span=(lower, higher)):
                    response = service.summary(example, lower, higher)
                    self.assertEqual(response, service.summary(example, higher, lower))
                    comparison = service._comparison(loaded, lower, higher)
                    step = loaded.timeline.steps[higher - 1]
                    expected = summarise_correspondence(comparison, loaded.timeline.state(lower),
                                                        loaded.timeline.state(higher), step)
                    self.assertEqual(response['context'], expected.context)
                    self.assertEqual([i['text'] for i in response['items']], [i.text for i in expected.items])
                    self.assertEqual(len(response['links']), len(comparison.links))
                    for index, link in enumerate(comparison.links):
                        record = response['links'][index]
                        self.assertEqual(record['fromNodeIds'], list(link.from_node_ids))
                        self.assertEqual(record['toNodeIds'], list(link.to_node_ids))
                        self.assertEqual(record['evidence'], link.evidence)
                        self.assertEqual(record['confidence'], link.confidence)
                    for item in response['items']:
                        self.assertTrue(item['linkIndices'] or item['remarkIndices'])
                        self.assertTrue(all(0 <= i < len(response['links']) for i in item['linkIndices']))
                        self.assertTrue(all(0 <= i < len(step.remarks) for i in item['remarkIndices']))
                    for record, original in zip(response['steps'], loaded.timeline.steps[lower:higher]):
                        self.assertEqual(record['command'], original.origin.command)
                        self.assertEqual([r['raw'] for r in record['remarks']], [r.raw for r in original.remarks])
                    if higher == 13:
                        self.assertIn('not the effect of one optimisation pass', response['context'])
                    if higher > lower + 1:
                        self.assertIn('Composed comparison', response['context'])

    def test_same_state_no_op_and_whole_example_scope(self):
        for example in curated.list_examples():
            for ordinal in range(14):
                response = self.service.summary(example, ordinal, ordinal)
                self.assertEqual(response['items'], [])
                self.assertEqual(response['links'], [])
                self.assertEqual(response['steps'], [])
                self.assertEqual(response['states'][0]['ordinal'], ordinal)
                self.assertIn('Same recorded state', response['context'])
        no_op = self.service.summary('score', 3, 4)
        self.assertIn('retained as a no-op', no_op['items'][0]['text'])
        composed = self.service.summary('score', 4, 6)
        self.assertNotIn('this pass', ' '.join(i['text'] for i in composed['items']))
        self.assertEqual(self.service.summary('quick_sort', 0, 9)['scope'], 'whole example')

    def test_http_schema_errors_and_no_mutation(self):
        with TestClient(create_app(self.service)) as client:
            for example in curated.list_examples():
                for before, after in [(0, 1), (0, 9), (0, 13), (13, 0), (12, 13), (4, 4), (3, 4)]:
                    response = client.get(f'/api/examples/{example}/summary', params={'fromOrdinal': before, 'toOrdinal': after})
                    self.assertEqual(response.status_code, 200, response.text)
                    self.assertEqual(response.json(), self.service.summary(example, before, after))
            for query, status in [('fromOrdinal=-1&toOrdinal=1', 422), ('fromOrdinal=0', 422),
                                  ('fromOrdinal=0&toOrdinal=99', 404)]:
                self.assertEqual(client.get('/api/examples/score/summary?' + query).status_code, status)
            self.assertEqual(client.get('/api/examples/missing/summary?fromOrdinal=0&toOrdinal=1').status_code, 404)
            with patch('src.backend.api.query.compose_timeline_correspondences', side_effect=ValueError('private path')):
                with self.assertLogs('src.backend.api.app', level='ERROR'):
                    response = client.get('/api/examples/score/summary?fromOrdinal=0&toOrdinal=9')
                self.assertEqual(response.status_code, 503)
                self.assertNotIn('private path', response.text)
            self.assertIn(client.post('/api/examples/score/summary').status_code, (404, 405))
