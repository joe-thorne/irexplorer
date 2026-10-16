"""Fake clang and opt that replay recorded compiler artefacts, so tests need no LLVM.

The compiler service runs these exactly as it runs the pinned toolchain, with the curated pass sequence
commands. Nothing is compiled: each output is the artefact recorded for the same command on the same
source, looked up by the SHA-256 of the source text (the normalised source the service was sent).

The recordings are the committed curated artefacts of the three unedited curated sources, with their
`examples/curated` paths rewritten to `user-programs`, as the compiler service would have written them,
and the corpus in tests/data/user-programs, recorded from the real toolchain in the same layout by
scripts/record_user_programs.py. The -O0 emit command prints its recorded stderr (clang's warnings), or
nothing if none was recorded. A recorded failure (`failure.json`) replays its failing command's stderr
and exit status. A source with no recording fails with a distinct "no recording" message and exit
status, so a mistake in a test never looks like a compile failure.

A marker line, `// irx-fake: <marker>`, chooses a failure instead of a replay:

- `error`: clang fails as the pinned clang does on each call to an undeclared `abss` (a typo for `abs`),
  with a note in the system header and the `/workspace` paths the compiler image would print.
- `crash`: clang succeeds and opt crashes on the first pass, as an LLVM crash reports itself.
- `hang`: clang never finishes, in a child process that keeps writing its output, as clang's own
  `-cc1` child would.
- `slow`: clang spends a couple of seconds in the first command, then the rest of the source (without
  its marker line) replays as recorded, so a marker can be added to a recorded source.
"""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from src.backend.toolchain import curated  # noqa: E402
from src.backend.toolchain.compiler_service import SOURCE_DIRECTORY, WORKSPACE  # noqa: E402
from src.backend.toolchain.generate_curated import format_command  # noqa: E402

NO_RECORDING = 86
MARKER = re.compile(r"^[ \t]*// irx-fake: (\w+)[ \t]*$", re.MULTILINE)
# The compiler service's workspace in the compiler image, where a failure's printed paths start.
IMAGE_WORKSPACE = WORKSPACE
USER_PROGRAMS = REPO_ROOT / "tests" / "data" / "user-programs"
# clang's default -ferror-limit.
ERROR_LIMIT = 20
# The stand-in IR a crash-marked source compiles to, which the fake opt crashes on.
CRASH_IR = "; irx-fake: crash\n"
# A slow program spends this long in its first command, then compiles as its recording says.
SLOW_SECONDS = 2.0
# A hanging clang's child keeps writing its output until it is stopped. It gives up after a minute, so a
# compiler service that fails to stop it leaks nothing for long.
HANG = """
import sys, time
from pathlib import Path
output = Path(sys.argv[1])
for _ in range(3000):
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(b"hanging\\n")
    time.sleep(0.02)
"""


@dataclass(frozen=True)
class Recording:
    """Every compiler artefact of the curated pass sequence for one source, in the curated file layout."""

    directory: Path
    stem: str

    def text(self, name: str) -> str:
        text = (self.directory / name).read_text(encoding="utf-8")
        return text.replace("examples/curated", SOURCE_DIRECTORY)

    def ir(self, state: curated.PassState) -> str:
        return self.text(f"{self.stem}_{state.file_suffix}.ll")

    def pass_remarks(self, state: curated.PassState) -> str:
        return self.text(f"{self.stem}_{state.file_suffix}_remarks.yaml")

    @property
    def o0_stderr(self) -> str:
        """What the -O0 emit command printed: clang's warnings, recorded only for a program that has any."""
        path = self.directory / f"{self.stem}_O0_stderr.txt"
        return self.text(path.name) if path.exists() else ""

    @property
    def failure(self) -> dict[str, str] | None:
        """The compiler service's error for a recorded program whose compile failed."""
        path = self.directory / "failure.json"
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None

    def manifest_line(self, key: str) -> str:
        for line in self.text("manifest.txt").splitlines():
            if line.startswith(f"{key}: "):
                return line.removeprefix(f"{key}: ")
        raise LookupError(f"manifest has no {key} line")


def recordings() -> dict[str, Recording]:
    """Recordings keyed by the SHA-256 of their source text: the curated examples first, then the user programs."""

    found = {
        _digest(curated.source_path(example).read_bytes()): Recording(curated.artefact_dir(example), example)
        for example in curated.list_examples()
    }
    for program in json.loads((USER_PROGRAMS / "corpus.json").read_text(encoding="utf-8"))["programs"]:
        stem = program["fileName"].removesuffix(".c")
        found[_digest((USER_PROGRAMS / program["fileName"]).read_bytes())] = Recording(USER_PROGRAMS / stem, stem)
    return found


def clang(args: list[str]) -> int:
    if args == ["--version"]:
        print(_any_recording().manifest_line("clang"))
        print("Target: x86_64-unknown-linux-gnu")
        return 0
    source = Path(next(arg for arg in args if arg.endswith(".c")))
    output = Path(_after(args, "-o"))
    text = source.read_bytes().decode("utf-8")
    failure = _marker(text)
    if failure == "error":
        return _undeclared_abss(source)
    if failure == "crash":
        output.write_text(CRASH_IR, encoding="utf-8")
        return 0
    if failure == "hang":
        return subprocess.run([sys.executable, "-c", HANG, str(output)], check=False).returncode
    if failure == "slow" and "-O0" in args and "-S" in args:
        time.sleep(SLOW_SECONDS)
    digest = _digest("".join(line for line in text.splitlines(keepends=True)
                             if not MARKER.fullmatch(line.rstrip("\r\n"))).encode("utf-8"))
    recording = recordings().get(digest)
    if recording is None:
        return _no_recording(f"source sha256 {digest}")
    if recording.failure is not None:
        return _failed(recording.failure, ["clang", *args])
    level = curated.PASS_STATES[0] if "-O0" in args else curated.PASS_STATES[-1]
    if "-S" in args:
        output.write_text(recording.ir(level), encoding="utf-8")
        if level is curated.PASS_STATES[0]:
            sys.stderr.write(recording.o0_stderr)
    elif "-emit-llvm" in args:
        # Stand-in bitcode: the O0 IR text, which the fake opt recognises as its first input.
        output.write_text(recording.ir(level), encoding="utf-8")
    else:
        output.write_bytes(b"fake object\n")
        output.with_suffix(".opt.yaml").write_text(recording.text(f"{recording.stem}.opt.yaml"), encoding="utf-8")
        sys.stderr.write(recording.text(f"{recording.stem}_remarks.txt"))
    return 0


