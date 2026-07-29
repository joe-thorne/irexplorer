"""Deterministic first-pass comparison for adjacent optimisation states."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
import re
from typing import Callable, Iterable

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
    """Return a deterministic, coverage-complete hybrid overlay.

    The matcher combines containment/CFG structure, eager SSA def-use edges,
    debug source locations, and a deliberately weak positional tiebreak.
    Exact instruction links require the structural and value-flow signature to
    agree. Source-only and positional links are approximate. A candidate set
    which was inspected but could not be resolved remains an explicit
    confidence-``none`` addition or removal; ``none`` never means that work is
    pending.
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

    function_pairs = _match_unique(
        unmatched_from,
        unmatched_to,
        links,
        kind="Function",
        key=lambda node: node.display_name,
        evidence="unique function name",
    )
    block_pairs = _match_blocks(
        unmatched_from,
        unmatched_to,
        links,
        from_state,
        to_state,
        function_pairs,
    )
    _match_instructions(
        unmatched_from,
        unmatched_to,
        links,
        from_state,
        to_state,
        function_pairs,
        block_pairs,
    )
    _append_unmatched_links(
        unmatched_from,
        unmatched_to,
        links,
        from_state,
        to_state,
        function_pairs,
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
        summary=summarise_correspondence(correspondence, from_state, to_state, step),
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
    key: Callable[[Node], object],
    evidence: str,
    relation: str = "same",
    confidence: str = "exact",
) -> dict[str, str]:
    grouped_from = _group_unique(
        (node for node in unmatched_from.values() if node.kind == kind), key
    )
    grouped_to = _group_unique(
        (node for node in unmatched_to.values() if node.kind == kind), key
    )
    pairs: dict[str, str] = {}
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
        pairs[from_node.stable_id] = to_node.stable_id
    return pairs


def _match_blocks(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    function_pairs: dict[str, str],
) -> dict[str, str]:
    """Match blocks by CFG role, retaining position only as a tiebreak."""

    pairs: dict[str, str] = {}
    for from_function, to_function in function_pairs.items():
        pairs.update(
            _match_unique_in_context(
                unmatched_from,
                unmatched_to,
                links,
                kind="BasicBlock",
                from_parent=from_function,
                to_parent=to_function,
                from_state=from_state,
                to_state=to_state,
                key=lambda state, node: (node.display_name, _block_shape(state, node)),
                evidence="unique basic-block label and CFG role",
                confidence="exact",
            )
        )
    for from_function, to_function in function_pairs.items():
        pairs.update(
            _match_unique_in_context(
                unmatched_from,
                unmatched_to,
                links,
                kind="BasicBlock",
                from_parent=from_function,
                to_parent=to_function,
                from_state=from_state,
                to_state=to_state,
                key=lambda state, node: node.display_name,
                evidence="unique basic-block label after CFG change",
                relation="changed",
                confidence="approximate",
            )
        )
    for from_function, to_function in function_pairs.items():
        pairs.update(
            _match_unique_in_context(
                unmatched_from,
                unmatched_to,
                links,
                kind="BasicBlock",
                from_parent=from_function,
                to_parent=to_function,
                from_state=from_state,
                to_state=to_state,
                key=lambda state, node: (_block_shape(state, node), _contains_position(state, node)),
                evidence="unique CFG role and layout position",
                relation="moved",
                confidence="approximate",
            )
        )
    return pairs


