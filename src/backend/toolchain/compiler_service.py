"""The compiler service: compiles one user program on request with the pinned toolchain.

It runs in its own container beside the app, and is a small standard-library HTTP server so that it
needs nothing installed there but Python. It runs exactly the curated commands on
``<workspace>/user-programs/<fileName>``, from the workspace, writing outputs to ``<workspace>/out``,
and wipes both after every program. It returns only text: each state's IR and remarks, the ``-Rpass``
text, the optimisation record and the manifest. Bitcode and object files never leave it, and
interpreting a failure (such as parsing diagnostics) is the app's job.

Tests run the same code on loopback, pointed at a fake toolchain with ``--toolchain``:

    python -m src.backend.toolchain.compiler_service --port 7560 --toolchain tests/fake_toolchain \\
        --workspace "$(mktemp -d)"
"""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import select
import shutil
import signal
import socket
import subprocess
import sys
import time
from collections.abc import Callable
from dataclasses import dataclass, field
from functools import cached_property
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
from pathlib import Path
from threading import Lock
from typing import Any

from src.backend.toolchain.curated import PASS_STATES, PassState
from src.backend.toolchain.generate_curated import format_command, pass_sequence_commands

# The service's workspace in the compiler image, which the paths in its commands and output name.
WORKSPACE = Path("/workspace")
# The workspace directory a program's source is written to.
SOURCE_DIRECTORY = "user-programs"
TARGET_TRIPLE = "x86_64-unknown-linux-gnu"
# The app sends only safe file names; the service refuses anything else, so no name leaves the workspace.
SAFE_FILE_NAME = re.compile(r"[A-Za-z0-9_-]{1,64}\.c")
# How often a running command is checked against the deadline and its client's connection.
POLL_INTERVAL = 0.05
# A compile whose client has gone stops at its next poll; a request arriving meanwhile waits this long at
# most for it, rather than being refused as busy.
STOPPING_GRACE = 5.0
# Reading the tool versions is not a compile, so the compile timeout does not bound it.
VERSION_TIMEOUT = 30.0
# Busy and timeout messages are shown to the student as they are.
BUSY = "The compiler is busy with another program. Try again in a moment."
TIMED_OUT = "The compile took longer than {:g} s and was stopped."


class CompileError(Exception):
    """A compile the service refused or could not finish, answered as ``{"error": {...}}``."""

    def __init__(self, status: HTTPStatus, code: str, message: str, **details: str) -> None:
        super().__init__(message)
        self.status = status
        self.body = {"code": code, "message": message, **details}


class ClientDisconnected(Exception):
    """The client went away mid-compile, so nobody is waiting for the answer: the compile is stopped."""


def never() -> bool:
    """A client that never disconnects, for work no client waits on (such as reading the tool versions)."""
    return False


@dataclass
class RunningCompile:
    """The running compile's check for whether its client has gone; ``never`` while no compile runs."""

    disconnected: Callable[[], bool] = never


