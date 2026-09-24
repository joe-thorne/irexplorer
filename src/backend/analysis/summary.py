"""Evidence-backed summaries of one comparison, traceable to links and remarks."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass

from src.backend.analysis.compare import ComposedCorrespondence
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import Edge, StateGraph
from src.backend.model.timeline import PassStep


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
