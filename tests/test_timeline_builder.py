"""The pure timeline builder shared by curated examples and user programs."""

import unittest
from pathlib import Path
from unittest.mock import patch

from src.backend.ingest import StateArtefacts, build_timeline
from src.backend.model import serialise_json, serialise_timeline
from src.backend.toolchain import curated


def _curated_artefacts(example: str) -> dict[str, StateArtefacts]:
    """Read one curated example's per-state compiler artefacts as the texts the builder takes."""

    return {
        state.state_id: StateArtefacts(
            ir=curated.read_ir(example, state.state_id),
            command=curated.origin_command(example, state.state_id),
            pass_remarks=(curated.step_remarks_path(example, state.state_id).read_text(encoding="utf-8")
                          if state.pass_pipeline is not None else None),
        )
        for state in curated.PASS_STATES
    }


def _opt_record(example: str) -> str:
    return curated.opt_record_path(example).read_text(encoding="utf-8")


class TimelineBuilderTests(unittest.TestCase):
    maxDiff = None

    def test_texts_in_memory_build_each_committed_curated_timeline_record(self) -> None:
        for example in curated.list_examples():
            with self.subTest(example=example):
                artefacts = _curated_artefacts(example)
                opt_record = _opt_record(example)
                committed = curated.model_timeline_path(example).read_text(encoding="utf-8")
                no_files = OSError("the builder must not read files")
                with patch.object(Path, "read_text", side_effect=no_files), \
                        patch.object(Path, "open", side_effect=no_files):
                    timeline = build_timeline(example, artefacts, opt_record)

                self.assertEqual(serialise_json(serialise_timeline(timeline)), committed)

    def test_artefacts_must_cover_exactly_the_curated_pass_sequence(self) -> None:
        artefacts = _curated_artefacts("score")
        missing = {key: value for key, value in artefacts.items() if key != "licm"}
        with self.assertRaisesRegex(ValueError, "licm"):
            build_timeline("score", missing, _opt_record("score"))
        with self.assertRaisesRegex(ValueError, "O2"):
            build_timeline("score", {**artefacts, "O2": artefacts["O3"]}, _opt_record("score"))


if __name__ == "__main__":
    unittest.main()
