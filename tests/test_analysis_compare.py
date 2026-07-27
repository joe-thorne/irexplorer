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
