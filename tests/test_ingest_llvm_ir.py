import unittest

from src.backend.ingest import IngestError, parse_ir_state
from src.backend.toolchain import curated


class LlvmIrIngestionTests(unittest.TestCase):
    def test_score_o0_ingests_containment_cfg_and_source_maps(self) -> None:
        graph = parse_ir_state(
            curated.read_ir("score", "O0"),
            ordinal=0,
            state_id="O0",
        )

        kinds = _kind_counts(graph)
        self.assertEqual(kinds["Module"], 1)
        self.assertEqual(kinds["Function"], 1)
        self.assertEqual(kinds["BasicBlock"], 4)
        self.assertEqual(kinds["Instruction"], 41)
        self.assertEqual(graph.target_triple, "x86_64-unknown-linux-gnu")

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


def _kind_counts(graph) -> dict[str, int]:
    counts: dict[str, int] = {}
    for node in graph.nodes:
        counts[node.kind] = counts.get(node.kind, 0) + 1
    return counts


if __name__ == "__main__":
    unittest.main()
