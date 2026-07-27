"""Immutable optimisation timelines and transition provenance."""

from __future__ import annotations

from dataclasses import dataclass, field
from types import MappingProxyType
from typing import Literal, Mapping

from src.backend.model.graph import ModelValidationError, StateGraph


StepKind = Literal["derived", "recompiled"]


@dataclass(frozen=True)
class StepOrigin:
    """Auditable provenance for one transition into an optimisation state."""

    command: str
    pass_name: str | None = None
    level: str | None = None


@dataclass(frozen=True)
class PassStep:
    """Metadata for one adjacent transition; comparisons live in Layer 4."""

    from_ordinal: int
    to_ordinal: int
    kind: StepKind
    origin: StepOrigin


@dataclass(frozen=True)
class OptimisationTimeline:
    """An ordered, immutable sequence of independently loadable states."""

    example_id: str
    config_id: str
    states: tuple[StateGraph, ...]
    steps: tuple[PassStep, ...]
    state_by_ordinal: Mapping[int, StateGraph] = field(
        init=False, repr=False, compare=False
    )

    def __post_init__(self) -> None:
        object.__setattr__(
            self,
            "state_by_ordinal",
            MappingProxyType({state.ordinal: state for state in self.states}),
        )

    def validate(self) -> None:
        validate_timeline(self)

    def state(self, ordinal: int) -> StateGraph:
        """Return a state by its timeline-scoped ordinal."""

        try:
            return self.state_by_ordinal[ordinal]
        except KeyError as exc:
            raise ModelValidationError(f"unknown state ordinal: {ordinal}") from exc


def validate_timeline(timeline: OptimisationTimeline) -> None:
    """Validate timeline ordering, immutable states, and transition honesty."""

    if not timeline.example_id:
        raise ModelValidationError("timeline example_id must not be empty")
    if not timeline.config_id:
        raise ModelValidationError("timeline config_id must not be empty")
    if not timeline.states:
        raise ModelValidationError("timeline must contain at least one state")

    expected_ordinals = tuple(range(len(timeline.states)))
    actual_ordinals = tuple(state.ordinal for state in timeline.states)
    if actual_ordinals != expected_ordinals:
        raise ModelValidationError(
            f"state ordinals must be contiguous from zero: {actual_ordinals}"
        )
    if len(timeline.state_by_ordinal) != len(timeline.states):
        raise ModelValidationError("timeline contains duplicate state ordinals")

    for state in timeline.states:
        state.validate()

    if len(timeline.steps) != len(timeline.states) - 1:
        raise ModelValidationError("timeline must contain one step per adjacent state pair")

    for ordinal, step in enumerate(timeline.steps):
        if (step.from_ordinal, step.to_ordinal) != (ordinal, ordinal + 1):
            raise ModelValidationError(
                "steps must join adjacent states in timeline order: "
                f"expected {ordinal}->{ordinal + 1}, got "
                f"{step.from_ordinal}->{step.to_ordinal}"
            )
        if step.kind not in {"derived", "recompiled"}:
            raise ModelValidationError(f"unknown pass step kind: {step.kind}")
        if not step.origin.command:
            raise ModelValidationError("pass step origin command must not be empty")

        target = timeline.state(step.to_ordinal)
        if target.origin_command != step.origin.command:
            raise ModelValidationError(
                f"step provenance does not match target state {target.state_id}"
            )
        if step.kind == "derived" and not step.origin.pass_name:
            raise ModelValidationError("derived step requires an origin pass_name")
        if step.kind == "recompiled" and not step.origin.level:
            raise ModelValidationError("recompiled step requires an origin level")
