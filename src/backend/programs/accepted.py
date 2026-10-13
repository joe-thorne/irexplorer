"""What the server accepts as a user program, and the content address it is held under."""

from __future__ import annotations

import re
from dataclasses import dataclass
from hashlib import sha256

SAFE_FILE_NAME = re.compile(r"[A-Za-z0-9_-]{1,64}\.c")


class RefusedProgram(ValueError):
    """Raised when a posted program is refused before anything is sent to the compiler service."""


@dataclass(frozen=True)
class AcceptedProgram:
    """A user program as the compiler service receives it: a safe file name and normalised source."""

    file_name: str
    source: str

    @property
    def program_id(self) -> str:
        # NUL cannot occur in either part, so it separates them unambiguously.
        return sha256(self.file_name.encode("utf-8") + b"\0" + self.source.encode("utf-8")).hexdigest()

    @property
    def sha256(self) -> str:
        return sha256(self.source.encode("utf-8")).hexdigest()


def accept_program(file_name: str, source: str) -> AcceptedProgram:
    """Accept a posted file name and source, or refuse them before compiling."""

    if not SAFE_FILE_NAME.fullmatch(file_name):
        raise RefusedProgram(f"unsafe file name: {file_name!r}")
    return AcceptedProgram(file_name, source)
