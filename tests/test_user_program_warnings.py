"""Clang's warnings on a user program that compiles, through the app's HTTP boundary.

The compiler service runs on loopback over the fake clang and opt, which replay the -O0 command's stderr
as the pinned clang 22 printed it for the recorded `clang_warnings.c`: 22 warnings, some with notes, against
`/workspace/user-programs/clang_warnings.c`.
"""

import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient
from test_user_programs_api import LoopbackCompilerService, curated_source

from src.backend.api.app import create_app
from src.backend.evaluation.service import Config
from src.backend.programs import UserProgramsSetting
from src.backend.toolchain import curated

WARNINGS_PROGRAM = curated.REPO_ROOT / "tests" / "data" / "user-programs" / "clang_warnings.c"
# The first 20 of the pinned clang's 22 warnings for WARNINGS_PROGRAM, in the order it printed them.
FIRST_TWENTY = [
    (7, 16, "using the result of an assignment as a condition without parentheses [-Wparentheses]"),
    (17, 15, "expression result unused [-Wunused-value]"),
    (24, 18, "self-comparison always evaluates to true [-Wtautological-compare]"),
    (28, 26, "implicit conversion from 'int' to 'unsigned char' changes value from 300 to 44 [-Wconstant-conversion]"),
    (33, 18, "shift count >= width of type [-Wshift-count-overflow]"),
    (39, 19, "using the result of an assignment as a condition without parentheses [-Wparentheses]"),
    (47, 20, "if statement has empty body [-Wempty-body]"),
    (52, 16, "implicit conversion from 'double' to 'int' changes value from 2.5 to 2 [-Wliteral-conversion]"),
    (58, 12, "array index 4 is past the end of the array (that has type 'int[4]') [-Warray-bounds]"),
    (62, 9, "logical not is only applied to the left hand side of this comparison [-Wlogical-not-parentheses]"),
    (69, 18, "sizeof on array function parameter will return size of 'int *' instead of 'int[8]' "
             "[-Wsizeof-array-argument]"),
    (69, 27, "'sizeof (values)' will return the size of the pointer, not the array itself [-Wsizeof-pointer-div]"),
    (73, 26, "format specifies type 'int' but the argument has type 'long' [-Wformat]"),
    (74, 25, "format specifies type 'int' but the argument has type 'double' [-Wformat]"),
    (80, 19, "using the result of an assignment as a condition without parentheses [-Wparentheses]"),
    (81, 19, "equality comparison result unused [-Wunused-comparison]"),
    (89, 17, "implicit conversion from 'int' to 'char' changes value from 200 to -56 [-Wconstant-conversion]"),
    (88, 16, "implicit conversion from 'int' to 'char' changes value from -200 to 56 [-Wconstant-conversion]"),
    (102, 18, "using the result of an assignment as a condition without parentheses [-Wparentheses]"),
    (103, 18, "equality comparison result unused [-Wunused-comparison]"),
]


class CompileWarningTests(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls) -> None:
        cls.compiler = LoopbackCompilerService()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.compiler.stop()

    def setUp(self) -> None:
        study = tempfile.TemporaryDirectory()
        self.addCleanup(study.cleanup)
        app = create_app(study_config=Config(Path(study.name), collection_mode="local"),
                         user_programs=UserProgramsSetting(True, self.compiler.url))
        self.client = TestClient(app)
        self.addCleanup(self.client.close)

    def post(self, file_name: str, source: str):
        return self.client.post("/api/programs", json={"fileName": file_name, "source": source})

    def test_a_program_that_compiles_with_warnings_answers_its_first_twenty_warnings_without_notes(self) -> None:
        created = self.post("clang_warnings.c", WARNINGS_PROGRAM.read_text(encoding="utf-8"))

        self.assertEqual(created.status_code, 201, created.text)
        self.assertEqual(created.json()["warnings"], [
            {"file": "clang_warnings.c", "line": line, "column": column, "severity": "warning", "message": message}
            for line, column, message in FIRST_TWENTY
        ])

    def test_a_held_program_answers_the_same_warnings_when_posted_again_and_when_viewed(self) -> None:
        source = WARNINGS_PROGRAM.read_text(encoding="utf-8")
        created = self.post("clang_warnings.c", source).json()

        again = self.post("clang_warnings.c", source)
        viewed = self.client.get(f"/api/programs/{created['programId']}")

        self.assertEqual((again.status_code, again.json()["warnings"]), (200, created["warnings"]))
        self.assertEqual((viewed.status_code, viewed.json()["warnings"]), (200, created["warnings"]))
        self.assertEqual(len(created["warnings"]), 20)

    def test_a_program_that_compiles_cleanly_answers_no_warnings(self) -> None:
        created = self.post("score.c", curated_source("score"))

        self.assertEqual(created.status_code, 201, created.text)
        self.assertEqual(created.json()["warnings"], [])
        self.assertEqual(self.client.get(f"/api/programs/{created.json()['programId']}").json()["warnings"], [])

    def test_curated_example_routes_answer_no_warnings(self) -> None:
        self.assertNotIn("warnings", self.client.get("/api/examples/score/source").json())


if __name__ == "__main__":
    unittest.main()
