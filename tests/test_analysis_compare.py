import unittest

from src.backend.analysis import (
    compose_correspondences,
    compose_timeline_correspondences,
    compare_timeline_step,
    is_identity_correspondence,
    load_prebaked_curated_correspondence,
    load_prebaked_curated_correspondences,
)
from src.backend.ingest import load_curated_timeline, load_prebaked_curated_timeline
from src.backend.model import (
    Correspondence,
    Edge,
    Link,
    ModelValidationError,
    Node,
    StateGraph,
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
        timeline = load_curated_timeline("score", resolution="full")
        result = compare_timeline_step(timeline, len(timeline.steps) - 1)
        correspondence = result.correspondence
        from_state = timeline.state(12)
        to_state = timeline.state(13)

        correspondence.validate(from_state, to_state)
        self.assertIn("not the effect of one optimisation pass", result.summary.context)
        self.assertEqual(
            len(correspondence.links_from),
            sum(1 for node in from_state.nodes if node.kind != "Module"),
        )
        self.assertEqual(
            len(correspondence.links_to),
            sum(1 for node in to_state.nodes if node.kind != "Module"),
        )

        self.assertTrue(
            any(link.confidence == "none" for link in correspondence.links)
        )

        for item in result.summary.items:
            self.assertTrue(item.link_indices or item.remark_indices)
            for index in item.link_indices:
                self.assertLess(index, len(correspondence.links))
            for index in item.remark_indices:
                self.assertLess(index, len(timeline.steps[-1].remarks))

        conservative_matches = [
            link
            for link in correspondence.links
            if link.from_node_ids
            and link.to_node_ids
            and timeline.state(12).by_id[link.from_node_ids[0]].kind != "Function"
        ]
        self.assertTrue(conservative_matches)
        self.assertTrue(
            all(link.confidence == "approximate" for link in conservative_matches)
        )
        self.assertTrue(
            all("conservative anchor" in (link.evidence or "") for link in conservative_matches)
        )

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

    def test_prebaked_adjacent_correspondences_load_for_all_examples(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_prebaked_curated_timeline(example)
                correspondences = load_prebaked_curated_correspondences(example, timeline)
                self.assertEqual(len(correspondences), len(timeline.steps))
                for ordinal, correspondence in enumerate(correspondences):
                    self.assertEqual(
                        (correspondence.from_ordinal, correspondence.to_ordinal),
                        (ordinal, ordinal + 1),
                    )
                    correspondence.validate(
                        timeline.state(ordinal), timeline.state(ordinal + 1)
                    )
                self.assertGreater(
                    len(load_prebaked_curated_correspondence(example).links), 0
                )

    def test_noop_steps_are_identity_correspondences(self) -> None:
        timeline = load_prebaked_curated_timeline("score")
        correspondences = load_prebaked_curated_correspondences("score", timeline)

        self.assertTrue(is_identity_correspondence(correspondences[3]))
        self.assertFalse(is_identity_correspondence(correspondences[0]))

        result = compare_timeline_step(timeline, 3)
        self.assertIn("retained as a no-op", result.summary.items[0].text)
        self.assertEqual(
            result.summary.items[0].link_indices,
            tuple(range(len(result.correspondence.links))),
        )

    def test_pass_summary_cites_its_own_captured_remarks(self) -> None:
        timeline = load_curated_timeline("quick_sort", resolution="full")
        result = compare_timeline_step(timeline, 3)

        remark_item = next(item for item in result.summary.items if item.remark_indices)
        self.assertEqual(remark_item.remark_indices, tuple(range(len(timeline.steps[3].remarks))))
        self.assertIn("compiler remarks were captured for this step", remark_item.text)

    def test_composed_view_coarsens_relation_and_degrades_confidence(self) -> None:
        timeline = load_curated_timeline("binary_search", resolution="full")
        correspondences = tuple(
            compare_timeline_step(timeline, ordinal).correspondence
            for ordinal in range(len(timeline.steps))
        )

        composed = compose_timeline_correspondences(timeline, correspondences, 0, 2)

        composed.validate(timeline.state(0), timeline.state(2))
        self.assertEqual((composed.from_ordinal, composed.to_ordinal), (0, 2))
        self.assertTrue(
            any(
                link.relation == "changed"
                and link.confidence == "approximate"
                and "same (exact" in (link.evidence or "")
                and "simplifiedInto (approximate" in (link.evidence or "")
                for link in composed.links
            )
        )


class CorrespondenceCompositionTests(unittest.TestCase):
    def test_composition_preserves_a_split_across_the_intermediate_state(self) -> None:
        from_state = _function_state(0, "source")
        intermediate_state = _function_state(1, "left", "right")
        to_state = _function_state(2, "left-final", "right-final")
        earlier = _correspondence(
            0,
            1,
            Link(("source",), ("left", "right"), "split", "approximate", "split"),
        )
        later = _correspondence(
            1,
            2,
            Link(("left",), ("left-final",), "same", "exact", "left retained"),
            Link(("right",), ("right-final",), "same", "exact", "right retained"),
        )

        composed = compose_correspondences(
            earlier, later, from_state, intermediate_state, to_state
        )

        composed.validate(from_state, to_state)
        self.assertEqual(len(composed.links), 1)
        self.assertEqual(composed.links[0].from_node_ids, ("source",))
        self.assertEqual(composed.links[0].to_node_ids, ("left-final", "right-final"))
        self.assertEqual(composed.links[0].relation, "split")
        self.assertEqual(composed.links[0].confidence, "approximate")

    def test_composition_preserves_a_many_to_one_merge(self) -> None:
        from_state = _function_state(0, "left", "right")
        intermediate_state = _function_state(1, "left-mid", "right-mid")
        to_state = _function_state(2, "merged")
        earlier = _correspondence(
            0,
            1,
            Link(("left",), ("left-mid",), "same", "exact", "left retained"),
            Link(("right",), ("right-mid",), "same", "exact", "right retained"),
        )
        later = _correspondence(
            1,
            2,
            Link(
                ("left-mid", "right-mid"),
                ("merged",),
                "merged",
                "approximate",
                "merged functions",
            ),
        )

        composed = compose_correspondences(
            earlier, later, from_state, intermediate_state, to_state
        )

        composed.validate(from_state, to_state)
        self.assertEqual(len(composed.links), 1)
        self.assertEqual(composed.links[0].from_node_ids, ("left", "right"))
        self.assertEqual(composed.links[0].to_node_ids, ("merged",))
        self.assertEqual(composed.links[0].relation, "merged")
        self.assertEqual(composed.links[0].confidence, "approximate")

    def test_composition_carries_an_intermediate_addition_to_the_endpoint(self) -> None:
        from_state = _function_state(0, "retained")
        intermediate_state = _function_state(1, "retained-mid", "new-mid")
        to_state = _function_state(2, "retained-final", "new-final")
        earlier = _correspondence(
            0,
            1,
            Link(("retained",), ("retained-mid",), "same", "exact", "retained"),
            Link((), ("new-mid",), "added", "approximate", "introduced"),
        )
        later = _correspondence(
            1,
            2,
            Link(
                ("retained-mid",),
                ("retained-final",),
                "same",
                "exact",
                "retained",
            ),
            Link(("new-mid",), ("new-final",), "renamed", "exact", "renamed"),
        )

        composed = compose_correspondences(
            earlier, later, from_state, intermediate_state, to_state
        )

        composed.validate(from_state, to_state)
        addition = next(link for link in composed.links if not link.from_node_ids)
        self.assertEqual(addition.to_node_ids, ("new-final",))
        self.assertEqual(addition.relation, "added")
        self.assertEqual(addition.confidence, "approximate")
        self.assertIn("added (approximate", addition.evidence or "")
        self.assertIn("renamed (exact", addition.evidence or "")

    def test_composition_carries_an_intermediate_removal_to_the_endpoint(self) -> None:
        from_state = _function_state(0, "retained", "doomed")
        intermediate_state = _function_state(1, "retained-mid", "doomed-mid")
        to_state = _function_state(2, "retained-final")
        earlier = _correspondence(
            0,
            1,
            Link(("retained",), ("retained-mid",), "same", "exact", "retained"),
            Link(("doomed",), ("doomed-mid",), "renamed", "approximate", "renamed"),
        )
        later = _correspondence(
            1,
            2,
            Link(
                ("retained-mid",),
                ("retained-final",),
                "same",
                "exact",
                "retained",
            ),
            Link(("doomed-mid",), (), "removed", "exact", "removed"),
        )

        composed = compose_correspondences(
            earlier, later, from_state, intermediate_state, to_state
        )

        composed.validate(from_state, to_state)
        removal = next(link for link in composed.links if not link.to_node_ids)
        self.assertEqual(removal.from_node_ids, ("doomed",))
        self.assertEqual(removal.relation, "removed")
        self.assertEqual(removal.confidence, "approximate")
        self.assertIn("renamed (approximate", removal.evidence or "")
        self.assertIn("removed (exact", removal.evidence or "")


def _correspondence(
    from_ordinal: int, to_ordinal: int, *links: Link
) -> Correspondence:
    return Correspondence(
        from_ordinal=from_ordinal,
        to_ordinal=to_ordinal,
        covered_kinds=("Function",),
        links=links,
    )


def _function_state(ordinal: int, *function_ids: str) -> StateGraph:
    nodes = [Node("module", "Module", "module")]
    edges: list[Edge] = []
    for order, function_id in enumerate(function_ids):
        block_id = f"{function_id}/entry"
        instruction_id = f"{block_id}/ret"
        nodes.extend(
            (
                Node(function_id, "Function", function_id),
                Node(block_id, "BasicBlock", "entry", {"label": "entry"}),
                Node(
                    instruction_id,
                    "Instruction",
                    "ret void",
                    {"opcode": "ret", "is_terminator": True, "successors": ()},
                ),
            )
        )
        edges.extend(
            (
                Edge("module", function_id, "contains", order=order),
                Edge(function_id, block_id, "contains", order=0),
                Edge(block_id, instruction_id, "contains", order=0),
            )
        )
    state = StateGraph(
        ordinal=ordinal,
        state_id=f"state-{ordinal}",
        nodes=tuple(nodes),
        edges=tuple(edges),
    )
    state.validate()
    return state


if __name__ == "__main__":
    unittest.main()
