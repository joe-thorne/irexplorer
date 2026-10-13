"""The user programs setting, read once at startup. It is runtime configuration, not release identity."""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class UserProgramsSetting:
    enabled: bool = False
    # The compiler service's internal address. It is kept only when the feature is on, and never
    # turns the feature on by itself.
    compiler_url: str | None = None
    # Seconds the app waits for the compiler service to answer before calling it unavailable: the
    # service's own 30 s limit on a compile, with room to spare.
    compiler_timeout: float = 40.0

    def __post_init__(self) -> None:
        if self.enabled and not self.compiler_url:
            raise ValueError("IREXPLORER_USER_PROGRAMS=1 requires IREXPLORER_COMPILER_URL, "
                             "the compiler service's address.")
        if not self.compiler_timeout > 0:
            raise ValueError("IREXPLORER_COMPILER_TIMEOUT must be a positive number of seconds.")

    @classmethod
    def environment(cls) -> UserProgramsSetting:
        enabled = os.environ.get("IREXPLORER_USER_PROGRAMS", "0")
        if enabled not in ("0", "1"):
            raise ValueError("IREXPLORER_USER_PROGRAMS must be 0 (off) or 1 (on).")
        if enabled == "0":
            return cls()
        timeout = os.environ.get("IREXPLORER_COMPILER_TIMEOUT", str(cls.compiler_timeout))
        try:
            seconds = float(timeout)
        except ValueError:
            raise ValueError("IREXPLORER_COMPILER_TIMEOUT must be a positive number of seconds.") from None
        return cls(True, os.environ.get("IREXPLORER_COMPILER_URL"), seconds)
