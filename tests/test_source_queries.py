import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from src.backend.api import QueryService, create_app
from src.backend.toolchain import curated


class SourceQueriesTests(unittest.TestCase):
    def test_all_sources_and_function_scoped_mappings(self):
        service = QueryService()
        for example in curated.list_examples():
            source = service.source(example)
            self.assertTrue(source['inputVerified'])
            self.assertEqual(source['text'], curated.read_source(example))
            for ordinal in range(14):
                state = service._state(example, ordinal)
                for fn in service.ir(example, ordinal)['functions']:
                    mappings = service.source_mappings(example, ordinal, fn['id'])['mappings']
                    expected = {e.from_id for e in state.edges if e.relation == 'sourceMap'
                                and state.contains_parent[state.contains_parent[e.from_id]] == fn['id']}
                    self.assertEqual({m['instructionId'] for m in mappings}, expected)
                    for m in mappings:
                        self.assertEqual(m['blockId'], state.contains_parent[m['instructionId']])
                        self.assertEqual(m['location']['file'], source['file'])
                        self.assertTrue(0 < m['location']['line'] <= len(source['text'].splitlines()))
                        self.assertEqual(m['evidence'], 'debugLoc')
                        self.assertNotIn('confidence', m)

    def test_wasted_multiple_matches_and_missing_locations(self):
        service = QueryService()
        counts = [sum(m['location']['line'] == 3 for m in service.source_mappings('score', n, 'fn0')['mappings']) for n in (0, 1, 2, 8, 12, 13)]
        self.assertGreater(counts[0], 1)
        self.assertGreater(counts[1], 1)
        self.assertEqual(counts[2:], [0, 0, 0, 0])
        state = service._state('score', 0)
        mapped = {m['instructionId'] for m in service.source_mappings('score', 0, 'fn0')['mappings']}
        self.assertTrue(any(n.kind == 'Instruction' and n.stable_id not in mapped for n in state.nodes))

    def test_http_boundaries_and_checksum_failure(self):
        with TestClient(create_app()) as client:
            self.assertEqual(client.get('/api/examples/score/source').status_code, 200)
            path = '/api/examples/score/states/0/source-mappings'
            self.assertEqual(client.get(path, params={'functionId': 'fn0'}).status_code, 200)
            for url in ('/api/examples/missing/source', '/api/examples/score/states/99/source-mappings?functionId=fn0', path+'?functionId=fn0/bb0'):
                self.assertEqual(client.get(url).status_code, 404)
            self.assertEqual(client.get(path).status_code, 422)
            with patch('src.backend.toolchain.curated.read_source', return_value='changed input'):
                with self.assertLogs('src.backend.api.app', level='ERROR'):
                    response = client.get('/api/examples/score/source')
                self.assertEqual(response.status_code, 503)
                self.assertNotIn('changed input', response.text)
            self.assertIn(client.post('/api/analyse', json={'source': 'int main() {}'}).status_code, (404, 405))
