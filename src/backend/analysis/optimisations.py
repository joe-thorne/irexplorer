"""Small, conservative transformation detectors over recorded adjacent states.

Names describe observed rewrites, not everything a compiler pass might do.
No detector runs across independently recompiled output.
"""
from __future__ import annotations

import re

from src.backend.model.graph import Node, StateGraph
from src.backend.model.correspondence import Correspondence
from src.backend.model.timeline import OptimisationTimeline, PassStep

_BINARY = re.compile(
    r"^(?:%[-\w.$]+\s*=\s*)?(add|sub|mul|shl|lshr|ashr|udiv|sdiv)"
    r"(?:\s+(?:nsw|nuw|exact))*\s+i(\d+)\s+([^,]+),\s*([^,]+)"
)
_PURE = {"add", "sub", "mul", "shl", "lshr", "ashr", "and", "or", "xor",
         "icmp", "sext", "zext", "trunc", "getelementptr", "select"}


def _binary(node):
    match = _BINARY.match(node.attributes.get("text", ""))
    return tuple(part.strip() for part in match.groups()) if match else None


def _function(state, node):
    current = node.stable_id
    while state.by_id[current].kind != "Function":
        current = state.contains_parent[current]
    return current


def _definitions(state, node):
    function = _function(state, node)
    return {n.attributes["result"]: n for n in state.nodes
            if n.kind == "Instruction" and n.attributes.get("result")
            and _function(state, n) == function}


def _without_debug(text):
    return re.sub(r",?\s*!dbg\s*!\d+", "", text).strip()


def _folded_constant(node):
    expression = _binary(node)
    if not expression or expression[0] not in {"add", "sub", "mul"}:
        return None
    opcode, bits, left, right = expression
    try:
        left, right, bits = int(left), int(right), int(bits)
    except ValueError:
        return None
    # Stay inside the signed range; wrapping/poison cases need richer analysis.
    if not 1 <= bits <= 128:
        return None
    result = {"add": lambda: left + right, "sub": lambda: left - right,
              "mul": lambda: left * right}[opcode]()
    if not -(1 << (bits - 1)) <= result < (1 << (bits - 1)):
        return None
    if "nuw" in node.attributes.get("text", "") and (left < 0 or right < 0 or result < 0):
        return None
    return result