@dataclass(frozen=True)
class CompilerService:
    """Runs the curated pass sequence for one program at a time in a wiped workspace."""

    # Directory holding ``clang`` and ``opt``; None finds them on PATH, as in the compiler image.
    toolchain: Path | None = None
    workspace: Path = WORKSPACE
    # Seconds allowed for a whole program, every command included.
    timeout: float = 30.0
    compiler_image: str = "unknown"
    libc_version: str = "unknown"
    # Held for the whole of a compile: one program at a time, and nothing queues behind it.
    _compiling: Lock = field(default_factory=Lock, init=False, repr=False, compare=False)
    # The service is frozen, but which compile is running changes, so it is held in its own mutable record.
    _running: RunningCompile = field(default_factory=RunningCompile, init=False, repr=False, compare=False)

    def compile(self, file_name: str, source: str, *,
                disconnected: Callable[[], bool] = never) -> dict[str, Any]:
        """Compile one program; ``disconnected`` is checked as the commands run, and stops the compile."""

        if not SAFE_FILE_NAME.fullmatch(file_name):
            raise CompileError(HTTPStatus.BAD_REQUEST, "invalid_request", "fileName must be a safe C file name.")
        if not self._compiling.acquire(blocking=False) and not self._after_abandoned_compile():
            raise CompileError(HTTPStatus.CONFLICT, "busy", BUSY)
        self._running.disconnected = disconnected
        try:
            return self._compile(file_name, source, disconnected)
        finally:
            self._running.disconnected = never
            self._compiling.release()

    def _after_abandoned_compile(self) -> bool:
        """Take the compile slot once the running compile stops, if its client has gone (the student
        cancelled and uploaded again at once); otherwise the service is busy."""

        return self._running.disconnected() and self._compiling.acquire(timeout=STOPPING_GRACE)

    def _compile(self, file_name: str, source: str, disconnected: Callable[[], bool]) -> dict[str, Any]:
        deadline = time.monotonic() + self.timeout
        source_dir = self.workspace / SOURCE_DIRECTORY
        output_dir = self.workspace / "out"
        self._wipe(source_dir, output_dir)
        try:
            source_dir.mkdir()
            output_dir.mkdir()
            source_path = source_dir / file_name
            source_path.write_text(source, encoding="utf-8", newline="")
            stem = source_path.stem
            clang, opt = self.tool_versions
            commands = pass_sequence_commands(str(source_path), str(output_dir), stem)
            stderr = ""
            for command in commands:
                stderr = self._run(command, deadline, disconnected, output="stderr")
            return {
                "states": [self._state(state, output_dir, stem, commands) for state in PASS_STATES],
                "optRecord": (output_dir / f"{stem}.opt.yaml").read_text(encoding="utf-8"),
                # The last command is the -O3 object compile, whose stderr is the -Rpass text.
                "rpass": stderr,
                "manifest": {
                    "clang": clang,
                    "opt": opt,
                    "targetTriple": TARGET_TRIPLE,
                    "compilerImage": self.compiler_image,
                    "libcVersion": self.libc_version,
                    "commands": [format_command(command) for command in commands],
                },
            }
        finally:
            self._wipe(source_dir, output_dir)

    @cached_property
    def tool_versions(self) -> tuple[str, str]:
        """The ``clang`` and ``opt`` version lines, read once: a running service's toolchain never changes."""

        deadline = time.monotonic() + VERSION_TIMEOUT
        return (self._run(["clang", "--version"], deadline).splitlines()[0].strip(),
                self._run(["opt", "--version"], deadline).splitlines()[1].strip())

    def _state(self, state: PassState, output_dir: Path, stem: str, commands: list[list[str]]) -> dict[str, Any]:
        ir_path = output_dir / f"{stem}_{state.file_suffix}.ll"
        remarks_path = output_dir / f"{stem}_{state.file_suffix}_remarks.yaml"
        # A state's origin is the command that wrote its IR, matched by -o target as the curated manifest is.
        (command,) = [command for command in commands if command[command.index("-o") + 1] == str(ir_path)]
        return {
            "stateId": state.state_id,
            "ir": ir_path.read_text(encoding="utf-8"),
            "remarks": remarks_path.read_text(encoding="utf-8") if state.pass_pipeline else None,
            "command": format_command(command),
        }

    def _run(self, command: list[str], deadline: float, disconnected: Callable[[], bool] = never, *,
             output: str = "stdout") -> str:
        tool = str(self.toolchain / command[0]) if self.toolchain else command[0]
        # Its own process group, so stopping it also stops every process it started (clang runs clang -cc1).
        process = subprocess.Popen([tool, *command[1:]], cwd=self.workspace, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, encoding="utf-8", errors="replace",
                                   start_new_session=True)
        try:
            stdout, stderr = self._wait(process, deadline, disconnected)
        finally:
            self._stop(process)
        if process.returncode != 0:
            raise CompileError(HTTPStatus.UNPROCESSABLE_ENTITY, "command_failed",
                               f"{command[0]} exited with status {process.returncode}.",
                               command=format_command(command), stderr=stderr)
        return stdout if output == "stdout" else stderr

    def _wait(self, process: subprocess.Popen[str], deadline: float,
              disconnected: Callable[[], bool]) -> tuple[str, str]:
        """Wait for a command, checking every so often whether the compile must stop.

        Stopping raises; the command's group is then killed and the caller wipes the work directory.
        """

        while True:
            try:
                return process.communicate(timeout=POLL_INTERVAL)
            except subprocess.TimeoutExpired:
                if time.monotonic() >= deadline:
                    raise CompileError(HTTPStatus.GATEWAY_TIMEOUT, "timeout", TIMED_OUT.format(self.timeout)) from None
                if disconnected():
                    raise ClientDisconnected from None

    @staticmethod
    def _stop(process: subprocess.Popen[str]) -> None:
        """Kill a command's whole process group if it is still running, and reap it.

        The group is killed again until it has gone: a process forked as the first kill was sent can miss
        it (macOS does not restart such a fork, as Linux does), and would hold the output open.
        """

        while process.returncode is None:
            with contextlib.suppress(ProcessLookupError):
                os.killpg(process.pid, signal.SIGKILL)
            # Returns once every process in the group has exited and closed its output.
            with contextlib.suppress(subprocess.TimeoutExpired):
                process.communicate(timeout=POLL_INTERVAL)

    @staticmethod
    def _wipe(*directories: Path) -> None:
        for directory in directories:
            shutil.rmtree(directory, ignore_errors=True)


