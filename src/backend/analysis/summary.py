"""Evidence-backed summaries of one comparison, traceable to links and remarks."""

from __future__ import annotations

from dataclasses import dataclass

from src.backend.analysis.cfg_diff import CfgEdgeDifference, cfg_edge_differences
from src.backend.analysis.compare import ComposedCorrespondence
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import StateGraph
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
            removed_edges, added_edges, relabelled_edges = cfg_edge_differences(
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


def _format_cfg_edge(edge: tuple[str, str, str]) -> str:
    return f"{edge[0]} → {edge[1]} [{edge[2]}]"


def _cfg_difference_summary_item(
    removed: tuple[CfgEdgeDifference, ...],
    added: tuple[CfgEdgeDifference, ...],
    relabelled: tuple[CfgEdgeDifference, ...],
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
