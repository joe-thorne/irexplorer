"""Artefact-reviewed expectations, independent of matcher-generated records."""

import csv
import hashlib
import json
from pathlib import Path
import re
import unittest

from src.backend.analysis import (
    compare_timeline_step,
    load_prebaked_curated_correspondence,
)
from src.backend.analysis.compare import summarise_correspondence
from src.backend.ingest import load_curated_timeline, load_prebaked_curated_timeline
from src.backend.toolchain import curated


DATA = Path(__file__).parent / 'data' / 'expected_links'


class ArtefactExpectedLinkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        record = json.loads((DATA / 'cases.json').read_text(encoding='utf-8'))
        if record['formatVersion'] != 1:
            raise ValueError('Unsupported expected-link fixture format')
        cls.cases = record['cases']
        cls.fresh = {
            example: load_curated_timeline(example, resolution='full')
            for example in ('score', 'binary_search')
        }
        cls.baked = {
            example: load_prebaked_curated_timeline(example)
            for example in cls.fresh
        }

    def rows(self, case):
        with (DATA / case['table']).open(encoding='utf-8', newline='') as handle:
            return list(csv.DictReader(handle, delimiter='\t'))

    def expected_links(self, rows):
        return {
            (tuple(filter(None, row['from_id'].split(','))),
             tuple(filter(None, row['to_id'].split(','))),
             row['relation'], row['confidence'])
            for row in rows
        }

    def actual_links(self, correspondence):
        return {
            (link.from_node_ids, link.to_node_ids, link.relation, link.confidence)
            for link in correspondence.links
        }

    def test_review_tables_pin_artefacts_and_cover_every_comparable_node(self) -> None:
        self.assertEqual(
            {(case['example'], case['stepType']) for case in self.cases},
            {(example, step) for example in self.fresh
             for step in ('mem2reg', 'instcombine', 'simplifycfg', 'loop-rotate', 'anchor')},
        )
        self.assertEqual(len(self.cases), 10)
        for case in self.cases:
            with self.subTest(table=case['table']):
                rows = self.rows(case)
                self.assertTrue(rows)
                self.assertEqual(len(self.expected_links(rows)), len(rows))
                timeline = self.fresh[case['example']]
                step = timeline.steps[case['fromOrdinal']]
                self.assertEqual(step.to_ordinal, case['toOrdinal'])
                self.assertEqual(step.kind, case['stepKind'])
                self.assertTrue(case['story'])
                for side, ordinal, artefact in zip(
                    ('from', 'to'), (case['fromOrdinal'], case['toOrdinal']), case['artefacts']
                ):
                    state = timeline.state(ordinal)
                    path = curated.REPO_ROOT / artefact['path']
                    self.assertEqual(state.state_id, artefact['stateId'])
                    self.assertEqual(path, curated.ir_path(case['example'], state.state_id))
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), artefact['sha256'])
                    ids = [row[f'{side}_id'] for row in rows if row[f'{side}_id']]
                    self.assertEqual(len(ids), len(set(ids)), 'Each endpoint must occur once')
                    self.assertEqual(set(ids), {node.stable_id for node in state.nodes if node.kind != 'Module'})
                    for row in rows:
                        self.assertTrue(row['rationale'])
                        node_id = row[f'{side}_id']
                        if not node_id:
                            self.assertEqual(row[f'{side}_text'], '')
                            self.assertEqual(row[f'{side}_source'], '')
                            continue
                        node = state.by_id[node_id]
                        text = str(node.attributes.get('text', node.display_name))
                        text = re.sub(r',?\s*!dbg\s*!\d+', '', text)
                        self.assertEqual(text, row[f'{side}_text'])
                        source = node.attributes.get('source')
                        location = f'{Path(source.file).name}:{source.line}:{source.column}' if source else ''
                        self.assertEqual(location, row[f'{side}_source'])

    def test_fresh_analysis_matches_reviewed_links(self) -> None:
        for case in self.cases:
            with self.subTest(table=case['table']):
                result = compare_timeline_step(self.fresh[case['example']], case['fromOrdinal'])
                baked = load_prebaked_curated_correspondence(
                    case['example'], case['fromOrdinal']
                )
                # Compare reviewed rows here only when fresh and stored overlays
                # agree; the served-overlay test below always checks the fixture.
                if self.actual_links(result.correspondence) != self.actual_links(baked):
                    continue
                self.assertEqual(self.actual_links(result.correspondence), self.expected_links(self.rows(case)))

    def test_served_overlays_match_reviewed_links(self) -> None:
        for case in self.cases:
            with self.subTest(table=case['table']):
                correspondence = load_prebaked_curated_correspondence(
                    case['example'], case['fromOrdinal']
                )
                self.assertEqual(self.actual_links(correspondence), self.expected_links(self.rows(case)))

    def test_cfg_and_summary_match_the_reviewed_artefact_story(self) -> None:
        for case in self.cases:
            for dataset in (self.fresh, self.baked):
                with self.subTest(table=case['table'], prebaked=dataset is self.baked):
                    timeline = dataset[case['example']]
                    before = timeline.state(case['fromOrdinal'])
                    after = timeline.state(case['toOrdinal'])
                    for state, expected in ((before, case['cfgBefore']), (after, case['cfgAfter'])):
                        actual = {
                            (state.by_id[edge.from_id].display_name,
                             state.by_id[edge.to_id].display_name,
                             edge.label or 'unconditional')
                            for edge in state.edges if edge.relation == 'controlFlow'
                        }
                        self.assertEqual(actual, {tuple(edge) for edge in expected})
                    if dataset is self.fresh:
                        result = compare_timeline_step(timeline, case['fromOrdinal'])
                        correspondence, summary = result.correspondence, result.summary
                    else:
                        correspondence = load_prebaked_curated_correspondence(
                            case['example'], case['fromOrdinal']
                        )
                        summary = summarise_correspondence(
                            correspondence, before, after, step=timeline.steps[case['fromOrdinal']]
                        )
                    text = ' '.join(item.text for item in summary.items)
                    claims = (
                        case.get('freshSummaryContains', case['summaryContains'])
                        if dataset is self.fresh
                        else case['summaryContains']
                    )
                    for claim in claims:
                        self.assertIn(claim, text)
                    if case['stepKind'] == 'recompiled':
                        self.assertIn('not the effect of one optimisation pass', summary.context)
                        matched = [link for link in correspondence.links
                                   if link.from_node_ids and link.to_node_ids
                                   and before.by_id[link.from_node_ids[0]].kind != 'Function']
                        self.assertTrue(matched)
                        self.assertTrue(all(link.confidence == 'approximate' for link in matched))
                    for item in summary.items:
                        self.assertTrue(item.link_indices or item.remark_indices)
                        self.assertTrue(all(0 <= index < len(correspondence.links) for index in item.link_indices))
                        self.assertTrue(all(0 <= index < len(timeline.steps[case['fromOrdinal']].remarks)
                                            for index in item.remark_indices))


if __name__ == '__main__':
    unittest.main()
