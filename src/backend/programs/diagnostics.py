"""What a student is shown of a failed compile: clang's diagnostics, and the failed command's output.

The compiler service only reports which command failed and its stderr; reading that stderr is the app's.
"""

from __future__ import annotations

import re
from typing import Any

from src.backend.programs.compiler import CompileFailed
from src.backend.toolchain.compiler_service import SOURCE_DIRECTORY, WORKSPACE

# Where the compiler service puts the upload, so every diagnostic against it names only the file.
USER_PROGRAMS = f"{WORKSPACE / SOURCE_DIRECTORY}/"
MAX_DIAGNOSTICS = 20
MAX_OUTPUT_BYTES = 64 * 1024
# clang's `file:line:col: severity: message` lines. Source snippets and carets are indented, so they never match.
DIAGNOSTIC = re.compile(
    r"^(?P<file>[^\s:][^:\n]*):(?P<line>\d+):(?P<column>\d+): "
    r"(?P<severity>fatal error|error|warning|note|remark): (?P<message>.*)$",
    re.MULTILINE,
)


def compile_failure(failure: CompileFailed) -> dict[str, Any]:
    """The ``compile_failed`` details: clang's first diagnostics, in order, and the failed command's output.

    A failure after clang (an ``opt`` crash) has no diagnostics against the source, only its output.
    """

    output = failure.output.replace(USER_PROGRAMS, "")
    diagnostics = [
        {"file": match["file"], "line": int(match["line"]), "column": int(match["column"]),
         "severity": match["severity"], "message": match["message"]}
        for match in DIAGNOSTIC.finditer(output)
    ] if failure.tool == "clang" else []
    return {"diagnostics": diagnostics[:MAX_DIAGNOSTICS],
            "output": output.encode("utf-8")[:MAX_OUTPUT_BYTES].decode("utf-8", errors="ignore")}
