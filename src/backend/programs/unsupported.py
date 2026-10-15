"""Why a program that compiled cannot be shown, told apart from an error in the student's C.

irexplorer's model describes the control flow and functions most C programs compile to. A program that
compiles to something it does not describe is answered as unsupported, with what it was in the C where
that is known, and otherwise with the parser's own message.
"""

from __future__ import annotations

from src.backend.ingest import NoFunctionDefinitions, UnsupportedTerminator
from src.backend.programs.errors import ProgramError

# The C each LLVM terminator irexplorer cannot show comes from.
TERMINATORS = {
    "indirectbr": ("computed_goto",
                   "This program uses a computed goto (goto *pointer), which compiles to LLVM's indirectbr. "
                   "irexplorer can't display indirectbr control flow."),
    "callbr": ("asm_goto",
               "This program uses asm goto, which compiles to LLVM's callbr. "
               "irexplorer can't display callbr control flow."),
}
NO_FUNCTIONS = ("The compiled program defines no functions, so there is nothing to display. Add a function "
                "that is not only static or inline, such as int main(void).")
UNPARSABLE = "irexplorer can't display this program."


class UnsupportedProgram(ProgramError):
    """Raised when a program compiled but its artefacts cannot be read into irexplorer's model.

    Only a parser failure carries the parser's message, as ``parserMessage``.
    """

    code = "unsupported_program"
    status_code = 422


def unsupported_program(failure: ValueError) -> UnsupportedProgram:
    """What to tell the student about a compiled program whose ingest or validation failed."""

    if isinstance(failure, UnsupportedTerminator) and failure.opcode in TERMINATORS:
        return UnsupportedProgram(*TERMINATORS[failure.opcode])
    if isinstance(failure, NoFunctionDefinitions):
        return UnsupportedProgram("no_functions", NO_FUNCTIONS)
    return UnsupportedProgram("unparsable", UNPARSABLE, parserMessage=str(failure))
