"""The recorded user programs, replayed by the fake toolchain as the real toolchain answered them.

`scripts/record_user_programs.py` records each corpus program in tests/data/user-programs from the
running user-programs stack, and `scripts/check_user_programs.sh` checks the recordings still match the
real toolchain. Here the compiler service runs on loopback over the fake clang and opt, with no Docker or
LLVM.
"""

import json
import tempfile
import unittest
import urllib.error
import urllib.request
from pathlib import Path

from fastapi.testclient import TestClient
from test_user_programs_api import LoopbackCompilerService, program_id

from scripts.record_user_programs import answered_outcome, corpus, differences, recorded_files, recording_files
from src.backend.api.app import create_app
from src.backend.evaluation.service import Config
from src.backend.programs import UserProgramsSetting
from src.backend.programs.accepted import accept_program

# The loopback service reports a fake compiler image and libc version, not the recorded ones.
FAKE_IDENTITY = ("compilerImage", "libcVersion")


def compile_on(url: str, file_name: str, source: str) -> tuple[int, dict]:
    request = urllib.request.Request(f"{url}/compile", data=json.dumps({"fileName": file_name, "source": source})
                                     .encode("utf-8"), headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        with error:
            return error.code, json.load(error)


class RecordedUserProgramTests(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls) -> None:
        cls.compiler = LoopbackCompilerService()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.compiler.stop()

    def test_the_corpus_covers_the_programs_the_spec_names(self) -> None:
        names = {program.file_name for program in corpus()}

        self.assertLessEqual({"ends_in_abort.c", "ends_in_exit.c", "computed_goto.c", "asm_goto.c",
                              "only_static_inline.c", "compile_error.c", "word_frequency.c"}, names)
        realistic = next(program for program in corpus() if program.file_name == "word_frequency.c")
        self.assertGreaterEqual(realistic.source.count("\n"), 190)
        self.assertEqual(realistic.within_seconds, 15)

    def test_each_corpus_source_is_stored_as_the_app_sends_it(self) -> None:
        for program in corpus():
            with self.subTest(program=program.file_name):
                accepted = accept_program(program.file_name, program.source)
                self.assertEqual((accepted.file_name, accepted.source), (program.file_name, program.source))

    def test_each_recording_replays_through_the_fake_toolchain_as_recorded(self) -> None:
        workspace = str(Path(self.compiler.workspace.name).resolve())
        for program in corpus():
            with self.subTest(program=program.file_name):
                status, body = compile_on(self.compiler.url, program.file_name, program.source)
                answered = recording_files(program.stem, status, body, workspace=workspace)
                self.assertEqual(differences(recorded_files(program.recording_dir), answered, ignoring=FAKE_IDENTITY),
                                 [])

    def app_client(self) -> TestClient:
        study = tempfile.TemporaryDirectory()
        self.addCleanup(study.cleanup)
        app = create_app(study_config=Config(Path(study.name), collection_mode="local"),
                         user_programs=UserProgramsSetting(True, self.compiler.url))
        client = TestClient(app)
        self.addCleanup(client.close)
        return client

    def test_each_corpus_program_answers_as_the_corpus_says(self) -> None:
        client = self.app_client()
        for program in corpus():
            with self.subTest(program=program.file_name):
                response = client.post("/api/programs", json={"fileName": program.file_name,
                                                              "source": program.source})
                self.assertEqual(answered_outcome(response.status_code, response.json()), program.outcome)

    def test_the_recorded_abort_program_opens_through_every_program_route(self) -> None:
        client = self.app_client()
        program = next(program for program in corpus() if program.file_name == "ends_in_abort.c")
        created = client.post("/api/programs", json={"fileName": program.file_name, "source": program.source})
        self.assertEqual(created.status_code, 201, created.text)
        root = f"/api/programs/{created.json()['programId']}"

        def view(path: str) -> dict:
            response = client.get(root + path)
            self.assertEqual(response.status_code, 200, f"{path}: {response.text}")
            return response.json()

        self.assertEqual(view(""), created.json())
        self.assertEqual(view("/source")["text"], program.source)
        states = view("/states")["states"]
        for ordinal in range(len(states)):
            for function in view(f"/states/{ordinal}/ir")["functions"]:
                query = f"?functionId={function['id']}"
                view(f"/states/{ordinal}/cfg{query}")
                view(f"/states/{ordinal}/source-mappings{query}")
            view(f"/comparison-report?fromOrdinal={ordinal}&toOrdinal={(ordinal + 1) % len(states)}")
        # The block that calls abort() ends in `unreachable, !dbg …`, read as the unreachable terminator.
        divide = next(function for function in view("/states/0/ir")["functions"]
                      if function["name"] == "checked_divide")
        aborting = next(block for block in divide["blocks"] if block["label"] == "if.then")
        self.assertEqual([instruction["opcode"] for instruction in aborting["instructions"]], ["call", "unreachable"])

    def test_each_unsupported_program_says_why_and_only_a_parser_failure_quotes_the_parser(self) -> None:
        client = self.app_client()
        cases = {
            "computed_goto.c": ("This program uses a computed goto (goto *pointer), which compiles to LLVM's "
                                "indirectbr. irexplorer can't display indirectbr control flow.", None),
            "asm_goto.c": ("This program uses asm goto, which compiles to LLVM's callbr. irexplorer can't display "
                           "callbr control flow.", None),
            "only_static_inline.c": ("The compiled program defines no functions, so there is nothing to display. "
                                     "Add a function that is not only static or inline, such as int main(void).",
                                     None),
            "non_ascii_name.c": ("irexplorer can't display this program.",
                                 'unrecognised function definition at line 7: '
                                 'define dso_local i32 @"caf\\C3\\A9_total"('),
        }
        for program in corpus():
            if program.file_name not in cases:
                continue
            message, parser_message = cases[program.file_name]
            with self.subTest(program=program.file_name):
                response = client.post("/api/programs", json={"fileName": program.file_name,
                                                              "source": program.source})
                error = response.json()["error"]
                self.assertEqual((response.status_code, error["code"], error["message"]),
                                 (422, "unsupported_program", message))
                self.assertEqual(response.headers["cache-control"], "no-store")
                if parser_message is None:
                    self.assertNotIn("parserMessage", error)
                else:
                    self.assertTrue(error["parserMessage"].startswith(parser_message), error["parserMessage"])
                held = client.get(f"/api/programs/{program_id(program.file_name, program.source)}")
                self.assertEqual(held.json()["error"]["code"], "unknown_program")


if __name__ == "__main__":
    unittest.main()