def _match_instructions(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    function_pairs: dict[str, str],
    block_pairs: dict[str, str],
) -> None:
    for from_block, to_block in block_pairs.items():
        _match_unique_in_context(
            unmatched_from,
            unmatched_to,
            links,
            kind="Instruction",
            from_parent=from_block,
            to_parent=to_block,
            from_state=from_state,
            to_state=to_state,
            key=_instruction_exact_signature,
            evidence="unique structural, source, and value-flow signature",
            confidence="exact",
        )

    for from_function, to_function in function_pairs.items():
        _match_unique_in_context(
            unmatched_from,
            unmatched_to,
            links,
            kind="Instruction",
            from_parent=from_function,
            to_parent=to_function,
            from_state=from_state,
            to_state=to_state,
            key=lambda state, node: _source_opcode_key(node),
            evidence="unique debug source location and opcode",
            relation="renamed",
            confidence="approximate",
            ignore_none=True,
            parent_kind="Function",
        )
        _match_source_rewrites_in_context(
            unmatched_from,
            unmatched_to,
            links,
            from_state,
            to_state,
            from_function,
            to_function,
        )

    for from_block, to_block in block_pairs.items():
        _match_unique_in_context(
            unmatched_from,
            unmatched_to,
            links,
            kind="Instruction",
            from_parent=from_block,
            to_parent=to_block,
            from_state=from_state,
            to_state=to_state,
            key=lambda state, node: (node.attributes.get("opcode"), _contains_position(state, node)),
            evidence="unique opcode and layout position in matched basic block",
            relation="moved",
            confidence="approximate",
        )


def _match_unique_in_context(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    *,
    kind: str,
    from_parent: str,
    to_parent: str,
    from_state: StateGraph,
    to_state: StateGraph,
    key: Callable[[StateGraph, Node], object],
    evidence: str,
    relation: str = "same",
    confidence: str = "exact",
    ignore_none: bool = False,
    parent_kind: str = "BasicBlock",
) -> dict[str, str]:
    """Match unique node keys inside already matched containment contexts."""

    if parent_kind == "Function":
        from_nodes = (
            node
            for node in unmatched_from.values()
            if node.kind == kind and _function_for_node(from_state, node) == from_parent
        )
        to_nodes = (
            node
            for node in unmatched_to.values()
            if node.kind == kind and _function_for_node(to_state, node) == to_parent
        )
    else:
        from_nodes = (
            node
            for node in unmatched_from.values()
            if node.kind == kind and from_state.contains_parent.get(node.stable_id) == from_parent
        )
        to_nodes = (
            node
            for node in unmatched_to.values()
            if node.kind == kind and to_state.contains_parent.get(node.stable_id) == to_parent
        )
    grouped_from = _group_unique(
        from_nodes, lambda node: key(from_state, node), ignore_none=ignore_none
    )
    grouped_to = _group_unique(
        to_nodes, lambda node: key(to_state, node), ignore_none=ignore_none
    )

    pairs: dict[str, str] = {}
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
        pairs[from_node.stable_id] = to_node.stable_id
    return pairs


def _match_source_rewrites_in_context(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    from_function: str,
    to_function: str,
) -> None:
    source_key = lambda state, node: node.attributes.get("source")
    grouped_from = _group_unique(
        (
            node
            for node in unmatched_from.values()
            if node.kind == "Instruction" and _function_for_node(from_state, node) == from_function
        ),
        lambda node: source_key(from_state, node),
        ignore_none=True,
    )
    grouped_to = _group_unique(
        (
            node
            for node in unmatched_to.values()
            if node.kind == "Instruction" and _function_for_node(to_state, node) == to_function
        ),
        lambda node: source_key(to_state, node),
        ignore_none=True,
    )
    for match_key in sorted(grouped_from.keys() & grouped_to.keys(), key=str):
        from_node = grouped_from[match_key]
        to_node = grouped_to[match_key]
        relation = (
            "promoted"
            if from_node.attributes.get("opcode") == "load"
            and to_node.attributes.get("opcode") != "load"
            else "simplifiedInto"
        )
        links.append(
            Link(
                from_node_ids=(from_node.stable_id,),
                to_node_ids=(to_node.stable_id,),
                relation=relation,
                confidence="approximate",
                evidence="unique debug source location after instruction rewrite",
            )
        )
        del unmatched_from[from_node.stable_id]
        del unmatched_to[to_node.stable_id]


