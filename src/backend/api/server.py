"""Minimal localhost HTTP server for the read-only browser query boundary."""

from __future__ import annotations

from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse

from src.backend.api.query import QueryError, QueryService


FRONTEND_ROOT = Path(__file__).resolve().parents[2] / "frontend"
STATIC_CONTENT_TYPES = {
    ".css": "text/css; charset=utf-8",
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
}


def create_server(
    service: QueryService | None = None,
    host: str = "127.0.0.1",
    port: int = 8000,
) -> ThreadingHTTPServer:
    """Create, but do not start, the local model-query HTTP server."""

    query_service = service or QueryService()

    class QueryHandler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802 - required HTTP handler name
            if not urlparse(self.path).path.startswith("/api/"):
                self._serve_frontend()
                return
            try:
                self._send_json(HTTPStatus.OK, _route_get(query_service, self.path))
            except QueryError as exc:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": str(exc)})
            except ValueError as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        def do_POST(self) -> None:  # noqa: N802 - required HTTP handler name
            try:
                body = _read_json_body(self)
                self._send_json(
                    HTTPStatus.OK, _route_post(query_service, self.path, body)
                )
            except QueryError as exc:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": str(exc)})
            except ValueError as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})

        def log_message(self, _format: str, *_args: object) -> None:
            """Keep development/test output focused on explicit application logs."""

        def _send_json(self, status: HTTPStatus, body: dict[str, Any]) -> None:
            encoded = json.dumps(body).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

        def _serve_frontend(self) -> None:
            request_path = urlparse(self.path).path
            relative_path = "index.html" if request_path == "/" else request_path.lstrip("/")
            candidate = (FRONTEND_ROOT / relative_path).resolve()
            try:
                candidate.relative_to(FRONTEND_ROOT.resolve())
            except ValueError:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "frontend asset not found"})
                return
            content_type = STATIC_CONTENT_TYPES.get(candidate.suffix)
            if content_type is None or not candidate.is_file():
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "frontend asset not found"})
                return
            encoded = candidate.read_bytes()
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

    return ThreadingHTTPServer((host, port), QueryHandler)


def run_server(host: str = "127.0.0.1", port: int = 8000) -> None:
    """Serve the query API on localhost until interrupted."""

    server = create_server(host=host, port=port)
    print(f"irexplorer API listening at http://{host}:{server.server_port}")
    try:
        server.serve_forever()
    finally:
        server.server_close()


def _route_get(service: QueryService, request_path: str) -> dict[str, Any]:
    path, query = _request_parts(request_path)
    if path == "/api/health":
        return {"status": "ok"}
    if path == "/api/examples":
        return service.list_examples()
    if path == "/api/session":
        return service.session()
    if path == "/api/states":
        return service.list_states()
    if path == "/api/ir":
        return service.ir(_required_int(query, "ordinal"))
    if path == "/api/source":
        return service.source(_required_int(query, "ordinal"))
    if path == "/api/cfg":
        return service.cfg(_required_int(query, "ordinal"), _required_str(query, "functionId"))
    if path == "/api/children":
        return service.children(
            _required_int(query, "ordinal"), _required_str(query, "nodeId")
        )
    if path == "/api/parent":
        return service.parent(
            _required_int(query, "ordinal"), _required_str(query, "nodeId")
        )
    if path == "/api/step":
        return service.step(_optional_int(query, "fromOrdinal", default=0))
    if path == "/api/counterparts":
        return service.counterparts(
            _required_int(query, "ordinal"),
            _required_str(query, "nodeId"),
            _optional_int_or_none(query, "toOrdinal"),
        )
    if path == "/api/summary":
        return service.summary(
            _optional_int(query, "fromOrdinal", default=0),
            _optional_int_or_none(query, "toOrdinal"),
        )
    raise QueryError(f"unknown API route: {path}")


def _route_post(
    service: QueryService,
    request_path: str,
    body: dict[str, Any],
) -> dict[str, Any]:
    path, _ = _request_parts(request_path)
    if path == "/api/session":
        example_id = body.get("exampleId")
        if not isinstance(example_id, str):
            raise ValueError("exampleId must be a string")
        return service.load_example(example_id)
    if path == "/api/focus":
        ordinal = body.get("ordinal")
        node_id = body.get("nodeId")
        if not isinstance(ordinal, int):
            raise ValueError("ordinal must be an integer")
        if node_id is not None and not isinstance(node_id, str):
            raise ValueError("nodeId must be a string or null")
        return service.set_focus(ordinal, node_id)
    raise QueryError(f"unknown API route: {path}")


def _read_json_body(handler: BaseHTTPRequestHandler) -> dict[str, Any]:
    length_text = handler.headers.get("Content-Length")
    if length_text is None:
        raise ValueError("Content-Length is required")
    try:
        length = int(length_text)
    except ValueError as exc:
        raise ValueError("Content-Length must be an integer") from exc
    try:
        body = json.loads(handler.rfile.read(length).decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError("request body must be valid JSON") from exc
    if not isinstance(body, dict):
        raise ValueError("request body must be a JSON object")
    return body


def _request_parts(request_path: str) -> tuple[str, dict[str, list[str]]]:
    parsed = urlparse(request_path)
    return parsed.path, parse_qs(parsed.query, keep_blank_values=True)


def _required_str(query: dict[str, list[str]], key: str) -> str:
    values = query.get(key)
    if values is None or len(values) != 1 or not values[0]:
        raise ValueError(f"{key} query parameter is required")
    return values[0]


def _required_int(query: dict[str, list[str]], key: str) -> int:
    return _parse_int(_required_str(query, key), key)


def _optional_int(query: dict[str, list[str]], key: str, *, default: int) -> int:
    values = query.get(key)
    if values is None:
        return default
    if len(values) != 1:
        raise ValueError(f"{key} query parameter must appear once")
    return _parse_int(values[0], key)


def _optional_int_or_none(query: dict[str, list[str]], key: str) -> int | None:
    if key not in query:
        return None
    return _optional_int(query, key, default=0)


def _parse_int(value: str, key: str) -> int:
    try:
        return int(value)
    except ValueError as exc:
        raise ValueError(f"{key} must be an integer") from exc


if __name__ == "__main__":
    run_server()
