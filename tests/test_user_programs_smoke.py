"""The real-compiler smoke check: user programs through the running user-programs stack.

Run by hand before the demo and before merging, with `scripts/check_user_programs.sh`, which checks that
Docker and the stack are up and sets IREXPLORER_SMOKE_COMPILER (the compiler service's container) and
IREXPLORER_SMOKE_APP (the app's address). Without them this module is skipped: the offline suite and CI
have no Docker or LLVM.
"""

import json
import os
import re
import sys
import time
import unittest
import urllib.error
import urllib.request
import uuid

from scripts.record_user_programs import (
    StackCompiler,
    answered_outcome,
    corpus,
    differences,
    recorded_files,
    recording_files,
)
from src.backend.toolchain import curated

COMPILER = os.environ.get("IREXPLORER_SMOKE_COMPILER")
APP = os.environ.get("IREXPLORER_SMOKE_APP", "http://127.0.0.1:8001")


def post_program(file_name: str, source: str) -> tuple[int, dict]:
    request = urllib.request.Request(f"{APP}/api/programs", headers={"Content-Type": "application/json"},
                                     data=json.dumps({"fileName": file_name, "source": source}).encode("utf-8"))
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        with error:
            return error.code, json.load(error)


# A remark's debug location that the YAML writer wrapped onto a second line.
WRAPPED_LOCATION = re.compile(r", \n +(?=Column: )")


def as_user_program(text: str, example: str) -> str:
    """A curated artefact's text with its paths written as the compiler service's: the source under
    user-programs and the outputs under out. The remark YAML wraps a debug location longer than its line
    width, which the longer curated path can cross, so wrapped locations are rejoined on both sides."""
    text = text.replace("examples/curated", "user-programs").replace(f"artefacts/curated/{example}", "out")
    return WRAPPED_LOCATION.sub(", ", text)


@unittest.skipUnless(COMPILER, "needs the user-programs stack: run scripts/check_user_programs.sh")
class RealCompilerSmokeTests(unittest.TestCase):
    maxDiff = None

    def setUp(self) -> None:
        self.compiler = StackCompiler(COMPILER)

    def test_each_unedited_curated_source_compiles_to_its_committed_artefacts(self) -> None:
        for example in curated.list_examples():
            with self.subTest(example=example):
                status, body = self.compiler.compile(f"{example}.c", curated.read_source(example))
                answered = recording_files(example, status, body)
                answered.pop("manifest.json")
                committed = {name: (curated.artefact_dir(example) / name).read_text(encoding="utf-8")
                             for name in answered}
                self.assertEqual([name for name in answered if as_user_program(answered[name], example)
                                  != as_user_program(committed[name], example)], [])

    def test_each_recording_still_matches_the_real_toolchain(self) -> None:
        for program in corpus():
            with self.subTest(program=program.file_name):
                answered = recording_files(program.stem, *self.compiler.compile(program.file_name, program.source))
                drifted = differences(recorded_files(program.recording_dir), answered)
                self.assertEqual(drifted, [], "re-record with scripts/record_user_programs.py if the change is meant")

    def test_each_corpus_program_answers_as_the_corpus_says_within_its_time(self) -> None:
        # A file name of its own gives each run a new programId, so every program is compiled afresh rather
        # than answered from the app's store.
        run = uuid.uuid4().hex[:8]
        for program in corpus():
            with self.subTest(program=program.file_name):
                started = time.monotonic()
                status, body = post_program(f"{program.stem}_{run}.c", program.source)
                elapsed = time.monotonic() - started
                print(f"\n  {program.file_name}: {status} in {elapsed:.1f} s", end="", file=sys.stderr)
                self.assertEqual(answered_outcome(status, body), program.outcome)
                if program.within_seconds is not None:
                    self.assertLessEqual(elapsed, program.within_seconds)
        print(file=sys.stderr)


if __name__ == "__main__":
    unittest.main()
