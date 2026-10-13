"""Build an optimisation timeline from the curated pass sequence's compiler artefacts."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass

from src.backend.ingest.llvm_ir import parse_ir_state
from src.backend.model.graph import Remark
from src.backend.model.timeline import OptimisationTimeline, PassStep, StepOrigin
from src.backend.toolchain.curated import PASS_STATES, PassState


@dataclass(frozen=True)
class StateArtefacts:
    """The compiler artefacts that record one state of the curated pass sequence.

    ``remarks`` is the per-pass remark YAML for a derived state, the ``.opt.yaml``
    record for the recompiled O3 state, and ``None`` for O0.
    """

    ir: str
    command: str
    remarks: str | None = None


def build_timeline(
    timeline_id: str, artefacts: Mapping[str, StateArtefacts]
) -> OptimisationTimeline:
    """Build and validate a timeline from texts already read, keyed by state id.

    Every state in the curated pass sequence is retained, so derivation is
    claimed only for the ``opt`` steps that actually produced their target
    artefact; the final step leads to the recompiled O3 state.
    """

    expected = [state.state_id for state in PASS_STATES]
    if set(artefacts) != set(expected):
        missing = [state_id for state_id in expected if state_id not in artefacts]
        unexpected = sorted(set(artefacts) - set(expected))
        raise ValueError(
            "artefacts must cover exactly the curated pass sequence; "
            f"missing: {missing}, unexpected: {unexpected}"
        )
    states = tuple(
        parse_ir_state(
            artefacts[state.state_id].ir,
            ordinal=ordinal,
            state_id=state.state_id,
            origin_command=artefacts[state.state_id].command,
            opt_yaml_text=artefacts[state.state_id].remarks,
        )
        for ordinal, state in enumerate(PASS_STATES)
    )
    steps = tuple(
        _step_for_target(
            ordinal,
            state,
            states[ordinal].origin_command,
            states[ordinal].remarks,
        )
        for ordinal, state in enumerate(PASS_STATES[1:], start=1)
    )
    timeline = OptimisationTimeline(
        example_id=timeline_id,
        config_id="curated-pass-sequence",
        states=states,
        steps=steps,
    )
    timeline.validate()
    return timeline


def _step_for_target(
    ordinal: int,
    state: PassState,
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
