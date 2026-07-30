"""Plain-record serialisation for immutable Layer 3 model records."""

from __future__ import annotations

import json
from typing import Any, Mapping

from src.backend.model.graph import (
    Edge,
    ModelValidationError,
    Node,
    Remark,
    SourceLocation,
    StateGraph,
)
from src.backend.model.correspondence import Correspondence, Link
from src.backend.model.timeline import OptimisationTimeline, PassStep, StepOrigin


FORMAT_VERSION = 2
_TYPE_KEY = "__irexplorer_type__"


def serialise_state_graph(graph: StateGraph) -> dict[str, Any]:
    """Return the canonical plain record for one independently loadable state."""

    graph.validate()
    return {
        "formatVersion": FORMAT_VERSION,
        "ordinal": graph.ordinal,
        "stateId": graph.state_id,
        "sourceFilename": graph.source_filename,
        "targetTriple": graph.target_triple,
        "targetDatalayout": graph.target_datalayout,
        "originCommand": graph.origin_command,
        "nodes": [
            {
                "stableId": node.stable_id,
                "kind": node.kind,
                "displayName": node.display_name,
                "attributes": _serialise_value(node.attributes),
            }
            for node in graph.nodes
        ],
        "edges": [
            {
                "fromId": edge.from_id,
                "toId": edge.to_id,
                "relation": edge.relation,
                "label": edge.label,
                "order": edge.order,
            }
            for edge in graph.edges
        ],
        "remarks": [_serialise_remark(remark) for remark in graph.remarks],
    }


def deserialise_state_graph(record: Mapping[str, Any]) -> StateGraph:
    """Load and validate one state record, rebuilding its derived indices."""

    _require_format_version(record)
    try:
        graph = StateGraph(
            ordinal=_require_int(record, "ordinal"),
            state_id=_require_str(record, "stateId"),
            nodes=tuple(_deserialise_node(item) for item in _require_list(record, "nodes")),
            edges=tuple(_deserialise_edge(item) for item in _require_list(record, "edges")),
            source_filename=_optional_str(record.get("sourceFilename"), "sourceFilename"),
            target_triple=_optional_str(record.get("targetTriple"), "targetTriple"),
            target_datalayout=_optional_str(
                record.get("targetDatalayout"), "targetDatalayout"
            ),
            origin_command=_optional_str(record.get("originCommand"), "originCommand"),
            remarks=tuple(
                _deserialise_remark(item) for item in _require_list(record, "remarks")
            ),
        )
        graph.validate()
        return graph
    except (KeyError, TypeError, ValueError) as exc:
        if isinstance(exc, ModelValidationError):
            raise
        raise ModelValidationError(f"invalid state graph record: {exc}") from exc


def serialise_timeline(timeline: OptimisationTimeline) -> dict[str, Any]:
    """Return a plain timeline record without derived lookup indices."""

    timeline.validate()
    return {
        "formatVersion": FORMAT_VERSION,
        "exampleId": timeline.example_id,
        "configId": timeline.config_id,
        "states": [serialise_state_graph(state) for state in timeline.states],
        "steps": [
            {
                "fromOrdinal": step.from_ordinal,
                "toOrdinal": step.to_ordinal,
                "kind": step.kind,
                "origin": {
                    "passName": step.origin.pass_name,
                    "level": step.origin.level,
                    "command": step.origin.command,
                },
                "remarks": [_serialise_remark(remark) for remark in step.remarks],
            }
            for step in timeline.steps
        ],
    }


def deserialise_timeline(record: Mapping[str, Any]) -> OptimisationTimeline:
    """Load and validate a timeline, rebuilding indices for every state."""

    _require_format_version(record)
    try:
        timeline = OptimisationTimeline(
            example_id=_require_str(record, "exampleId"),
            config_id=_require_str(record, "configId"),
            states=tuple(
                deserialise_state_graph(item) for item in _require_list(record, "states")
            ),
            steps=tuple(_deserialise_step(item) for item in _require_list(record, "steps")),
        )
        timeline.validate()
        return timeline
    except (KeyError, TypeError, ValueError) as exc:
        if isinstance(exc, ModelValidationError):
            raise
        raise ModelValidationError(f"invalid optimisation timeline record: {exc}") from exc


