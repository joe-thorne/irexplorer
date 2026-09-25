"""Read-only, stateless queries over curated model records."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import PurePosixPath
from threading import RLock
from typing import Any

from src.backend.analysis.compare import is_identity_correspondence
from src.backend.analysis.curated import load_stored_curated_correspondences
from src.backend.analysis.report import ComparisonReport, describe_comparison
from src.backend.analysis.summary import RemarkReference
from src.backend.ingest.curated import SourceRecord, load_curated_source_record, load_curated_timeline_record
from src.backend.model.correspondence import Correspondence
from src.backend.model.graph import Node, Remark, StateGraph
from src.backend.model.timeline import OptimisationTimeline
from src.backend.toolchain import curated


class QueryError(ValueError):
    """Raised when a curated query cannot be satisfied."""

    status_code = 404
    code = "not_found"


class DataUnavailableError(RuntimeError):
    """Raised when model records cannot be loaded or composed safely."""

    status_code = 503
    code = "data_unavailable"

    def __init__(self, example_id: str) -> None:
        super().__init__("Model records are temporarily unavailable.")
        self.example_id = example_id


@dataclass(frozen=True)
class LoadedExample:
    """Immutable model records for one curated example."""

    example_id: str
    timeline: OptimisationTimeline
    correspondences: tuple[Correspondence, ...]
    source: SourceRecord


class QueryService:
    """The stateless model-query boundary consumed by browser API clients."""

    def __init__(self, *, preload: bool = True) -> None:
        self._examples: dict[str, LoadedExample] = {}
        self._cache_lock = RLock()
        if preload:
            for example_id in curated.list_examples():
                self._example(example_id)

    def list_examples(self) -> dict[str, Any]:
        return {"examples": list(curated.list_examples())}

    def list_states(self, example_id: str) -> dict[str, Any]:
        loaded = self._example(example_id)
        return {"states": [_state_view(loaded, state) for state in loaded.timeline.states]}

    def source(self, example_id: str) -> dict[str, Any]:
        source = self._example(example_id).source
        return {"exampleId": example_id, "file": source.file, "text": source.text,
                "sha256": source.sha256}

    def source_mappings(self, example_id: str, ordinal: int, function_id: str) -> dict[str, Any]:
        state = self._state(example_id, ordinal)
        function = self._node(state, function_id)
        if function.kind != "Function":
            raise QueryError(f"unknown function in state {ordinal}: {function_id}")
        blocks = set(state.contains_children.get(function_id, ()))
        mappings = []
        for edge in state.edges:
            if edge.relation != "sourceMap":
                continue
            block_id = state.contains_parent.get(edge.from_id)
            if block_id not in blocks:
                continue
            location = state.by_id[edge.from_id].attributes.get("source")
            if location is None:
                continue
            mappings.append({"instructionId": edge.from_id, "blockId": block_id,
                             "location": {"file": PurePosixPath(location.file).name,
                                          "line": location.line, "column": location.column},
                             "evidence": "debugLoc"})
        return {"exampleId": example_id, "ordinal": ordinal, "stateId": state.state_id,
                "functionId": function_id, "mappings": mappings}

    def ir(self, example_id: str, ordinal: int) -> dict[str, Any]:
        state = self._state(example_id, ordinal)
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

    def cfg(self, example_id: str, ordinal: int, function_id: str) -> dict[str, Any]:
        state = self._state(example_id, ordinal)
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

    def comparison_report(self, example_id: str, from_ordinal: int, to_ordinal: int) -> dict[str, Any]:
        """Whole-example outcomes in timeline order, with resolvable evidence indices."""
        loaded = self._example(example_id)
        for ordinal in sorted((from_ordinal, to_ordinal)):
            self._state(example_id, ordinal)
        try:
            report = describe_comparison(loaded.timeline, loaded.correspondences, from_ordinal, to_ordinal)
        except (IndexError, ValueError) as exc:
            raise DataUnavailableError(example_id) from exc
        return _comparison_report_view(loaded, report)

    def _example(self, example_id: str) -> LoadedExample:
        if example_id not in curated.list_examples():
            raise QueryError(f"unknown curated example: {example_id}")
        try:
            return self._examples[example_id]
        except KeyError:
            pass
        with self._cache_lock:
            try:
                return self._examples[example_id]
            except KeyError:
                pass
            try:
                timeline = load_curated_timeline_record(example_id)
                correspondences = load_stored_curated_correspondences(
                    example_id,
                    timeline,
                )
                source = load_curated_source_record(example_id)
            except (OSError, ValueError, RuntimeError) as exc:
                raise DataUnavailableError(example_id) from exc
            loaded = LoadedExample(example_id, timeline, correspondences, source)
            self._examples[example_id] = loaded
            return loaded

    def _state(self, example_id: str, ordinal: int) -> StateGraph:
        try:
            return self._example(example_id).timeline.state(ordinal)
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


def _state_view(loaded: LoadedExample, state: StateGraph) -> dict[str, Any]:
    return {
        "ordinal": state.ordinal,
        "stateId": state.state_id,
        "originCommand": state.origin_command,
        "step": _step_view(loaded, state.ordinal),
    }


def _step_view(loaded: LoadedExample, ordinal: int) -> dict[str, Any] | None:
    if ordinal == 0:
        return None
    step = loaded.timeline.steps[ordinal - 1]
    return {
        "kind": step.kind,
        "passName": step.origin.pass_name,
        "level": step.origin.level,
        "noOp": is_identity_correspondence(loaded.correspondences[ordinal - 1]),
        "remarkCount": len(step.remarks),
    }


def _comparison_report_view(loaded: LoadedExample, report: ComparisonReport) -> dict[str, Any]:
    return {
        "exampleId": loaded.example_id,
        "fromOrdinal": report.from_ordinal,
        "toOrdinal": report.to_ordinal,
        "scope": "whole example",
        "structuralClaims": [{"text": item.text, "linkIndices": list(item.link_indices),
                   "remarkReferences": [_remark_reference_view(ref) for ref in item.remark_references]}
                  for item in report.claims],
        "links": [{"fromNodeIds": list(link.from_node_ids), "toNodeIds": list(link.to_node_ids),
                   "relation": link.relation, "confidence": link.confidence, "evidence": link.evidence}
                  for link in report.links],
        "steps": [{"fromOrdinal": s.from_ordinal, "toOrdinal": s.to_ordinal, "kind": s.kind,
                   "command": s.origin.command, "remarks": [_remark_view(r) for r in s.remarks]}
                  for s in report.steps],
        "optimisations": list(report.optimisations),
        "states": [_state_view(loaded, state) for state in report.states],
        "context": report.context,
    }


def _remark_reference_view(reference: RemarkReference) -> dict[str, int]:
    """Address a remark by its step's position in the summary's steps, then within that step."""
    return {"stepIndex": reference.step_index, "remarkIndex": reference.remark_index}


def _remark_view(remark: Remark) -> dict[str, Any]:
    location = remark.location
    return {
        "passName": remark.pass_name,
        "name": remark.name,
        "function": remark.function,
        "location": None if location is None
        else {"file": location.file, "line": location.line, "column": location.column},
        "raw": remark.raw,
    }
