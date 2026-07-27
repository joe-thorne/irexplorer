"""Deterministic first-pass comparison for adjacent optimisation states."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
import re
from typing import Iterable

from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import Node, StateGraph
from src.backend.model.timeline import OptimisationTimeline, PassStep


COMPARABLE_KINDS = ("Function", "BasicBlock", "Instruction")
_VALUE_NAME_RE = re.compile(r"%[-A-Za-z0-9_.$]+")
_DEBUG_REF_RE = re.compile(r",?\s*!dbg\s*!\d+")


@dataclass(frozen=True)
class SummaryItem:
    """One user-facing claim, traceable to the links that justify it."""

    text: str
    link_indices: tuple[int, ...]


@dataclass(frozen=True)
class ComparisonSummary:
    """Concise, evidence-backed description of a comparison."""

    context: str
    items: tuple[SummaryItem, ...]


@dataclass(frozen=True)
class ComparisonResult:
    """The correspondence and its derived summary, without state mutation."""

    correspondence: Correspondence
    summary: ComparisonSummary


def compare_timeline_step(
    timeline: OptimisationTimeline,
    from_ordinal: int = 0,
) -> ComparisonResult:
    """Compare one adjacent timeline pair using its honest transition metadata."""

    timeline.validate()
    if from_ordinal < 0 or from_ordinal >= len(timeline.steps):
        raise ValueError(f"timeline has no step from ordinal {from_ordinal}")
    step = timeline.steps[from_ordinal]
    return compare_states(
        timeline.state(step.from_ordinal),
        timeline.state(step.to_ordinal),
        step=step,
    )


def compare_states(
    from_state: StateGraph,
    to_state: StateGraph,
    *,
    step: PassStep | None = None,
) -> ComparisonResult:
    """Return a deterministic, coverage-complete overlay for adjacent states.

    This MVP matcher uses only evidence that remains auditable after an LLVM
    rewrite: unique function/block names and debug source locations. It is
    intentionally conservative; unmatched nodes become explicit additions or
    removals rather than speculative cross-state identity claims.
    """

    if to_state.ordinal != from_state.ordinal + 1:
        raise ValueError("comparison requires adjacent state ordinals")
    if step is not None and (step.from_ordinal, step.to_ordinal) != (
        from_state.ordinal,
        to_state.ordinal,
    ):
        raise ValueError("pass step does not describe the supplied state pair")

    unmatched_from = _comparable_nodes(from_state)
    unmatched_to = _comparable_nodes(to_state)
    links: list[Link] = []

    _match_unique(
        unmatched_from,
        unmatched_to,
        links,
        kind="Function",
        key=lambda node: node.display_name,
        evidence="unique function name",
    )
    _match_unique(
        unmatched_from,
        unmatched_to,
        links,
        kind="BasicBlock",
        key=lambda node: node.display_name,
        evidence="unique basic-block label",
    )
    _match_instructions_by_source(unmatched_from, unmatched_to, links)

    for node in unmatched_from.values():
        links.append(
            Link(
                from_node_ids=(node.stable_id,),
                to_node_ids=(),
                relation="removed",
                confidence="exact",
                evidence="node absent from target after conservative matching",
            )
        )
    for node in unmatched_to.values():
        links.append(
            Link(
                from_node_ids=(),
                to_node_ids=(node.stable_id,),
                relation="added",
                confidence="exact",
                evidence="node absent from source after conservative matching",
            )
        )

    correspondence = Correspondence(
        from_ordinal=from_state.ordinal,
        to_ordinal=to_state.ordinal,
        covered_kinds=COMPARABLE_KINDS,
        links=tuple(links),
    )
    correspondence.validate(from_state, to_state)
    return ComparisonResult(
        correspondence=correspondence,
        summary=_summarise(correspondence, from_state, to_state, step),
    )


def _comparable_nodes(state: StateGraph) -> dict[str, Node]:
    return {
        node.stable_id: node for node in state.nodes if node.kind in COMPARABLE_KINDS
    }


def _match_unique(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    *,
    kind: str,
    key: object,
    evidence: str,
    relation: str = "same",
    confidence: str = "exact",
) -> None:
    grouped_from = _group_unique(
        (node for node in unmatched_from.values() if node.kind == kind), key
    )
    grouped_to = _group_unique(
        (node for node in unmatched_to.values() if node.kind == kind), key
    )
    for match_key in sorted(grouped_from.keys() & grouped_to.keys(), key=str):
        from_node = grouped_from[match_key]
        to_node = grouped_to[match_key]
        links.append(
            Link(
                from_node_ids=(from_node.stable_id,),
                to_node_ids=(to_node.stable_id,),
                relation=relation,  # type: ignore[arg-type]
                confidence=confidence,  # type: ignore[arg-type]
                evidence=evidence,
            )
        )
        del unmatched_from[from_node.stable_id]
        del unmatched_to[to_node.stable_id]


def _match_instructions_by_source(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
) -> None:
    source_key = lambda node: node.attributes.get("source")
    opcode_key = lambda node: (source_key(node), node.attributes.get("opcode"))

    _match_unique(
        unmatched_from,
        unmatched_to,
        links,
        kind="Instruction",
        key=opcode_key,
        evidence="unique debug source location and opcode",
        relation="renamed",
        confidence="approximate",
    )

    # LLVM may rewrite an instruction's opcode while retaining its source
    # location (e.g., `sub` to `add`). Only unique one-to-one locations are
    # linked; every ambiguous location remains explicit add/remove evidence.
    grouped_from = _group_unique(
        (node for node in unmatched_from.values() if node.kind == "Instruction"),
        source_key,
        ignore_none=True,
    )
    grouped_to = _group_unique(
        (node for node in unmatched_to.values() if node.kind == "Instruction"),
        source_key,
        ignore_none=True,
    )
    for match_key in sorted(grouped_from.keys() & grouped_to.keys(), key=str):
        from_node = grouped_from[match_key]
        to_node = grouped_to[match_key]
        links.append(
            Link(
                from_node_ids=(from_node.stable_id,),
                to_node_ids=(to_node.stable_id,),
                relation="simplifiedInto",
                confidence="approximate",
                evidence="unique debug source location after opcode rewrite",
            )
        )
        del unmatched_from[from_node.stable_id]
        del unmatched_to[to_node.stable_id]


def _group_unique(
    nodes: Iterable[Node],
    key: object,
    *,
    ignore_none: bool = False,
) -> dict[object, Node]:
    grouped: dict[object, list[Node]] = defaultdict(list)
    for node in nodes:
        match_key = key(node)  # type: ignore[operator]
        if ignore_none and match_key is None:
            continue
        grouped[match_key].append(node)
    return {
        match_key: members[0]
        for match_key, members in grouped.items()
        if len(members) == 1
    }


def _summarise(
    correspondence: Correspondence,
    from_state: StateGraph,
    to_state: StateGraph,
    step: PassStep | None,
) -> ComparisonSummary:
    if step is not None and step.kind == "recompiled":
        context = (
            f"Recompiled {step.origin.level} anchor comparison: these are output "
            "differences, not the effect of one optimisation pass."
        )
    elif step is not None:
        context = f"Derived pass comparison: {step.origin.pass_name}."
    else:
        context = "Adjacent optimisation-state comparison."

    items: list[SummaryItem] = []
    for relation, verb in (("removed", "removed"), ("added", "added")):
        for kind in ("BasicBlock", "Instruction"):
            indices = tuple(
                index
                for index, link in enumerate(correspondence.links)
                if link.relation == relation
                and _link_kind(link, from_state, to_state) == kind
            )
            if indices:
                noun = _plural(_kind_label(kind), len(indices))
                suffix = "; control flow is simpler" if kind == "BasicBlock" and relation == "removed" else ""
                items.append(SummaryItem(f"{len(indices)} {noun} {verb}{suffix}.", indices))

    rewritten = tuple(
        index
        for index, link in enumerate(correspondence.links)
        if link.relation in {"renamed", "simplifiedInto", "promoted", "moved"}
        and _link_kind(link, from_state, to_state) == "Instruction"
    )
    if rewritten:
        items.append(
            SummaryItem(
                f"{len(rewritten)} {_plural('instruction', len(rewritten))} were rewritten with source-location evidence.",
                rewritten,
            )
        )
    if not items:
        items.append(
            SummaryItem(
                "No comparable structural changes were detected.",
                tuple(range(len(correspondence.links))),
            )
        )
    return ComparisonSummary(context=context, items=tuple(items))


def _link_kind(link: Link, from_state: StateGraph, to_state: StateGraph) -> str:
    if link.from_node_ids:
        return from_state.by_id[link.from_node_ids[0]].kind
    return to_state.by_id[link.to_node_ids[0]].kind


def _plural(noun: str, count: int) -> str:
    return noun if count == 1 else f"{noun}s"


def _kind_label(kind: str) -> str:
    return "basic block" if kind == "BasicBlock" else kind.lower()