def serialise_correspondence(correspondence: Correspondence) -> dict[str, Any]:
    """Return a plain correspondence record; endpoint validation occurs on load."""

    return {
        "formatVersion": FORMAT_VERSION,
        "fromOrdinal": correspondence.from_ordinal,
        "toOrdinal": correspondence.to_ordinal,
        "coveredKinds": list(correspondence.covered_kinds),
        "links": [
            {
                "fromNodeIds": list(link.from_node_ids),
                "toNodeIds": list(link.to_node_ids),
                "relation": link.relation,
                "confidence": link.confidence,
                "evidence": link.evidence,
            }
            for link in correspondence.links
        ],
    }


def deserialise_correspondence(
    record: Mapping[str, Any],
    from_state: StateGraph,
    to_state: StateGraph,
) -> Correspondence:
    """Load a correspondence only when its concrete endpoint states are known."""

    _require_format_version(record)
    try:
        correspondence = Correspondence(
            from_ordinal=_require_int(record, "fromOrdinal"),
            to_ordinal=_require_int(record, "toOrdinal"),
            covered_kinds=tuple(
                _require_string_items(_require_list(record, "coveredKinds"), "coveredKinds")
            ),
            links=tuple(
                _deserialise_link(item) for item in _require_list(record, "links")
            ),
        )
        correspondence.validate(from_state, to_state)
        return correspondence
    except (KeyError, TypeError, ValueError) as exc:
        if isinstance(exc, ModelValidationError):
            raise
        raise ModelValidationError(f"invalid correspondence record: {exc}") from exc


def serialise_json(record: Mapping[str, Any]) -> str:
    """Encode a plain model record deterministically for fixture storage."""

    return json.dumps(record, indent=2, sort_keys=True) + "\n"


def deserialise_json(text: str) -> dict[str, Any]:
    """Decode a JSON model record and reject non-object roots."""

    try:
        record = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ModelValidationError(f"invalid model JSON: {exc.msg}") from exc
    if not isinstance(record, dict):
        raise ModelValidationError("model JSON root must be an object")
    return record


def _serialise_value(value: Any) -> Any:
    if isinstance(value, SourceLocation):
        return {_TYPE_KEY: "SourceLocation", "file": value.file, "line": value.line, "column": value.column}
    if isinstance(value, Remark):
        return {_TYPE_KEY: "Remark", **_serialise_remark(value)}
    if isinstance(value, tuple):
        return {_TYPE_KEY: "tuple", "items": [_serialise_value(item) for item in value]}
    if isinstance(value, Mapping):
        return {str(key): _serialise_value(item) for key, item in value.items()}
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    raise ModelValidationError(f"cannot serialise node attribute value: {type(value).__name__}")


def _deserialise_value(value: Any) -> Any:
    if isinstance(value, list):
        return [_deserialise_value(item) for item in value]
    if not isinstance(value, dict):
        return value
    type_name = value.get(_TYPE_KEY)
    if type_name == "SourceLocation":
        return SourceLocation(
            file=_require_str(value, "file"),
            line=_require_int(value, "line"),
            column=_require_int(value, "column"),
        )
    if type_name == "Remark":
        return _deserialise_remark(value)
    if type_name == "tuple":
        return tuple(_deserialise_value(item) for item in _require_list(value, "items"))
    if type_name is not None:
        raise ModelValidationError(f"unknown serialised value type: {type_name}")
    return {str(key): _deserialise_value(item) for key, item in value.items()}


def _serialise_remark(remark: Remark) -> dict[str, Any]:
    return {
        "passName": remark.pass_name,
        "name": remark.name,
        "function": remark.function,
        "location": _serialise_value(remark.location),
        "raw": remark.raw,
    }


