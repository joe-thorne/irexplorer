"""FastAPI application for read-only curated model queries."""

from __future__ import annotations

from pathlib import Path
from typing import Annotated

from fastapi import FastAPI, Path as ApiPath, Query, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHttpException

from src.backend.api.query import QueryError, QueryService
from src.backend.api.schemas import (
    CfgResponse,
    CounterpartsResponse,
    ErrorDetail,
    ErrorResponse,
    ExamplesResponse,
    HealthResponse,
    IrResponse,
    StatesResponse,
)


FRONTEND_ROOT = Path(__file__).resolve().parents[2] / "frontend"
ExampleId = Annotated[str, ApiPath(min_length=1)]
Ordinal = Annotated[int, ApiPath(ge=0)]
FunctionId = Annotated[str, Query(alias="functionId", min_length=1)]
NodeId = Annotated[str, Query(alias="nodeId", min_length=1)]
TargetOrdinal = Annotated[int | None, Query(alias="toOrdinal", ge=0)]


def create_app(
    service: QueryService | None = None,
    *,
    include_docs: bool = True,
) -> FastAPI:
    """Create the same-origin API and static frontend application."""

    query_service = service or QueryService()
    app = FastAPI(
        title="irexplorer curated query API",
        version="1.0.0",
        description="Read-only queries over pre-baked compiler optimisation records.",
        docs_url="/docs" if include_docs else None,
        redoc_url=None,
    )

    @app.exception_handler(QueryError)
    async def query_error_handler(
        _request: Request,
        exc: QueryError,
    ) -> JSONResponse:
        return _error_response(exc.status_code, exc.code, str(exc))

    @app.exception_handler(RequestValidationError)
    async def request_validation_handler(
        _request: Request,
        _exc: RequestValidationError,
    ) -> JSONResponse:
        return _error_response(
            422,
            "invalid_request",
            "Request parameters are invalid.",
        )

    @app.exception_handler(StarletteHttpException)
    async def http_error_handler(
        _request: Request,
        exc: StarletteHttpException,
    ) -> JSONResponse:
        code = "not_found" if exc.status_code == 404 else "method_not_allowed"
        message = "Resource not found." if exc.status_code == 404 else "Method not allowed."
        return _error_response(exc.status_code, code, message)

    @app.get("/api/health", response_model=HealthResponse)
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/api/examples", response_model=ExamplesResponse)
    def list_examples() -> dict[str, object]:
        return query_service.list_examples()

    @app.get("/api/examples/{example_id}/states", response_model=StatesResponse)
    def list_states(example_id: ExampleId) -> dict[str, object]:
        return query_service.list_states(example_id)

    @app.get(
        "/api/examples/{example_id}/states/{ordinal}/ir",
        response_model=IrResponse,
    )
    def ir(example_id: ExampleId, ordinal: Ordinal) -> dict[str, object]:
        return query_service.ir(example_id, ordinal)

    @app.get(
        "/api/examples/{example_id}/states/{ordinal}/cfg",
        response_model=CfgResponse,
    )
    def cfg(
        example_id: ExampleId,
        ordinal: Ordinal,
        function_id: FunctionId,
    ) -> dict[str, object]:
        return query_service.cfg(example_id, ordinal, function_id)

    @app.get(
        "/api/examples/{example_id}/states/{ordinal}/counterparts",
        response_model=CounterpartsResponse,
    )
    def counterparts(
        example_id: ExampleId,
        ordinal: Ordinal,
        node_id: NodeId,
        to_ordinal: TargetOrdinal = None,
    ) -> dict[str, object]:
        return query_service.counterparts(example_id, ordinal, node_id, to_ordinal)

    app.mount("/", StaticFiles(directory=FRONTEND_ROOT, html=True), name="frontend")
    return app


def _error_response(status_code: int, code: str, message: str) -> JSONResponse:
    body = ErrorResponse(error=ErrorDetail(code=code, message=message))
    return JSONResponse(status_code=status_code, content=body.model_dump())


app = create_app()
