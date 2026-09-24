"""Offline coordinator for deriving curated model records from compiler artefacts."""

from __future__ import annotations

from pathlib import Path
import shutil
import tempfile

from src.backend.analysis.curated import bake_curated_comparison_records
from src.backend.ingest.curated import bake_curated_model_records
from src.backend.toolchain import curated as curated_paths
from src.backend.toolchain import generate_curated
from src.backend.toolchain.curated import ToolchainError


def generate_all(*, artefacts_root: Path = curated_paths.ARTEFACTS_ROOT) -> None:
    """Generate raw artefacts, then bake model records into one staged snapshot."""

    artefacts_root.parent.mkdir(parents=True, exist_ok=True)
    _recover_interrupted_replacement(artefacts_root)
    staging_root = Path(
        tempfile.mkdtemp(
            prefix=f".{artefacts_root.name}.staging-",
            dir=artefacts_root.parent,
        )
    )
    try:
        generate_curated.generate_snapshot(staging_root)
        bake_curated_snapshot(staging_root)
        _replace_snapshot(staging_root, artefacts_root)
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


def _backup_path(artefacts_root: Path) -> Path:
    return artefacts_root.with_name(f".{artefacts_root.name}.previous")


def _recover_interrupted_replacement(artefacts_root: Path) -> None:
    backup_root = _backup_path(artefacts_root)
    if not backup_root.exists():
        return
    if artefacts_root.exists():
        raise ToolchainError(
            f"Previous curated snapshot backup still exists: {backup_root}"
        )
    backup_root.replace(artefacts_root)


def _replace_snapshot(staging_root: Path, artefacts_root: Path) -> None:
    """Install a complete staged tree, restoring the previous tree on failure."""

    backup_root = _backup_path(artefacts_root)
    had_previous = artefacts_root.exists()
    if had_previous:
        artefacts_root.replace(backup_root)
    try:
        staging_root.replace(artefacts_root)
    except OSError as exc:
        if had_previous:
            try:
                backup_root.replace(artefacts_root)
            except OSError as restore_exc:
                raise ToolchainError(
                    "Could not install or restore curated snapshot; "
                    f"backup remains at {backup_root}"
                ) from restore_exc
        raise ToolchainError("Could not install staged curated snapshot") from exc
    if had_previous:
        shutil.rmtree(backup_root)


if __name__ == "__main__":
    generate_all()
