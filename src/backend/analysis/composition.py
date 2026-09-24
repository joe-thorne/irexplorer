"""Composed correspondences for non-adjacent spans, chained from stored correspondences."""

from __future__ import annotations

from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from types import MappingProxyType

from src.backend.model.correspondence import (
    Confidence,
    Correspondence,
    Link,
    Relation,
    validate_correspondence,
)
from src.backend.model.graph import StateGraph
from src.backend.model.timeline import OptimisationTimeline


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
