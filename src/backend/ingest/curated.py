"""Curated artefact ingestion into executable Layer 3 timelines."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from hashlib import sha256

from src.backend.ingest.llvm_ir import parse_ir_state
from src.backend.model.graph import ModelValidationError, Remark
from src.backend.model.serialisation import (
    deserialise_json,
    deserialise_timeline,
    serialise_json,
    serialise_timeline,
)
from src.backend.model.timeline import OptimisationTimeline, PassStep, StepOrigin
from src.backend.toolchain import curated

SOURCE_RECORD_FORMAT_VERSION = 1


@dataclass(frozen=True)
class SourceRecord:
    """A curated example's C source, as checked against the pinned compilations.

    ``input_verified`` records that the bake wrote this text only after it
    matched every pinned compilation's debug checksum.
    """

    file: str
    text: str
    sha256: str
    input_verified: bool


def load_curated_timeline(example: str) -> OptimisationTimeline:
    """Load a curated example's optimisation timeline from its compiler artefacts.

    Every state in the curated pass sequence is retained, so derivation is
    claimed only for the ``opt`` steps that actually produced their target
    artefact; the final step leads to the recompiled O3 state.
    """

    states = tuple(
        parse_ir_state(
            curated.read_ir(example, state.state_id),
            ordinal=ordinal,
            state_id=state.state_id,
            origin_command=curated.origin_command(example, state.state_id),
            opt_yaml_text=(
                curated.opt_record_path(example).read_text(encoding="utf-8")
                if state.state_id == "O3"
                else (
                    curated.step_remarks_path(example, state.state_id).read_text(
                        encoding="utf-8"
                    )
                    if state.pass_pipeline is not None
                    else None
                )
            ),
        )
        for ordinal, state in enumerate(curated.PASS_STATES)
    )
    steps = tuple(
        _step_for_target(
            ordinal,
            state,
            states[ordinal].origin_command,
            states[ordinal].remarks,
        )
        for ordinal, state in enumerate(curated.PASS_STATES[1:], start=1)
    )
    timeline = OptimisationTimeline(
        example_id=example,
        config_id="curated-pass-sequence",
        states=states,
        steps=steps,
    )
    timeline.validate()
    return timeline


def bake_curated_model_records() -> None:
    """Persist the full teaching-pass timelines used by the runtime."""

    for example in curated.list_examples():
        model_dir = curated.artefact_dir(example) / "model"
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
    return SourceRecord(file=record["file"], text=text, sha256=record["sha256"], input_verified=True)


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
    path = curated.artefact_dir(timeline.example_id) / "model" / "timeline.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        serialise_json(serialise_timeline(timeline)),
        encoding="utf-8",
    )


def _step_for_target(
    ordinal: int,
    state: curated.PassState,
    command: str | None,
    remarks: tuple[Remark, ...],
) -> PassStep:
    if command is None:
        raise ValueError(f"missing origin command for curated state {state.state_id}")
    if state.state_id == "O3":
        return PassStep(
            from_ordinal=ordinal - 1,
            to_ordinal=ordinal,
            kind="recompiled",
            origin=StepOrigin(command=command, level="-O3"),
            remarks=remarks,
        )
    if state.pass_pipeline is None:
        raise ValueError(f"derived curated state has no pass pipeline: {state.state_id}")
    return PassStep(
        from_ordinal=ordinal - 1,
        to_ordinal=ordinal,
        kind="derived",
        origin=StepOrigin(command=command, pass_name=state.pass_pipeline),
        remarks=remarks,
    )
