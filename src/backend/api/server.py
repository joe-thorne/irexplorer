"""Uvicorn runner for the read-only curated query application."""

from __future__ import annotations

import uvicorn

from src.backend.api.app import app


def run_server(host: str = "127.0.0.1", port: int = 8000) -> None:
    """Serve the FastAPI application on localhost until interrupted."""

    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    run_server()
