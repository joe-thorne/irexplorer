"""Deterministic first-pass comparison for adjacent optimisation states."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
import re
from types import MappingProxyType
from typing import Callable, Iterable, Mapping, Sequence

from src.backend.model.correspondence import Correspondence, Link, validate_correspondence
from src.backend.model.graph import Node, StateGraph
from src.backend.model.timeline import OptimisationTimeline, PassStep


COMPARABLE_KINDS = ("Function", "BasicBlock", "Instruction")
_VALUE_NAME_RE = re.compile(r"%[-A-Za-z0-9_.$]+")
_DEBUG_REF_RE = re.compile(r",?\s*!dbg\s*!\d+")


@dataclass(frozen=True)
class SummaryItem:
    """One claim, traceable to correspondence links and/or pass remarks."""

    text: str
    link_indices: tuple[int, ...] = ()
    remark_indices: tuple[int, ...] = ()


@dataclass(frozen=True)
class ComparisonSummary:
    """Concise, evidence-backed description of a comparison."""

    context: str
    items: tuple[SummaryItem, ...]


@dataclass(frozen=True)
class ComparisonResult:
    """The correspondence and its derived summary, without state mutation."""

    correspondence: Correspondence | ComposedCorrespondence
    summary: ComparisonSummary


@dataclass(frozen=True)
class ComposedCorrespondence:
    """A transient non-adjacent view derived from stored adjacent overlays.

    It intentionally is not a Layer 3 ``Correspondence``: I12 permits only
    adjacent overlays to be persisted. The shape remains identical so callers
    can use the same query and summary code without special-case traversal.
    """

    from_ordinal: int
    to_ordinal: int
    covered_kinds: tuple[str, ...]
    links: tuple[Link, ...]
    links_from: Mapping[str, Link] = field(init=False, repr=False, compare=False)
    links_to: Mapping[str, Link] = field(init=False, repr=False, compare=False)

    def __post_init__(self) -> None:
        object.__setattr__(
            self,
            "links_from",
            MappingProxyType(
                {
                    node_id: link
                    for link in self.links
                    for node_id in link.from_node_ids
                }
            ),
        )
        object.__setattr__(
            self,
            "links_to",
            MappingProxyType(
                {
                    node_id: link
                    for link in self.links
                    for node_id in link.to_node_ids
                }
            ),
        )

    def validate(self, from_state: StateGraph, to_state: StateGraph) -> None:
        validate_correspondence(
            self,
            from_state,
            to_state,
            require_adjacent=False,
        )


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


def is_identity_correspondence(correspondence: Correspondence) -> bool:
    """Return whether an adjacent pass left every comparable node unchanged."""

    return bool(correspondence.links) and all(
        link.relation == "same" and link.confidence == "exact"
        for link in correspondence.links
    )


def compose_timeline_correspondences(
    timeline: OptimisationTimeline,
    correspondences: Sequence[Correspondence],
    from_ordinal: int,
    to_ordinal: int,
) -> ComposedCorrespondence:
    """Compose a non-adjacent view from the timeline's stored overlays.

    The fold is deliberately performed over the adjacent overlay sequence,
    never over a pre-baked skip-level record. This keeps I12 intact while
    making confidence degradation and relation coarsening deterministic.
    """

    timeline.validate()
    if from_ordinal < 0 or to_ordinal >= len(timeline.states):
        raise ValueError("comparison ordinals are outside the timeline")
    if to_ordinal <= from_ordinal + 1:
        raise ValueError("composition requires at least two adjacent steps")

    by_from = {correspondence.from_ordinal: correspondence for correspondence in correspondences}
    try:
        first = by_from[from_ordinal]
    except KeyError as exc:
        raise ValueError(f"missing adjacent correspondence from ordinal {from_ordinal}") from exc
    first.validate(timeline.state(from_ordinal), timeline.state(from_ordinal + 1))

    composed: Correspondence | ComposedCorrespondence = first
    for ordinal in range(from_ordinal + 1, to_ordinal):
        try:
            following = by_from[ordinal]
        except KeyError as exc:
            raise ValueError(f"missing adjacent correspondence from ordinal {ordinal}") from exc
        following.validate(timeline.state(ordinal), timeline.state(ordinal + 1))
        composed = compose_correspondences(
            composed,
            following,
            timeline.state(from_ordinal),
            timeline.state(ordinal),
            timeline.state(ordinal + 1),
        )
    if not isinstance(composed, ComposedCorrespondence):  # pragma: no cover - guarded above
        raise AssertionError("non-adjacent composition did not produce a composed view")
    return composed


def compose_correspondences(
    earlier: Correspondence | ComposedCorrespondence,
    later: Correspondence,
    from_state: StateGraph,
    intermediate_state: StateGraph,
    to_state: StateGraph,
) -> ComposedCorrespondence:
    """Relationally compose two contiguous overlays without persisting them.

    Hyperedges are retained by collecting every reachable later target for one
    earlier source set. That preserves coverage at both endpoints even when a
    split or merge crosses the intermediate state.
    """

    earlier.validate(from_state, intermediate_state)
    later.validate(intermediate_state, to_state)
    if earlier.to_ordinal != later.from_ordinal:
        raise ValueError("correspondences must share an intermediate ordinal")
    if earlier.covered_kinds != later.covered_kinds:
        raise ValueError("correspondences must cover the same node kinds")

    links: list[Link] = []
    covered_to: set[str] = set()
    for earlier_link in earlier.links:
        if not earlier_link.from_node_ids:
            continue
        following_links = _following_links(earlier_link, later)
        target_ids = _unique_node_ids(
            node_id
            for link in following_links
            for node_id in link.to_node_ids
        )
        chain = (earlier_link, *following_links)
        if target_ids:
            links.append(
                Link(
                    from_node_ids=earlier_link.from_node_ids,
                    to_node_ids=target_ids,
                    relation=_coarsened_relation(chain),
                    confidence=_minimum_confidence(chain),
                    evidence=_composition_evidence(chain),
                )
            )
            covered_to.update(target_ids)
        else:
            links.append(
                Link(
                    from_node_ids=earlier_link.from_node_ids,
                    to_node_ids=(),
                    relation="removed",
                    confidence=_minimum_confidence(chain),
                    evidence=_composition_evidence(chain),
                )
            )

    for later_link in later.links:
        uncovered_target_ids = tuple(
            node_id for node_id in later_link.to_node_ids if node_id not in covered_to
        )
        if not uncovered_target_ids:
            continue
        addition_chain = _addition_chain(later_link, earlier)
        links.append(
            Link(
                from_node_ids=(),
                to_node_ids=uncovered_target_ids,
                relation="added",
                confidence=_minimum_confidence(addition_chain),
                evidence=_composition_evidence(addition_chain),
            )
        )
        covered_to.update(uncovered_target_ids)

    composed = ComposedCorrespondence(
        from_ordinal=earlier.from_ordinal,
        to_ordinal=later.to_ordinal,
        covered_kinds=earlier.covered_kinds,
        links=tuple(links),
    )
    composed.validate(from_state, to_state)
    return composed


def _following_links(
    earlier_link: Link,
    later: Correspondence,
) -> tuple[Link, ...]:
    """Return the unique later hyperedges reachable from one earlier link."""

    seen: set[int] = set()
    links: list[Link] = []
    for node_id in earlier_link.to_node_ids:
        link = later.links_from.get(node_id)
        if link is not None and id(link) not in seen:
            links.append(link)
            seen.add(id(link))
    return tuple(links)


def _addition_chain(later_link: Link, earlier: Correspondence | ComposedCorrespondence) -> tuple[Link, ...]:
    """Retain confidence from an intermediate addition on an endpoint addition."""

    predecessors: list[Link] = []
    seen: set[int] = set()
    for node_id in later_link.from_node_ids:
        link = earlier.links_to.get(node_id)
        if link is not None and not link.from_node_ids and id(link) not in seen:
            predecessors.append(link)
            seen.add(id(link))
    return (*predecessors, later_link)


def _unique_node_ids(node_ids: Iterable[str]) -> tuple[str, ...]:
    return tuple(dict.fromkeys(node_ids))


def _minimum_confidence(links: Iterable[Link]) -> str:
    confidence_rank = {"none": 0, "approximate": 1, "exact": 2}
    return min(links, key=lambda link: confidence_rank[link.confidence]).confidence


def _coarsened_relation(links: Iterable[Link]) -> str:
    relations = tuple(link.relation for link in links)
    return relations[0] if len(set(relations)) == 1 else "changed"


def _composition_evidence(links: Iterable[Link]) -> str:
    fragments = [
        f"{link.relation} ({link.confidence}; {link.evidence or 'no recorded evidence'})"
        for link in links
    ]
    return "composed path: " + " → ".join(fragments)


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
    if step is not None and step.kind == "recompiled":
        _match_anchor_blocks(
            unmatched_from,
            unmatched_to,
            links,
            from_state,
            to_state,
            function_pairs,
        )
        _match_anchor_instructions(
            unmatched_from,
            unmatched_to,
            links,
            from_state,
            to_state,
            function_pairs,
        )
    else:
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


def _match_anchor_blocks(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    function_pairs: dict[str, str],
) -> dict[str, str]:
    """Match anchor blocks only on their retained labels, never layout guesses.

    A recompiled anchor has no pass derivation. Its labels and CFG layout can
    independently change, so even a unique label is informative but only
    approximate; unmatched blocks remain visible rather than being paired by
    position.
    """

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
                key=lambda state, node: node.display_name,
                evidence="conservative anchor match on unique basic-block label",
                relation="changed",
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


def _match_anchor_instructions(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    function_pairs: dict[str, str],
) -> None:
    """Use only source-backed approximate evidence for a recompiled anchor."""

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
            evidence="conservative anchor match on unique debug source location and opcode",
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
            evidence="conservative anchor match on unique debug source location after rewrite",
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
    evidence: str = "unique debug source location after instruction rewrite",
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
                evidence=evidence,
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
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
    step: PassStep | None,
) -> ComparisonSummary:
    if isinstance(correspondence, ComposedCorrespondence) and step is not None and step.kind == "recompiled":
        context = (
            f"Composed comparison across {correspondence.to_ordinal - correspondence.from_ordinal} "
            f"transitions, ending at the recompiled {step.origin.level} anchor: "
            "these are output differences, not the effect of one optimisation pass."
        )
    elif isinstance(correspondence, ComposedCorrespondence):
        context = (
            f"Composed comparison across {correspondence.to_ordinal - correspondence.from_ordinal} "
            "derived transitions."
        )
    elif step is not None and step.kind == "recompiled":
        context = (
            f"Recompiled {step.origin.level} anchor comparison: these are output "
            "differences, not the effect of one optimisation pass."
        )
    elif step is not None:
        context = f"Derived pass comparison: {step.origin.pass_name}."
    else:
        context = "Adjacent optimisation-state comparison."

    items: list[SummaryItem] = []
    all_indices = tuple(range(len(correspondence.links)))
    if _is_identity_view(correspondence):
        items.append(
            SummaryItem(
                "No structural or value-level changes were detected; this pass is retained as a no-op.",
                all_indices,
            )
        )
    else:
        for relation, verb in (("removed", "removed"), ("added", "added")):
            for kind in ("BasicBlock", "Instruction"):
                indices = _link_indices(
                    correspondence,
                    from_state,
                    to_state,
                    relation=relation,
                    kind=kind,
                    confidence="exact",
                )
                if indices:
                    noun = _plural(_kind_label(kind), len(indices))
                    items.append(SummaryItem(f"{len(indices)} {noun} {verb}.", indices))

        for relation, label in (
            ("promoted", "promotions"),
            ("simplifiedInto", "simplifications"),
            ("renamed", "renamed correspondences"),
            ("moved", "moved correspondences"),
        ):
            indices = _link_indices(
                correspondence,
                from_state,
                to_state,
                relation=relation,
                kind="Instruction",
            )
            if indices:
                confidence = _confidence_phrase(correspondence, indices)
                verb = "was" if len(indices) == 1 else "were"
                items.append(
                    SummaryItem(
                        f"{len(indices)} {_plural('instruction', len(indices))} "
                        f"{verb} linked as {label}{confidence}.",
                        indices,
                    )
                )

        changed_blocks = _link_indices(
            correspondence,
            from_state,
            to_state,
            relation="changed",
            kind="BasicBlock",
        )
        if changed_blocks:
            items.append(
                SummaryItem(
                    f"{len(changed_blocks)} {_plural('basic block', len(changed_blocks))} "
                    f"changed shape{_confidence_phrase(correspondence, changed_blocks)}.",
                    changed_blocks,
                )
            )

        basic_block_indices = _indices_for_kind(correspondence, from_state, to_state, "BasicBlock")
        if basic_block_indices and all(
            correspondence.links[index].relation == "same"
            and correspondence.links[index].confidence == "exact"
            for index in basic_block_indices
        ):
            items.append(
                SummaryItem(
                    "CFG unchanged across the recorded basic-block correspondences.",
                    basic_block_indices,
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
                    f"{len(unresolved)} {_plural('node', len(unresolved))} could not be classified "
                    "with the available matching evidence.",
                    unresolved,
                )
            )
        if not items:
            items.append(
                SummaryItem("No comparable structural changes were detected.", all_indices)
            )

    if step is not None and step.remarks:
        remark_names = tuple(
            sorted({remark.name or remark.pass_name or "unnamed" for remark in step.remarks})
        )
        labels = ", ".join(remark_names[:3])
        remaining = len(remark_names) - 3
        if remaining > 0:
            labels += f", and {remaining} more"
        remark_scope = (
            "the final transition"
            if isinstance(correspondence, ComposedCorrespondence)
            else "this step"
        )
        items.append(
            SummaryItem(
                f"{len(step.remarks)} compiler {_plural('remark', len(step.remarks))} "
                f"were captured for {remark_scope} ({labels}); expand the evidence to inspect them.",
                remark_indices=tuple(range(len(step.remarks))),
            )
        )
    return ComparisonSummary(context=context, items=tuple(items))


def _is_identity_view(correspondence: Correspondence | ComposedCorrespondence) -> bool:
    return bool(correspondence.links) and all(
        link.relation == "same" and link.confidence == "exact"
        for link in correspondence.links
    )


def _link_indices(
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
    *,
    relation: str,
    kind: str,
    confidence: str | None = None,
) -> tuple[int, ...]:
    return tuple(
        index
        for index, link in enumerate(correspondence.links)
        if link.relation == relation
        and _link_kind(link, from_state, to_state) == kind
        and (confidence is None or link.confidence == confidence)
    )


def _indices_for_kind(
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
    kind: str,
) -> tuple[int, ...]:
    return tuple(
        index
        for index, link in enumerate(correspondence.links)
        if _link_kind(link, from_state, to_state) == kind
    )


def _confidence_phrase(
    correspondence: Correspondence | ComposedCorrespondence,
    indices: tuple[int, ...],
) -> str:
    confidences = {correspondence.links[index].confidence for index in indices}
    if confidences == {"exact"}:
        return ""
    if confidences == {"approximate"}:
        return " with approximate correspondence evidence"
    return " with mixed-confidence correspondence evidence"


def _link_kind(link: Link, from_state: StateGraph, to_state: StateGraph) -> str:
    if link.from_node_ids:
        return from_state.by_id[link.from_node_ids[0]].kind
    return to_state.by_id[link.to_node_ids[0]].kind


def _plural(noun: str, count: int) -> str:
    return noun if count == 1 else f"{noun}s"


def _kind_label(kind: str) -> str:
    return "basic block" if kind == "BasicBlock" else kind.lower()
