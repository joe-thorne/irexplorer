"""Curated artefact ingestion into executable Layer 3 timelines."""

from __future__ import annotations

import shutil

from src.backend.ingest.llvm_ir import parse_ir_state
from src.backend.model.serialisation import (
    deserialise_json,
    deserialise_timeline,
    serialise_json,
    serialise_timeline,
)
from src.backend.model.graph import Remark
from src.backend.model.timeline import OptimisationTimeline, PassStep, StepOrigin
from src.backend.toolchain import curated


def load_curated_timeline(
    example: str,
    *,
    resolution: str = "endpoints",
) -> OptimisationTimeline:
    """Load a curated example as an honest endpoint or full-pass timeline.

    ``endpoints`` is the initial MVP view: the single transition is explicitly
    marked as a recompiled ``-O3`` anchor.  ``full`` retains every generated
    pass state and therefore only claims derivation for the ``opt`` steps that
    actually produced their target artefact.
    """

    states_to_load = _states_for_resolution(resolution)
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
        for ordinal, state in enumerate(states_to_load)
    )
    steps = tuple(
        _step_for_target(
            ordinal,
            state,
            states[ordinal].origin_command,
            states[ordinal].remarks,
        )
        for ordinal, state in enumerate(states_to_load[1:], start=1)
    )
    timeline = OptimisationTimeline(
        example_id=example,
        config_id=("O0-to-O3" if resolution == "endpoints" else "teaching-pass-chain"),
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
        _write_timeline_record(load_curated_timeline(example, resolution="full"))


def load_prebaked_curated_timeline(example: str) -> OptimisationTimeline:
    """Load the validated full-pass timeline that the browser API will serve."""

    path = curated.model_timeline_path(example)
    return deserialise_timeline(deserialise_json(path.read_text(encoding="utf-8")))


def _write_timeline_record(timeline: OptimisationTimeline) -> None:
    path = curated.artefact_dir(timeline.example_id) / "model" / "timeline.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        serialise_json(serialise_timeline(timeline)),
        encoding="utf-8",
    )


def _states_for_resolution(resolution: str) -> tuple[curated.PassState, ...]:
    if resolution == "endpoints":
        return (curated.PASS_STATES[0], curated.PASS_STATES[-1])
    if resolution == "full":
        return curated.PASS_STATES
    raise ValueError(f"unknown curated timeline resolution: {resolution}")


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
