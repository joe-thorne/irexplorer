"""Integrity checks for the canonical curated artefact snapshot."""

from __future__ import annotations

import hashlib
from pathlib import Path

from src.backend.toolchain.curated import ARTEFACTS_ROOT, REPO_ROOT, ToolchainError


CHECKSUM_PATH = REPO_ROOT / "docs" / "curated-artefacts.sha256"


def curated_tree_digest() -> tuple[int, str]:
    """Return a deterministic digest over every generated curated artefact."""

    files = tuple(sorted(path for path in ARTEFACTS_ROOT.rglob("*") if path.is_file()))
    digest = hashlib.sha256()
    for path in files:
        relative_path = path.relative_to(REPO_ROOT).as_posix().encode("utf-8")
        digest.update(relative_path)
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
        digest.update(b"\n")
    return len(files), digest.hexdigest()


def verify_curated_snapshot() -> None:
    """Reject a curated snapshot that diverges from the pinned golden digest."""

    expected_count, expected_digest = _read_expected_digest()
    actual_count, actual_digest = curated_tree_digest()
    if (actual_count, actual_digest) != (expected_count, expected_digest):
        raise ToolchainError(
            "Canonical curated artefacts differ from the pinned snapshot: "
            f"expected {expected_count}/{expected_digest}, "
            f"got {actual_count}/{actual_digest}. Regenerate deliberately and "
            "update docs/curated-artefacts.sha256 after review."
        )


def _read_expected_digest() -> tuple[int, str]:
    if not CHECKSUM_PATH.exists():
        raise ToolchainError(f"Missing curated artefact checksum: {CHECKSUM_PATH}")
    values: dict[str, str] = {}
    for line in CHECKSUM_PATH.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if not separator:
            raise ToolchainError(f"Malformed curated artefact checksum: {line}")
        values[key.strip()] = value.strip()
    try:
        return int(values["files"]), values["sha256"]
    except (KeyError, ValueError) as exc:
        raise ToolchainError(f"Malformed curated artefact checksum: {CHECKSUM_PATH}") from exc
