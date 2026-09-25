"""The comparison report: everything the application can say about one span.

The report takes an optimisation timeline and its stored correspondences as
values, independent of how their model records were produced.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any

from src.backend.analysis.composition import compose_timeline_correspondences
from src.backend.analysis.optimisations import explain_comparison
from src.backend.analysis.summary import StructuralClaim, summarise_correspondence
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import StateGraph
from src.backend.model.timeline import OptimisationTimeline, PassStep

SAME_STATE_CONTEXT = "Same recorded state; no cross-state change is being compared."


@dataclass(frozen=True)
class ComparisonReport:
    """What can truthfully be said about one span, read from lower to higher ordinal."""

    from_ordinal: int
    to_ordinal: int
    context: str
    states: tuple[StateGraph, ...]
    steps: tuple[PassStep, ...]
    links: tuple[Link, ...]
    claims: tuple[StructuralClaim, ...]
    optimisations: tuple[dict[str, Any], ...]


def describe_comparison(
    timeline: OptimisationTimeline,
    correspondences: Sequence[Correspondence],
    from_ordinal: int,
    to_ordinal: int,
) -> ComparisonReport:
    """Describe the span between two states in either order.

    Raises ``ValueError`` when an ordinal is outside the timeline, and
    ``ValueError`` or ``IndexError`` when the correspondences cannot be
    composed across the span.
    """

    lower, higher = sorted((from_ordinal, to_ordinal))
    states = tuple(timeline.state(ordinal) for ordinal in range(lower, higher + 1))
    if lower == higher:
        return ComparisonReport(lower, higher, SAME_STATE_CONTEXT, states, (), (), (), ())

    # The timeline is one linear chain, so a span covers exactly these steps.
    steps = timeline.steps[lower:higher]
    comparison = (
        correspondences[lower]
        if higher == lower + 1
        else compose_timeline_correspondences(timeline, correspondences, lower, higher)
    )
    # Summary remark indices address the final step in the span.
    final_step = len(steps) - 1
    summary = summarise_correspondence(
        comparison, states[0], states[-1], steps[final_step], remark_step_index=final_step
    )
    return ComparisonReport(
        from_ordinal=lower,
        to_ordinal=higher,
        context=summary.context,
        states=states,
        steps=steps,
        links=comparison.links,
        claims=summary.claims,
        optimisations=tuple(explain_comparison(timeline, correspondences, comparison)),
    )
