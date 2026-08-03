"""Read-only query service over pre-baked optimisation model records."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from src.backend.analysis.compare import (
    ComposedCorrespondence,
    compose_timeline_correspondences,
    is_identity_correspondence,
)
from src.backend.analysis.curated import load_prebaked_curated_correspondences
from src.backend.ingest.curated import load_prebaked_curated_timeline
from src.backend.model.correspondence import Correspondence
from src.backend.model.graph import Node, StateGraph
from src.backend.model.timeline import OptimisationTimeline
from src.backend.toolchain import curated


class QueryError(ValueError):
    """Raised when a query cannot be satisfied from the loaded example."""


@dataclass
class LoadedExample:
    """In-memory cache of immutable, pre-baked records for one curated example."""

    example_id: str
    timeline: OptimisationTimeline
    correspondences: tuple[Correspondence, ...]


class QueryService:
    """The model-query boundary consumed by the localhost browser API."""

    def __init__(self) -> None:
        self._loaded: LoadedExample | None = None

    def list_examples(self) -> dict[str, Any]:
        return {"examples": list(curated.list_examples())}

    def load_example(self, example_id: str) -> dict[str, Any]:
        try:
            timeline = load_prebaked_curated_timeline(example_id)
            correspondences = load_prebaked_curated_correspondences(example_id, timeline)
        except (ValueError, RuntimeError) as exc:
            raise QueryError(str(exc)) from exc
        self._loaded = LoadedExample(example_id, timeline, correspondences)
        return {
            "exampleId": example_id,
            "states": self.list_states()["states"],
        }

    def list_states(self) -> dict[str, Any]:
        loaded = self._require_loaded()
        return {
            "states": [
                {
                    "ordinal": state.ordinal,
                    "stateId": state.state_id,
                    "originCommand": state.origin_command,
                    "transition": self._transition_view(state.ordinal),
                }
                for state in loaded.timeline.states
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

    def _transition_view(self, ordinal: int) -> dict[str, Any] | None:
        if ordinal == 0:
            return None
        loaded = self._require_loaded()
        step = loaded.timeline.steps[ordinal - 1]
        return {
            "kind": step.kind,
            "passName": step.origin.pass_name,
            "level": step.origin.level,
            "noOp": is_identity_correspondence(loaded.correspondences[ordinal - 1]),
            "remarkCount": len(step.remarks),
        }

    def _default_counterpart_ordinal(
        self,
        ordinal: int,
        to_ordinal: int | None,
    ) -> int:
        state_count = len(self._require_loaded().timeline.states)
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
        loaded = self._require_loaded()
        if from_ordinal < 0 or to_ordinal >= len(loaded.timeline.states):
            raise QueryError("comparison ordinals are outside the timeline")
        if to_ordinal == from_ordinal + 1:
            return loaded.correspondences[from_ordinal]
        try:
            return compose_timeline_correspondences(
                loaded.timeline,
                loaded.correspondences,
                from_ordinal,
                to_ordinal,
            )
        except ValueError as exc:
            raise QueryError(str(exc)) from exc

    def _require_loaded(self) -> LoadedExample:
        if self._loaded is None:
            raise QueryError("no curated example is loaded")
        return self._loaded

    def _state(self, ordinal: int) -> StateGraph:
        try:
            return self._require_loaded().timeline.state(ordinal)
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
    }


def _node_view(node: Node) -> dict[str, Any]:
    return {"id": node.stable_id, "kind": node.kind, "displayName": node.display_name}
