import unittest

from src.backend.analysis import load_stored_curated_correspondences
from src.backend.analysis.report import SAME_STATE_CONTEXT, describe_comparison
from src.backend.analysis.summary import StructuralClaim
from src.backend.ingest import load_curated_timeline_record
from src.backend.toolchain import curated

SPANS = [(n, n + 1) for n in range(13)] + [(0, 9), (0, 13), (4, 6)]


class ComparisonReportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.examples = {}
        for example in curated.list_examples():
            timeline = load_curated_timeline_record(example)
            cls.examples[example] = (timeline, load_stored_curated_correspondences(example, timeline))

    def test_span_order_does_not_change_the_report(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            for lower, higher in SPANS:
                with self.subTest(example=example, span=(lower, higher)):
                    self.assertEqual(describe_comparison(timeline, correspondences, lower, higher),
                                     describe_comparison(timeline, correspondences, higher, lower))

    def test_report_covers_exactly_the_states_and_steps_in_the_span(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            for lower, higher in SPANS:
                with self.subTest(example=example, span=(lower, higher)):
                    report = describe_comparison(timeline, correspondences, higher, lower)
                    self.assertEqual((report.from_ordinal, report.to_ordinal), (lower, higher))
                    self.assertEqual([s.ordinal for s in report.states], list(range(lower, higher + 1)))
                    self.assertEqual(report.steps, timeline.steps[lower:higher])

    def test_every_item_is_backed_by_resolvable_evidence(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            for lower, higher in SPANS:
                with self.subTest(example=example, span=(lower, higher)):
                    report = describe_comparison(timeline, correspondences, lower, higher)
                    for item in report.claims:
                        self.assertIs(type(item), StructuralClaim)
                        self.assertTrue(item.link_indices or item.remark_references)
                        self.assertTrue(all(0 <= i < len(report.links) for i in item.link_indices))
                        for ref in item.remark_references:
                            self.assertLess(ref.remark_index, len(report.steps[ref.step_index].remarks))
                    for event in report.optimisations:
                        self.assertTrue(all(0 <= i < len(report.links) for i in event["linkIndices"]))

    def test_adjacent_span_reports_the_stored_overlay(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            for ordinal in range(len(correspondences)):
                with self.subTest(example=example, ordinal=ordinal):
                    report = describe_comparison(timeline, correspondences, ordinal, ordinal + 1)
                    self.assertEqual(report.links, correspondences[ordinal].links)

    def test_composed_span_says_so(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            with self.subTest(example=example):
                report = describe_comparison(timeline, correspondences, 0, 13)
                self.assertIn("Composed comparison", report.context)
                self.assertIn("not the effect of one optimisation pass", report.context)

    def test_same_state_reports_no_change(self) -> None:
        for example, (timeline, correspondences) in self.examples.items():
            for ordinal in range(len(timeline.states)):
                with self.subTest(example=example, ordinal=ordinal):
                    report = describe_comparison(timeline, correspondences, ordinal, ordinal)
                    self.assertEqual(report.context, SAME_STATE_CONTEXT)
                    self.assertEqual([s.ordinal for s in report.states], [ordinal])
                    self.assertEqual((report.steps, report.links, report.claims, report.optimisations),
                                     ((), (), (), ()))

    def test_ordinal_outside_the_timeline_is_rejected(self) -> None:
        timeline, correspondences = next(iter(self.examples.values()))
        with self.assertRaises(ValueError):
            describe_comparison(timeline, correspondences, 0, len(timeline.states))


if __name__ == "__main__":
    unittest.main()
