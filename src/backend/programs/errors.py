"""A program the app answers with an error of its own, rather than compiling or showing it."""

from __future__ import annotations

from typing import ClassVar


class ProgramError(Exception):
    """Why a program was not compiled or shown: a ``reason``, the ``message`` the student is shown as it is,
    and any further ``details``, named as in the error body."""

    code: ClassVar[str]
    status_code: ClassVar[int]

    def __init__(self, reason: str, message: str, **details: str) -> None:
        super().__init__(message)
        self.reason = reason
        self.message = message
        self.details = details

    def error(self) -> dict[str, str]:
        """The error body's ``error`` object."""
        return {"code": self.code, "message": self.message, "reason": self.reason, **self.details}