def detect_optimisations(before: StateGraph, after: StateGraph,
                         correspondence: Correspondence, step: PassStep) -> list[dict]:
    if step.kind != "derived":
        return []
    events = []

    def emit(name, purpose, change, old, new=(), certainty="detected"):
        events.append(dict(
            name=name, purpose=purpose, change=change, certainty=certainty,
            fromOrdinal=before.ordinal, toOrdinal=after.ordinal,
            fromStateId=before.state_id, toStateId=after.state_id,
            fromNodeIds=list(dict.fromkeys(n.stable_id for n in old)),
            toNodeIds=list(dict.fromkeys(n.stable_id for n in new)),
        ))

    for link in correspondence.links:
        old = [before.by_id[node] for node in link.from_node_ids]
        new = [after.by_id[node] for node in link.to_node_ids]
        if not old or any(n.kind != "Instruction" for n in old + new):
            continue
        if len(old) == len(new) == 1 and link.confidence != "none":
            a, b = _binary(old[0]), _binary(new[0])
            if a and b and a[1:3] == b[1:3]:
                try:
                    constant, shift = int(a[3]), int(b[3])
                except ValueError:
                    constant = shift = None
                if (constant is not None and shift is not None and 0 <= shift < int(a[1])
                        and constant == 1 << shift
                        and ((a[0] == "mul" and b[0] == "shl")
                             or (a[0] in {"sdiv", "udiv"} and b[0] in {"lshr", "ashr"}))):
                    action = "Multiplication" if a[0] == "mul" else "Division"
                    direction = "left" if b[0] == "shl" else "right"
                    emit("Strength reduction", "Replace arithmetic with a simpler operation.",
                         f"{action} by {constant} becomes a {direction} shift by {shift}.", old, new)
                if a[0] == "sub" and b[0] == "add" and constant is not None and shift == -constant:
                    emit("Arithmetic canonicalisation", "Put equivalent arithmetic into a standard form.",
                         f"Subtracting {constant} becomes adding {-constant}.", old, new)

        # The grouped index rewrite exposes the removed conversion and the
        # widened PHI that now feeds the address directly.
        if link.relation == "merged" and link.confidence != "none" and len(new) == 1:
            conversions = [n for n in old if n.attributes.get("opcode") in {"sext", "zext"}]
            if (conversions and new[0].attributes.get("opcode") == "getelementptr"
                    and any(n.attributes.get("opcode") == "getelementptr" for n in old)):
                definitions = _definitions(after, new[0])
                wide_phis = [definitions[value] for value in new[0].attributes.get("operands", ())
                             if value in definitions and definitions[value].attributes.get("opcode") == "phi"
                             and "phi i64 " in definitions[value].attributes.get("text", "")]
                if wide_phis:
                    emit("Induction-variable widening", "Avoid converting the loop index on each iteration.",
                         "The address uses a 64-bit loop index directly; the separate index extension disappears.",
                         old, new, "likely")

        if link.relation == "removed" and len(old) == 1:
            node = old[0]
            expression = _binary(node)
            definitions = _definitions(before, node)
            value = _folded_constant(node)
            users = [before.by_id[e.to_id] for e in before.value_flow_successors.get(node.stable_id, ())]
            replacements = []
            if value is not None and users:
                for user in users:
                    mapped = correspondence.links_from.get(user.stable_id)
                    if not mapped or mapped.confidence == "none" or len(mapped.to_node_ids) != 1:
                        break
                    target = after.by_id[mapped.to_node_ids[0]]
                    expected = re.sub(re.escape(node.attributes["result"]) + r"(?![-\w.$])",
                                      str(value), _without_debug(user.attributes["text"]))
                    if expected != _without_debug(target.attributes.get("text", "")):
                        break
                    replacements.append(target)
                if len(replacements) == len(users):
                    emit("Constant folding", "Evaluate constant arithmetic at compile time.",
                         f"The {node.attributes['opcode']} calculation becomes the constant {value} in its recorded uses.",
                         [node, *users], replacements)
            # Recognise the expression itself, then corroborate its disappearance.
            # Do not claim constant propagation or folding merely from an absent node.
            if expression and expression[0] == "sub":
                left, right = expression[2:]
                left_node, right_node = definitions.get(left), definitions.get(right)
                left_expr = _binary(left_node) if left_node else None
                right_expr = _binary(right_node) if right_node else None
                equivalent = left == right or (left_expr is not None and left_expr == right_expr)
                if equivalent:
                    operands = [n for n in (left_node, right_node) if n]
                    emit("Algebraic simplification", "Remove arithmetic whose result is already known.",
                         "Two identical values are subtracted, giving zero; this subtraction is absent in the later state.",
                         [node, *operands], certainty="likely")
            if (node.attributes.get("opcode") in _PURE
                    and not before.value_flow_successors.get(node.stable_id)
                    and link.confidence == "exact"):
                emit("Dead-code elimination", "Remove computations whose results are unused.",
                     f"The unused {node.attributes['opcode']} instruction is removed.", old)

    # A removed PHI and a new select with the same two choices provide
    # evidence for if-conversion. A removed conditional branch corroborates it.
    for select in after.nodes:
        if select.attributes.get("opcode") != "select":
            continue
        match = re.search(r"select i1 (%[-\w.$]+), i\d+ ([^,]+), i\d+ ([^,]+)",
                          _without_debug(select.attributes.get("text", "")))
        if not match:
            continue
        condition, first, second = (part.strip() for part in match.groups())
        function_name = after.by_id[_function(after, select)].display_name
        candidates = []
        branches = []
        for node in before.nodes:
            if node.kind != "Instruction" or before.by_id[_function(before, node)].display_name != function_name:
                continue
            link = correspondence.links_from.get(node.stable_id)
            if not link or link.to_node_ids:
                continue
            if node.attributes.get("opcode") == "phi":
                choices = re.findall(r"\[\s*([^,]+),\s*%[-\w.$]+\s*\]", node.attributes.get("text", ""))
                if len(choices) == 2 and sorted(c.strip() for c in choices) == sorted([first, second]):
                    candidates.append(node)
            if (node.attributes.get("opcode") == "br"
                    and node.attributes.get("text", "").startswith(f"br i1 {condition},")):
                branches.append(node)
        if len(candidates) == 1 and len(branches) == 1:
            emit("If-conversion", "Choose a value without separate branch paths.",
                 f"The two-way value choice becomes a select instruction using {condition}.",
                 [candidates[0], branches[0]], [select], "likely")

    # Stack slots are examined as groups, so selecting a load/store explains the
    # storage rewrite too. Pass provenance corroborates, but cannot alone trigger it.
    if step.origin.pass_name == "mem2reg":
        for allocation in before.nodes:
            if allocation.attributes.get("opcode") != "alloca":
                continue
            pointer = allocation.attributes.get("result")
            users = [before.by_id[e.to_id] for e in before.value_flow_successors.get(allocation.stable_id, ())]
            if not users or any(n.attributes.get("opcode") not in {"load", "store"} for n in users):
                continue
            members = [allocation, *users]
            if not all(correspondence.links_from.get(n.stable_id)
                       and not correspondence.links_from[n.stable_id].to_node_ids for n in members):
                continue
            loads = sum(n.attributes["opcode"] == "load" for n in users)
            stores = len(users) - loads
            emit("Local-variable promotion", "Keep local values directly in SSA instead of stack memory.",
                 f"The {pointer} stack slot disappears, along with {loads} " 
                 f"{'load' if loads == 1 else 'loads'} and {stores} {'store' if stores == 1 else 'stores'}.",
                 members, certainty="likely")
    return events


