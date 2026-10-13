"""What the server accepts as a user program: the shared cases in data/user-program-acceptance.json.

The browser checks the same cases (scripts/check_user_programs.mjs). The HTTP answers to refusals are
covered in test_user_programs_api.py.
"""

import json
import unittest
from pathlib import Path

from src.backend.programs.accepted import RefusedProgram, accept_program

CASES_FILE = Path(__file__).parent / "data" / "user-program-acceptance.json"
CASES = json.loads(CASES_FILE.read_text(encoding="utf-8"))["cases"]


def expand(text: str | list) -> str:
    """A case's text: a string, or strings and [text, count] repeats joined in order."""
    if isinstance(text, str):
        return text
    return "".join(part if isinstance(part, str) else part[0] * part[1] for part in text)


class AcceptedProgramTests(unittest.TestCase):
    def test_each_accepted_case_becomes_its_safe_name_and_normalised_source(self) -> None:
        for case in CASES:
            if "accepted" not in case:
                continue
            with self.subTest(case["name"]):
                program = accept_program(expand(case["fileName"]), expand(case["source"]))
                self.assertEqual((program.file_name, program.source),
                                 (expand(case["accepted"]["fileName"]), expand(case["accepted"]["source"])))

    def test_each_refused_case_gives_its_reason_and_message(self) -> None:
        for case in CASES:
            if "refused" not in case:
                continue
            with self.subTest(case["name"]):
                with self.assertRaises(RefusedProgram) as refused:
                    accept_program(expand(case["fileName"]), expand(case["source"]))
                self.assertEqual({"reason": refused.exception.reason, "message": refused.exception.message},
                                 case["refused"])


if __name__ == "__main__":
    unittest.main()
