"""Access to canonical curated LLVM artefacts."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shlex


REPO_ROOT = Path(__file__).resolve().parents[3]
EXAMPLES_ROOT = REPO_ROOT / "examples" / "curated"
ARTEFACTS_ROOT = REPO_ROOT / "artefacts" / "curated"


class ToolchainError(RuntimeError):
    """Raised when a curated artefact cannot be produced or resolved."""


@dataclass(frozen=True)
class PassState:
    state_id: str
    file_suffix: str
    pass_pipeline: str | None


PASS_STATES: tuple[PassState, ...] = (
    PassState("O0", "O0", None),
    PassState("mem2reg", "01_mem2reg", "mem2reg"),
    PassState("instcombine", "02_instcombine", "instcombine"),
    PassState("simplifycfg", "03_simplifycfg", "simplifycfg"),
    PassState("gvn", "04_gvn", "gvn"),
    PassState("cleanup", "05_cleanup", "instcombine,simplifycfg"),
    PassState("loop_canonical", "06_loop_canonical", "loop-simplify,lcssa"),
    PassState("loop_rotate", "07_loop_rotate", "loop-rotate"),
    PassState("licm", "08_licm", "licm"),
    PassState("indvars", "09_indvars", "indvars"),
    PassState("loop_cleanup", "10_loop_cleanup", "instcombine,simplifycfg"),
    PassState("vectorize", "11_vectorize", "loop-vectorize"),
    PassState("final_cleanup", "12_final_cleanup", "instcombine,simplifycfg"),
    PassState("O3", "O3", None),
)


def list_examples() -> tuple[str, ...]:
    """Return curated example IDs available as source inputs."""

    if not EXAMPLES_ROOT.exists():
        return ()
    return tuple(sorted(path.stem for path in EXAMPLES_ROOT.glob("*.c")))


def list_states() -> tuple[PassState, ...]:
    """Return the standard state sequence produced for every curated example."""

    return PASS_STATES


def artefact_dir(example: str) -> Path:
    _require_example(example)
    return ARTEFACTS_ROOT / example


def ir_path(example: str, state_id: str) -> Path:
    """Resolve the IR path for a generated curated example state."""

    state = _require_state(state_id)
    path = artefact_dir(example) / f"{example}_{state.file_suffix}.ll"
    if not path.exists():
        raise ToolchainError(
            f"Missing generated IR for example '{example}' state '{state_id}': {path}"
        )
    return path


def read_ir(example: str, state_id: str) -> str:
    """Read the textual IR for a generated curated example state."""

    return ir_path(example, state_id).read_text(encoding="utf-8")


def remarks_path(example: str) -> Path:
    path = artefact_dir(example) / f"{example}_remarks.txt"
    if not path.exists():
        raise ToolchainError(f"Missing optimisation remarks for example '{example}': {path}")
    return path


def opt_record_path(example: str) -> Path:
    path = artefact_dir(example) / f"{example}.opt.yaml"
    if not path.exists():
        raise ToolchainError(f"Missing optimisation record for example '{example}': {path}")
    return path


def manifest_path(example: str) -> Path:
    path = artefact_dir(example) / "manifest.txt"
    if not path.exists():
        raise ToolchainError(f"Missing command manifest for example '{example}': {path}")
    return path


def origin_command(example: str, state_id: str) -> str:
    """Resolve the exact toolchain command that produced a state's IR.

    Provenance is read back from the generated manifest by matching the
    command whose ``-o`` target is the state's ``.ll`` file, so the model can
    carry ``origin.command`` per state (R8, NFR3/NFR4). Persisting this into the
    serialised StateGraph is an S1.4 task.
    """

    state = _require_state(state_id)
    target = f"{example}_{state.file_suffix}.ll"
    for command in _manifest_commands(example):
        if _command_output(command) == target:
            return command
    raise ToolchainError(
        f"No recorded command for example '{example}' state '{state_id}' "
        f"(target '{target}') in {manifest_path(example)}"
    )


def generate_curated() -> None:
    """Regenerate curated artefacts through the pinned Docker toolchain."""

    from src.backend.toolchain.generate_curated import generate_all

    generate_all()


def _require_example(example: str) -> None:
    if example not in list_examples():
        available = ", ".join(list_examples()) or "<none>"
        raise ToolchainError(f"Unknown curated example '{example}'. Available examples: {available}")


def _require_state(state_id: str) -> PassState:
    for state in PASS_STATES:
        if state.state_id == state_id:
            return state
    available = ", ".join(state.state_id for state in PASS_STATES)
    raise ToolchainError(f"Unknown optimisation state '{state_id}'. Available states: {available}")


def _manifest_commands(example: str) -> tuple[str, ...]:
    commands: list[str] = []
    for line in manifest_path(example).read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- "):
            commands.append(stripped[2:].strip())
    return tuple(commands)


def _command_output(command: str) -> str | None:
    tokens = shlex.split(command)
    if "-o" not in tokens:
        return None
    index = tokens.index("-o")
    if index + 1 >= len(tokens):
        return None
    return Path(tokens[index + 1]).name