def explain_comparison(timeline: OptimisationTimeline, correspondences, comparison) -> list[dict]:
    """Attach adjacent detections to the selected endpoint comparison's links.

    Carry membership through resolved links only. This retains distinct
    transformations at intermediate states without attributing them to one pass.
    """
    lower, higher = comparison.from_ordinal, comparison.to_ordinal
    if lower == higher:
        return []
    labels = {ordinal: {} for ordinal in range(lower, higher + 1)}
    for index, link in enumerate(comparison.links):
        for ordinal, ids in ((lower, link.from_node_ids), (higher, link.to_node_ids)):
            for node in ids:
                labels[ordinal].setdefault(node, set()).add(index)

    def propagate(ordinal, reverse=False):
        step = timeline.steps[ordinal]
        if step.kind != "derived":
            return
        origin, target = (ordinal + 1, ordinal) if reverse else (ordinal, ordinal + 1)
        for link in correspondences[ordinal].links:
            if link.confidence == "none":
                continue
            source_ids = link.to_node_ids if reverse else link.from_node_ids
            target_ids = link.from_node_ids if reverse else link.to_node_ids
            indices = set().union(*(labels[origin].get(node, set()) for node in source_ids))
            for node in target_ids:
                labels[target].setdefault(node, set()).update(indices)

    for ordinal in range(lower, higher):
        propagate(ordinal)
    for ordinal in range(higher - 1, lower - 1, -1):
        propagate(ordinal, True)
    events = []
    for ordinal in range(lower, higher):
        for event in detect_optimisations(timeline.state(ordinal), timeline.state(ordinal + 1),
                                          correspondences[ordinal], timeline.steps[ordinal]):
            indices = set()
            for state, ids in ((ordinal, event["fromNodeIds"]), (ordinal + 1, event["toNodeIds"])):
                for node in ids:
                    indices.update(labels[state].get(node, ()))
            if indices:
                events.append({**event, "linkIndices": sorted(indices)})
    return events
