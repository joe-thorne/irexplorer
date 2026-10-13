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
from test_user_programs_api import LoopbackCompilerService

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

    def test_each_corpus_program_answers_as_the_corpus_says(self) -> None:
        study = tempfile.TemporaryDirectory()
        self.addCleanup(study.cleanup)
        app = create_app(study_config=Config(Path(study.name), collection_mode="local"),
                         user_programs=UserProgramsSetting(True, self.compiler.url))
        # A program irexplorer cannot show yet fails inside the app; answer it as a client would see it.
        client = TestClient(app, raise_server_exceptions=False)
        self.addCleanup(client.close)
        for program in corpus():
            with self.subTest(program=program.file_name):
                response = client.post("/api/programs", json={"fileName": program.file_name,
                                                              "source": program.source})
                self.assertEqual(answered_outcome(response.status_code, response.json()), program.expected)


if __name__ == "__main__":
    unittest.main()
