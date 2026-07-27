"""Pre-bake the MVP correspondence overlays for curated endpoint timelines."""

from __future__ import annotations

from src.backend.analysis.compare import compare_timeline_step
from src.backend.ingest.curated import load_prebaked_curated_timeline
from src.backend.model.correspondence import Correspondence
from src.backend.model.serialisation import (
    deserialise_correspondence,
    deserialise_json,
    serialise_correspondence,
    serialise_json,
)
from src.backend.toolchain import curated


def bake_curated_comparison_records() -> None:
    """Persist one validated endpoint correspondence per curated example."""

    for example in curated.list_examples():
        timeline = load_prebaked_curated_timeline(example)
        result = compare_timeline_step(timeline)
        path = curated.artefact_dir(example) / "model" / "correspondence-endpoints.json"
        path.write_text(
            serialise_json(serialise_correspondence(result.correspondence)),
            encoding="utf-8",
        )


def load_prebaked_curated_correspondence(example: str) -> Correspondence:
    """Load the validated endpoint overlay paired with a pre-baked timeline."""

    timeline = load_prebaked_curated_timeline(example)
    return deserialise_correspondence(
        deserialise_json(
            curated.model_correspondence_path(example).read_text(encoding="utf-8")
        ),
        timeline.state(0),
        timeline.state(1),
    )
