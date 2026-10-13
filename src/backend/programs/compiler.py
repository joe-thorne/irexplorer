"""The app's client of the compiler service: send one program, receive its compiler artefacts as text."""

from __future__ import annotations

import contextlib
import http.client
import json
import logging
import socket
from dataclasses import dataclass
from threading import Lock
from typing import Any
from urllib.parse import urlsplit

from src.backend.programs.accepted import AcceptedProgram

logger = logging.getLogger(__name__)

UNAVAILABLE = ("The compiler service is unavailable. Check that the user programs stack is running, "
               "then try again.")


class CompileFailed(Exception):
    """A toolchain command failed; ``output`` is its stderr."""

    def __init__(self, command: str, output: str) -> None:
        super().__init__(f"command failed: {command}")
        self.command = command
        self.output = output

    @property
    def tool(self) -> str:
        """The failed command's tool, ``clang`` or ``opt``."""
        return self.command.split(" ", 1)[0]


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


class CompileDropped(Exception):
    """The app dropped its request because its own client went away (Cancel): nobody waits for an answer."""


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


class CompileRequest:
    """One request to the compiler service, which the app can drop from another thread.

    Dropping closes the connection, and the compiler service stops a compile whose client has gone.
    """

    def __init__(self) -> None:
        self._lock = Lock()
        self._connection: http.client.HTTPConnection | None = None
        self.dropped = False

    def drop(self) -> None:
        with self._lock:
            self.dropped = True
            if self._connection is not None and self._connection.sock is not None:
                # Wakes the thread waiting on the answer, and tells the compiler service at once.
                with contextlib.suppress(OSError):
                    self._connection.sock.shutdown(socket.SHUT_RDWR)

    def attach(self, connection: http.client.HTTPConnection) -> None:
        """Send this request on ``connection``, unless it has already been dropped."""

        with self._lock:
            if self.dropped:
                raise CompileDropped
            self._connection = connection


class CompilerClient:
    def __init__(self, url: str, *, timeout: float) -> None:
        # http.client ignores any environment proxy, so the compiler service is always reached directly.
        address = urlsplit(url)
        self._host = address.hostname or ""
        self._port = address.port
        self._path = address.path.rstrip("/") + "/compile"
        self._timeout = timeout

    def compile(self, program: AcceptedProgram, request: CompileRequest | None = None) -> CompilerOutput:
        request = request or CompileRequest()
        connection = http.client.HTTPConnection(self._host, self._port, timeout=self._timeout)
        try:
            connection.connect()
            request.attach(connection)
            connection.request(
                "POST", self._path,
                body=json.dumps({"fileName": program.file_name, "source": program.source}).encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
            response = connection.getresponse()
            status, reply = response.status, response.read()
        except (OSError, http.client.HTTPException) as exc:
            if request.dropped:
                raise CompileDropped from exc
            # Refused, dropped, or silent for longer than the timeout: the service is down or stuck.
            raise CompilerUnavailable(UNAVAILABLE) from exc
        finally:
            connection.close()
        try:
            return _output(status, json.loads(reply))
        except (ValueError, KeyError, TypeError) as exc:
            # Not an answer the service gives: a proxy's error page, say, or a service of another version.
            logger.warning("The compiler service answered %s with a reply the app does not understand: %.200r",
                           status, reply)
            raise CompilerUnavailable(UNAVAILABLE) from exc


def _output(status: int, body: Any) -> CompilerOutput:
    """The compiler output in a compiler service reply, or its error raised as the app's exception."""

    if status != 200:
        error = body["error"]
        if error["code"] == "command_failed":
            raise CompileFailed(error["command"], error["stderr"])
        if error["code"] in NOT_FINISHED:
            raise NOT_FINISHED[error["code"]](error["message"])
        raise ValueError(f"compiler service refused the compile: {error}")
    return CompilerOutput(
        states=tuple(CompiledState(state["stateId"], state["ir"], state["remarks"], state["command"])
                     for state in body["states"]),
        opt_record=body["optRecord"],
        manifest=body["manifest"],
    )
