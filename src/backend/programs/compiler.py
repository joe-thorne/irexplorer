"""The app's client of the compiler service: send one program, receive its compiler artefacts as text."""

from __future__ import annotations

import json
import urllib.request
from dataclasses import dataclass
from typing import Any
from urllib.error import HTTPError

from src.backend.programs.accepted import AcceptedProgram

UNAVAILABLE = ("The compiler service is unavailable. Check that the user programs stack is running, "
               "then try again.")


class CompileFailed(Exception):
    """A toolchain command failed; ``output`` is its stderr."""

    def __init__(self, command: str, output: str) -> None:
        super().__init__(f"command failed: {command}")
        self.command = command
        self.output = output


class CompileNotFinished(Exception):
    """The compiler was busy, slow or out of reach, so the compile did not finish; trying again may work.

    ``code`` and ``status_code`` are the app's answer, and the message is shown to the student as it is.
    """

    code: str
    status_code: int


class CompilerBusy(CompileNotFinished):
    code = "compiler_busy"
    status_code = 409


class CompileTimeout(CompileNotFinished):
    code = "compile_timeout"
    status_code = 504


class CompilerUnavailable(CompileNotFinished):
    code = "compiler_unavailable"
    status_code = 503


# The compiler service's codes for a compile it did not finish; its message is written for the student.
NOT_FINISHED: dict[str, type[CompileNotFinished]] = {"busy": CompilerBusy, "timeout": CompileTimeout}


class CompilerServiceError(RuntimeError):
    """The compiler service refused or could not finish a compile for any other reason."""


@dataclass(frozen=True)
class CompiledState:
    state_id: str
    ir: str
    # The per-pass remark YAML of a derived state; None for O0 and O3.
    remarks: str | None
    command: str


@dataclass(frozen=True)
class CompilerOutput:
    states: tuple[CompiledState, ...]
    opt_record: str
    manifest: dict[str, Any]


class CompilerClient:
    def __init__(self, url: str, *, timeout: float) -> None:
        self._url = url.rstrip("/") + "/compile"
        self._timeout = timeout
        # The compiler service is always reached directly, never through an environment proxy.
        self._opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def compile(self, program: AcceptedProgram) -> CompilerOutput:
        request = urllib.request.Request(
            self._url,
            data=json.dumps({"fileName": program.file_name, "source": program.source}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with self._opener.open(request, timeout=self._timeout) as response:
                body = json.loads(response.read())
        except HTTPError as exc:
            with exc:
                error = json.loads(exc.read())["error"]
            if error["code"] == "command_failed":
                raise CompileFailed(error["command"], error["stderr"]) from exc
            if error["code"] in NOT_FINISHED:
                raise NOT_FINISHED[error["code"]](error["message"]) from exc
            raise CompilerServiceError(f"compiler service refused the compile: {error}") from exc
        except OSError as exc:
            # Refused, dropped, or silent for longer than the timeout: the service is down or stuck.
            raise CompilerUnavailable(UNAVAILABLE) from exc
        return CompilerOutput(
            states=tuple(CompiledState(state["stateId"], state["ir"], state["remarks"], state["command"])
                         for state in body["states"]),
            opt_record=body["optRecord"],
            manifest=body["manifest"],
        )
