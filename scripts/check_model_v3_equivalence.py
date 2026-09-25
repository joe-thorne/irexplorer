#!/usr/bin/env python3
"""Compare v3 records and reports with a v2 checkout under the declared renames."""

from __future__ import annotations

import argparse
import json
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from src.backend.api import QueryService
from tests.test_summary_digests import comparison_report_responses, normalise_report_renames

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE_RENAMES = (
    (
        "conservative anchor match on unique basic-block label",
        "conservative match to the separately recompiled O3 state by unique basic-block label",
    ),
    (
        "conservative anchor match on unique debug source location and opcode",
        "conservative match to the separately recompiled O3 state by unique debug source location and opcode",
    ),
    (
        "conservative anchor match on unique debug source location after rewrite",
        "conservative match to the separately recompiled O3 state by unique debug source location after rewrite",
    ),
)
CONTEXT_RENAMES = (
    (
        "Recompiled -O3 anchor comparison: these are output differences, not the effect of one optimisation pass.",
        "Comparison with the separately recompiled -O3 state: these are output differences, "
        "not the effect of one optimisation pass.",
    ),
    (
        "ending at the recompiled -O3 anchor:",
        "ending at the separately recompiled -O3 state:",
    ),
)


def normalise_v2_to_v3(value: Any, *, key: str | None = None) -> Any:
    if isinstance(value, dict):
        return {name: normalise_v2_to_v3(item, key=name) for name, item in value.items()}
    if isinstance(value, list):
        return [normalise_v2_to_v3(item) for item in value]
    if key == "formatVersion" and value == 2:
        return 3
    if key == "configId" and value == "teaching-pass-chain":
        return "curated-pass-sequence"
    if key == "confidence" and value == "none":
        return "unresolved"
    if isinstance(value, str):
        for old, new in (*EVIDENCE_RENAMES, *CONTEXT_RENAMES):
            value = value.replace(old, new)
        return (
            value.replace("(none;", "(unresolved;")
            .replace(" transitions,", " steps,")
            .replace("derived transitions.", "derived steps.")
        )
    return value


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def compare_model_records(previous_root: Path) -> int:
    previous = previous_root / "artefacts" / "curated"
    current = ROOT / "artefacts" / "curated"
    count = 0
    for old_path in sorted(previous.glob("*/model/**/*.json")):
        relative = old_path.relative_to(previous)
        new_path = current / relative
        if (
            not new_path.is_file()
            or normalise_v2_to_v3(read_json(old_path)) != read_json(new_path)
        ):
            raise SystemExit(f"model record differs beyond the declared renames: {relative}")
        count += 1
    if count == 0 or len(list(current.glob("*/model/**/*.json"))) != count:
        raise SystemExit("the old and new model record sets differ")
    return count


def compare_compiler_artefacts(previous_root: Path) -> int:
    previous = previous_root / "artefacts" / "curated"
    current = ROOT / "artefacts" / "curated"
    old_files = {
        path.relative_to(previous): path
        for path in previous.rglob("*")
        if path.is_file() and "model" not in path.relative_to(previous).parts
    }
    new_files = {
        path.relative_to(current): path
        for path in current.rglob("*")
        if path.is_file() and "model" not in path.relative_to(current).parts
    }
    if old_files.keys() != new_files.keys():
        raise SystemExit("the old and new compiler artefact file sets differ")
    for relative, old_path in old_files.items():
        if old_path.read_bytes() != new_files[relative].read_bytes():
            raise SystemExit(f"compiler artefact changed: {relative}")
    return len(old_files)


def compare_responses(previous_root: Path) -> int:
    old_python = previous_root / ".venv" / "bin" / "python"
    if not old_python.is_file():
        raise SystemExit(f"baseline virtualenv is required at {old_python}")
    with tempfile.TemporaryDirectory(prefix="irexplorer-v3-equivalence-") as temporary:
        old_dir = Path(temporary) / "old"
        new_dir = Path(temporary) / "new"
        old_dir.mkdir()
        new_dir.mkdir()
        subprocess.run(
            [str(old_python), "-m", "tests.test_summary_digests", "--dump", str(old_dir)],
            cwd=previous_root,
            check=True,
        )
        for span, response in comparison_report_responses(QueryService()):
            name = span.replace(" ", "_") + ".json"
            (new_dir / name).write_text(
                json.dumps(normalise_report_renames(response), ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        old_files = {path.name for path in old_dir.glob("*.json")}
        new_files = {path.name for path in new_dir.glob("*.json")}
        if old_files != new_files:
            raise SystemExit("the old and new comparison response sets differ")
        for name in sorted(old_files):
            if normalise_v2_to_v3(read_json(old_dir / name)) != read_json(new_dir / name):
                raise SystemExit(f"comparison response differs beyond the declared renames: {name}")
        return len(old_files)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("previous_checkout", type=Path)
    previous_root = parser.parse_args().previous_checkout.resolve()
    compiler_artefacts = compare_compiler_artefacts(previous_root)
    records = compare_model_records(previous_root)
    responses = compare_responses(previous_root)
    print(
        f"Equivalent under declared v2-to-v3 renames: {records} model records, "
        f"{responses} comparison response payloads; {compiler_artefacts} "
        "compiler artefacts byte-identical."
    )


if __name__ == "__main__":
    main()