def _deserialise_remark(record: Mapping[str, Any]) -> Remark:
    location = _deserialise_value(record.get("location"))
    if location is not None and not isinstance(location, SourceLocation):
        raise ModelValidationError("remark location must be a SourceLocation or null")
    return Remark(
        pass_name=_require_str(record, "passName"),
        name=_require_str(record, "name"),
        function=_require_str(record, "function"),
        location=location,
        raw=_require_str(record, "raw"),
    )


def _deserialise_node(record: Mapping[str, Any]) -> Node:
    attributes = _deserialise_value(record.get("attributes", {}))
    if not isinstance(attributes, Mapping):
        raise ModelValidationError("node attributes must be an object")
    return Node(
        stable_id=_require_str(record, "stableId"),
        kind=_require_str(record, "kind"),
        display_name=_require_str(record, "displayName"),
        attributes=attributes,
    )


def _deserialise_edge(record: Mapping[str, Any]) -> Edge:
    return Edge(
        from_id=_require_str(record, "fromId"),
        to_id=_require_str(record, "toId"),
        relation=_require_str(record, "relation"),
        label=_optional_str(record.get("label"), "label"),
        order=_optional_int(record.get("order"), "order"),
    )


def _deserialise_step(record: Mapping[str, Any]) -> PassStep:
    origin = record.get("origin")
    if not isinstance(origin, Mapping):
        raise ModelValidationError("pass step origin must be an object")
    return PassStep(
        from_ordinal=_require_int(record, "fromOrdinal"),
        to_ordinal=_require_int(record, "toOrdinal"),
        kind=_require_str(record, "kind"),  # type: ignore[arg-type]
        origin=StepOrigin(
            command=_require_str(origin, "command"),
            pass_name=_optional_str(origin.get("passName"), "passName"),
            level=_optional_str(origin.get("level"), "level"),
        ),
        remarks=tuple(
            _deserialise_remark(item) for item in _require_list(record, "remarks")
        ),
    )


def _deserialise_link(record: Mapping[str, Any]) -> Link:
    return Link(
        from_node_ids=tuple(
            _require_string_items(_require_list(record, "fromNodeIds"), "fromNodeIds")
        ),
        to_node_ids=tuple(
            _require_string_items(_require_list(record, "toNodeIds"), "toNodeIds")
        ),
        relation=_require_str(record, "relation"),  # type: ignore[arg-type]
        confidence=_require_str(record, "confidence"),  # type: ignore[arg-type]
        evidence=_optional_str(record.get("evidence"), "evidence"),
    )


def _require_format_version(record: Mapping[str, Any]) -> None:
    if _require_int(record, "formatVersion") != FORMAT_VERSION:
        raise ModelValidationError("unsupported model record formatVersion")


def _require_list(record: Mapping[str, Any], key: str) -> list[Any]:
    value = record[key]
    if not isinstance(value, list):
        raise ModelValidationError(f"{key} must be a list")
    return value


def _require_str(record: Mapping[str, Any], key: str) -> str:
    value = record[key]
    if not isinstance(value, str):
        raise ModelValidationError(f"{key} must be a string")
    return value


def _require_string_items(values: list[Any], key: str) -> list[str]:
    if not all(isinstance(value, str) for value in values):
        raise ModelValidationError(f"{key} must contain only strings")
    return values


def _optional_str(value: Any, key: str) -> str | None:
    if value is not None and not isinstance(value, str):
        raise ModelValidationError(f"{key} must be a string or null")
    return value


def _require_int(record: Mapping[str, Any], key: str) -> int:
    value = record[key]
    if not isinstance(value, int) or isinstance(value, bool):
        raise ModelValidationError(f"{key} must be an integer")
    return value


def _optional_int(value: Any, key: str) -> int | None:
    if value is not None and (not isinstance(value, int) or isinstance(value, bool)):
        raise ModelValidationError(f"{key} must be an integer or null")
    return value
