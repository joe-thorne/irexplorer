"""Immutable, coverage-complete links between adjacent optimisation states."""

from __future__ import annotations

from dataclasses import dataclass, field
from types import MappingProxyType
from typing import Literal, Mapping, Protocol

from src.backend.model.graph import ModelValidationError, StateGraph


Relation = Literal[
    "same",
    "renamed",
    "moved",
    "simplifiedInto",
    "promoted",
    "split",
    "merged",
    "added",
    "removed",
    "changed",
]
Confidence = Literal["exact", "approximate", "none"]


@dataclass(frozen=True)
class Link:
    """One confidence-bearing bipartite hyperedge between two state graphs."""

    from_node_ids: tuple[str, ...]
    to_node_ids: tuple[str, ...]
    relation: Relation
    confidence: Confidence
    evidence: str | None = None


@dataclass(frozen=True)
class Correspondence:
    """A separate overlay that accounts for every declared comparable node."""

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
        validate_correspondence(self, from_state, to_state)


class CorrespondenceView(Protocol):
    """The common read-only shape shared by stored and composed overlays."""

    from_ordinal: int
    to_ordinal: int
    covered_kinds: tuple[str, ...]
    links: tuple[Link, ...]


def validate_correspondence(
    correspondence: CorrespondenceView,
    from_state: StateGraph,
    to_state: StateGraph,
    *,
    require_adjacent: bool = True,
) -> None:
    """Enforce I9–I12 for a stored or derived correspondence view.

    Stored ``Correspondence`` records must be adjacent. Layer 4 uses the same
    coverage checks for its transient composed views, which deliberately span
    more than one adjacent pair and are never serialised as correspondences.
    """

    if correspondence.from_ordinal != from_state.ordinal:
        raise ModelValidationError("correspondence from ordinal does not match source state")
    if correspondence.to_ordinal != to_state.ordinal:
        raise ModelValidationError("correspondence to ordinal does not match target state")
    if require_adjacent and correspondence.to_ordinal != correspondence.from_ordinal + 1:
        raise ModelValidationError("correspondence must relate adjacent state ordinals")
    if not require_adjacent and correspondence.to_ordinal <= correspondence.from_ordinal:
        raise ModelValidationError("composed correspondence must advance in timeline order")
    if not correspondence.covered_kinds:
        raise ModelValidationError("correspondence must declare covered node kinds")

    covered_kinds = set(correspondence.covered_kinds)
    if "Module" in covered_kinds:
        raise ModelValidationError("Module nodes must not be included in correspondence coverage")

    expected_from = {
        node.stable_id for node in from_state.nodes if node.kind in covered_kinds
    }
    expected_to = {node.stable_id for node in to_state.nodes if node.kind in covered_kinds}
    seen_from: set[str] = set()
    seen_to: set[str] = set()

    for link in correspondence.links:
        _validate_link(link)
        for node_id in link.from_node_ids:
            node = from_state.by_id.get(node_id)
            if node is None:
                raise ModelValidationError(f"link references unknown source node: {node_id}")
            if node.kind not in covered_kinds:
                raise ModelValidationError(f"link source node outside coverage: {node_id}")
            if node_id in seen_from:
                raise ModelValidationError(f"source node appears in multiple links: {node_id}")
            seen_from.add(node_id)
        for node_id in link.to_node_ids:
            node = to_state.by_id.get(node_id)
            if node is None:
                raise ModelValidationError(f"link references unknown target node: {node_id}")
            if node.kind not in covered_kinds:
                raise ModelValidationError(f"link target node outside coverage: {node_id}")
            if node_id in seen_to:
                raise ModelValidationError(f"target node appears in multiple links: {node_id}")
            seen_to.add(node_id)

    if seen_from != expected_from:
        raise ModelValidationError("correspondence does not cover every declared source node")
    if seen_to != expected_to:
        raise ModelValidationError("correspondence does not cover every declared target node")


def _validate_link(link: Link) -> None:
    if not link.from_node_ids and not link.to_node_ids:
        raise ModelValidationError("link cannot have empty source and target sides")
    if link.relation not in {
        "same",
        "renamed",
        "moved",
        "simplifiedInto",
        "promoted",
        "split",
        "merged",
        "added",
        "removed",
        "changed",
    }:
        raise ModelValidationError(f"unknown link relation: {link.relation}")
    if link.confidence not in {"exact", "approximate", "none"}:
        raise ModelValidationError(f"unknown link confidence: {link.confidence}")
    if link.relation == "added" and link.from_node_ids:
        raise ModelValidationError("added link must have an empty source side")
    if link.relation == "removed" and link.to_node_ids:
        raise ModelValidationError("removed link must have an empty target side")
    if link.relation not in {"added", "removed"} and (
        not link.from_node_ids or not link.to_node_ids
    ):
        raise ModelValidationError("matched link must have source and target sides")
