"""A user program that fails to compile, through the app's HTTP boundary.

The fake toolchain fails as the pinned clang 22 does when a source carries `// irx-fake: error` (each call
to an undeclared `abss` is reported, as on a typo for `abs`), and as opt does when it carries
`// irx-fake: crash` (opt crashes on the first pass).
"""

import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient
from test_user_programs_api import LoopbackCompilerService, program_id

from src.backend.api.app import create_app
from src.backend.evaluation.service import Config
from src.backend.programs import UserProgramsSetting

TYPO = """\
// irx-fake: error
#include <stdlib.h>

int distance(int from, int to) {
  return abss(to - from);
}
"""
# The pinned clang's stderr for TYPO, as the compiler image gives it, less the /workspace/user-programs/ prefix.
TYPO_OUTPUT = """\
typo.c:5:10: error: call to undeclared function 'abss'; ISO C99 and later do not support implicit function \
declarations [-Wimplicit-function-declaration]
    5 |   return abss(to - from);
      |          ^
typo.c:5:10: note: did you mean 'abs'?
/usr/include/stdlib.h:980:12: note: 'abs' declared here
  980 | extern int abs (int __x) __THROW __attribute__ ((__const__)) __wur;
      |            ^
1 error generated.
"""
UNDECLARED_ABSS = ("call to undeclared function 'abss'; ISO C99 and later do not support implicit function "
                   "declarations [-Wimplicit-function-declaration]")


class CompileFailureTests(unittest.TestCase):
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

    def compile_failure(self, file_name: str, source: str) -> dict:
        response = self.client.post("/api/programs", json={"fileName": file_name, "source": source})
        self.assertEqual(response.status_code, 422, response.text)
        self.assertEqual(response.headers["cache-control"], "no-store")
        error = response.json()["error"]
        self.assertEqual(error["code"], "compile_failed")
        held = self.client.get(f"/api/programs/{program_id(file_name, source)}")
        self.assertEqual(held.json()["error"]["code"], "unknown_program")
        return error

    def test_a_clang_failure_reports_each_diagnostic_against_the_users_file_and_keeps_header_paths(self) -> None:
        error = self.compile_failure("typo.c", TYPO)

        self.assertEqual(error["diagnostics"], [
            {"file": "typo.c", "line": 5, "column": 10, "severity": "error", "message": UNDECLARED_ABSS},
            {"file": "typo.c", "line": 5, "column": 10, "severity": "note", "message": "did you mean 'abs'?"},
            {"file": "/usr/include/stdlib.h", "line": 980, "column": 12, "severity": "note",
             "message": "'abs' declared here"},
        ])
        self.assertEqual(error["output"], TYPO_OUTPUT)
        self.assertTrue(error["message"])

    def test_a_long_clang_failure_reports_its_first_twenty_diagnostics_and_64_kib_of_output(self) -> None:
        # One long line of 25 typos: clang stops at its 20-error limit, echoing the line under each error.
        line = "  return 0" + " + 0" * 800 + " + abss(0)" * 25 + ";"
        source = f"// irx-fake: error\nint total(void) {{\n{line}\n}}\n"

        error = self.compile_failure("many.c", source)

        first_column = len("  return 0" + " + 0" * 800 + " + ") + 1
        self.assertEqual(len(error["diagnostics"]), 20)
        self.assertEqual([(d["file"], d["line"], d["severity"]) for d in error["diagnostics"][:4]], [
            ("many.c", 3, "error"), ("many.c", 3, "note"), ("/usr/include/stdlib.h", 980, "note"),
            ("many.c", 3, "error"),
        ])
        self.assertEqual([d["column"] for d in error["diagnostics"] if d["severity"] == "error"],
                         [first_column + 10 * call for call in range(7)])
        output = error["output"]
        self.assertEqual(len(output.encode("utf-8")), 64 * 1024)
        self.assertTrue(output.startswith(f"many.c:3:{first_column}: error: {UNDECLARED_ABSS}\n    3 | {line}\n"))
        self.assertNotIn("/workspace/", output)

    def test_an_opt_failure_reports_only_its_output(self) -> None:
        source = "// irx-fake: crash\nint answer(void) { return 42; }\n"

        error = self.compile_failure("crash.c", source)

        self.assertEqual(error["diagnostics"], [])
        self.assertIn("opt", error["message"])
        self.assertTrue(error["output"].startswith("PLEASE submit a bug report"), error["output"])
        self.assertIn("Stack dump:\n0.\tProgram arguments: opt -passes=mem2reg ", error["output"])
        self.assertIn('Running pass "mem2reg" on module "/workspace/out/crash_O0.bc"', error["output"])


if __name__ == "__main__":
    unittest.main()
