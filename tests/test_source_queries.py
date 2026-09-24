import json
from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from src.backend.api import QueryService, create_app
from src.backend.ingest import bake_curated_model_records, load_prebaked_curated_source
from src.backend.model import ModelValidationError
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

    def test_source_is_served_without_reading_raw_artefacts(self):
        expected = curated.read_source('score')
        service = QueryService(preload=False)
        unavailable = curated.ToolchainError('raw artefact read at runtime')
        with patch.object(curated, 'read_ir', side_effect=unavailable), \
                patch.object(curated, 'read_source', side_effect=unavailable):
            source = service.source('score')
        self.assertEqual(source['text'], expected)
        self.assertEqual(source['file'], 'score.c')
        self.assertTrue(source['inputVerified'])

    def test_wasted_multiple_matches_and_missing_locations(self):
        service = QueryService()
        counts = [sum(m['location']['line'] == 3 for m in service.source_mappings('score', n, 'fn0')['mappings']) for n in (0, 1, 2, 8, 12, 13)]
        self.assertGreater(counts[0], 1)
        self.assertGreater(counts[1], 1)
        self.assertEqual(counts[2:], [0, 0, 0, 0])
        state = service._state('score', 0)
        mapped = {m['instructionId'] for m in service.source_mappings('score', 0, 'fn0')['mappings']}
        self.assertTrue(any(n.kind == 'Instruction' and n.stable_id not in mapped for n in state.nodes))

    def test_http_boundaries(self):
        with TestClient(create_app()) as client:
            self.assertEqual(client.get('/api/examples/score/source').status_code, 200)
            path = '/api/examples/score/states/0/source-mappings'
            self.assertEqual(client.get(path, params={'functionId': 'fn0'}).status_code, 200)
            for url in ('/api/examples/missing/source', '/api/examples/score/states/99/source-mappings?functionId=fn0', path+'?functionId=fn0/bb0'):
                self.assertEqual(client.get(url).status_code, 404)
            self.assertEqual(client.get(path).status_code, 422)
            self.assertIn(client.post('/api/analyse', json={'source': 'int main() {}'}).status_code, (404, 405))

    def test_damaged_source_record_is_unavailable(self):
        damaged = ModelValidationError('damaged source record')
        with patch('src.backend.api.query.load_prebaked_curated_source', side_effect=damaged), \
                TestClient(create_app(QueryService(preload=False))) as client:
            with self.assertLogs('src.backend.api.app', level='ERROR'):
                response = client.get('/api/examples/score/source')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('damaged', response.text)

    def test_bake_rejects_source_that_differs_from_the_pinned_input(self):
        with TemporaryDirectory() as temporary:
            staged = Path(temporary) / 'curated'
            shutil.copytree(curated.ARTEFACTS_ROOT, staged)
            with curated.using_artefacts_root(staged), \
                    patch.object(curated, 'read_source', return_value='changed input'):
                with self.assertRaisesRegex(curated.ToolchainError, 'does not match the pinned input'):
                    bake_curated_model_records()

    def test_untrustworthy_source_records_are_rejected(self):
        record = json.loads(curated.model_source_path('score').read_text(encoding='utf-8'))
        damages = {
            'unsupported format': {**record, 'formatVersion': 99},
            'wrong example': {**record, 'file': 'quick_sort.c'},
            'edited text': {**record, 'text': record['text'] + '// edited\n'},
            'missing text': {k: v for k, v in record.items() if k != 'text'},
        }
        for name, damaged in damages.items():
            with self.subTest(name), TemporaryDirectory() as temporary:
                staged = Path(temporary) / 'curated'
                model_dir = staged / 'score' / 'model'
                model_dir.mkdir(parents=True)
                (model_dir / 'source.json').write_text(json.dumps(damaged), encoding='utf-8')
                with curated.using_artefacts_root(staged), self.assertRaises(ModelValidationError):
                    load_prebaked_curated_source('score')
