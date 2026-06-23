"""Generate canonical curated LLVM artefacts through Docker."""

from __future__ import annotations

from pathlib import Path
import shutil
import subprocess

from src.backend.toolchain.curated import (
    ARTEFACTS_ROOT,
    EXAMPLES_ROOT,
    PASS_STATES,
    REPO_ROOT,
    ToolchainError,
    list_examples,
)


WORKSPACE_ROOT = Path("/workspace")


def generate_all() -> None:
    """Regenerate all curated artefacts through the pinned Docker toolchain."""

    ARTEFACTS_ROOT.mkdir(parents=True, exist_ok=True)
    for example in list_examples():
        print(f"Generating {example}")
        generate_example(example)


def generate_example(example: str) -> None:
    source = EXAMPLES_ROOT / f"{example}.c"
    if not source.exists():
        raise ToolchainError(f"Missing curated source: {source}")

    out_dir = ARTEFACTS_ROOT / example
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    manifest = out_dir / "manifest.txt"
    _write_manifest_header(manifest, example, source)

    baseline_ll = out_dir / f"{example}_O0.ll"
    baseline_bc = out_dir / f"{example}_O0.bc"

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
    )

    previous = baseline_bc
    for state in PASS_STATES[1:-1]:
        if state.pass_pipeline is None:
            raise ToolchainError(f"Pass state '{state.state_id}' has no pass pipeline")
        output = out_dir / f"{example}_{state.file_suffix}.ll"
        _run_and_record(
            manifest,
            [
                "opt",
                f"-passes={state.pass_pipeline}",
                _container_path(previous),
                "-S",
                "-o",
                _container_path(output),
            ],
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
            _container_path(out_dir / f"{example}_O3.ll"),
        ],
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
            _container_path(out_dir / f"{example}.o"),
        ],
        stderr_path=out_dir / f"{example}_remarks.txt",
    )


def _write_manifest_header(manifest: Path, example: str, source: Path) -> None:
    manifest.write_text(
        "\n".join(
            [
                f"example: {example}",
                f"source: {source.relative_to(REPO_ROOT)}",
                f"clang: {_tool_version(['clang', '--version'], line_index=0)}",
                f"opt: {_tool_version(['opt', '--version'], line_index=1)}",
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
    stderr_path: Path | None = None,
) -> None:
    with manifest.open("a", encoding="utf-8") as manifest_file:
        manifest_file.write(f"  - {_format_command(command)}\n")

    result = subprocess.run(
        _docker_command(command),
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


def _tool_version(command: list[str], line_index: int) -> str:
    result = subprocess.run(
        _docker_command(command),
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


def _docker_command(command: list[str]) -> list[str]:
    return ["docker", "compose", "run", "--rm", "--no-TTY", "toolchain", *command]


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
