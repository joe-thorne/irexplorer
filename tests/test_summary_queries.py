import hashlib
import unittest
from dataclasses import replace
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.analysis.composition import ComposedCorrespondence
from src.backend.analysis.report import describe_comparison
from src.backend.analysis.summary import RemarkReference, StructuralClaim, summarise_correspondence
from src.backend.api import QueryService, create_app
from src.backend.ingest import load_curated_timeline_record
from src.backend.model import Correspondence, Link, StateGraph
from src.backend.model.graph import Edge, Node
from src.backend.toolchain import curated


class SummaryQueriesTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.service = QueryService()

    def test_all_examples_comparison_modes_resolve_existing_evidence(self):
        service = self.service
        for example in curated.list_examples():
            timeline = load_curated_timeline_record(example)
            for lower, higher in [(n, n + 1) for n in range(13)] + [(0, 9), (0, 13), (4, 6)]:
                with self.subTest(example=example, span=(lower, higher)):
                    response = service.comparison_report(example, lower, higher)
                    self.assertEqual(response, service.comparison_report(example, higher, lower))
                    self.assertEqual([s['ordinal'] for s in response['states']], list(range(lower, higher + 1)))
                    self.assertEqual(len(response['steps']), higher - lower)
                    for item in response['structuralClaims']:
                        self.assertEqual(set(item), {'text', 'linkIndices', 'remarkReferences'})
                        self.assertTrue(item['linkIndices'] or item['remarkReferences'])
                        self.assertTrue(all(0 <= i < len(response['links']) for i in item['linkIndices']))
                        # Each remark reference addresses a step in this span, then a remark in that step.
                        for ref in item['remarkReferences']:
                            self.assertEqual(set(ref), {'stepIndex', 'remarkIndex'})
                            self.assertLess(ref['remarkIndex'], len(response['steps'][ref['stepIndex']]['remarks']))
                    for record, original in zip(response['steps'], timeline.steps[lower:higher], strict=True):
                        self.assertEqual(record['command'], original.origin.command)
                        self.assertEqual([r['raw'] for r in record['remarks']], [r.raw for r in original.remarks])
                        self.assertEqual([r['passName'] for r in record['remarks']],
                                         [r.pass_name for r in original.remarks])
                        for remark in record['remarks']:
                            self.assertEqual(set(remark), {'passName', 'name', 'function', 'location', 'raw'})
                    if higher == 13:
                        self.assertIn('not the effect of one optimisation pass', response['context'])
                    if higher > lower + 1:
                        self.assertIn('Composed comparison', response['context'])

    def test_remark_reference_to_an_intermediate_step_reaches_the_wire(self):
        # quick_sort step 3 (after gvn) records remarks; the final step of span 3→5 records no compiler remarks.
        def cite_first_step(*args):
            report = describe_comparison(*args)
            item = StructuralClaim('An intermediate remark.', remark_references=(RemarkReference(0, 1),))
            return replace(report, claims=(*report.claims, item))

        with patch('src.backend.api.query.describe_comparison', side_effect=cite_first_step):
            response = QueryService().comparison_report('quick_sort', 3, 5)
        self.assertEqual(response['steps'][-1]['remarks'], [])
        self.assertEqual(response['structuralClaims'][-1]['remarkReferences'], [{'stepIndex': 0, 'remarkIndex': 1}])
        self.assertEqual(response['steps'][0]['remarks'][1]['raw'],
                         load_curated_timeline_record('quick_sort').steps[3].remarks[1].raw)

    def test_same_state_no_op_and_whole_example_scope(self):
        for example in curated.list_examples():
            for ordinal in range(14):
                response = self.service.comparison_report(example, ordinal, ordinal)
                self.assertEqual(response['structuralClaims'], [])
                self.assertEqual(response['links'], [])
                self.assertEqual(response['steps'], [])
                self.assertEqual(response['states'][0]['ordinal'], ordinal)
                self.assertIn('Same recorded state', response['context'])
        no_op = self.service.comparison_report('score', 3, 4)
        self.assertIn('retained as a no-op', no_op['structuralClaims'][0]['text'])
        composed = self.service.comparison_report('score', 4, 6)
        self.assertNotIn('this pass', ' '.join(i['text'] for i in composed['structuralClaims']))
        self.assertEqual(self.service.comparison_report('quick_sort', 0, 9)['scope'], 'whole example')

    def test_baked_cfg_summary_names_relabelled_branch_edges(self):
        response = self.service.comparison_report('quick_sort', 1, 2)
        cfg_item = next(item for item in response['structuralClaims'] if item['text'].startswith('CFG'))

        self.assertEqual(
            cfg_item['text'],
            'CFG edges changed: relabelled for.body → if.then [true → false], '
            'for.body → if.end [false → true].',
        )
        self.assertTrue(cfg_item['linkIndices'])

    def test_composed_summary_covers_changed_and_approximate_endpoint_changes(self):
        """I4: composed summaries must account for every non-exact endpoint change."""
        response = self.service.comparison_report('score', 0, 12)
        timeline = load_curated_timeline_record('score')
        covered_indices = {
            index for item in response['structuralClaims'] for index in item['linkIndices']
        }
        relevant_indices = {
            index
            for index, link in enumerate(response['links'])
            if self._link_kind_at_comparison_endpoint(timeline, link, 0, 12) == 'Instruction'
            and (
                link['relation'] == 'changed'
                or (link['relation'] in {'added', 'removed'} and link['confidence'] == 'approximate')
            )
        }

        self.assertTrue(relevant_indices)
        self.assertTrue(relevant_indices.issubset(covered_indices))
        summary_text = ' '.join(item['text'] for item in response['structuralClaims'])
        self.assertIn('instructions changed with approximate correspondence evidence.', summary_text)
        self.assertIn('instructions removed with approximate correspondence evidence.', summary_text)

    def test_summary_covers_every_non_same_link_in_task_comparisons(self):
        """Summaries must expose every recorded structural change."""
        pairs = [(ordinal, ordinal + 1) for ordinal in range(13)] + [(0, 9), (0, 13), (4, 6)]
        uncovered = []
        for example in self.service.list_examples()['examples']:
            for lower, higher in pairs:
                with self.subTest(example=example, span=(lower, higher)):
                    response = self.service.comparison_report(example, lower, higher)
                    covered = {
                        index
                        for item in response['structuralClaims']
                        for index in item['linkIndices']
                    }
                    uncovered.extend(
                        (example, lower, higher, index, link)
                        for index, link in enumerate(response['links'])
                        if link['relation'] != 'same' and index not in covered
                    )
        self.assertEqual(uncovered, [])

    def test_function_summary_item_is_added_without_rewording_adjacent_items(self):
        """The new function item must not disturb the 39 existing item lists."""
        expected_digests = {
            'binary_search:0-1': '0f29f9eb77d4ef47bdf6bb2e8fc5cbb4ecb87d28f4c3ed0a8eaf861732bd7bc6',
            'binary_search:1-2': 'cae048b9dcd76afd6aaf35eaeffdb83e1f86592f232ad5a77a20bdf2e6d7a2fe',
            'binary_search:2-3': '1adff203156999df4271318f36765100fcfe672d5047667c2d7d23f7a9882e0f',
            'binary_search:3-4': '93b9572519282275b5b3f8f29079a4a723a738e481f9a554c702709cf79d3452',
            'binary_search:4-5': '93b9572519282275b5b3f8f29079a4a723a738e481f9a554c702709cf79d3452',
            'binary_search:5-6': '34ad1b4a64e2094512656dbd1a1e872089882365b89c36de3c0a67257cc664bf',
            'binary_search:6-7': 'b5dff3773fef6e3acaa1062b120ee29c32255e6d52f4f2b2d27bd81a7a5179e3',
            'binary_search:7-8': '93b9572519282275b5b3f8f29079a4a723a738e481f9a554c702709cf79d3452',
            'binary_search:8-9': '93b9572519282275b5b3f8f29079a4a723a738e481f9a554c702709cf79d3452',
            'binary_search:9-10': '7e67616c896642e2dbdbb6ce2ab7f1ad15a3b1f7e7be411eac3c4dce7ed09788',
            'binary_search:10-11': '17318a9ca30895af81ffc06ae128183ade68886732f099ad2b035d8f4a19a937',
            'binary_search:11-12': 'fd34857fd308269eb465e00fdeb8d418b17693fd4b2b6ed07565712d079fd1d8',
            'binary_search:12-13': '35ae167331c9dcb14ed2888d853bf7047984d50d1b30bd6363366ef22f171036',
            'quick_sort:0-1': 'c58bf0ee00615e3800f726a2c4b9c48bda6a94df0008792f974cf9e96efbb09d',
            'quick_sort:1-2': '9519af0de2b6b5be654c996ee5cf6dd1819eb0aad5ce29f3749d7d8c9c9a683a',
            'quick_sort:2-3': '7d1ffa6b0eac431dc1822ac1b18d4c61f22b7454ec395df1b5ff857db1f5e5ef',
            'quick_sort:3-4': 'df6e4dafdfadf8e859749abc720a11761bd5517d190e7af9c1cc1f919cf3b6bd',
            'quick_sort:4-5': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'quick_sort:5-6': '11574c0b44b6b7d3e826b1223910f6bc262be0e2cd18c6837b9501ad60b6727a',
            'quick_sort:6-7': '2cd606bb8759ee51eed72087945b044b47d181a064dd02d19e6a0d04830333b6',
            'quick_sort:7-8': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'quick_sort:8-9': 'd6ab697e0a2d43a268ec105e7a149b36067153c6053689e3d295fe679b16537c',
            'quick_sort:9-10': '856fe2b77f2e37f41450eab1e337c0274d4a4ab8bf77db72fc6aa8176ea6519a',
            'quick_sort:10-11': '77b73a9f98ff89aa2b6c89c66502926cb9f7d6493c30cb086c4ad5a2764b34d4',
            'quick_sort:11-12': '828e2c9e4847cb14bbcdd26c684983ee9db098cb7fdf22885ec002a88ed8249b',
            'quick_sort:12-13': '9d75a91d3457cd7cd33c9ca70aec59b9f0094a0e26a75e4bb3109f0be326ec55',
            'score:0-1': 'a36a3e37c891cba1fc9629e03d8cec0e9aa39eec2d53bfe15d5c19ee7a4bff42',
            'score:1-2': 'd612aa5f7251562023cf05219b6951d42085c964fd0502da4439c755b3e2122c',
            'score:2-3': 'e7e0c8201467912bb5a33452386431d705f6690d3ae58bd0ac0fba989b4396d1',
            'score:3-4': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:4-5': '1cd82089c800d0c027a6a6440c875cac26a5661af59f245c9238758f3128a1af',
            'score:5-6': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:6-7': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:7-8': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:8-9': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:9-10': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:10-11': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:11-12': 'dc551e2ba1ab0e2283b8d5425216f13011da20e66b0d3668215fe9264ea08bc8',
            'score:12-13': '1491933ad921a9faed51ca20a4301e85af4ccebd8912e4fcde80cf5b1722baaa',
        }
        additions = {'quick_sort:12-13': '1 function removed.'}

        self.assertEqual(len(expected_digests), 39)
        for key, expected_digest in expected_digests.items():
            example, span = key.split(':')
            lower, higher = map(int, span.split('-'))
            texts = [
                item['text']
                for item in self.service.comparison_report(example, lower, higher)['structuralClaims']
            ]
            if key in additions:
                self.assertIn(additions[key], texts)
                texts.remove(additions[key])
            digest = hashlib.sha256('\n'.join(texts).encode()).hexdigest()
            self.assertEqual(digest, expected_digest, key)

    def test_block_movement_and_composed_group_summaries_are_covered(self):
        from_state = _block_state(0, 'source')
        moved_state = _block_state(1, 'target')
        moved = Correspondence(
            from_ordinal=0,
            to_ordinal=1,
            covered_kinds=('BasicBlock',),
            links=(Link(('source/entry',), ('target/entry',), 'moved', 'exact', 'moved'),),
        )
        moved.validate(from_state, moved_state)
        self.assertIn(
            '1 basic block was linked as moved correspondences.',
            {item.text for item in summarise_correspondence(moved, from_state, moved_state, None).claims},
        )

        split_state = _block_state(2, 'left', 'right')
        split = ComposedCorrespondence(
            from_ordinal=0,
            to_ordinal=2,
            covered_kinds=('BasicBlock',),
            links=(Link(('source/entry',), ('left/entry', 'right/entry'), 'split', 'approximate', 'split'),),
        )
        split.validate(from_state, split_state)
        self.assertIn(
            '1 basic block groups split: 1 → 2 basic blocks with approximate correspondence evidence.',
            {item.text for item in summarise_correspondence(split, from_state, split_state, None).claims},
        )

        merged_state = _block_state(4, 'merged')
        merged = ComposedCorrespondence(
            from_ordinal=2,
            to_ordinal=4,
            covered_kinds=('BasicBlock',),
            links=(Link(('left/entry', 'right/entry'), ('merged/entry',), 'merged', 'approximate', 'merged'),),
        )
        merged.validate(split_state, merged_state)
        self.assertIn(
            '1 basic block groups merged: 2 → 1 basic block with approximate correspondence evidence.',
            {item.text for item in summarise_correspondence(merged, split_state, merged_state, None).claims},
        )

    @staticmethod
    def _link_kind_at_comparison_endpoint(timeline, link, from_ordinal, to_ordinal):
        node_id = (link['fromNodeIds'] or link['toNodeIds'])[0]
        state = timeline.state(from_ordinal if link['fromNodeIds'] else to_ordinal)
        return state.by_id[node_id].kind

    def test_http_schema_errors_and_no_mutation(self):
        with TestClient(create_app(self.service)) as client:
            for example in curated.list_examples():
                for before, after in [(0, 1), (0, 9), (0, 13), (13, 0), (12, 13), (4, 4), (3, 4)]:
                    response = client.get(f'/api/examples/{example}/comparison-report',
                                          params={'fromOrdinal': before, 'toOrdinal': after})
                    self.assertEqual(response.status_code, 200, response.text)
                    self.assertEqual(response.json(), self.service.comparison_report(example, before, after))
            for query, status in [('fromOrdinal=-1&toOrdinal=1', 422), ('fromOrdinal=0', 422),
                                  ('fromOrdinal=0&toOrdinal=99', 404)]:
                self.assertEqual(client.get('/api/examples/score/comparison-report?' + query).status_code, status)
            missing = client.get('/api/examples/missing/comparison-report?fromOrdinal=0&toOrdinal=1')
            self.assertEqual(missing.status_code, 404)
            with patch('src.backend.analysis.report.compose_timeline_correspondences',
                       side_effect=ValueError('private path')):
                with self.assertLogs('src.backend.api.app', level='ERROR'):
                    response = client.get('/api/examples/score/comparison-report?fromOrdinal=0&toOrdinal=9')
                self.assertEqual(response.status_code, 503)
                self.assertNotIn('private path', response.text)
            self.assertIn(client.post('/api/examples/score/comparison-report').status_code, (404, 405))


def _block_state(ordinal, *function_ids):
    nodes = [Node('module', 'Module', 'module')]
    edges = []
    for order, function_id in enumerate(function_ids):
        block_id = f'{function_id}/entry'
        instruction_id = f'{block_id}/ret'
        nodes.extend((
            Node(function_id, 'Function', function_id),
            Node(block_id, 'BasicBlock', 'entry', {'label': 'entry'}),
            Node(instruction_id, 'Instruction', 'ret void', {'opcode': 'ret', 'is_terminator': True, 'successors': ()}),
        ))
        edges.extend((
            Edge('module', function_id, 'contains', order=order),
            Edge(function_id, block_id, 'contains', order=0),
            Edge(block_id, instruction_id, 'contains', order=0),
        ))
    state = StateGraph(ordinal=ordinal, state_id=f'state-{ordinal}', nodes=tuple(nodes), edges=tuple(edges))
    state.validate()
    return state
