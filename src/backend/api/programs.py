"""User programs over /api/programs: compiled on request, held in memory, answered by the shared views.

Mounted only when the user programs setting is on. Its routes resolve ids only through the user-program
store, as the curated routes resolve only curated examples, so neither ever answers for the other.
"""

from __future__ import annotations

from collections import OrderedDict
from dataclasses import dataclass
from threading import Lock
from typing import Annotated, Any

from fastapi import APIRouter, Query, Response
from fastapi import Path as ApiPath
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.concurrency import run_in_threadpool

from src.backend.analysis.compare import compare_timeline_step
from src.backend.api.query import (
    ModelRecords,
    QueryError,
    cfg_view,
    comparison_report_view,
    ir_view,
    source_mappings_view,
    source_view,
    states_view,
)
from src.backend.api.schemas import (
    CfgResponse,
    IrResponse,
    ProgramComparisonReportResponse,
    ProgramRequest,
    ProgramResponse,
    ProgramSourceMappingsResponse,
    ProgramSourceResponse,
    StatesResponse,
)
from src.backend.ingest import SourceRecord, StateArtefacts, build_timeline
from src.backend.model import (
    deserialise_correspondence,
    deserialise_json,
    deserialise_timeline,
    serialise_correspondence,
    serialise_json,
    serialise_timeline,
)
from src.backend.programs.accepted import AcceptedProgram, RefusedProgram, accept_program
from src.backend.programs.compiler import CompileFailed, CompilerClient, CompilerOutput
from src.backend.programs.diagnostics import compile_failure

# About 16 programs are held; nothing is persisted, so a restart forgets them all.
STORE_CAPACITY = 16
# No pattern constraint: a malformed id is simply not held, so it answers unknown_program, not invalid_request.
ProgramId = Annotated[str, ApiPath(min_length=1)]
Ordinal = Annotated[int, ApiPath(ge=0)]
FunctionId = Annotated[str, Query(alias="functionId", min_length=1)]
NO_STORE = {"Cache-Control": "no-store"}


class UnknownProgramError(QueryError):
    """Raised for an id the store does not hold: never compiled, evicted, or lost on restart."""

    code = "unknown_program"


@dataclass(frozen=True)
class UserProgram:
    records: ModelRecords
    manifest: dict[str, Any]


class ProgramStore:
    """The user-program resolver: the most recently used programs, least recently used out first."""

    def __init__(self, capacity: int = STORE_CAPACITY) -> None:
        self._capacity = capacity
        self._programs: OrderedDict[str, UserProgram] = OrderedDict()
        self._lock = Lock()

    def resolve(self, program_id: str) -> UserProgram:
        with self._lock:
            try:
                self._programs.move_to_end(program_id)
            except KeyError:
                raise UnknownProgramError(f"The server does not hold user program {program_id}.") from None
            return self._programs[program_id]

    def hold(self, program: UserProgram) -> None:
        with self._lock:
            self._programs[program.records.timeline_id] = program
            self._programs.move_to_end(program.records.timeline_id)
            while len(self._programs) > self._capacity:
                self._programs.popitem(last=False)


def derive_records(program: AcceptedProgram, output: CompilerOutput) -> ModelRecords:
    """Build a user program's model records from its compiler artefacts, as a curated example's are built."""

    artefacts = {
        # O3's remarks are its optimisation record, as for a curated example.
        state.state_id: StateArtefacts(state.ir, state.command,
                                       output.opt_record if state.state_id == "O3" else state.remarks)
        for state in output.states
    }
    timeline = build_timeline(program.program_id, artefacts)
    correspondences = [compare_timeline_step(timeline, ordinal) for ordinal in range(len(timeline.steps))]
    # Once through model-record serialisation, so a user program is validated exactly as a curated record is.
    timeline = deserialise_timeline(deserialise_json(serialise_json(serialise_timeline(timeline))))
    return ModelRecords(
        timeline_id=program.program_id,
        timeline=timeline,
        correspondences=tuple(
            deserialise_correspondence(
                deserialise_json(serialise_json(serialise_correspondence(correspondence))),
                timeline.state(ordinal),
                timeline.state(ordinal + 1),
            )
            for ordinal, correspondence in enumerate(correspondences)
        ),
        source=SourceRecord(file=program.file_name, text=program.source, sha256=program.sha256),
    )