def _append_unmatched_links(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    function_pairs: dict[str, str],
) -> None:
    """Account for every unresolved node without inventing a counterpart."""

    inverse_function_pairs = {to_id: from_id for from_id, to_id in function_pairs.items()}
    for node in tuple(unmatched_from.values()):
        confidence = "none" if _has_plausible_target(
            node, unmatched_to.values(), from_state, to_state, function_pairs
        ) else "exact"
        evidence = (
            "candidate counterparts were inspected but no unique hybrid match exists"
            if confidence == "none"
            else "no target node shares the structural matcher signature"
        )
        links.append(
            Link(
                from_node_ids=(node.stable_id,),
                to_node_ids=(),
                relation="removed",
                confidence=confidence,
                evidence=evidence,
            )
        )
    for node in tuple(unmatched_to.values()):
        confidence = "none" if _has_plausible_target(
            node,
            unmatched_from.values(),
            to_state,
            from_state,
            inverse_function_pairs,
        ) else "exact"
        evidence = (
            "candidate counterparts were inspected but no unique hybrid match exists"
            if confidence == "none"
            else "no source node shares the structural matcher signature"
        )
        links.append(
            Link(
                from_node_ids=(),
                to_node_ids=(node.stable_id,),
                relation="added",
                confidence=confidence,
                evidence=evidence,
            )
        )


def _has_plausible_target(
    node: Node,
    candidates: Iterable[Node],
    state: StateGraph,
    candidate_state: StateGraph,
    function_pairs: dict[str, str],
) -> bool:
    if node.kind == "Function":
        return any(candidate.display_name == node.display_name for candidate in candidates)
    expected_function = function_pairs.get(_function_for_node(state, node))
    for candidate in candidates:
        if candidate.kind != node.kind:
            continue
        if expected_function is not None and _function_for_node(candidate_state, candidate) != expected_function:
            continue
        if node.kind == "Instruction" and candidate.attributes.get("opcode") == node.attributes.get("opcode"):
            return True
        if node.kind == "BasicBlock" and _block_shape(candidate_state, candidate) == _block_shape(state, node):
            return True
    return False


def _function_for_node(state: StateGraph, node: Node) -> str:
    if node.kind == "Function":
        return node.stable_id
    current = node.stable_id
    while state.by_id[current].kind != "Function":
        current = state.contains_parent[current]
    return current


def _contains_position(state: StateGraph, node: Node) -> int:
    parent_id = state.contains_parent[node.stable_id]
    return state.contains_children[parent_id].index(node.stable_id)


def _block_shape(state: StateGraph, node: Node) -> tuple[object, ...]:
    successors = tuple(edge.label for edge in state.cfg_successors.get(node.stable_id, ()))
    instructions = state.contains_children.get(node.stable_id, ())
    terminator = state.by_id[instructions[-1]].attributes.get("opcode") if instructions else None
    return (
        _contains_position(state, node) == 0,
        len(state.cfg_predecessors.get(node.stable_id, ())),
        successors,
        terminator,
    )


def _instruction_exact_signature(state: StateGraph, node: Node) -> tuple[object, ...]:
    predecessors = tuple(
        sorted(
            str(state.by_id[edge.from_id].attributes.get("opcode"))
            for edge in state.value_flow_predecessors.get(node.stable_id, ())
        )
    )
    successors = tuple(
        sorted(
            str(state.by_id[edge.to_id].attributes.get("opcode"))
            for edge in state.value_flow_successors.get(node.stable_id, ())
        )
    )
    return (
        node.attributes.get("opcode"),
        node.attributes.get("source"),
        _normalised_instruction_text(node),
        predecessors,
        successors,
    )


def _normalised_instruction_text(node: Node) -> str:
    text = str(node.attributes.get("text", ""))
    text = _DEBUG_REF_RE.sub("", text)
    text = re.sub(r"^%[-A-Za-z0-9_.$]+\s*=\s*", "", text)
    return _VALUE_NAME_RE.sub("%value", " ".join(text.split()))


def _source_opcode_key(node: Node) -> tuple[object, object] | None:
    source = node.attributes.get("source")
    if source is None:
        return None
    return (source, node.attributes.get("opcode"))


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


def summarise_correspondence(
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
                and link.confidence == "exact"
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
                f"{len(rewritten)} {_plural('instruction', len(rewritten))} were linked as rewrites or moves.",
                rewritten,
            )
        )
    unresolved = tuple(
        index
        for index, link in enumerate(correspondence.links)
        if link.confidence == "none"
    )
    if unresolved:
        items.append(
            SummaryItem(
                f"{len(unresolved)} {_plural('node', len(unresolved))} could not be classified with the available matching evidence.",
                unresolved,
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
