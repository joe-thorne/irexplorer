import unittest

from src.backend.analysis import (
    compare_timeline_step,
    load_prebaked_curated_correspondence,
)
from src.backend.ingest import load_curated_timeline
from src.backend.model import (
    ModelValidationError,
    deserialise_correspondence,
    deserialise_json,
    serialise_correspondence,
    serialise_json,
)


class EndpointComparisonTests(unittest.TestCase):
    def test_hybrid_matcher_validates_all_curated_pass_pairs(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_curated_timeline(example, resolution="full")
                for ordinal in range(len(timeline.steps)):
                    result = compare_timeline_step(timeline, ordinal)
                    result.correspondence.validate(
                        timeline.state(ordinal), timeline.state(ordinal + 1)
                    )

    def test_hybrid_matcher_uses_eager_value_flow_across_early_passes(self) -> None:
        timeline = load_curated_timeline("score", resolution="full")
        for ordinal in range(3):
            with self.subTest(pass_name=timeline.steps[ordinal].origin.pass_name):
                result = compare_timeline_step(timeline, ordinal)
                result.correspondence.validate(
                    timeline.state(ordinal), timeline.state(ordinal + 1)
                )
                matched_instructions = [
                    link
                    for link in result.correspondence.links
                    if link.from_node_ids
                    and link.to_node_ids
                    and timeline.state(ordinal).by_id[link.from_node_ids[0]].kind
                    == "Instruction"
                ]
                self.assertTrue(matched_instructions)

        mem2reg = compare_timeline_step(timeline, 0).correspondence
        exact_blocks = [
            link
            for link in mem2reg.links
            if link.relation == "same"
            and link.confidence == "exact"
            and timeline.state(0).by_id[link.from_node_ids[0]].kind == "BasicBlock"
        ]
        self.assertEqual(len(exact_blocks), 4)

        instcombine = compare_timeline_step(timeline, 1).correspondence
        self.assertTrue(
            any(
                link.relation == "simplifiedInto"
                and link.confidence == "approximate"
                for link in instcombine.links
            )
        )

    def test_unresolved_candidates_are_explicit_none_links(self) -> None:
        timeline = load_curated_timeline("binary_search", resolution="full")
        correspondence = compare_timeline_step(timeline, 2).correspondence
        unresolved = [link for link in correspondence.links if link.confidence == "none"]

        self.assertTrue(unresolved)
        self.assertTrue(
            all(link.relation in {"added", "removed"} for link in unresolved)
        )
        self.assertTrue(
            all("inspected" in (link.evidence or "") for link in unresolved)
        )

    def test_score_anchor_comparison_is_coverage_complete_and_honest(self) -> None:
        timeline = load_curated_timeline("score")
        result = compare_timeline_step(timeline)
        correspondence = result.correspondence

        correspondence.validate(timeline.state(0), timeline.state(1))
        self.assertIn("not the effect of one optimisation pass", result.summary.context)
        self.assertEqual(
            len(correspondence.links_from),
            sum(1 for node in timeline.state(0).nodes if node.kind != "Module"),
        )
        self.assertEqual(
            len(correspondence.links_to),
            sum(1 for node in timeline.state(1).nodes if node.kind != "Module"),
        )

        removed_allocas = [
            link
            for link in correspondence.links
            if link.relation == "removed"
            and timeline.state(0).by_id[link.from_node_ids[0]].attributes.get("opcode")
            == "alloca"
        ]
        self.assertEqual(len(removed_allocas), 7)

        removed_blocks = [
            link
            for link in correspondence.links
            if link.relation == "removed"
            and timeline.state(0).by_id[link.from_node_ids[0]].kind == "BasicBlock"
        ]
        self.assertEqual(len(removed_blocks), 3)
        self.assertTrue(any("37 instructions removed" in item.text for item in result.summary.items))

        for item in result.summary.items:
            self.assertTrue(item.link_indices)
            for index in item.link_indices:
                self.assertLess(index, len(correspondence.links))

    def test_endpoint_correspondences_validate_for_all_curated_examples(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_curated_timeline(example)
                correspondence = compare_timeline_step(timeline).correspondence
                correspondence.validate(timeline.state(0), timeline.state(1))

    def test_correspondence_round_trips_and_rejects_invalid_endpoint_ids(self) -> None:
        timeline = load_curated_timeline("score")
        correspondence = compare_timeline_step(timeline).correspondence
        record = serialise_correspondence(correspondence)
        loaded = deserialise_correspondence(
            deserialise_json(serialise_json(record)), timeline.state(0), timeline.state(1)
        )
        self.assertEqual(loaded, correspondence)

        record["links"][0]["fromNodeIds"] = ["missing"]
        with self.assertRaises(ModelValidationError):
            deserialise_correspondence(record, timeline.state(0), timeline.state(1))

    def test_prebaked_correspondences_load_for_all_examples(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                self.assertGreater(
                    len(load_prebaked_curated_correspondence(example).links), 0
                )


if __name__ == "__main__":
    unittest.main()
