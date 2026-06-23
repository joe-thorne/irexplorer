"""Immutable internal graph records and validation."""

from __future__ import annotations

from dataclasses import dataclass, field
from types import MappingProxyType
from typing import Any, Iterable, Mapping


class ModelValidationError(ValueError):
    """Raised when a model record violates the Layer 3 invariants."""


@dataclass(frozen=True)
class SourceLocation:
    file: str
    line: int
    column: int


@dataclass(frozen=True)
class Remark:
    pass_name: str
    name: str
    function: str
    location: SourceLocation | None
    raw: str


@dataclass(frozen=True)
class Node:
    stable_id: str
    kind: str
    display_name: str
    attributes: Mapping[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        object.__setattr__(self, "attributes", MappingProxyType(dict(self.attributes)))


@dataclass(frozen=True)
class Edge:
    from_id: str
    to_id: str
    relation: str
    label: str | None = None
    order: int | None = None


@dataclass(frozen=True)
class StateGraph:
    ordinal: int
    state_id: str
    nodes: tuple[Node, ...]
    edges: tuple[Edge, ...]
    source_filename: str | None = None
    target_triple: str | None = None
    target_datalayout: str | None = None
    origin_command: str | None = None
    remarks: tuple[Remark, ...] = ()

    def validate(self) -> None:
        validate_state_graph(self)

    @property
    def by_id(self) -> dict[str, Node]:
        return {node.stable_id: node for node in self.nodes}

    @property
    def contains_children(self) -> dict[str, tuple[str, ...]]:
        children: dict[str, list[tuple[int, str]]] = {}
        for edge in self.edges:
            if edge.relation == "contains":
                if edge.order is None:
                    raise ModelValidationError("contains edge missing sibling order")
                children.setdefault(edge.from_id, []).append((edge.order, edge.to_id))
        return {
            parent: tuple(child for _, child in sorted(items))
            for parent, items in children.items()
        }

    @property
    def contains_parent(self) -> dict[str, str]:
        parents: dict[str, str] = {}
        for edge in self.edges:
            if edge.relation == "contains":
                parents[edge.to_id] = edge.from_id
        return parents

    @property
    def cfg_successors(self) -> dict[str, tuple[Edge, ...]]:
        successors: dict[str, list[Edge]] = {}
        for edge in self.edges:
            if edge.relation == "controlFlow":
                successors.setdefault(edge.from_id, []).append(edge)
        return {block_id: tuple(edges) for block_id, edges in successors.items()}

    @property
    def cfg_predecessors(self) -> dict[str, tuple[Edge, ...]]:
        predecessors: dict[str, list[Edge]] = {}
        for edge in self.edges:
            if edge.relation == "controlFlow":
                predecessors.setdefault(edge.to_id, []).append(edge)
        return {block_id: tuple(edges) for block_id, edges in predecessors.items()}


def validate_state_graph(graph: StateGraph) -> None:
    by_id = _validate_unique_ids(graph.nodes)
    module_ids = [node.stable_id for node in graph.nodes if node.kind == "Module"]
    if len(module_ids) != 1:
        raise ModelValidationError(f"expected exactly one Module node, found {len(module_ids)}")
    root_id = module_ids[0]

    _validate_edge_endpoints(graph.edges, by_id)
    parent_by_id, children_by_id = _validate_containment_tree(graph.edges, by_id, root_id)
    function_by_block = _validate_containment_kinds(by_id, parent_by_id, children_by_id, root_id)
    _validate_control_flow(graph.edges, by_id, function_by_block)
    _validate_blocks(graph.edges, by_id, children_by_id, function_by_block)


def _validate_unique_ids(nodes: Iterable[Node]) -> dict[str, Node]:
    by_id: dict[str, Node] = {}
    for node in nodes:
        if node.stable_id in by_id:
            raise ModelValidationError(f"duplicate stableId: {node.stable_id}")
        by_id[node.stable_id] = node
    return by_id


def _validate_edge_endpoints(edges: Iterable[Edge], by_id: Mapping[str, Node]) -> None:
    for edge in edges:
        if edge.relation == "sourceMap":
            if edge.from_id not in by_id:
                raise ModelValidationError(f"sourceMap edge has unknown source: {edge.from_id}")
            if by_id[edge.from_id].kind != "Instruction":
                raise ModelValidationError("sourceMap edge must start at an Instruction")
            continue
        if edge.from_id not in by_id or edge.to_id not in by_id:
            raise ModelValidationError(
                f"{edge.relation} edge references unknown endpoint: {edge.from_id}->{edge.to_id}"
            )


def _validate_containment_tree(
    edges: Iterable[Edge],
    by_id: Mapping[str, Node],
    root_id: str,
) -> tuple[dict[str, str], dict[str, tuple[str, ...]]]:
    parent_by_id: dict[str, str] = {}
    ordered_children: dict[str, list[tuple[int, str]]] = {}

    for edge in edges:
        if edge.relation != "contains":
            continue
        if edge.order is None:
            raise ModelValidationError("contains edge missing sibling order")
        if edge.to_id in parent_by_id:
            raise ModelValidationError(f"node has multiple contains parents: {edge.to_id}")
        parent_by_id[edge.to_id] = edge.from_id
        ordered_children.setdefault(edge.from_id, []).append((edge.order, edge.to_id))

    for node_id in by_id:
        if node_id == root_id:
            continue
        if node_id not in parent_by_id:
            raise ModelValidationError(f"node has no contains parent: {node_id}")

    children_by_id: dict[str, tuple[str, ...]] = {}
    for parent_id, children in ordered_children.items():
        orders = sorted(order for order, _ in children)
        expected = list(range(len(orders)))
        if orders != expected:
            raise ModelValidationError(f"contains children of {parent_id} are not densely ordered")
        children_by_id[parent_id] = tuple(child_id for _, child_id in sorted(children))

    for node_id in by_id:
        seen: set[str] = set()
        current = node_id
        while current != root_id:
            if current in seen:
                raise ModelValidationError(f"contains cycle reaches {current}")
            seen.add(current)
            current = parent_by_id[current]

    return parent_by_id, children_by_id


def _validate_containment_kinds(
    by_id: Mapping[str, Node],
    parent_by_id: Mapping[str, str],
    children_by_id: Mapping[str, tuple[str, ...]],
    root_id: str,
) -> dict[str, str]:
    allowed = {
        "Module": {"Function"},
        "Function": {"BasicBlock"},
        "BasicBlock": {"Instruction"},
        "Instruction": set(),
    }
    function_by_block: dict[str, str] = {}

    for parent_id, child_ids in children_by_id.items():
        parent_kind = by_id[parent_id].kind
        if parent_kind not in allowed:
            raise ModelValidationError(f"unknown node kind: {parent_kind}")
        for child_id in child_ids:
            child_kind = by_id[child_id].kind
            if child_kind not in allowed[parent_kind]:
                raise ModelValidationError(
                    f"invalid containment {parent_kind}->{child_kind}: {parent_id}->{child_id}"
                )

    for node in by_id.values():
        if node.kind == "BasicBlock":
            function_id = parent_by_id[node.stable_id]
            if by_id[function_id].kind != "Function":
                raise ModelValidationError(f"block parent is not a function: {node.stable_id}")
            function_by_block[node.stable_id] = function_id
        elif node.kind not in allowed:
            raise ModelValidationError(f"unknown node kind: {node.kind}")

    if by_id[root_id].kind != "Module":
        raise ModelValidationError("contains root is not a Module")
    return function_by_block


def _validate_control_flow(
    edges: Iterable[Edge],
    by_id: Mapping[str, Node],
    function_by_block: Mapping[str, str],
) -> None:
    for edge in edges:
        if edge.relation != "controlFlow":
            continue
        if by_id[edge.from_id].kind != "BasicBlock" or by_id[edge.to_id].kind != "BasicBlock":
            raise ModelValidationError("controlFlow edge must connect BasicBlock nodes")
        if function_by_block[edge.from_id] != function_by_block[edge.to_id]:
            raise ModelValidationError(
                f"controlFlow edge crosses functions: {edge.from_id}->{edge.to_id}"
            )


def _validate_blocks(
    edges: Iterable[Edge],
    by_id: Mapping[str, Node],
    children_by_id: Mapping[str, tuple[str, ...]],
    function_by_block: Mapping[str, str],
) -> None:
    cfg_edges = [edge for edge in edges if edge.relation == "controlFlow"]
    pred_by_block: dict[str, list[Edge]] = {}
    succ_by_block: dict[str, list[Edge]] = {}
    for edge in cfg_edges:
        pred_by_block.setdefault(edge.to_id, []).append(edge)
        succ_by_block.setdefault(edge.from_id, []).append(edge)

    block_label_by_id = {
        node.stable_id: str(node.attributes["label"])
        for node in by_id.values()
        if node.kind == "BasicBlock"
    }

    for function_id, block_ids in _blocks_by_function(function_by_block).items():
        if not block_ids:
            raise ModelValidationError(f"function has no basic blocks: {function_id}")
        entry_id = block_ids[0]
        if pred_by_block.get(entry_id):
            raise ModelValidationError(f"entry block has CFG predecessor: {entry_id}")

    for block_id in block_label_by_id:
        instruction_ids = children_by_id.get(block_id, ())
        terminators = [
            by_id[instruction_id]
            for instruction_id in instruction_ids
            if bool(by_id[instruction_id].attributes.get("is_terminator"))
        ]
        if len(terminators) != 1:
            raise ModelValidationError(
                f"block must have exactly one terminator: {block_id} has {len(terminators)}"
            )
        if terminators[0].stable_id != instruction_ids[-1]:
            raise ModelValidationError(f"block terminator is not last instruction: {block_id}")

        expected = tuple(terminators[0].attributes.get("successors", ()))
        actual = tuple((edge.to_id, edge.label) for edge in succ_by_block.get(block_id, ()))
        if actual != expected:
            raise ModelValidationError(f"CFG does not agree with terminator in block {block_id}")

        pred_labels = {block_label_by_id[edge.from_id] for edge in pred_by_block.get(block_id, ())}
        for instruction_id in instruction_ids:
            node = by_id[instruction_id]
            if node.attributes.get("opcode") != "phi":
                continue
            incoming = set(node.attributes.get("incoming_blocks", ()))
            if incoming != pred_labels:
                raise ModelValidationError(
                    f"phi incoming blocks disagree with CFG in {block_id}: "
                    f"{sorted(incoming)} != {sorted(pred_labels)}"
                )


def _blocks_by_function(function_by_block: Mapping[str, str]) -> dict[str, list[str]]:
    blocks: dict[str, list[str]] = {}
    for block_id, function_id in function_by_block.items():
        blocks.setdefault(function_id, []).append(block_id)
    return blocks
