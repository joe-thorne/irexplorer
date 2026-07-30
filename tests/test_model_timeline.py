from dataclasses import replace
import unittest

from src.backend.ingest import load_curated_timeline, load_prebaked_curated_timeline
from src.backend.model import (
    ModelValidationError,
    StepOrigin,
    deserialise_json,
    deserialise_state_graph,
    deserialise_timeline,
    serialise_json,
    serialise_state_graph,
    serialise_timeline,
)


class OptimisationTimelineTests(unittest.TestCase):
    def test_endpoint_timeline_is_an_honest_recompiled_anchor(self) -> None:
        timeline = load_curated_timeline("score")

        self.assertEqual([state.state_id for state in timeline.states], ["O0", "O3"])
        self.assertEqual(len(timeline.steps), 1)
        step = timeline.steps[0]
        self.assertEqual(step.kind, "recompiled")
        self.assertEqual(step.origin.level, "-O3")
        self.assertEqual(step.origin.command, timeline.state(1).origin_command)

    def test_full_timeline_retains_every_pass_and_derived_provenance(self) -> None:
        timeline = load_curated_timeline("score", resolution="full")

        self.assertEqual(len(timeline.states), 14)
        self.assertEqual(len(timeline.steps), 13)
        self.assertEqual(timeline.steps[0].kind, "derived")
        self.assertEqual(timeline.steps[0].origin.pass_name, "mem2reg")
        self.assertEqual(timeline.steps[0].remarks, timeline.state(1).remarks)
        self.assertEqual(timeline.steps[-1].kind, "recompiled")
        self.assertEqual(timeline.steps[-1].origin.level, "-O3")
        self.assertEqual(timeline.steps[-1].remarks, timeline.state(13).remarks)

        quick_sort_timeline = load_curated_timeline("quick_sort", resolution="full")
        gvn_step = quick_sort_timeline.steps[3]
        self.assertGreater(len(gvn_step.remarks), 0)
        self.assertEqual(gvn_step.remarks, quick_sort_timeline.state(4).remarks)

    def test_timeline_round_trips_through_plain_json_and_rebuilds_indices(self) -> None:
        original = load_curated_timeline("binary_search", resolution="full")
        record = serialise_timeline(original)
        loaded = deserialise_timeline(deserialise_json(serialise_json(record)))

        self.assertEqual(loaded, original)
        graph = loaded.state(0)
        self.assertIs(graph.by_id, graph.by_id)
        self.assertIn("module", graph.by_id)
        self.assertIn("fn0", graph.contains_children["module"])
        with self.assertRaises(TypeError):
            graph.by_id["unexpected"] = graph.by_id["module"]

    def test_state_graph_round_trips_independently(self) -> None:
        state = load_curated_timeline("score").state(0)
        loaded = deserialise_state_graph(
            deserialise_json(serialise_json(serialise_state_graph(state)))
        )

        self.assertEqual(loaded, state)
        self.assertEqual(loaded.origin_command, state.origin_command)

    def test_prebaked_full_timeline_loads_without_reingestion(self) -> None:
        for example in ("score", "binary_search", "quick_sort"):
            with self.subTest(example=example):
                timeline = load_prebaked_curated_timeline(example)
                self.assertEqual(timeline.config_id, "teaching-pass-chain")
                self.assertEqual(
                    [state.state_id for state in timeline.states],
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

    def test_invalid_step_provenance_is_rejected_at_load_boundary(self) -> None:
        timeline = load_curated_timeline("score")
        invalid_step = replace(
            timeline.steps[0],
            origin=StepOrigin(command="clang -O3 wrong.c -o wrong.ll", level="-O3"),
        )
        invalid = replace(timeline, steps=(invalid_step,))

        with self.assertRaises(ModelValidationError) as context:
            invalid.validate()

        self.assertIn("provenance does not match", str(context.exception))

    def test_invalid_serialised_record_is_a_controlled_failure(self) -> None:
        record = serialise_timeline(load_curated_timeline("score"))
        record["steps"][0]["origin"]["level"] = None

        with self.assertRaises(ModelValidationError) as context:
            deserialise_timeline(record)

        self.assertIn("recompiled step requires", str(context.exception))


if __name__ == "__main__":
    unittest.main()
