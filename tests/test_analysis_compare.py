import unittest

from src.backend.analysis import (
    compare_states,
    compare_timeline_step,
    compose_correspondences,
    compose_timeline_correspondences,
    is_identity_correspondence,
    load_prebaked_curated_correspondence,
    load_prebaked_curated_correspondences,
)
from src.backend.analysis.compare import (
    _function_for_node,
    _instruction_operand_shape_is_compatible,
    _instruction_relation,
)
from src.backend.analysis.summary import summarise_correspondence
from src.backend.ingest import (
    load_curated_timeline,
    load_prebaked_curated_timeline,
    parse_ir_state,
)
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
from src.backend.toolchain import curated


class EndpointComparisonTests(unittest.TestCase):
    def test_adjacent_comparison_returns_only_the_stored_correspondence(self) -> None:
        timeline = load_curated_timeline("score")
        correspondence = compare_timeline_step(timeline, 0)
        self.assertIs(type(correspondence), Correspondence)
        self.assertEqual(correspondence, compare_states(timeline.state(0), timeline.state(1)))

    def test_hybrid_matcher_validates_all_curated_pass_pairs(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_curated_timeline(example)
                for ordinal in range(len(timeline.steps)):
                    correspondence = compare_timeline_step(timeline, ordinal)
                    correspondence.validate(
                        timeline.state(ordinal), timeline.state(ordinal + 1)
                    )

    def test_hybrid_matcher_uses_eager_value_flow_across_early_passes(self) -> None:
        timeline = load_curated_timeline("score")
        for ordinal in range(3):
            with self.subTest(pass_name=timeline.steps[ordinal].origin.pass_name):
                correspondence = compare_timeline_step(timeline, ordinal)
                correspondence.validate(
                    timeline.state(ordinal), timeline.state(ordinal + 1)
                )
                matched_instructions = [
                    link
                    for link in correspondence.links
                    if link.from_node_ids
                    and link.to_node_ids
                    and timeline.state(ordinal).by_id[link.from_node_ids[0]].kind
                    == "Instruction"
                ]
                self.assertTrue(matched_instructions)

        mem2reg = compare_timeline_step(timeline, 0)
        exact_blocks = [
            link
            for link in mem2reg.links
            if link.relation == "same"
            and link.confidence == "exact"
            and timeline.state(0).by_id[link.from_node_ids[0]].kind == "BasicBlock"
        ]
        self.assertEqual(len(exact_blocks), 4)

        instcombine = compare_timeline_step(timeline, 1)
        self.assertTrue(
            any(
                link.relation == "simplifiedInto"
                and link.confidence == "approximate"
                for link in instcombine.links
            )
        )

    def test_instruction_relation_describes_paired_text_not_fallback_tier(self) -> None:
        """Fallback evidence must not make unchanged IR look renamed or moved."""
        score = load_curated_timeline("score")
        mem2reg = compare_timeline_step(score, 0)
        unchanged_link = next(
            link
            for link in mem2reg.links
            if link.from_node_ids == ("fn0/bb0/i18",)
        )
        self.assertEqual((unchanged_link.relation, unchanged_link.confidence), ("same", "exact"))

        rewritten_link = next(
            link
            for link in mem2reg.links
            if link.from_node_ids == ("fn0/bb0/i21",)
        )
        self.assertEqual((rewritten_link.relation, rewritten_link.confidence), ("changed", "approximate"))

        quick_sort = load_curated_timeline("quick_sort")
        indvars = compare_timeline_step(quick_sort, 8)
        phi_link = next(
            link
            for link in indvars.links
            if link.from_node_ids == ("fn1/bb2/i0",)
        )
        self.assertEqual((phi_link.relation, phi_link.confidence), ("changed", "approximate"))

        self.assertEqual(
            _instruction_relation(
                Node("before", "Instruction", "", {"text": "%old = add i32 %left, %right"}),
                Node("after", "Instruction", "", {"text": "%new = add i32 %left, %right"}),
            ),
            "renamed",
        )

    def test_unresolved_candidates_are_explicit_none_links(self) -> None:
        timeline = load_curated_timeline("binary_search")
        correspondence = compare_timeline_step(timeline, 2)
        unresolved = [link for link in correspondence.links if link.confidence == "none"]

        self.assertTrue(unresolved)
        self.assertTrue(
            all(link.relation in {"added", "removed"} for link in unresolved)
        )
        self.assertTrue(
            all("inspected" in (link.evidence or "") for link in unresolved)
        )

    def test_exact_instruction_and_block_additions_and_removals_have_paired_functions(self) -> None:
        """Exact local-node claims require their containing function in both states."""
        violations = []
        for example in ("score", "binary_search", "quick_sort"):
            timeline = load_curated_timeline(example)
            for ordinal in range(len(timeline.steps)):
                from_state = timeline.state(ordinal)
                to_state = timeline.state(ordinal + 1)
                from_function_names = {
                    node.display_name for node in from_state.nodes if node.kind == "Function"
                }
                to_function_names = {
                    node.display_name for node in to_state.nodes if node.kind == "Function"
                }
                for link in compare_timeline_step(timeline, ordinal).links:
                    if link.confidence != "exact" or link.relation not in {"removed", "added"}:
                        continue
                    state, paired_function_names, node_ids = (
                        (from_state, to_function_names, link.from_node_ids)
                        if link.relation == "removed"
                        else (to_state, from_function_names, link.to_node_ids)
                    )
                    for node_id in node_ids:
                        node = state.by_id[node_id]
                        if node.kind not in {"Instruction", "BasicBlock"}:
                            continue
                        function = state.by_id[_function_for_node(state, node)]
                        if function.display_name not in paired_function_names:
                            violations.append(
                                f"{example} {ordinal}-{ordinal + 1}: {link.relation} "
                                f"{node.kind} {node_id} in vanished function {function.display_name}"
                            )
        self.assertFalse(violations, "\n".join(violations))

    def test_quick_sort_vanished_partition_nodes_are_unresolved(self) -> None:
        timeline = load_curated_timeline("quick_sort")
        from_state = timeline.state(12)
        correspondence = compare_timeline_step(timeline, 12)
        partition = next(
            node for node in from_state.nodes if node.kind == "Function" and node.display_name == "partition"
        )
        partition_removed_links = [
            link
            for link in correspondence.links
            if link.relation == "removed"
            and link.from_node_ids
            and from_state.by_id[link.from_node_ids[0]].kind in {"Instruction", "BasicBlock"}
            and _function_for_node(from_state, from_state.by_id[link.from_node_ids[0]])
            == partition.stable_id
        ]

        self.assertTrue(partition_removed_links)
        self.assertTrue(all(link.confidence == "none" for link in partition_removed_links))
        function_link = next(
            link for link in correspondence.links if link.from_node_ids == (partition.stable_id,)
        )
        self.assertEqual(
            (function_link.relation, function_link.confidence), ("removed", "exact")
        )

    def test_recompiled_renamed_block_branch_links_are_plausible(self) -> None:
        """A renamed paired block is qualified evidence, not a definite deletion."""
        timeline = load_curated_timeline("binary_search")
        from_state = timeline.state(12)
        to_state = timeline.state(13)
        correspondence = compare_timeline_step(timeline, 12)

        self.assertEqual(timeline.steps[12].kind, "recompiled")
        branch_links = {
            link.relation: link
            for link in correspondence.links
            if (
                link.from_node_ids
                and str(from_state.by_id[link.from_node_ids[0]].attributes.get("text", "")).startswith(
                    "br i1 %cmp6, label %return, label %if.end8"
                )
            )
            or (
                link.to_node_ids
                and str(to_state.by_id[link.to_node_ids[0]].attributes.get("text", "")).startswith(
                    "br i1 %cmp6, label %cleanup, label %if.end8"
                )
            )
        }

        self.assertEqual(set(branch_links), {"removed", "added"})
        self.assertTrue(all(link.confidence != "exact" for link in branch_links.values()))
        self.assertTrue(all(link.confidence == "plausible" for link in branch_links.values()))

    def test_operand_aware_plausibility_reduces_curated_none_links(self) -> None:
        expected_none_counts = {
            ("binary_search", 6): 11,
            ("quick_sort", 6): 8,
            ("binary_search", 12): 24,
            ("quick_sort", 12): 58,
        }
        for (example, ordinal), expected in expected_none_counts.items():
            with self.subTest(example=example, ordinal=ordinal):
                timeline = load_curated_timeline(example)
                correspondence = compare_timeline_step(timeline, ordinal)
                self.assertEqual(
                    sum(link.confidence == "none" for link in correspondence.links), expected
                )

    def test_phi_with_vanished_incoming_block_is_not_a_plausible_target(self) -> None:
        """Phi incoming blocks must exist in the paired function."""
        source = parse_ir_state(
            """define i32 @f(i1 %condition, i32 %value) {
entry:
  br i1 %condition, label %incoming, label %join
incoming:
  br label %join
join:
  %result = phi i32 [ %value, %incoming ], [ 0, %entry ]
  ret i32 %result
}
""",
            ordinal=0,
            state_id="source",
        )
        candidate = parse_ir_state(
            """define i32 @f(i1 %condition, i32 %value) {
entry:
  br i1 %condition, label %replacement, label %join
replacement:
  br label %join
join:
  %result = phi i32 [ %value, %replacement ], [ 0, %entry ]
  ret i32 %result
}
""",
            ordinal=1,
            state_id="candidate",
        )
        phi = next(node for node in source.nodes if node.attributes.get("opcode") == "phi")
        candidate_phi = next(
            node for node in candidate.nodes if node.attributes.get("opcode") == "phi"
        )

        self.assertFalse(
            _instruction_operand_shape_is_compatible(
                phi, candidate_phi, source, candidate, "fn0"
            )
        )

    def test_score_anchor_comparison_is_coverage_complete_and_honest(self) -> None:
        timeline = load_curated_timeline("score")
        correspondence = compare_timeline_step(timeline, len(timeline.steps) - 1)
        from_state = timeline.state(12)
        to_state = timeline.state(13)
        summary = summarise_correspondence(correspondence, from_state, to_state, timeline.steps[-1])

        correspondence.validate(from_state, to_state)
        self.assertIn("not the effect of one optimisation pass", summary.context)
        self.assertEqual(
            len(correspondence.links_from),
            sum(1 for node in from_state.nodes if node.kind != "Module"),
        )
        self.assertEqual(
            len(correspondence.links_to),
            sum(1 for node in to_state.nodes if node.kind != "Module"),
        )

        for item in summary.items:
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
        self.assertIn(
            "CFG unchanged across the recorded basic-block correspondences.",
            {item.text for item in summary.items},
        )

    def test_recompiled_step_correspondences_validate_for_all_curated_examples(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_curated_timeline(example)
                last = len(timeline.steps) - 1
                correspondence = compare_timeline_step(timeline, last)
                correspondence.validate(timeline.state(last), timeline.state(last + 1))

    def test_correspondence_round_trips_and_rejects_invalid_endpoint_ids(self) -> None:
        timeline = load_curated_timeline("score")
        last = len(timeline.steps) - 1
        before, after = timeline.state(last), timeline.state(last + 1)
        correspondence = compare_timeline_step(timeline, last)
        record = serialise_correspondence(correspondence)
        loaded = deserialise_correspondence(
            deserialise_json(serialise_json(record)), before, after
        )
        self.assertEqual(loaded, correspondence)

        record["links"][0]["fromNodeIds"] = ["missing"]
        with self.assertRaises(ModelValidationError):
            deserialise_correspondence(record, before, after)

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

    def test_prebaked_overlays_match_the_current_adjacent_matcher(self) -> None:
        """Require an intentional re-bake whenever matcher behaviour changes."""
        for example in ("score", "binary_search", "quick_sort"):
            timeline = load_prebaked_curated_timeline(example)
            for ordinal in range(len(timeline.steps)):
                with self.subTest(example=example, ordinal=ordinal):
                    baked = deserialise_json(
                        curated.model_correspondence_path(example, ordinal).read_text(
                            encoding="utf-8"
                        )
                    )
                    fresh = serialise_correspondence(
                        compare_timeline_step(timeline, ordinal)
                    )
                    self.assertEqual(fresh, baked)

    def test_noop_steps_are_identity_correspondences(self) -> None:
        timeline = load_prebaked_curated_timeline("score")
        correspondences = load_prebaked_curated_correspondences("score", timeline)

        self.assertTrue(is_identity_correspondence(correspondences[3]))
        self.assertFalse(is_identity_correspondence(correspondences[0]))

        summary = _step_summary(timeline, 3)
        self.assertIn("retained as a no-op", summary.items[0].text)
        self.assertEqual(
            summary.items[0].link_indices,
            tuple(range(len(correspondences[3].links))),
        )

    def test_pass_summary_cites_its_own_captured_remarks(self) -> None:
        timeline = load_curated_timeline("quick_sort")
        summary = _step_summary(timeline, 3)

        remark_item = next(item for item in summary.items if item.remark_indices)
        self.assertEqual(remark_item.remark_indices, tuple(range(len(timeline.steps[3].remarks))))
        self.assertIn("compiler remarks were captured for this step", remark_item.text)

    def test_cfg_summary_reports_relabelled_branch_edges(self) -> None:
        timeline = load_curated_timeline("quick_sort")
        correspondence = compare_timeline_step(timeline, 1)
        summary_text = " ".join(item.text for item in _step_summary(timeline, 1).items)

        self.assertNotIn("CFG unchanged", summary_text)
        self.assertIn(
            "CFG edges changed: relabelled for.body → if.then [true → false], "
            "for.body → if.end [false → true].",
            summary_text,
        )
        changed_block = next(
            link
            for link in correspondence.links
            if link.from_node_ids == ("fn1/bb2",)
        )
        self.assertEqual((changed_block.relation, changed_block.confidence), ("changed", "approximate"))

    def test_cfg_summary_reports_named_added_and_removed_edges(self) -> None:
        timeline = load_curated_timeline("binary_search")
        summary_text = " ".join(item.text for item in _step_summary(timeline, 6).items)

        self.assertIn("CFG edges changed: removed entry → while.cond [unconditional]", summary_text)
        self.assertIn("added entry → while.body.lr.ph [true]", summary_text)

    def test_composed_view_coarsens_relation_and_degrades_confidence(self) -> None:
        timeline = load_curated_timeline("binary_search")
        correspondences = tuple(
            compare_timeline_step(timeline, ordinal)
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


def _step_summary(timeline, ordinal):
    """Summarise one freshly compared adjacent step with its own pass metadata."""
    return summarise_correspondence(
        compare_timeline_step(timeline, ordinal),
        timeline.state(ordinal),
        timeline.state(ordinal + 1),
        timeline.steps[ordinal],
    )


class CorrespondenceCompositionTests(unittest.TestCase):
    def test_plausible_confidence_validates_round_trips_composes_and_summarises(self) -> None:
        from_state = _function_state(0, "source")
        intermediate_state = _function_state(1, "middle")
        to_state = _function_state(2, "target")
        earlier = _correspondence(
            0,
            1,
            Link(("source",), ("middle",), "same", "plausible", "qualified match"),
        )
        later = _correspondence(
            1,
            2,
            Link(("middle",), ("target",), "same", "approximate", "source-backed match"),
        )

        earlier.validate(from_state, intermediate_state)
        record = serialise_correspondence(earlier)
        self.assertEqual(record["links"][0]["confidence"], "plausible")
        self.assertEqual(
            deserialise_correspondence(record, from_state, intermediate_state), earlier
        )
        composed = compose_correspondences(
            earlier, later, from_state, intermediate_state, to_state
        )
        self.assertEqual(composed.links[0].confidence, "plausible")

        summary_from = _function_state(0, "removed")
        summary_to = _function_state(1, "added")
        summary_correspondence = Correspondence(
            from_ordinal=0,
            to_ordinal=1,
            covered_kinds=("BasicBlock",),
            links=(
                Link(("removed/entry",), (), "removed", "plausible", "qualified removal"),
                Link((), ("added/entry",), "added", "exact", "definite addition"),
            ),
        )
        summary_correspondence.validate(summary_from, summary_to)
        summary = summarise_correspondence(
            summary_correspondence, summary_from, summary_to, None
        )
        self.assertIn(
            "1 basic block removed with plausible but unconfirmed correspondence evidence.",
            {item.text for item in summary.items},
        )

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
