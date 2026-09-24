"""Deterministic first-pass comparison for adjacent optimisation states."""

from __future__ import annotations

import re
from collections import Counter, defaultdict
from collections.abc import Callable, Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from types import MappingProxyType

from src.backend.model.correspondence import (
    Confidence,
    Correspondence,
    Link,
    Relation,
    validate_correspondence,
)
from src.backend.model.graph import Edge, Node, StateGraph
from src.backend.model.timeline import OptimisationTimeline, PassStep

COMPARABLE_KINDS = ("Function", "BasicBlock", "Instruction")
_VALUE_NAME_RE = re.compile(r"%[-A-Za-z0-9_.$]+")
_DEBUG_REF_RE = re.compile(r",?\s*!dbg\s*!\d+")
_BLOCK_REFERENCE_RE = re.compile(r"label\s+%([-A-Za-z0-9_.$]+)")
_PHI_INCOMING_BLOCK_RE = re.compile(r"\[[^\]]+,\s*%([-A-Za-z0-9_.$]+)\s*\]")
_POINTER_REFERENCE_RE = re.compile(r"\bptr\s+(%[-A-Za-z0-9_.$]+)")


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
) -> Correspondence:
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

    Links that share intermediate nodes form connected components. Each
    component becomes one endpoint hyperedge, preserving complete coverage
    when splits or merges join otherwise separate links.
    """

    earlier.validate(from_state, intermediate_state)
    later.validate(intermediate_state, to_state)
    if earlier.to_ordinal != later.from_ordinal:
        raise ValueError("correspondences must share an intermediate ordinal")
    if earlier.covered_kinds != later.covered_kinds:
        raise ValueError("correspondences must cover the same node kinds")

    links: list[Link] = []
    for earlier_indices, later_indices in _composition_components(earlier, later):
        component_links = tuple(earlier.links[index] for index in earlier_indices) + tuple(
            later.links[index] for index in later_indices
        )
        source_ids = _unique_node_ids(
            node_id
            for index in earlier_indices
            for node_id in earlier.links[index].from_node_ids
        )
        target_ids = _unique_node_ids(
            node_id
            for index in later_indices
            for node_id in later.links[index].to_node_ids
        )
        if not source_ids and not target_ids:
            continue
        links.append(
            Link(
                from_node_ids=source_ids,
                to_node_ids=target_ids,
                relation=_composition_relation(source_ids, target_ids, component_links),
                confidence=_minimum_confidence(component_links),
                evidence=_composition_evidence(component_links),
            )
        )

    composed = ComposedCorrespondence(
        from_ordinal=earlier.from_ordinal,
        to_ordinal=later.to_ordinal,
        covered_kinds=earlier.covered_kinds,
        links=tuple(links),
    )
    composed.validate(from_state, to_state)
    return composed


def _composition_components(
    earlier: Correspondence | ComposedCorrespondence,
    later: Correspondence,
) -> tuple[tuple[tuple[int, ...], tuple[int, ...]], ...]:
    """Return bipartite link components joined through intermediate nodes."""

    earlier_count = len(earlier.links)
    adjacency: list[set[int]] = [set() for _ in range(earlier_count + len(later.links))]
    later_index_by_node = {
        node_id: index
        for index, link in enumerate(later.links)
        for node_id in link.from_node_ids
    }
    for earlier_index, link in enumerate(earlier.links):
        for node_id in link.to_node_ids:
            later_vertex = earlier_count + later_index_by_node[node_id]
            adjacency[earlier_index].add(later_vertex)
            adjacency[later_vertex].add(earlier_index)

    components: list[tuple[tuple[int, ...], tuple[int, ...]]] = []
    visited: set[int] = set()
    for start in range(len(adjacency)):
        if start in visited:
            continue
        pending = [start]
        component: list[int] = []
        while pending:
            vertex = pending.pop()
            if vertex in visited:
                continue
            visited.add(vertex)
            component.append(vertex)
            pending.extend(adjacency[vertex] - visited)
        component.sort()
        components.append(
            (
                tuple(vertex for vertex in component if vertex < earlier_count),
                tuple(
                    vertex - earlier_count
                    for vertex in component
                    if vertex >= earlier_count
                ),
            )
        )
    return tuple(components)


def _unique_node_ids(node_ids: Iterable[str]) -> tuple[str, ...]:
    return tuple(dict.fromkeys(node_ids))


def _minimum_confidence(links: Iterable[Link]) -> Confidence:
    confidence_rank = {"none": 0, "plausible": 1, "approximate": 2, "exact": 3}
    return min(links, key=lambda link: confidence_rank[link.confidence]).confidence


def _composition_relation(
    source_ids: tuple[str, ...],
    target_ids: tuple[str, ...],
    links: tuple[Link, ...],
) -> Relation:
    if not source_ids:
        return "added"
    if not target_ids:
        return "removed"
    if len(source_ids) == 1 and len(target_ids) > 1:
        return "split"
    if len(source_ids) > 1 and len(target_ids) == 1:
        return "merged"
    if len(source_ids) > 1 and len(target_ids) > 1:
        return "changed"
    return _coarsened_relation(links)


def _coarsened_relation(links: Iterable[Link]) -> Relation:
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
) -> Correspondence:
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
        step,
    )

    correspondence = Correspondence(
        from_ordinal=from_state.ordinal,
        to_ordinal=to_state.ordinal,
        covered_kinds=COMPARABLE_KINDS,
        links=tuple(links),
    )
    correspondence.validate(from_state, to_state)
    return correspondence


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
    relation: Relation = "same",
    confidence: Confidence = "exact",
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
                relation=relation,
                confidence=confidence,
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
    _match_minmax_rewrites(
        unmatched_from, unmatched_to, links, from_state, to_state, block_pairs
    )
    _match_instruction_groups(
        unmatched_from, unmatched_to, links, from_state, to_state, block_pairs
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
    relation: Relation = "same",
    confidence: Confidence = "exact",
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
        observed_relation = relation
        # Evidence tier says how confidently a candidate pair was identified;
        # it does not describe what happened to the instruction.  In
        # particular, source- and layout-based fallbacks often pair bytewise
        # unchanged instructions.  Derive their relation from the paired
        # records instead of exposing the fallback's old ``renamed`` or
        # ``moved`` label as a claim about the IR.
        if kind == "Instruction" and relation in {"same", "renamed", "moved"}:
            observed_relation = _instruction_relation(from_node, to_node)
        links.append(
            Link(
                from_node_ids=(from_node.stable_id,),
                to_node_ids=(to_node.stable_id,),
                relation=observed_relation,
                confidence=confidence,
                evidence=evidence,
            )
        )
        del unmatched_from[from_node.stable_id]
        del unmatched_to[to_node.stable_id]
        pairs[from_node.stable_id] = to_node.stable_id
    return pairs


# Deliberately limited to scalar integer patterns with ordinary SSA operands.
_MINMAX_VALUE = r"(%[-A-Za-z0-9_.$]+|-?\d+)"


def _minmax_expression(state: StateGraph, node: Node) -> tuple | None:
    """Return (operation, type, operands, members) for a recognised idiom."""
    def body(item: Node) -> str:
        text = _DEBUG_REF_RE.sub("", str(item.attributes.get("text", "")))
        return text.split("=", 1)[-1].strip()

    value = _MINMAX_VALUE
    call = re.fullmatch(
        rf"(?:tail )?call (i\d+) @llvm\.([su](?:min|max))\.(i\d+)"
        rf"\(\1 {value}, \1 {value}\)", body(node))
    if call and call[1] == call[3]:
        return call[2], call[1], tuple(sorted((call[4], call[5]))), [node]
    select = re.fullmatch(rf"select i1 {value}, (i\d+) {value}, \2 {value}", body(node))
    if not select:
        return None
    block = state.contains_parent[node.stable_id]
    definitions = [state.by_id[key] for key in state.contains_children[block]
                   if state.by_id[key].attributes.get("result") == select[1]]
    if len(definitions) != 1:
        return None
    cmp = definitions[0]
    match = re.fullmatch(rf"icmp ([su](?:gt|ge|lt|le)) (i\d+) {value}, {value}", body(cmp))
    if not match or match[2] != select[2] or match[3] == match[4]:
        return None
    if (select[3], select[4]) == (match[3], match[4]):
        direct = True
    elif (select[3], select[4]) == (match[4], match[3]):
        direct = False
    else:
        return None
    # A comparison with other users has not been wholly absorbed by the call.
    users = state.value_flow_successors.get(cmp.stable_id, ())
    if not users or any(edge.to_id != node.stable_id for edge in users):
        return None
    maximum = (match[1][1] == "g") == direct
    operation = match[1][0] + ("max" if maximum else "min")
    return operation, match[2], tuple(sorted((match[3], match[4]))), [cmp, node]


def _match_minmax_rewrites(
    unmatched_from: dict[str, Node], unmatched_to: dict[str, Node],
    links: list[Link], from_state: StateGraph, to_state: StateGraph,
    block_pairs: dict[str, str],
) -> None:
    """Match unique min/max idioms without depending on debug locations.

    Operand identity, connected value flow and surviving users corroborate the
    recognised pattern. Keep correspondence approximate, as for other groups.
    """
    def candidates(state, block, unmatched, context):
        result = defaultdict(list)
        for node_id in state.contains_children.get(block, ()):
            node = unmatched.get(node_id)
            if node is None or node.attributes.get("opcode") not in {"select", "call"}:
                continue
            expression = _minmax_expression(state, node)
            if expression is None:
                continue
            operation, type_, operands, members = expression
            if any(member.stable_id not in unmatched for member in members):
                continue
            boundary = _expression_boundary(state, members, context)
            if boundary is not None:
                result[(operation, type_, operands, boundary)].append(members)
        return result

    for old_block, new_block in block_pairs.items():
        before = candidates(from_state, old_block, unmatched_from,
                            {key: key for key in block_pairs})
        after = candidates(to_state, new_block, unmatched_to,
                           {value: key for key, value in block_pairs.items()})
        for key in sorted(before.keys() & after.keys(), key=str):
            if len(before[key]) != 1 or len(after[key]) != 1:
                continue
            old, new = before[key][0], after[key][0]
            if sorted((len(old), len(new))) != [1, 2]:
                continue
            links.append(Link(
                from_node_ids=tuple(node.stable_id for node in old),
                to_node_ids=tuple(node.stable_id for node in new),
                relation="merged" if len(old) == 2 else "split",
                confidence="approximate",
                evidence=(f"recognised integer {key[0]} compare/select intrinsic rewrite; "
                          "matched block, predicate, types, operands and result-use boundary"),
            ))
            for node in old:
                del unmatched_from[node.stable_id]
            for node in new:
                del unmatched_to[node.stable_id]


# Memory operations, calls, PHIs and terminators need specialised evidence.
_GROUP_OPCODES = frozenset({
    "add", "sub", "mul", "shl", "lshr", "ashr", "and", "or", "xor",
    "sdiv", "udiv", "srem", "urem", "icmp", "fcmp", "select",
    "sext", "zext", "trunc", "bitcast", "getelementptr",
    "fadd", "fsub", "fmul", "fdiv", "frem", "fneg",
})


def _expression_boundary(
    state: StateGraph, nodes: list[Node], block_context: dict[str, str]
) -> tuple | None:
    """Corroborate a connected expression with its inputs and result users."""
    ids = {node.stable_id for node in nodes}
    neighbours: dict[str, set[str]] = {node_id: set() for node_id in ids}
    inputs: set[tuple] = set()
    outputs: set[tuple] = set()
    function = _function_for_node(state, nodes[0])
    definitions = {node.attributes.get("result"): node for node in state.nodes
                   if node.kind == "Instruction"
                   and _function_for_node(state, node) == function}

    def signature(node: Node) -> tuple:
        return (node.attributes.get("source"), node.attributes.get("opcode"),
                _normalised_instruction_text(node))

    for node in nodes:
        for operand in node.attributes.get("operands", ()):
            definition = definitions.get(operand)
            if definition is None:
                inputs.add(("external", operand))
            elif definition.stable_id not in ids:
                parent = state.contains_parent[definition.stable_id]
                if parent not in block_context:
                    return None
                # Induction-variable rewrites can widen a PHI while retaining
                # its slot in the matched block. Keep that evidence approximate.
                text = _normalised_instruction_text(definition)
                if definition.attributes.get("opcode") == "phi":
                    text = re.sub(r"\bi\d+\b", "iN", text)
                inputs.add(("definition", block_context[parent],
                            _contains_position(state, definition),
                            definition.attributes.get("source"),
                            definition.attributes.get("opcode"), text))
        for edge in state.value_flow_successors.get(node.stable_id, ()):
            if edge.to_id in ids:
                neighbours[node.stable_id].add(edge.to_id)
                neighbours[edge.to_id].add(node.stable_id)
            else:
                outputs.add((signature(state.by_id[edge.to_id]), edge.label))
    visited: set[str] = set()
    pending = [nodes[0].stable_id]
    while pending:
        current = pending.pop()
        if current not in visited:
            visited.add(current)
            pending.extend(neighbours[current] - visited)
    if visited != ids or not inputs or not outputs:
        return None
    return (frozenset(inputs), frozenset(outputs))


def _match_instruction_groups(
    unmatched_from: dict[str, Node],
    unmatched_to: dict[str, Node],
    links: list[Link],
    from_state: StateGraph,
    to_state: StateGraph,
    block_pairs: dict[str, str],
) -> None:
    """Recognise 1→N/N→1 expressions before pairwise matches consume members.

    Require exact source locations, matched block context, connected def-use
    structure and equal external input/result-use boundaries. These are
    approximate structural correspondences, not proofs of equivalence.
    Recompiled anchors do not use this derived-state heuristic.
    """
    def groups(state: StateGraph, block: str, unmatched: dict[str, Node]) -> dict:
        result: dict[object, list[Node]] = defaultdict(list)
        for node_id in state.contains_children.get(block, ()):
            node = unmatched.get(node_id)
            if node is None or node.attributes.get("opcode") not in _GROUP_OPCODES:
                continue
            source = node.attributes.get("source")
            if source is not None and source.line > 0 and source.column > 0:
                result[source].append(node)
        return result

    for from_block, to_block in block_pairs.items():
        before = groups(from_state, from_block, unmatched_from)
        after = groups(to_state, to_block, unmatched_to)
        for source in sorted(before.keys() & after.keys(), key=str):
            old, new = before[source], after[source]
            if min(len(old), len(new)) != 1 or len(old) == len(new):
                continue
            boundary = _expression_boundary(from_state, old, {key: key for key in block_pairs})
            if boundary is None or boundary != _expression_boundary(
                to_state, new, {value: key for key, value in block_pairs.items()}
            ):
                continue
            links.append(Link(
                from_node_ids=tuple(node.stable_id for node in old),
                to_node_ids=tuple(node.stable_id for node in new),
                relation="split" if len(old) == 1 else "merged",
                confidence="approximate",
                evidence=(f"connected expression {len(old)}→{len(new)} at "
                          f"{source.file}:{source.line}:{source.column}; matched basic block, "
                          "corresponding external value inputs and equal result-use signatures; "
                          "structural correspondence, not proven semantic equivalence"),
            ))
            for node in old:
                del unmatched_from[node.stable_id]
            for node in new:
                del unmatched_to[node.stable_id]


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
    def source_key(state, node):
        return node.attributes.get("source")

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
        relation: Relation = (
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
    step: PassStep | None,
) -> None:
    """Account for every unresolved node without inventing a counterpart."""

    inverse_function_pairs = {to_id: from_id for from_id, to_id in function_pairs.items()}
    # Consuming an approximate group must not turn other ambiguous candidates
    # into exact additions/removals just because its members left the pool.
    from_candidates = list(unmatched_from.values())
    to_candidates = list(unmatched_to.values())
    for link in links:
        if link.relation in {"split", "merged"}:
            from_candidates.extend(from_state.by_id[node_id] for node_id in link.from_node_ids)
            to_candidates.extend(to_state.by_id[node_id] for node_id in link.to_node_ids)
    for node in tuple(unmatched_from.values()):
        confidence: Confidence = "none" if _has_plausible_target(
            node, to_candidates, from_state, to_state, function_pairs
        ) else "exact"
        if confidence == "exact" and step is not None and step.kind == "recompiled" and (
            _has_renamed_block_anchor_reference(
                node, to_candidates, from_state, to_state, function_pairs
            )
        ):
            confidence = "plausible"
        evidence = (
            "candidate counterparts were inspected but no unique hybrid match exists"
            if confidence == "none"
            else "a paired function has an unmatched block whose renamed label is the only failed structural reference"
            if confidence == "plausible"
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
            from_candidates,
            to_state,
            from_state,
            inverse_function_pairs,
        ) else "exact"
        if confidence == "exact" and step is not None and step.kind == "recompiled" and (
            _has_renamed_block_anchor_reference(
                node, from_candidates, to_state, from_state, inverse_function_pairs
            )
        ):
            confidence = "plausible"
        evidence = (
            "candidate counterparts were inspected but no unique hybrid match exists"
            if confidence == "none"
            else "a paired function has an unmatched block whose renamed label is the only failed structural reference"
            if confidence == "plausible"
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
    if expected_function is None:
        return True
    for candidate in candidates:
        if candidate.kind != node.kind:
            continue
        if expected_function is not None and _function_for_node(candidate_state, candidate) != expected_function:
            continue
        if (
            node.kind == "Instruction"
            and candidate.attributes.get("opcode") == node.attributes.get("opcode")
            and _instruction_operand_shape_is_compatible(
                node, candidate, state, candidate_state, expected_function
            )
        ):
            return True
        if node.kind == "BasicBlock" and _block_shape(candidate_state, candidate) == _block_shape(state, node):
            return True
    return False


def _has_renamed_block_anchor_reference(
    node: Node,
    candidates: Iterable[Node],
    state: StateGraph,
    candidate_state: StateGraph,
    function_pairs: dict[str, str],
) -> bool:
    """Identify the qualified renamed-block case at a recompiled anchor."""

    if node.kind != "Instruction":
        return False
    expected_function = function_pairs.get(_function_for_node(state, node))
    if expected_function is None:
        return False
    candidates = tuple(candidates)
    candidate_blocks = {
        item.display_name
        for item in candidate_state.nodes
        if item.kind == "BasicBlock"
        and _function_for_node(candidate_state, item) == expected_function
    }
    block_labels = set(node.attributes.get("incomingBlocks", ()))
    block_labels.update(_BLOCK_REFERENCE_RE.findall(str(node.attributes.get("text", ""))))
    if not block_labels - candidate_blocks:
        return False
    # At an anchor, a missing block label is plausible only when the paired
    # function retains an otherwise-unmapped block and every other checked
    # structural reference still has a counterpart. A vanished function stays none.
    if not any(
        candidate.kind == "BasicBlock"
        and _function_for_node(candidate_state, candidate) == expected_function
        for candidate in candidates
    ):
        return False
    if not any(
        candidate.kind == "Instruction"
        and _function_for_node(candidate_state, candidate) == expected_function
        and candidate.attributes.get("opcode") == node.attributes.get("opcode")
        and len(candidate.attributes.get("operands", ()))
        == len(node.attributes.get("operands", ()))
        for candidate in candidates
    ):
        return False
    return _referenced_structure_has_counterparts(
        node,
        state,
        candidate_state,
        expected_function,
        allow_missing_block_labels=True,
    )


def _instruction_operand_shape_is_compatible(
    node: Node,
    candidate: Node,
    state: StateGraph,
    candidate_state: StateGraph,
    expected_function: str | None,
) -> bool:
    """Reject same-opcode candidates whose referenced structure disappeared."""

    if len(node.attributes.get("operands", ())) != len(candidate.attributes.get("operands", ())):
        return False
    if node.attributes.get("opcode") not in {"phi", "load", "store", "br"}:
        return True
    return _referenced_structure_has_counterparts(node, state, candidate_state, expected_function)


def _referenced_structure_has_counterparts(
    node: Node,
    state: StateGraph,
    candidate_state: StateGraph,
    expected_function: str | None,
    *,
    allow_missing_block_labels: bool = False,
) -> bool:
    """Check block labels and locally-defined pointers used by an instruction."""

    function_id = _function_for_node(state, node)
    if expected_function is None:
        return True
    candidate_function = expected_function
    candidate_blocks = {
        item.display_name
        for item in candidate_state.nodes
        if item.kind == "BasicBlock" and _function_for_node(candidate_state, item) == candidate_function
    }
    text = str(node.attributes.get("text", ""))
    block_labels = set(node.attributes.get("incoming_blocks", ()))
    block_labels.update(
        _PHI_INCOMING_BLOCK_RE.findall(text)
        if node.attributes.get("opcode") == "phi"
        else _BLOCK_REFERENCE_RE.findall(text)
    )
    if not allow_missing_block_labels and not block_labels.issubset(candidate_blocks):
        return False

    definitions = {
        item.attributes.get("result"): item
        for item in state.nodes
        if item.kind == "Instruction" and _function_for_node(state, item) == function_id
    }
    candidate_definition_opcodes = {
        item.attributes.get("opcode")
        for item in candidate_state.nodes
        if item.kind == "Instruction"
        and _function_for_node(candidate_state, item) == candidate_function
        and item.attributes.get("result")
    }
    pointer_definitions = [
        definitions[value]
        for value in _POINTER_REFERENCE_RE.findall(text)
        if value in definitions
    ]
    return all(
        definition.attributes.get("opcode") in candidate_definition_opcodes
        for definition in pointer_definitions
    )


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
    successors = tuple(
        (edge.label, state.by_id[edge.to_id].display_name)
        for edge in state.cfg_successors.get(node.stable_id, ())
    )
    instructions = state.contains_children.get(node.stable_id, ())
    terminator = state.by_id[instructions[-1]].attributes.get("opcode") if instructions else None
    return (
        _contains_position(state, node) == 0,
        len(state.cfg_predecessors.get(node.stable_id, ())),
        successors,
        terminator,
    )


@dataclass(frozen=True)
class _CfgEdgeDifference:
    """One CFG edge change, with links that support the rendered claim."""

    before: tuple[str, str, str] | None
    after: tuple[str, str, str] | None
    link_indices: tuple[int, ...]


def _cfg_edge_differences(
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
) -> tuple[
    tuple[_CfgEdgeDifference, ...],
    tuple[_CfgEdgeDifference, ...],
    tuple[_CfgEdgeDifference, ...],
]:
    """Compare CFG edges after translating endpoints through block links.

    A correspondence is between nodes, while a CFG claim is about directed,
    labelled edges.  This projection retains additions and removals incident to
    unmatched blocks, and recognises changed labels on otherwise matched
    endpoints as relabels rather than unrelated edge changes.
    """

    from_to: dict[str, tuple[str, int]] = {}
    to_from: dict[str, tuple[str, int]] = {}
    from_link_indices: dict[str, int] = {}
    to_link_indices: dict[str, int] = {}
    for index, link in enumerate(correspondence.links):
        for node_id in link.from_node_ids:
            if from_state.by_id[node_id].kind == "BasicBlock":
                from_link_indices[node_id] = index
        for node_id in link.to_node_ids:
            if to_state.by_id[node_id].kind == "BasicBlock":
                to_link_indices[node_id] = index
        if len(link.from_node_ids) == 1 and len(link.to_node_ids) == 1:
            from_id, to_id = link.from_node_ids[0], link.to_node_ids[0]
            if (
                from_state.by_id[from_id].kind == "BasicBlock"
                and to_state.by_id[to_id].kind == "BasicBlock"
            ):
                from_to[from_id] = (to_id, index)
                to_from[to_id] = (from_id, index)

    def from_key(edge_from: str, edge_to: str, label: str) -> tuple[str | None, str | None, str]:
        return (
            from_to.get(edge_from, (None, -1))[0],
            from_to.get(edge_to, (None, -1))[0],
            label,
        )

    before_edges = [
        (from_key(edge.from_id, edge.to_id, edge.label or ""), edge)
        for edge in from_state.edges
        if edge.relation == "controlFlow"
    ]
    after_edges = [
        ((edge.from_id, edge.to_id, edge.label or ""), edge)
        for edge in to_state.edges
        if edge.relation == "controlFlow"
    ]
    # Edges whose endpoints have no block counterpart map to None and never match.
    after_counts: Counter[tuple[str | None, str | None, str]] = Counter(key for key, _ in after_edges)
    removed: list[tuple[tuple[str | None, str | None, str], Edge]] = []
    for key, edge in before_edges:
        if after_counts[key]:
            after_counts[key] -= 1
        else:
            removed.append((key, edge))

    before_counts = Counter(key for key, _ in before_edges)
    added: list[tuple[tuple[str, str, str], Edge]] = []
    for key, edge in after_edges:
        if before_counts[key]:
            before_counts[key] -= 1
        else:
            added.append((key, edge))

    def describe_before(edge: Edge) -> tuple[str, str, str]:
        return (
            from_state.by_id[edge.from_id].display_name,
            from_state.by_id[edge.to_id].display_name,
            edge.label or "",
        )

    def describe_after(edge: Edge) -> tuple[str, str, str]:
        return (
            to_state.by_id[edge.from_id].display_name,
            to_state.by_id[edge.to_id].display_name,
            edge.label or "",
        )

    def links_for(before: Edge | None, after: Edge | None) -> tuple[int, ...]:
        indices: set[int] = set()
        if before is not None:
            for node_id in (before.from_id, before.to_id):
                if node_id in from_link_indices:
                    indices.add(from_link_indices[node_id])
        if after is not None:
            for node_id in (after.from_id, after.to_id):
                if node_id in to_link_indices:
                    indices.add(to_link_indices[node_id])
        return tuple(sorted(indices))

    relabelled: list[_CfgEdgeDifference] = []
    remaining_removed: list[tuple[tuple[str | None, str | None, str], Edge]] = []
    remaining_added = list(added)
    for key, before in removed:
        endpoints = key[:2]
        match_index = next(
            (
                index
                for index, (after_key, _) in enumerate(remaining_added)
                if after_key[:2] == endpoints
            ),
            None,
        )
        if match_index is None:
            remaining_removed.append((key, before))
            continue
        _, after = remaining_added.pop(match_index)
        relabelled.append(
            _CfgEdgeDifference(
                describe_before(before),
                describe_after(after),
                links_for(before, after),
            )
        )

    return (
        tuple(
            _CfgEdgeDifference(describe_before(before), None, links_for(before, None))
            for _, before in remaining_removed
        ),
        tuple(
            _CfgEdgeDifference(None, describe_after(after), links_for(None, after))
            for _, after in remaining_added
        ),
        tuple(relabelled),
    )


def _format_cfg_edge(edge: tuple[str, str, str]) -> str:
    return f"{edge[0]} → {edge[1]} [{edge[2]}]"


def _cfg_difference_summary_item(
    removed: tuple[_CfgEdgeDifference, ...],
    added: tuple[_CfgEdgeDifference, ...],
    relabelled: tuple[_CfgEdgeDifference, ...],
) -> SummaryItem | None:
    """Render named CFG edge differences with their supporting block links."""

    differences = removed + added + relabelled
    if not differences:
        return None
    parts: list[str] = []
    if removed:
        parts.append(
            "removed "
            + ", ".join(_format_cfg_edge(item.before) for item in removed if item.before)
        )
    if added:
        parts.append(
            "added "
            + ", ".join(_format_cfg_edge(item.after) for item in added if item.after)
        )
    if relabelled:
        parts.append(
            "relabelled " + ", ".join(
                f"{item.before[0]} → {item.before[1]} [{item.before[2]} → {item.after[2]}]"
                for item in relabelled
                if item.before and item.after
            )
        )
    return SummaryItem(
        "CFG edges changed: " + "; ".join(parts) + ".",
        tuple(sorted({index for item in differences for index in item.link_indices})),
    )


def _instruction_exact_signature(state: StateGraph, node: Node) -> tuple[object, ...]:
    predecessors = tuple(
        sorted(
            str(state.by_id[edge.from_id].attributes.get("opcode"))
            for edge in state.value_flow_predecessors.get(node.stable_id, ())
        )
    )
    return (
        node.attributes.get("opcode"),
        node.attributes.get("source"),
        _normalised_instruction_text(node),
        predecessors,
    )


def _normalised_instruction_text(node: Node) -> str:
    text = str(node.attributes.get("text", ""))
    text = _DEBUG_REF_RE.sub("", text)
    text = re.sub(r"^%[-A-Za-z0-9_.$]+\s*=\s*", "", text)
    return _VALUE_NAME_RE.sub("%value", " ".join(text.split()))


def _instruction_relation(from_node: Node, to_node: Node) -> Relation:
    """Describe an instruction pair independently of the evidence used to find it."""

    from_text = _display_instruction_text(from_node)
    to_text = _display_instruction_text(to_node)
    if from_text == to_text:
        return "same"
    if _instruction_without_result_name(from_text) == _instruction_without_result_name(to_text):
        return "renamed"
    return "changed"


def _display_instruction_text(node: Node) -> str:
    """Return recorded instruction text with non-semantic debug metadata removed."""

    text = _DEBUG_REF_RE.sub("", str(node.attributes.get("text", "")))
    return " ".join(text.split())


def _instruction_without_result_name(text: str) -> str:
    """Remove only an SSA result definition, retaining all operation operands."""

    return re.sub(r"^%[-A-Za-z0-9_.$]+\s*=\s*", "", text)


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
                ("No structural or value-level changes were detected across these recorded endpoints."
                 if isinstance(correspondence, ComposedCorrespondence) or (step and step.kind == "recompiled")
                 else "No structural or value-level changes were detected; this pass is retained as a no-op."),
                all_indices,
            )
        )
    else:
        for relation, verb in (("removed", "removed"), ("added", "added")):
            for kind in ("Function", "BasicBlock", "Instruction"):
                for confidence in ("exact", "approximate", "plausible"):
                    indices = _link_indices(
                        correspondence,
                        from_state,
                        to_state,
                        relation=relation,
                        kind=kind,
                        confidence=confidence,
                    )
                    if indices:
                        noun = _plural(_kind_label(kind), len(indices))
                        items.append(
                            SummaryItem(
                                f"{len(indices)} {noun} {verb}"
                                f"{_confidence_phrase(correspondence, indices)}.",
                                indices,
                            )
                        )

        for kind in ("BasicBlock", "Instruction"):
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
                    kind=kind,
                )
                if indices:
                    confidence = _confidence_phrase(correspondence, indices)
                    verb = "was" if len(indices) == 1 else "were"
                    noun = _plural(_kind_label(kind), len(indices))
                    items.append(
                        SummaryItem(
                            f"{len(indices)} {noun} {verb} linked as {label}{confidence}.",
                            indices,
                        )
                    )

        for kind in ("BasicBlock", "Instruction"):
            for relation in ("split", "merged"):
                indices = _link_indices(
                    correspondence, from_state, to_state, relation=relation, kind=kind
                )
                if indices:
                    before_count = sum(len(correspondence.links[i].from_node_ids) for i in indices)
                    after_count = sum(len(correspondence.links[i].to_node_ids) for i in indices)
                    label = _kind_label(kind)
                    endpoint_label = "instructions" if kind == "Instruction" else _plural(label, after_count)
                    items.append(SummaryItem(
                        f"{len(indices)} {label} groups {relation}: "
                        f"{before_count} → {after_count} {endpoint_label}"
                        f"{_confidence_phrase(correspondence, indices)}.", indices))

        changed_instructions = _link_indices(
            correspondence,
            from_state,
            to_state,
            relation="changed",
            kind="Instruction",
        )
        if changed_instructions:
            items.append(
                SummaryItem(
                    f"{len(changed_instructions)} {_plural('instruction', len(changed_instructions))} "
                    f"changed{_confidence_phrase(correspondence, changed_instructions)}.",
                    changed_instructions,
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
        if basic_block_indices:
            removed_edges, added_edges, relabelled_edges = _cfg_edge_differences(
                correspondence, from_state, to_state
            )
            edge_difference_item = _cfg_difference_summary_item(
                removed_edges, added_edges, relabelled_edges
            )
            if edge_difference_item is not None:
                items.append(edge_difference_item)
            else:
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
    if confidences == {"plausible"}:
        return " with plausible but unconfirmed correspondence evidence"
    return " with mixed-confidence correspondence evidence"


def _link_kind(link: Link, from_state: StateGraph, to_state: StateGraph) -> str:
    if link.from_node_ids:
        return from_state.by_id[link.from_node_ids[0]].kind
    return to_state.by_id[link.to_node_ids[0]].kind


def _plural(noun: str, count: int) -> str:
    return noun if count == 1 else f"{noun}s"


def _kind_label(kind: str) -> str:
    return "basic block" if kind == "BasicBlock" else kind.lower()
