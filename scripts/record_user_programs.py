"""Record the real toolchain's answer for each corpus user program, for the fake toolchain to replay.

With the user-programs stack up (`docker compose -f compose.user-programs.yaml up -d --build --wait`), run
from the irexplorer root:

    .venv/bin/python scripts/record_user_programs.py

Each program listed in tests/data/user-programs/corpus.json is sent, exactly as the app would send it, to
the stack's compiler service. The service has no published port, so it is reached inside its own container.
Its answer is written to the directory named after the program's stem, in the curated file layout: each
state's IR and remarks, the optimisation record, the -Rpass text and `manifest.json`; or, for a program
whose compile failed, `failure.json`. Recording talks to the compiler service rather than the app, so a
program the app cannot show is recorded all the same. The fake toolchain (tests/fake_toolchain) looks
the recordings up by the SHA-256 of the source, and `scripts/check_user_programs.sh` checks them for drift.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from src.backend.programs.accepted import accept_program  # noqa: E402 - needs ROOT on sys.path
from src.backend.toolchain.curated import PASS_STATES  # noqa: E402

CORPUS_ROOT = ROOT / "tests" / "data" / "user-programs"
COMPILER_CONTAINER = "irexplorer-user-programs-compiler-1"
# The compiler service's workspace in the compiler image, which every recorded command names.
IMAGE_WORKSPACE = "/workspace"
# Posts the request on stdin to the service from inside its container; prints the status, then the body.
RELAY = """
import sys, urllib.error, urllib.request
request = urllib.request.Request("http://127.0.0.1:8080/compile", data=sys.stdin.buffer.read(),
                                 headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(request, timeout=300) as response:
        status, body = response.status, response.read()
except urllib.error.HTTPError as error:
    status, body = error.code, error.read()
sys.stdout.buffer.write(b"%d\\n" % status + body)
"""


@dataclass(frozen=True)
class CorpusProgram:
    """A user program in the recorded corpus, with how the app answers it."""

    file_name: str
    # How POST /api/programs answers: {"status": …} and, for a refusal, the error's code and any reason.
    outcome: dict[str, Any]
    # A bound on a fresh compile of the program through the real stack, in seconds.
    within_seconds: float | None = None

    @property
    def stem(self) -> str:
        return self.file_name.removesuffix(".c")

    @property
    def source(self) -> str:
        return (CORPUS_ROOT / self.file_name).read_bytes().decode("utf-8")

    @property
    def recording_dir(self) -> Path:
        return CORPUS_ROOT / self.stem


def corpus() -> tuple[CorpusProgram, ...]:
    listed = json.loads((CORPUS_ROOT / "corpus.json").read_text(encoding="utf-8"))["programs"]
    return tuple(CorpusProgram(entry["fileName"], entry["outcome"], entry.get("withinSeconds")) for entry in listed)


class StackCompiler:
    """The compiler service of the running user-programs stack."""

    def __init__(self, container: str = COMPILER_CONTAINER) -> None:
        self.container = container

    def compile(self, file_name: str, source: str) -> tuple[int, dict[str, Any]]:
        """Send one program as the app does, and return the service's status and JSON answer."""
        request = json.dumps({"fileName": file_name, "source": source}).encode("utf-8")
        relayed = subprocess.run(["docker", "exec", "-i", self.container, "python3", "-c", RELAY],
                                 input=request, capture_output=True, check=False)
        if relayed.returncode != 0:
            raise RuntimeError(f"cannot reach the compiler service in {self.container}: "
                               f"{relayed.stderr.decode('utf-8', 'replace').strip()}")
        status, _, body = relayed.stdout.partition(b"\n")
        return int(status), json.loads(body)


def recording_files(stem: str, status: int, body: dict[str, Any], *,
                    workspace: str = IMAGE_WORKSPACE) -> dict[str, str]:
    """The compiler service's answer for one program as recording files, by name.

    A compiled program is recorded in the curated file layout with its manifest; a failed command as its
    error. Commands name ``/workspace`` whatever workspace the answering service ran in.
    """

    body = json.loads(json.dumps(body).replace(workspace, IMAGE_WORKSPACE))
    if status != 200:
        if body["error"]["code"] != "command_failed":
            raise RuntimeError(f"{stem}: the compiler service answered {status}: {body['error']}")
        return {"failure.json": _json(body["error"])}
    files = {}
    for state, answered in zip(PASS_STATES, body["states"], strict=True):
        files[f"{stem}_{state.file_suffix}.ll"] = answered["ir"]
        if answered["remarks"] is not None:
            files[f"{stem}_{state.file_suffix}_remarks.yaml"] = answered["remarks"]
    files[f"{stem}.opt.yaml"] = body["optRecord"]
    files[f"{stem}_remarks.txt"] = body["rpass"]
    files["manifest.json"] = _json(body["manifest"])
    return files


def recorded_files(directory: Path) -> dict[str, str]:
    return {path.name: path.read_bytes().decode("utf-8") for path in sorted(directory.iterdir()) if path.is_file()}


def differences(recorded: dict[str, str], answered: dict[str, str], *,
                ignoring: tuple[str, ...] = ("compilerImage",)) -> list[str]:
    """The names of the files that differ between two recordings, ignoring the named manifest fields."""

    def comparable(name: str, text: str) -> object:
        if name != "manifest.json":
            return text
        return {key: value for key, value in json.loads(text).items() if key not in ignoring}

    return [name for name in sorted(recorded.keys() | answered.keys())
            if name not in recorded or name not in answered
            or comparable(name, recorded[name]) != comparable(name, answered[name])]


def answered_outcome(status: int, body: dict[str, Any]) -> dict[str, Any]:
    """How the app answered a POST /api/programs, in the corpus's outcome form."""

    error = body.get("error", {}) if status >= 400 else {}
    return {"status": status, **{key: error[key] for key in ("code", "reason") if key in error}}


def record(program: CorpusProgram, compiler: StackCompiler) -> None:
    accepted = accept_program(program.file_name, program.source)
    if (accepted.file_name, accepted.source) != (program.file_name, program.source):
        raise ValueError(f"{program.file_name}: store the source as the app sends it, as {accepted.file_name} "
                         "with normalised text")
    files = recording_files(program.stem, *compiler.compile(program.file_name, program.source))
    shutil.rmtree(program.recording_dir, ignore_errors=True)
    program.recording_dir.mkdir()
    for name, text in files.items():
        (program.recording_dir / name).write_text(text, encoding="utf-8", newline="")


def main() -> None:
    compiler = StackCompiler()
    for program in corpus():
        record(program, compiler)
        print(f"Recorded {program.file_name} in {program.recording_dir.relative_to(ROOT)}")


def _json(value: Any) -> str:
    return json.dumps(value, indent=2) + "\n"


if __name__ == "__main__":
    main()
