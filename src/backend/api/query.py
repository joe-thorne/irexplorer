"""Read-only query service over pre-baked optimisation model records."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from src.backend.analysis.compare import ComparisonSummary, summarise_correspondence
from src.backend.analysis.curated import load_prebaked_curated_correspondence
from src.backend.ingest.curated import load_prebaked_curated_timeline
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import Node, SourceLocation, StateGraph
from src.backend.model.timeline import OptimisationTimeline
from src.backend.toolchain import curated


class QueryError(ValueError):
    """Raised when a query cannot be satisfied from the current session."""


@dataclass
class SessionState:
    """In-memory UI focus over immutable, pre-baked model records."""

    example_id: str
    timeline: OptimisationTimeline
    correspondence: Correspondence
    current_ordinal: int = 0
    focused_node_id: str | None = None


class QueryService:
    """The model-query boundary consumed by the localhost browser API."""

    def __init__(self) -> None:
        self._session: SessionState | None = None

    def list_examples(self) -> dict[str, Any]:
        return {"examples": list(curated.list_examples())}

    def load_example(self, example_id: str) -> dict[str, Any]:
        try:
            timeline = load_prebaked_curated_timeline(example_id)
            correspondence = load_prebaked_curated_correspondence(example_id)
        except (ValueError, RuntimeError) as exc:
            raise QueryError(str(exc)) from exc
        self._session = SessionState(example_id, timeline, correspondence)
        return self.session()

    def session(self) -> dict[str, Any]:
        session = self._require_session()
        return {
            "exampleId": session.example_id,
            "currentOrdinal": session.current_ordinal,
            "focusedNodeId": session.focused_node_id,
            "states": self.list_states()["states"],
        }

    def set_focus(self, ordinal: int, node_id: str | None = None) -> dict[str, Any]:
        session = self._require_session()
        state = self._state(ordinal)
        if node_id is not None and node_id not in state.by_id:
            raise QueryError(f"unknown node in state {ordinal}: {node_id}")
        session.current_ordinal = ordinal
        session.focused_node_id = node_id
        return self.session()

    def list_states(self) -> dict[str, Any]:
        session = self._require_session()
        return {
            "states": [
                {
                    "ordinal": state.ordinal,
                    "stateId": state.state_id,
                    "originCommand": state.origin_command,
                }
                for state in session.timeline.states
            ]
        }

    def ir(self, ordinal: int) -> dict[str, Any]:
        state = self._state(ordinal)
        functions = []
        for function_id in state.contains_children.get("module", ()):
            function = state.by_id[function_id]
            if function.kind != "Function":
                continue
            blocks = []
            for block_id in state.contains_children.get(function_id, ()):
                block = state.by_id[block_id]
                blocks.append(
                    {
                        "id": block_id,
                        "label": block.display_name,
                        "instructions": [
                            _instruction_view(state.by_id[instruction_id])
                            for instruction_id in state.contains_children.get(block_id, ())
                        ],
                    }
                )
            functions.append(
                {
                    "id": function_id,
                    "name": function.display_name,
                    "signature": function.attributes.get("signature"),
                    "blocks": blocks,
                }
            )
        return {"ordinal": state.ordinal, "stateId": state.state_id, "functions": functions}

    def cfg(self, ordinal: int, function_id: str) -> dict[str, Any]:
        state = self._state(ordinal)
        function = state.by_id.get(function_id)
        if function is None or function.kind != "Function":
            raise QueryError(f"unknown function in state {ordinal}: {function_id}")
        block_ids = state.contains_children.get(function_id, ())
        block_set = set(block_ids)
        return {
            "ordinal": ordinal,
            "functionId": function_id,
            "blocks": [
                {"id": block_id, "label": state.by_id[block_id].display_name}
                for block_id in block_ids
            ],
            "edges": [
                {"fromId": edge.from_id, "toId": edge.to_id, "label": edge.label}
                for block_id in block_ids
                for edge in state.cfg_successors.get(block_id, ())
                if edge.to_id in block_set
            ],
        }

    def children(self, ordinal: int, node_id: str) -> dict[str, Any]:
        state = self._state(ordinal)
        self._node(state, node_id)
        return {
            "ordinal": ordinal,
            "nodeId": node_id,
            "children": [
                _node_view(state.by_id[child_id])
                for child_id in state.contains_children.get(node_id, ())
            ],
        }

    def parent(self, ordinal: int, node_id: str) -> dict[str, Any]:
        state = self._state(ordinal)
        self._node(state, node_id)
        parent_id = state.contains_parent.get(node_id)
        return {
            "ordinal": ordinal,
            "nodeId": node_id,
            "parent": _node_view(state.by_id[parent_id]) if parent_id is not None else None,
        }

    def step(self, from_ordinal: int = 0) -> dict[str, Any]:
        session = self._require_session()
        if from_ordinal != 0:
            raise QueryError(f"no pre-baked step from ordinal {from_ordinal}")
        step = session.timeline.steps[from_ordinal]
        return {
            "fromOrdinal": step.from_ordinal,
            "toOrdinal": step.to_ordinal,
            "kind": step.kind,
            "origin": {
                "command": step.origin.command,
                "passName": step.origin.pass_name,
                "level": step.origin.level,
            },
        }

    def counterparts(self, ordinal: int, node_id: str) -> dict[str, Any]:
        session = self._require_session()
        state = self._state(ordinal)
        self._node(state, node_id)
        if ordinal == session.correspondence.from_ordinal:
            link = session.correspondence.links_from.get(node_id)
            counterpart_ordinal = session.correspondence.to_ordinal
        elif ordinal == session.correspondence.to_ordinal:
            link = session.correspondence.links_to.get(node_id)
            counterpart_ordinal = session.correspondence.from_ordinal
        else:
            raise QueryError(f"no correspondence available for state {ordinal}")
        if link is None:
            raise QueryError(f"node is outside the correspondence coverage: {node_id}")
        counterpart_state = self._state(counterpart_ordinal)
        counterpart_ids = (
            link.to_node_ids
            if ordinal == session.correspondence.from_ordinal
            else link.from_node_ids
        )
        return {
            "ordinal": ordinal,
            "nodeId": node_id,
            "counterpartOrdinal": counterpart_ordinal,
            "relation": link.relation,
            "confidence": link.confidence,
            "evidence": link.evidence,
            "counterparts": [
                _node_view(counterpart_state.by_id[counterpart_id])
                for counterpart_id in counterpart_ids
            ],
        }

    def summary(self, from_ordinal: int = 0) -> dict[str, Any]:
        session = self._require_session()
        if from_ordinal != 0:
            raise QueryError(f"no pre-baked summary available from ordinal {from_ordinal}")
        step = session.timeline.steps[from_ordinal]
        summary = summarise_correspondence(
            session.correspondence,
            session.timeline.state(step.from_ordinal),
            session.timeline.state(step.to_ordinal),
            step,
        )
        return _summary_view(summary)

    def _require_session(self) -> SessionState:
        if self._session is None:
            raise QueryError("no curated example is loaded")
        return self._session

    def _state(self, ordinal: int) -> StateGraph:
        try:
            return self._require_session().timeline.state(ordinal)
        except ValueError as exc:
            raise QueryError(str(exc)) from exc

    @staticmethod
    def _node(state: StateGraph, node_id: str) -> Node:
        try:
            return state.by_id[node_id]
        except KeyError as exc:
            raise QueryError(f"unknown node in state {state.ordinal}: {node_id}") from exc


def _instruction_view(node: Node) -> dict[str, Any]:
    return {
        **_node_view(node),
        "text": node.attributes.get("text"),
        "opcode": node.attributes.get("opcode"),
        "result": node.attributes.get("result"),
        "source": _source_view(node.attributes.get("source")),
    }


def _node_view(node: Node) -> dict[str, Any]:
    return {"id": node.stable_id, "kind": node.kind, "displayName": node.display_name}


def _source_view(location: SourceLocation | None) -> dict[str, Any] | None:
    if location is None:
        return None
    return {"file": location.file, "line": location.line, "column": location.column}


def _summary_view(summary: ComparisonSummary) -> dict[str, Any]:
    return {
        "context": summary.context,
        "items": [
            {"text": item.text, "linkIndices": list(item.link_indices)}
            for item in summary.items
        ],
    }
