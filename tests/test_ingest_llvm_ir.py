import unittest

from src.backend.ingest import IngestError, parse_ir_state
from src.backend.model import SourceLocation
from src.backend.toolchain import curated


class LlvmIrIngestionTests(unittest.TestCase):
    def test_score_o0_ingests_containment_cfg_and_source_maps(self) -> None:
        graph = parse_ir_state(
            curated.read_ir("score", "O0"),
            ordinal=0,
            state_id="O0",
            origin_command=curated.origin_command("score", "O0"),
        )

        kinds = _kind_counts(graph)
        self.assertEqual(kinds["Module"], 1)
        self.assertEqual(kinds["Function"], 1)
        self.assertEqual(kinds["BasicBlock"], 4)
        self.assertEqual(kinds["Instruction"], 41)
        self.assertEqual(graph.target_triple, "x86_64-unknown-linux-gnu")
        self.assertIsNotNone(graph.origin_command)
        self.assertIn("score_O0.ll", graph.origin_command)

        cfg_edges = [
            edge
            for edge in graph.edges
            if edge.relation == "controlFlow"
        ]
        self.assertEqual(len(cfg_edges), 4)
        self.assertIn("true", {edge.label for edge in cfg_edges})
        self.assertIn("false", {edge.label for edge in cfg_edges})
        self.assertIn("unconditional", {edge.label for edge in cfg_edges})

        source_edges = [edge for edge in graph.edges if edge.relation == "sourceMap"]
        self.assertGreater(len(source_edges), 0)

        value_flow_edges = [edge for edge in graph.edges if edge.relation == "valueFlow"]
        self.assertGreater(len(value_flow_edges), 0)
        for edge in value_flow_edges:
            self.assertEqual(graph.by_id[edge.from_id].kind, "Instruction")
            self.assertEqual(graph.by_id[edge.to_id].kind, "Instruction")
            self.assertIn(edge, graph.value_flow_successors[edge.from_id])
            self.assertIn(edge, graph.value_flow_predecessors[edge.to_id])

    def test_all_curated_states_validate(self) -> None:
        for example in curated.list_examples():
            for ordinal, state in enumerate(curated.list_states()):
                with self.subTest(example=example, state=state.state_id):
                    graph = parse_ir_state(
                        curated.read_ir(example, state.state_id),
                        ordinal=ordinal,
                        state_id=state.state_id,
                    )
                    graph.validate()

    def test_debug_location_without_column_defaults_to_zero_and_maps_source(self) -> None:
        graph = parse_ir_state(
            curated.read_ir("quick_sort", "mem2reg"),
            ordinal=1,
            state_id="mem2reg",
        )
        instruction = next(
            node
            for node in graph.nodes
            if node.kind == "Instruction"
            and node.attributes["text"].startswith("%j.0 = phi i32")
        )

        self.assertEqual(
            instruction.attributes["source"],
            SourceLocation(
                file="/workspace/examples/curated/quick_sort.c",
                line=7,
                column=0,
            ),
        )
        self.assertTrue(
            any(
                edge.from_id == instruction.stable_id and edge.relation == "sourceMap"
                for edge in graph.edges
            )
        )

    def test_optimisation_record_remarks_attach_by_debug_location(self) -> None:
        graph = parse_ir_state(
            curated.read_ir("binary_search", "O3"),
            ordinal=13,
            state_id="O3",
            opt_yaml_text=curated.opt_record_path("binary_search").read_text(encoding="utf-8"),
        )

        attached = [
            node
            for node in graph.nodes
            if node.kind == "Instruction" and node.attributes["remarks"]
        ]
        self.assertGreater(len(attached), 0)
        self.assertGreater(len(graph.remarks), 0)

    def test_malformed_ir_is_controlled_failure(self) -> None:
        malformed = """source_filename = "bad.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @bad() {
entry:
  %x = add i32 1, 2
}
"""

        with self.assertRaises(IngestError) as context:
            parse_ir_state(malformed, ordinal=0, state_id="bad")

        self.assertIn("lacks terminator", str(context.exception))

    def test_unknown_cfg_successor_is_controlled_failure(self) -> None:
        malformed = """source_filename = "bad.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @bad() {
entry:
  br label %missing
}
"""

        with self.assertRaises(IngestError) as context:
            parse_ir_state(malformed, ordinal=0, state_id="bad")

        self.assertIn(
            "terminator in bad.entry targets unknown block missing",
            str(context.exception),
        )

    def test_multiline_switch_ingests_cases_and_phi_agreement(self) -> None:
        graph = parse_ir_state(
            """source_filename = "switch.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @choose(i32 %value) {
entry:
  switch i32 %value, label %default [
    i32 1, label %one
    i32 2, label %two ; ] in a comment must not end the switch
    i32 3, label %three
  ]
default:
  br label %join
one:
  br label %join
two:
  br label %join
three:
  br label %join
join:
  %result = phi i32 [ 0, %default ], [ 1, %one ], [ 2, %two ], [ 3, %three ]
  ret i32 %result
}
""",
            ordinal=0,
            state_id="switch",
        )

        entry = next(
            node
            for node in graph.nodes
            if node.kind == "BasicBlock" and node.attributes["label"] == "entry"
        )
        terminator = graph.by_id[graph.contains_children[entry.stable_id][-1]]
        self.assertEqual(terminator.attributes["opcode"], "switch")
        self.assertTrue(terminator.attributes["is_terminator"])
        self.assertEqual(
            tuple(
                (graph.by_id[edge.to_id].attributes["label"], edge.label)
                for edge in graph.cfg_successors[entry.stable_id]
            ),
            (
                ("default", "default"),
                ("one", "switch-case(1)"),
                ("two", "switch-case(2)"),
                ("three", "switch-case(3)"),
            ),
        )
        graph.validate()

    def test_unterminated_multiline_switch_is_controlled_failure(self) -> None:
        malformed = """source_filename = "bad.c"
target triple = "x86_64-unknown-linux-gnu"

define i32 @bad(i32 %value) {
entry:
  switch i32 %value, label %default [
    i32 1, label %one
}
"""

        with self.assertRaises(IngestError) as context:
            parse_ir_state(malformed, ordinal=0, state_id="bad")

        self.assertIn("unterminated switch instruction", str(context.exception))


def _kind_counts(graph) -> dict[str, int]:
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.kind] = counts.get(node.kind, 0) + 1
    return counts


if __name__ == "__main__":
    unittest.main()
