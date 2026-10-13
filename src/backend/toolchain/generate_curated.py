"""Generate canonical curated LLVM artefacts through Docker."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from src.backend.toolchain.curated import (
    ARTEFACTS_ROOT,
    EXAMPLES_ROOT,
    PASS_STATES,
    REPO_ROOT,
    ToolchainError,
    list_examples,
)

WORKSPACE_ROOT = Path("/workspace")
# The line of each tool's --version output that names its version.
VERSION_LINE = {"clang": 0, "opt": 1}


def generate_snapshot(staging_root: Path) -> None:
    """Generate the raw curated artefacts in an already staged tree."""

    _generate_snapshot(staging_root)


def _generate_snapshot(staging_root: Path) -> None:
    """Generate raw artefacts for each curated example."""

    for example in list_examples():
        print(f"Generating {example}")
        _generate_example(example, artefacts_root=staging_root)


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

    commands = pass_sequence_commands(
        _container_path(source), _container_path(canonical_out_dir), example
    )
    for command in commands[:-1]:
        _run_and_record(manifest, command, artefacts_root=artefacts_root)
    _run_and_record(
        manifest,
        commands[-1],
        artefacts_root=artefacts_root,
        stderr_path=out_dir / f"{example}_remarks.txt",
    )


def pass_sequence_commands(source: str, output_dir: str, stem: str) -> list[list[str]]:
    """Return the sixteen commands that compile one C source through the curated pass sequence.

    Two ``clang -O0`` compiles (IR and bitcode), the twelve ``opt`` steps one pass at a time, then two
    ``clang -O3`` compiles: the recompiled IR, and an object whose stderr is the ``-Rpass`` text and
    beside which ``-fsave-optimization-record`` writes ``<stem>.opt.yaml``. Outputs are named
    ``<stem>_<file suffix>.ll`` in ``output_dir``. The curated generator and the compiler service both
    run exactly these, so a user program is compiled as a curated example is.
    """

    def output(name: str) -> str:
        return f"{output_dir}/{name}"

    commands = [
        [
            "clang",
            "-O0",
            "-g",
            "-Xclang",
            "-disable-O0-optnone",
            "-fno-discard-value-names",
            "-S",
            "-emit-llvm",
            source,
            "-o",
            output(f"{stem}_O0.ll"),
        ],
        [
            "clang",
            "-O0",
            "-g",
            "-Xclang",
            "-disable-O0-optnone",
            "-fno-discard-value-names",
            "-emit-llvm",
            "-c",
            source,
            "-o",
            output(f"{stem}_O0.bc"),
        ],
    ]
    previous = output(f"{stem}_O0.bc")
    for state in PASS_STATES[1:-1]:
        if state.pass_pipeline is None:
            raise ToolchainError(f"Pass state '{state.state_id}' has no pass pipeline")
        ir_output = output(f"{stem}_{state.file_suffix}.ll")
        commands.append(
            [
                "opt",
                f"-passes={state.pass_pipeline}",
                "-pass-remarks=.*",
                "-pass-remarks-missed=.*",
                "-pass-remarks-analysis=.*",
                f"-pass-remarks-output={output(f'{stem}_{state.file_suffix}_remarks.yaml')}",
                previous,
                "-S",
                "-o",
                ir_output,
            ]
        )
        previous = ir_output
    commands.append(
        [
            "clang",
            "-O3",
            "-g",
            "-fno-discard-value-names",
            "-S",
            "-emit-llvm",
            source,
            "-o",
            output(f"{stem}_O3.ll"),
        ]
    )
    commands.append(
        [
            "clang",
            "-O3",
            "-g",
            "-fno-discard-value-names",
            "-Rpass=.*",
            "-Rpass-missed=.*",
            "-Rpass-analysis=.*",
            "-fsave-optimization-record",
            source,
            "-c",
            "-o",
            output(f"{stem}.o"),
        ]
    )
    return commands


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
                "clang: " + _tool_version("clang", artefacts_root),
                "opt: " + _tool_version("opt", artefacts_root),
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
        manifest_file.write(f"  - {format_command(command)}\n")

    result = subprocess.run(
        _docker_command(command, artefacts_root),
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
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


def version_line(tool: str, output: str) -> str:
    """The line of ``tool --version`` output that names the version: clang's first, opt's second."""

    lines = output.splitlines()
    if len(lines) <= VERSION_LINE[tool]:
        raise ToolchainError(f"Unexpected version output from '{tool} --version'")
    return lines[VERSION_LINE[tool]].strip()


def _tool_version(tool: str, artefacts_root: Path) -> str:
    command = [tool, "--version"]
    result = subprocess.run(
        _docker_command(command, artefacts_root),
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise ToolchainError(
            f"Could not read tool version with '{format_command(command)}': {result.stderr.strip()}"
        )
    return version_line(tool, result.stdout)


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


def _container_path(path: Path) -> str:
    return str(WORKSPACE_ROOT / path.relative_to(REPO_ROOT))


def format_command(command: list[str]) -> str:
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
