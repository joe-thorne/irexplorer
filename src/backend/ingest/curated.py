"""Curated artefact ingestion into executable Layer 3 timelines."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from hashlib import sha256

from src.backend.ingest.timeline import StateArtefacts, build_timeline
from src.backend.model.graph import ModelValidationError
from src.backend.model.serialisation import (
    deserialise_json,
    deserialise_timeline,
    serialise_json,
    serialise_timeline,
)
from src.backend.model.timeline import OptimisationTimeline
from src.backend.toolchain import curated

SOURCE_RECORD_FORMAT_VERSION = 1


@dataclass(frozen=True)
class SourceRecord:
    """A curated example's C source, checked against pinned compilations at bake time."""

    file: str
    text: str
    sha256: str


def load_curated_timeline(example: str) -> OptimisationTimeline:
    """Read a curated example's compiler artefacts, then build its timeline."""

    return build_timeline(
        example,
        {state.state_id: _state_artefacts(example, state) for state in curated.PASS_STATES},
        curated.opt_record_path(example).read_text(encoding="utf-8"),
    )


def bake_curated_model_records() -> None:
    """Persist the full teaching-pass timelines used by the runtime."""

    for example in curated.list_examples():
        model_dir = curated.model_records_dir(example)
        if model_dir.exists():
            shutil.rmtree(model_dir)
        _write_timeline_record(load_curated_timeline(example))
        _write_source_record(example)


def load_curated_timeline_record(example: str) -> OptimisationTimeline:
    """Load the validated full-pass timeline that the browser API will serve."""

    path = curated.model_timeline_path(example)
    return deserialise_timeline(deserialise_json(path.read_text(encoding="utf-8")))


def load_curated_source_record(example: str) -> SourceRecord:
    """Load the source record that was checked against every pinned compilation at bake time."""

    path = curated.model_source_path(example)
    record = deserialise_json(path.read_text(encoding="utf-8"))
    if record.get("formatVersion") != SOURCE_RECORD_FORMAT_VERSION:
        raise ModelValidationError("unsupported source record formatVersion")
    if record.get("file") != f"{example}.c":
        raise ModelValidationError(f"source record does not belong to example '{example}'")
    text = record.get("text")
    if not isinstance(text, str) or _source_digest(text) != record.get("sha256"):
        raise ModelValidationError(f"source record text failed its checksum for example '{example}'")
    return SourceRecord(file=record["file"], text=text, sha256=record["sha256"])


def _source_digest(text: str) -> str:
    return sha256(text.encode("utf-8")).hexdigest()


def _write_source_record(example: str) -> None:
    text = curated.verified_source(example)
    path = curated.model_source_path(example, must_exist=False)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        serialise_json(
            {
                "formatVersion": SOURCE_RECORD_FORMAT_VERSION,
                "file": f"{example}.c",
                "sha256": _source_digest(text),
                "text": text,
            }
        ),
        encoding="utf-8",
    )


def _write_timeline_record(timeline: OptimisationTimeline) -> None:
    path = curated.model_timeline_path(timeline.example_id, must_exist=False)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        serialise_json(serialise_timeline(timeline)),
        encoding="utf-8",
    )


def _state_artefacts(example: str, state: curated.PassState) -> StateArtefacts:
    # Only a derived state, run by one opt pass pipeline, writes per-pass remarks.
    return StateArtefacts(
        ir=curated.read_ir(example, state.state_id),
        command=curated.origin_command(example, state.state_id),
        pass_remarks=(curated.step_remarks_path(example, state.state_id).read_text(encoding="utf-8")
                      if state.pass_pipeline is not None else None),
    )
