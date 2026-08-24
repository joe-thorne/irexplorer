"""Generate canonical curated LLVM artefacts through Docker."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile

from src.backend.toolchain import curated as curated_paths
from src.backend.toolchain.curated import (
    ARTEFACTS_ROOT,
    EXAMPLES_ROOT,
    PASS_STATES,
    REPO_ROOT,
    ToolchainError,
    list_examples,
)


WORKSPACE_ROOT = Path("/workspace")


def generate_all(*, artefacts_root: Path = ARTEFACTS_ROOT) -> None:
    """Stage and transactionally replace the complete curated snapshot."""

    artefacts_root.parent.mkdir(parents=True, exist_ok=True)
    _recover_interrupted_replacement(artefacts_root)
    staging_root = Path(
        tempfile.mkdtemp(
            prefix=f".{artefacts_root.name}.staging-",
            dir=artefacts_root.parent,
        )
    )
    try:
        _generate_snapshot(staging_root)
        _replace_snapshot(staging_root, artefacts_root)
    except BaseException:
        if staging_root.exists():
            shutil.rmtree(staging_root)
        raise


def _generate_snapshot(staging_root: Path) -> None:
    """Generate raw artefacts and derived model records in one staged tree."""

    for example in list_examples():
        print(f"Generating {example}")
        _generate_example(example, artefacts_root=staging_root)

    # The compiler artefacts, model snapshots, and comparison overlays share
    # this one offline path: runtime consumes serialised records, never raw IR.
    from src.backend.ingest.curated import bake_curated_model_records
    from src.backend.analysis.curated import bake_curated_comparison_records

    with curated_paths.using_artefacts_root(staging_root):
        bake_curated_model_records()
        bake_curated_comparison_records()


def _generate_example(example: str, *, artefacts_root: Path) -> None:
    source = EXAMPLES_ROOT / f"{example}.c"
    if not source.exists():
        raise ToolchainError(f"Missing curated source: {source}")

    out_dir = artefacts_root / example
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)
    canonical_out_dir = ARTEFACTS_ROOT / example

    manifest = out_dir / "manifest.txt"
    _write_manifest_header(manifest, example, source, artefacts_root)

    baseline_ll = canonical_out_dir / f"{example}_O0.ll"
    baseline_bc = canonical_out_dir / f"{example}_O0.bc"

    _run_and_record(
        manifest,
        [
            "clang",
            "-O0",
            "-g",
            "-Xclang",
            "-disable-O0-optnone",
            "-fno-discard-value-names",
            "-S",
            "-emit-llvm",
            _container_path(source),
            "-o",
            _container_path(baseline_ll),
        ],
        artefacts_root=artefacts_root,
    )
    _run_and_record(
        manifest,
        [
            "clang",
            "-O0",
            "-g",
            "-Xclang",
            "-disable-O0-optnone",
            "-fno-discard-value-names",
            "-emit-llvm",
            "-c",
            _container_path(source),
            "-o",
            _container_path(baseline_bc),
        ],
        artefacts_root=artefacts_root,
    )

    previous = baseline_bc
    for state in PASS_STATES[1:-1]:
        if state.pass_pipeline is None:
            raise ToolchainError(f"Pass state '{state.state_id}' has no pass pipeline")
        output = canonical_out_dir / f"{example}_{state.file_suffix}.ll"
        remarks_output = canonical_out_dir / f"{example}_{state.file_suffix}_remarks.yaml"
        _run_and_record(
            manifest,
            [
                "opt",
                f"-passes={state.pass_pipeline}",
                "-pass-remarks=.*",
                "-pass-remarks-missed=.*",
                "-pass-remarks-analysis=.*",
                f"-pass-remarks-output={_container_path(remarks_output)}",
                _container_path(previous),
                "-S",
                "-o",
                _container_path(output),
            ],
            artefacts_root=artefacts_root,
        )
        previous = output

    _run_and_record(
        manifest,
        [
            "clang",
            "-O3",
            "-g",
            "-fno-discard-value-names",
            "-S",
            "-emit-llvm",
            _container_path(source),
            "-o",
            _container_path(canonical_out_dir / f"{example}_O3.ll"),
        ],
        artefacts_root=artefacts_root,
    )
    _run_and_record(
        manifest,
        [
            "clang",
            "-O3",
            "-g",
            "-fno-discard-value-names",
            "-Rpass=.*",
            "-Rpass-missed=.*",
            "-Rpass-analysis=.*",
            "-fsave-optimization-record",
            _container_path(source),
            "-c",
            "-o",
            _container_path(canonical_out_dir / f"{example}.o"),
        ],
        artefacts_root=artefacts_root,
        stderr_path=out_dir / f"{example}_remarks.txt",
    )


def _write_manifest_header(
    manifest: Path,
    example: str,
    source: Path,
    artefacts_root: Path,
) -> None:
    manifest.write_text(
        "\n".join(
            [
                f"example: {example}",
                f"source: {source.relative_to(REPO_ROOT)}",
                "clang: "
                + _tool_version(
                    ["clang", "--version"],
                    line_index=0,
                    artefacts_root=artefacts_root,
                ),
                "opt: "
                + _tool_version(
                    ["opt", "--version"],
                    line_index=1,
                    artefacts_root=artefacts_root,
                ),
                "targetTriple: x86_64-unknown-linux-gnu",
                "commands:",
            ]
        )
        + "\n",
        encoding="utf-8",
    )


def _run_and_record(
    manifest: Path,
    command: list[str],
    artefacts_root: Path,
    stderr_path: Path | None = None,
) -> None:
    with manifest.open("a", encoding="utf-8") as manifest_file:
        manifest_file.write(f"  - {_format_command(command)}\n")

    result = subprocess.run(
        _docker_command(command, artefacts_root),
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )

    stderr_text = _clean_docker_stderr(result.stderr)
    if stderr_path is not None:
        stderr_path.write_text(stderr_text, encoding="utf-8")

    if result.returncode != 0:
        detail = f": {stderr_text.strip()}" if stderr_text.strip() else ""
        raise ToolchainError(
            f"Toolchain command failed with exit code {result.returncode}{detail}"
        )


def _tool_version(
    command: list[str],
    line_index: int,
    artefacts_root: Path,
) -> str:
    result = subprocess.run(
        _docker_command(command, artefacts_root),
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise ToolchainError(
            f"Could not read tool version with '{_format_command(command)}': {result.stderr.strip()}"
        )
    lines = result.stdout.splitlines()
    if len(lines) <= line_index:
        raise ToolchainError(f"Unexpected version output from '{_format_command(command)}'")
    return lines[line_index].strip()


def _docker_command(command: list[str], artefacts_root: Path) -> list[str]:
    container_root = _container_path(ARTEFACTS_ROOT)
    return [
        "docker",
        "compose",
        "run",
        "--rm",
        "--no-TTY",
        "--volume",
        f"{artefacts_root}:{container_root}",
        "toolchain",
        *command,
    ]


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


def _container_path(path: Path) -> str:
    return str(WORKSPACE_ROOT / path.relative_to(REPO_ROOT))


def _format_command(command: list[str]) -> str:
    return " ".join(_quote(arg) for arg in command)


def _clean_docker_stderr(stderr: str) -> str:
    return "\n".join(
        line
        for line in stderr.splitlines()
        if not (line.startswith(" Container ") and line.rstrip().endswith((" Creating", "Created")))
    ) + ("\n" if stderr.endswith("\n") else "")


def _quote(arg: str) -> str:
    if all(ch.isalnum() or ch in "/._=-" for ch in arg):
        return arg
    return "'" + arg.replace("'", "'\\''") + "'"


if __name__ == "__main__":
    generate_all()
