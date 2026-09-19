"""Offline coordinator for deriving curated model records from compiler artefacts."""

from __future__ import annotations

from pathlib import Path

from src.backend.analysis.curated import bake_curated_comparison_records
from src.backend.ingest.curated import bake_curated_model_records
from src.backend.toolchain import curated as curated_paths


def bake_curated_snapshot(artefacts_root: Path) -> None:
    """Derive model and comparison records in one staged artefact tree."""

    # Runtime consumes serialised records, never raw IR. Keep this cross-layer
    # offline coordination above the toolchain boundary that creates raw files.
    with curated_paths.using_artefacts_root(artefacts_root):
        bake_curated_model_records()
        bake_curated_comparison_records()