def opt(args: list[str]) -> int:
    if args == ["--version"]:
        print("LLVM (http://llvm.org/):")
        print(f"  {_any_recording().manifest_line('opt')}")
        return 0
    pipeline = _option(args, "-passes=")
    remarks_output = Path(_option(args, "-pass-remarks-output="))
    output = Path(_after(args, "-o"))
    (input_path,) = [arg for arg in args if not arg.startswith("-") and arg != str(output)]
    received = Path(input_path).read_text(encoding="utf-8")
    if received == CRASH_IR:
        return _crash(args, input_path)
    for recording in recordings().values():
        if recording.failure is not None:
            continue
        for previous, state in zip(curated.PASS_STATES[:-2], curated.PASS_STATES[1:-1], strict=True):
            if recording.ir(previous) != received:
                continue
            if state.pass_pipeline != pipeline:
                print(f"irx-fake: expected -passes={state.pass_pipeline} after {previous.state_id}, "
                      f"not -passes={pipeline}", file=sys.stderr)
                return NO_RECORDING
            output.write_text(recording.ir(state), encoding="utf-8")
            remarks_output.write_text(recording.pass_remarks(state), encoding="utf-8")
            return 0
    return _no_recording(f"opt input {input_path}")


def _failed(failure: dict[str, str], command: list[str]) -> int:
    """Fail as the recorded command did; a recorded failure has no artefacts for any other command."""

    if failure["command"] != format_command(command).replace(str(Path.cwd()), str(IMAGE_WORKSPACE)):
        return _no_recording(f"command {format_command(command)}")
    sys.stderr.write(failure["stderr"])
    return int(re.fullmatch(r".* exited with status (\d+)\.", failure["message"]).group(1))


def _undeclared_abss(source: Path) -> int:
    """Fail as the pinned clang does on each call to an undeclared ``abss``, up to its error limit."""

    path = _in_image(source)
    calls = [(number, call.start() + 1, line)
             for number, line in enumerate(source.read_text(encoding="utf-8").splitlines(), start=1)
             for call in re.finditer(r"\babss\(", line)]
    if not calls:
        print("irx-fake: an error marker needs a call to abss", file=sys.stderr)
        return NO_RECORDING
    report = []
    for number, column, line in calls[:ERROR_LIMIT]:
        report += [
            f"{path}:{number}:{column}: error: call to undeclared function 'abss'; ISO C99 and later do not "
            "support implicit function declarations [-Wimplicit-function-declaration]",
            f"{number:5} | {line}",
            f"{'':5} | {' ' * (column - 1)}^",
            f"{path}:{number}:{column}: note: did you mean 'abs'?",
            "/usr/include/stdlib.h:980:12: note: 'abs' declared here",
            "  980 | extern int abs (int __x) __THROW __attribute__ ((__const__)) __wur;",
            "      |            ^",
        ]
    if len(calls) > ERROR_LIMIT:
        report.append("fatal error: too many errors emitted, stopping now [-ferror-limit=]")
    errors = min(len(calls), ERROR_LIMIT)
    report.append(f"{errors} error{'' if errors == 1 else 's'} generated.")
    print("\n".join(report), file=sys.stderr)
    return 1


def _crash(args: list[str], input_path: str) -> int:
    """Crash as opt does on an internal error: a stack dump naming the command and the pass it was running."""

    command = " ".join(["opt", *args]).replace(str(Path.cwd()), str(IMAGE_WORKSPACE))
    print("PLEASE submit a bug report to https://github.com/llvm/llvm-project/issues/ and include the crash "
          "backtrace.", file=sys.stderr)
    print("Stack dump:", file=sys.stderr)
    print(f"0.\tProgram arguments: {command}", file=sys.stderr)
    print(f'1.\tRunning pass "{_option(args, "-passes=")}" on module "{_in_image(Path(input_path))}"',
          file=sys.stderr)
    print(" #0 0x00005581c0de1f2a llvm::sys::PrintStackTrace(llvm::raw_ostream&, int)", file=sys.stderr)
    return 139


def _marker(source: str) -> str | None:
    match = MARKER.search(source)
    return match.group(1) if match else None


def _in_image(path: Path) -> Path:
    """A workspace path as the compiler image names it: the service runs every command from its workspace."""

    return IMAGE_WORKSPACE / path.relative_to(Path.cwd())


def _no_recording(what: str) -> int:
    print(f"irx-fake: no recording for {what}", file=sys.stderr)
    return NO_RECORDING


def _any_recording() -> Recording:
    return next(iter(recordings().values()))


def _digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _after(args: list[str], flag: str) -> str:
    return args[args.index(flag) + 1]


def _option(args: list[str], prefix: str) -> str:
    return next(arg.removeprefix(prefix) for arg in args if arg.startswith(prefix))
