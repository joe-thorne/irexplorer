"""What the server accepts as a user program, and the content address it is held under.

The browser applies the same rules before sending (src/frontend/accepted-program.js), so a refusal
here means a client skipped them. Both are checked against tests/data/user-program-acceptance.json;
change the two together.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from hashlib import sha256

MAX_LINES = 200
MAX_BYTES = 16 * 1024
STEM_LENGTH = 64
C_FILE_NAME = re.compile(r"(.*)\.[cC]", re.DOTALL)
UNSAFE_RUN = re.compile(r"[^A-Za-z0-9_-]+")
# C's own whitespace; CR is gone by the time this is checked.
WHITESPACE_ONLY = re.compile(r"[ \t\n\v\f]*")
BOM = "﻿"


class RefusedProgram(ValueError):
    """Raised when a posted program is refused before anything is sent to the compiler service."""

    def __init__(self, reason: str, message: str) -> None:
        super().__init__(message)
        self.reason = reason
        self.message = message


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
    """Accept a posted file name and source as a safe name and normalised source, or refuse them.

    The checks run in this order, and the first that fails gives the reason: the name, then the text
    (UTF-8, NUL characters, empty, lines, size). Nothing is ever truncated.
    """

    return AcceptedProgram(safe_file_name(file_name), normalised_source(source))


def safe_file_name(file_name: str) -> str:
    """The name saved for the compiler: a lowercase .c, unsafe runs as _, the stem cut to 64 characters."""

    match = C_FILE_NAME.fullmatch(file_name)
    if match is None:
        raise RefusedProgram("not_c_file", "Only C files can be compiled: the file name must end in .c.")
    stem = UNSAFE_RUN.sub("_", match.group(1))[:STEM_LENGTH]
    return f"{stem or 'program'}.c"


def normalised_source(source: str) -> str:
    """The source with LF line endings and no leading BOM, if it is small, non-empty UTF-8 text."""

    try:
        encoded = source.encode("utf-8")
    except UnicodeEncodeError:
        # Only a lone surrogate, as a JSON \u escape, can reach here: the body itself is UTF-8.
        raise RefusedProgram("invalid_utf8", "The file is not UTF-8 text.") from None
    if b"\0" in encoded:
        raise RefusedProgram("nul_character", "The file contains a NUL character.")
    text = source.removeprefix(BOM).replace("\r\n", "\n").replace("\r", "\n")
    if WHITESPACE_ONLY.fullmatch(text):
        raise RefusedProgram("empty", "The file is empty or contains only whitespace.")
    # One trailing newline ends the last line rather than starting another.
    lines = text.count("\n") + (0 if text.endswith("\n") else 1)
    if lines > MAX_LINES:
        raise RefusedProgram("too_many_lines", f"The file has {lines} lines; up to {MAX_LINES} are allowed.")
    size = len(text.encode("utf-8"))
    if size > MAX_BYTES:
        raise RefusedProgram("too_large", f"The file is {size} bytes of UTF-8 text; "
                                          f"up to 16 KiB ({MAX_BYTES} bytes) is allowed.")
    return text
