"""CFG edge differences between two states, projected through block links."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from typing import NamedTuple

from src.backend.analysis.compare import ComposedCorrespondence
from src.backend.model.correspondence import Correspondence
from src.backend.model.graph import Edge, StateGraph


@dataclass(frozen=True)
class CfgEdgeDifference:
    """One CFG edge change, with links that support the rendered claim."""

    before: tuple[str, str, str] | None
    after: tuple[str, str, str] | None
    link_indices: tuple[int, ...]


class CfgEdgeDifferences(NamedTuple):
    """Every CFG edge change between two states, by kind of change."""

    removed: tuple[CfgEdgeDifference, ...]
    added: tuple[CfgEdgeDifference, ...]
    relabelled: tuple[CfgEdgeDifference, ...]


def cfg_edge_differences(
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
) -> CfgEdgeDifferences:
    """Compare CFG edges after translating endpoints through block links.

    A correspondence is between nodes, while a CFG claim is about directed,
    labelled edges.  This projection retains additions and removals incident to
    unmatched blocks, and recognises changed labels on otherwise matched
    endpoints as relabels rather than unrelated edge changes.
    """

    from_to: dict[str, tuple[str, int]] = {}
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

    relabelled: list[CfgEdgeDifference] = []
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
            CfgEdgeDifference(
                describe_before(before),
                describe_after(after),
                links_for(before, after),
            )
        )

    return CfgEdgeDifferences(
        removed=tuple(
            CfgEdgeDifference(describe_before(before), None, links_for(before, None))
            for _, before in remaining_removed
        ),
        added=tuple(
            CfgEdgeDifference(None, describe_after(after), links_for(None, after))
            for _, after in remaining_added
        ),
        relabelled=tuple(relabelled),
    )
