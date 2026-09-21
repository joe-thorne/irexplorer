"""Offline coordinator for deriving curated model records from compiler artefacts."""

from __future__ import annotations

from pathlib import Path
import shutil
import tempfile

from src.backend.analysis.curated import bake_curated_comparison_records
from src.backend.ingest.curated import bake_curated_model_records
from src.backend.toolchain import curated as curated_paths
from src.backend.toolchain import generate_curated


def generate_all(*, artefacts_root: Path = curated_paths.ARTEFACTS_ROOT) -> None:
    """Generate raw artefacts, then bake model records into one staged snapshot."""

    artefacts_root.parent.mkdir(parents=True, exist_ok=True)
    generate_curated._recover_interrupted_replacement(artefacts_root)
    staging_root = Path(
        tempfile.mkdtemp(
            prefix=f".{artefacts_root.name}.staging-",
            dir=artefacts_root.parent,
        )
    )
    try:
        generate_curated.generate_snapshot(staging_root)
        bake_curated_snapshot(staging_root)
        generate_curated._replace_snapshot(staging_root, artefacts_root)
    except BaseException:
        if staging_root.exists():
            shutil.rmtree(staging_root)
        raise


def bake_curated_snapshot(artefacts_root: Path) -> None:
    """Derive model and comparison records in one staged artefact tree."""

    # Runtime consumes serialised records, never raw IR. Keep this cross-layer
    # offline coordination above the toolchain boundary that creates raw files.
    with curated_paths.using_artefacts_root(artefacts_root):
        bake_curated_model_records()
        bake_curated_comparison_records()