def server(service: CompilerService, host: str, port: int) -> HTTPServer:
    """Bind the service's HTTP server. Each request has its own thread, so a request that arrives during a
    compile is answered at once, as busy, rather than waiting for it."""

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            if self.path != "/compile":
                self._answer(HTTPStatus.NOT_FOUND, {"error": {"code": "not_found", "message": "Unknown path."}})
                return
            try:
                request = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
                file_name, source = request["fileName"], request["source"]
                if not isinstance(file_name, str) or not isinstance(source, str):
                    raise TypeError("fileName and source must be strings")
            except (ValueError, KeyError, TypeError):
                self._answer(HTTPStatus.BAD_REQUEST,
                             {"error": {"code": "invalid_request", "message": "Send {fileName, source}."}})
                return
            try:
                self._answer(HTTPStatus.OK, service.compile(file_name, source, disconnected=self._disconnected))
            except CompileError as exc:
                self._answer(exc.status, {"error": exc.body})
            except ClientDisconnected:
                # The app dropped its request (the student pressed Cancel): there is nobody to answer.
                self.close_connection = True

        def _disconnected(self) -> bool:
            """Whether the client has closed its connection: its socket is readable but has nothing to read."""

            try:
                if not select.select([self.connection], [], [], 0)[0]:
                    return False
                return not self.connection.recv(1, socket.MSG_PEEK)
            except (OSError, ValueError):  # reset, or already closed (another request may ask late)
                return True

        def _answer(self, status: HTTPStatus, body: dict[str, Any]) -> None:
            data = json.dumps(body).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    http = ThreadingHTTPServer((host, port), Handler)
    http.daemon_threads = True
    return http


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Compile user programs with the pinned toolchain.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080, help="0 picks a free port")
    parser.add_argument("--toolchain", type=Path, help="directory holding clang and opt (default: PATH)")
    parser.add_argument("--workspace", type=Path, default=WORKSPACE)
    parser.add_argument("--timeout", type=float, default=30.0, help="seconds allowed for a whole program")
    parser.add_argument("--compiler-image", default=os.environ.get("IREXPLORER_COMPILER_IMAGE", "unknown"))
    parser.add_argument("--libc-version", default=os.environ.get("IREXPLORER_LIBC_VERSION", "unknown"))
    args = parser.parse_args(argv)
    service = CompilerService(toolchain=args.toolchain.resolve() if args.toolchain else None,
                              workspace=args.workspace.resolve(), timeout=args.timeout,
                              compiler_image=args.compiler_image, libc_version=args.libc_version)
    # Fail at startup, not at the first program, if the toolchain cannot be run.
    print(f"Toolchain: {' · '.join(service.tool_versions)}", file=sys.stderr)
    with server(service, args.host, args.port) as http:
        print(f"Compiler service listening on http://{args.host}:{http.server_port}", flush=True)
        with contextlib.suppress(KeyboardInterrupt):
            http.serve_forever()


if __name__ == "__main__":
    main()
