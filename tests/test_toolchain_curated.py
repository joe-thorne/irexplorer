import unittest

from src.backend.toolchain import curated


class CuratedToolchainTests(unittest.TestCase):
    def test_examples_are_available(self) -> None:
        self.assertEqual(
            curated.list_examples(),
            ("binary_search", "quick_sort", "score"),
        )

    def test_standard_state_sequence_is_fixed(self) -> None:
        self.assertEqual(
            [state.state_id for state in curated.list_states()],
            [
                "O0",
                "mem2reg",
                "instcombine",
                "simplifycfg",
                "gvn",
                "cleanup",
                "loop_canonical",
                "loop_rotate",
                "licm",
                "indvars",
                "loop_cleanup",
                "vectorize",
                "final_cleanup",
                "O3",
            ],
        )

    def test_reads_generated_ir_state(self) -> None:
        ir = curated.read_ir("score", "O0")

        self.assertIn('target triple = "x86_64-unknown-linux-gnu"', ir)
        self.assertIn("!dbg", ir)
        self.assertIn("@score", ir)

    def test_resolves_generated_remarks_and_yaml(self) -> None:
        for example in curated.list_examples():
            self.assertGreater(curated.remarks_path(example).stat().st_size, 0)
            self.assertGreater(curated.opt_record_path(example).stat().st_size, 0)

    def test_unknown_state_is_controlled_failure(self) -> None:
        with self.assertRaises(curated.ToolchainError):
            curated.ir_path("score", "missing")

    def test_unknown_example_is_controlled_failure(self) -> None:
        with self.assertRaises(curated.ToolchainError):
            curated.ir_path("missing", "O0")


if __name__ == "__main__":
    unittest.main()
