"""Produce stored correspondences for curated optimisation timelines."""

from __future__ import annotations

from src.backend.analysis.compare import compare_timeline_step
from src.backend.ingest.curated import load_curated_timeline_record
from src.backend.model.correspondence import Correspondence
from src.backend.model.serialisation import (
    deserialise_correspondence,
    deserialise_json,
    serialise_correspondence,
    serialise_json,
)
from src.backend.model.timeline import OptimisationTimeline
from src.backend.toolchain import curated


def bake_curated_comparison_records() -> None:
    """Persist validated correspondences for every adjacent curated timeline pair."""

    for example in curated.list_examples():
        timeline = load_curated_timeline_record(example)
        for ordinal in range(len(timeline.steps)):
            # I12: only adjacent correspondences are persisted, never composed views.
            correspondence = compare_timeline_step(timeline, ordinal)
            path = curated.model_correspondence_path(
                example, ordinal, must_exist=False
            )
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                serialise_json(serialise_correspondence(correspondence)),
                encoding="utf-8",
            )


def load_stored_curated_correspondences(
    example: str,
    timeline: OptimisationTimeline | None = None,
) -> tuple[Correspondence, ...]:
    """Load every stored correspondence paired with a curated timeline record."""

    if timeline is None:
        timeline = load_curated_timeline_record(example)
    correspondences = tuple(
        deserialise_correspondence(
            deserialise_json(
                curated.model_correspondence_path(example, ordinal).read_text(
                    encoding="utf-8"
                )
            ),
            timeline.state(ordinal),
            timeline.state(ordinal + 1),
        )
        for ordinal in range(len(timeline.steps))
    )
    if len(correspondences) != len(timeline.steps):  # pragma: no cover - structural guard
        raise RuntimeError("stored correspondences do not cover the full timeline")
    return correspondences


def load_stored_curated_correspondence(
    example: str,
    from_ordinal: int = 0,
) -> Correspondence:
    """Load one stored correspondence for compatibility with focused callers."""

    if from_ordinal < 0:
        raise ValueError(f"timeline has no correspondence from ordinal {from_ordinal}")
    correspondences = load_stored_curated_correspondences(example)
    try:
        return correspondences[from_ordinal]
    except IndexError as exc:
        raise ValueError(f"timeline has no correspondence from ordinal {from_ordinal}") from exc