def router(store: ProgramStore, compiler: CompilerClient) -> APIRouter:
    api = APIRouter()

    def compile_program(program: AcceptedProgram) -> UserProgram:
        output = compiler.compile(program)
        return UserProgram(derive_records(program, output), output.manifest)

    @api.post("/api/programs", response_model=ProgramResponse, status_code=201)
    async def post_program(request: ProgramRequest, response: Response) -> Any:
        try:
            program = accept_program(request.fileName, request.source)
        except RefusedProgram as exc:
            raise RequestValidationError([]) from exc
        response.headers.update(NO_STORE)
        try:
            held = store.resolve(program.program_id)
        except UnknownProgramError:
            pass
        else:
            response.status_code = 200
            return _program_view(held)
        try:
            compiled = await run_in_threadpool(compile_program, program)
        except CompileFailed as exc:
            message = ("The C source did not compile." if exc.tool == "clang"
                       else f"{exc.tool} failed while optimising the program.")
            return JSONResponse({"error": {"code": "compile_failed", "message": message, **compile_failure(exc)}},
                                status_code=422, headers=NO_STORE)
        store.hold(compiled)
        return _program_view(compiled)

    @api.get("/api/programs/{program_id}", response_model=ProgramResponse)
    def get_program(program_id: ProgramId) -> dict[str, Any]:
        return _program_view(store.resolve(program_id))

    @api.get("/api/programs/{program_id}/states", response_model=StatesResponse)
    def list_states(program_id: ProgramId) -> dict[str, Any]:
        return states_view(_records(program_id))

    @api.get("/api/programs/{program_id}/source", response_model=ProgramSourceResponse)
    def source(program_id: ProgramId) -> dict[str, Any]:
        return _with_program_id(source_view(_records(program_id)))

    @api.get("/api/programs/{program_id}/comparison-report", response_model=ProgramComparisonReportResponse)
    def comparison_report(program_id: ProgramId,
                          from_ordinal: Annotated[int, Query(alias="fromOrdinal", ge=0)],
                          to_ordinal: Annotated[int, Query(alias="toOrdinal", ge=0)]) -> dict[str, Any]:
        return _with_program_id(comparison_report_view(_records(program_id), from_ordinal, to_ordinal))

    @api.get("/api/programs/{program_id}/states/{ordinal}/source-mappings",
             response_model=ProgramSourceMappingsResponse)
    def source_mappings(program_id: ProgramId, ordinal: Ordinal, function_id: FunctionId) -> dict[str, Any]:
        return _with_program_id(source_mappings_view(_records(program_id), ordinal, function_id))

    @api.get("/api/programs/{program_id}/states/{ordinal}/ir", response_model=IrResponse)
    def ir(program_id: ProgramId, ordinal: Ordinal) -> dict[str, Any]:
        return ir_view(_records(program_id), ordinal)

    @api.get("/api/programs/{program_id}/states/{ordinal}/cfg", response_model=CfgResponse)
    def cfg(program_id: ProgramId, ordinal: Ordinal, function_id: FunctionId) -> dict[str, Any]:
        return cfg_view(_records(program_id), ordinal, function_id)

    def _records(program_id: str) -> ModelRecords:
        return store.resolve(program_id).records

    return api


def _program_view(program: UserProgram) -> dict[str, Any]:
    source = program.records.source
    return {"programId": program.records.timeline_id, "fileName": source.file, "sha256": source.sha256,
            "manifest": program.manifest}


def _with_program_id(view: dict[str, Any]) -> dict[str, Any]:
    """Answer a shared view with ``programId`` in place of the curated ``exampleId`` (naming debt, ADR 0005)."""

    return {"programId": view["exampleId"], **{key: value for key, value in view.items() if key != "exampleId"}}
