"""Read-only query service over pre-baked optimisation model records."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

from src.backend.analysis.compare import (
    ComposedCorrespondence,
    ComparisonSummary,
    compose_timeline_correspondences,
    is_identity_correspondence,
    summarise_correspondence,
)
from src.backend.analysis.curated import load_prebaked_curated_correspondences
from src.backend.ingest.curated import load_prebaked_curated_timeline
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.graph import Node, Remark, SourceLocation, StateGraph
from src.backend.model.timeline import OptimisationTimeline, PassStep
from src.backend.toolchain import curated


class QueryError(ValueError):
    """Raised when a query cannot be satisfied from the current session."""


@dataclass
class SessionState:
    """In-memory UI focus over immutable, pre-baked model records."""

    example_id: str
    timeline: OptimisationTimeline
    correspondences: tuple[Correspondence, ...]
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
            correspondences = load_prebaked_curated_correspondences(example_id, timeline)
        except (ValueError, RuntimeError) as exc:
            raise QueryError(str(exc)) from exc
        self._session = SessionState(example_id, timeline, correspondences)
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
                    "transition": self._transition_view(state.ordinal),
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

    def source(self, ordinal: int) -> dict[str, Any]:
        """Return curated source text annotated only with recorded IR mappings."""

        session = self._require_session()
        state = self._state(ordinal)
        try:
            source_lines = curated.read_source(session.example_id).splitlines()
        except RuntimeError as exc:
            raise QueryError(str(exc)) from exc
        source_mapped_instruction_ids = {
            edge.from_id for edge in state.edges if edge.relation == "sourceMap"
        }
        source_filename = Path(state.source_filename or f"{session.example_id}.c").name
        instruction_ids_by_line: dict[int, list[str]] = {}
        for node in state.nodes:
            if node.kind != "Instruction" or node.stable_id not in source_mapped_instruction_ids:
                continue
            location = node.attributes.get("source")
            if not isinstance(location, SourceLocation):
                continue
            if Path(location.file).name != source_filename:
                continue
            if 1 <= location.line <= len(source_lines):
                instruction_ids_by_line.setdefault(location.line, []).append(node.stable_id)
        return {
            "ordinal": state.ordinal,
            "filename": source_filename,
            "lines": [
                {
                    "number": number,
                    "text": text,
                    "instructionIds": instruction_ids_by_line.get(number, []),
                }
                for number, text in enumerate(source_lines, start=1)
            ],
        }

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
        if from_ordinal < 0:
            raise QueryError(f"no pre-baked step from ordinal {from_ordinal}")
        try:
            step = session.timeline.steps[from_ordinal]
            correspondence = session.correspondences[from_ordinal]
        except IndexError as exc:
            raise QueryError(f"no pre-baked step from ordinal {from_ordinal}") from exc
        return {
            "fromOrdinal": step.from_ordinal,
            "toOrdinal": step.to_ordinal,
            "kind": step.kind,
            "origin": {
                "command": step.origin.command,
                "passName": step.origin.pass_name,
                "level": step.origin.level,
            },
            "noOp": is_identity_correspondence(correspondence),
            "remarks": [
                _remark_view(remark, index, self._state(step.to_ordinal))
                for index, remark in enumerate(step.remarks)
            ],
        }

    def counterparts(
        self,
        ordinal: int,
        node_id: str,
        to_ordinal: int | None = None,
    ) -> dict[str, Any]:
        state = self._state(ordinal)
        self._node(state, node_id)
        counterpart_ordinal = self._default_counterpart_ordinal(ordinal, to_ordinal)
        lower_ordinal, higher_ordinal = sorted((ordinal, counterpart_ordinal))
        correspondence = self._comparison(lower_ordinal, higher_ordinal)
        if ordinal == correspondence.from_ordinal:
            link = correspondence.links_from.get(node_id)
        else:
            link = correspondence.links_to.get(node_id)
        if link is None:
            raise QueryError(f"node is outside the correspondence coverage: {node_id}")
        counterpart_state = self._state(counterpart_ordinal)
        counterpart_ids = (
            link.to_node_ids
            if ordinal == correspondence.from_ordinal
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

    def summary(
        self,
        from_ordinal: int = 0,
        to_ordinal: int | None = None,
    ) -> dict[str, Any]:
        session = self._require_session()
        if to_ordinal is None:
            to_ordinal = len(session.timeline.states) - 1
        if to_ordinal <= from_ordinal:
            raise QueryError("summary target ordinal must follow its source ordinal")
        correspondence = self._comparison(from_ordinal, to_ordinal)
        final_step = session.timeline.steps[to_ordinal - 1]
        summary = summarise_correspondence(
            correspondence,
            session.timeline.state(from_ordinal),
            session.timeline.state(to_ordinal),
            final_step,
        )
        return _summary_view(
            summary,
            correspondence,
            session.timeline.state(from_ordinal),
            session.timeline.state(to_ordinal),
            final_step,
        )

    def _transition_view(self, ordinal: int) -> dict[str, Any] | None:
        if ordinal == 0:
            return None
        session = self._require_session()
        step = session.timeline.steps[ordinal - 1]
        return {
            "kind": step.kind,
            "passName": step.origin.pass_name,
            "level": step.origin.level,
            "noOp": is_identity_correspondence(session.correspondences[ordinal - 1]),
            "remarkCount": len(step.remarks),
        }

    def _default_counterpart_ordinal(
        self,
        ordinal: int,
        to_ordinal: int | None,
    ) -> int:
        state_count = len(self._require_session().timeline.states)
        if to_ordinal is not None:
            if to_ordinal < 0 or to_ordinal >= state_count or to_ordinal == ordinal:
                raise QueryError("counterpart target ordinal must be another timeline state")
            return to_ordinal
        if ordinal < state_count - 1:
            return ordinal + 1
        return ordinal - 1

    def _comparison(
        self,
        from_ordinal: int,
        to_ordinal: int,
    ) -> Correspondence | ComposedCorrespondence:
        session = self._require_session()
        if from_ordinal < 0 or to_ordinal >= len(session.timeline.states):
            raise QueryError("comparison ordinals are outside the timeline")
        if to_ordinal == from_ordinal + 1:
            return session.correspondences[from_ordinal]
        try:
            return compose_timeline_correspondences(
                session.timeline,
                session.correspondences,
                from_ordinal,
                to_ordinal,
            )
        except ValueError as exc:
            raise QueryError(str(exc)) from exc

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


def _summary_view(
    summary: ComparisonSummary,
    correspondence: Correspondence | ComposedCorrespondence,
    from_state: StateGraph,
    to_state: StateGraph,
    step: PassStep,
) -> dict[str, Any]:
    return {
        "context": summary.context,
        "items": [
            {
                "text": item.text,
                "linkIndices": list(item.link_indices),
                "remarkIndices": list(item.remark_indices),
                "evidence": [
                    _link_evidence(correspondence.links[index], index, from_state, to_state)
                    for index in item.link_indices
                ]
                + [
                    _remark_view(step.remarks[index], index, to_state)
                    for index in item.remark_indices
                ],
            }
            for item in summary.items
        ],
    }


def _link_evidence(
    link: Link,
    index: int,
    from_state: StateGraph,
    to_state: StateGraph,
) -> dict[str, Any]:
    return {
        "type": "link",
        "index": index,
        "relation": link.relation,
        "confidence": link.confidence,
        "evidence": link.evidence,
        "from": [_node_view(from_state.by_id[node_id]) for node_id in link.from_node_ids],
        "to": [_node_view(to_state.by_id[node_id]) for node_id in link.to_node_ids],
    }


def _remark_view(remark: Remark, index: int, state: StateGraph) -> dict[str, Any]:
    return {
        "type": "remark",
        "index": index,
        "passName": remark.pass_name,
        "name": remark.name,
        "function": remark.function,
        "location": _source_view(remark.location),
        "instructionIds": [
            node.stable_id
            for node in state.nodes
            if node.kind == "Instruction" and remark in node.attributes.get("remarks", ())
        ],
        "raw": remark.raw,
    }
