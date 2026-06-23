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

    def test_origin_command_resolves_per_state(self) -> None:
        baseline = curated.origin_command("score", "O0")
        self.assertIn("clang", baseline)
        self.assertIn("-emit-llvm", baseline)
        self.assertTrue(baseline.endswith("score_O0.ll"))

        mem2reg = curated.origin_command("score", "mem2reg")
        self.assertIn("opt", mem2reg)
        self.assertIn("-passes=mem2reg", mem2reg)
        self.assertTrue(mem2reg.endswith("score_01_mem2reg.ll"))

        anchor = curated.origin_command("score", "O3")
        self.assertIn("-O3", anchor)
        self.assertTrue(anchor.endswith("score_O3.ll"))

    def test_origin_command_unknown_state_is_controlled_failure(self) -> None:
        with self.assertRaises(curated.ToolchainError):
            curated.origin_command("score", "missing")

    def test_unknown_state_is_controlled_failure(self) -> None:
        with self.assertRaises(curated.ToolchainError):
            curated.ir_path("score", "missing")

    def test_unknown_example_is_controlled_failure(self) -> None:
        with self.assertRaises(curated.ToolchainError):
            curated.ir_path("missing", "O0")


if __name__ == "__main__":
    unittest.main()
