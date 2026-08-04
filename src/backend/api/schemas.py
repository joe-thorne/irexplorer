"""Pydantic HTTP schemas for the read-only curated query API."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict


class ApiModel(BaseModel):
    """Reject unexpected fields in public API records."""

    model_config = ConfigDict(extra="forbid")


class ErrorDetail(ApiModel):
    code: str
    message: str


class ErrorResponse(ApiModel):
    error: ErrorDetail


class HealthResponse(ApiModel):
    status: Literal["ok"]


class ExamplesResponse(ApiModel):
    examples: list[str]


class TransitionResponse(ApiModel):
    kind: Literal["derived", "recompiled"]
    passName: str | None
    level: str | None
    noOp: bool
    remarkCount: int


class StateResponse(ApiModel):
    ordinal: int
    stateId: str
    originCommand: str | None
    transition: TransitionResponse | None


class StatesResponse(ApiModel):
    states: list[StateResponse]


class NodeResponse(ApiModel):
    id: str
    kind: str
    displayName: str


class InstructionResponse(NodeResponse):
    text: str | None
    opcode: str | None


class BasicBlockResponse(ApiModel):
    id: str
    label: str
    instructions: list[InstructionResponse]


class FunctionResponse(ApiModel):
    id: str
    name: str
    signature: str | None
    blocks: list[BasicBlockResponse]


class IrResponse(ApiModel):
    ordinal: int
    stateId: str
    functions: list[FunctionResponse]


class CfgBlockResponse(ApiModel):
    id: str
    label: str


class CfgEdgeResponse(ApiModel):
    fromId: str
    toId: str
    label: str | None


class CfgResponse(ApiModel):
    ordinal: int
    functionId: str
    blocks: list[CfgBlockResponse]
    edges: list[CfgEdgeResponse]


class CounterpartsResponse(ApiModel):
    ordinal: int
    nodeId: str
    counterpartOrdinal: int
    relation: str
    confidence: str
    evidence: str | None
    counterparts: list[NodeResponse]
