"""User programs over /api/programs, through the app's HTTP boundary.

The app runs in-process with user programs on, pointed at the real compiler service, started by its
entry point on a loopback port over the fake clang and opt in tests/fake_toolchain. No Docker or LLVM.
"""

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from fastapi.testclient import TestClient

from src.backend.api.app import create_app
from src.backend.evaluation.service import Config
from src.backend.programs import UserProgramsSetting
from src.backend.toolchain import curated
from src.backend.toolchain.generate_curated import format_command, pass_sequence_commands

FAKE_TOOLCHAIN = curated.REPO_ROOT / "tests" / "fake_toolchain"
MANIFEST_FIELDS = {"clang", "opt", "targetTriple", "compilerImage", "libcVersion", "commands"}
PROGRAM_ROUTES = ("", "/states", "/source", "/states/0/ir", "/states/0/cfg?functionId=fn0",
                  "/states/0/source-mappings?functionId=fn0", "/comparison-report?fromOrdinal=0&toOrdinal=13")


def curated_source(example: str) -> str:
    return (curated.EXAMPLES_ROOT / f"{example}.c").read_text(encoding="utf-8")


def without_commands(value):
    """The response with every toolchain command removed: a user program's commands name its own paths."""
    if isinstance(value, dict):
        return {key: without_commands(item) for key, item in value.items() if key not in ("originCommand", "command")}
    if isinstance(value, list):
        return [without_commands(item) for item in value]
    return value


def paths_as_curated(value):
    """The response with a user program's source paths written as the curated example's."""
    return json.loads(json.dumps(value).replace("/workspace/user-programs/", "/workspace/examples/curated/"))


def with_program_id(curated_view: dict, program_id: str) -> dict:
    return {"programId": program_id, **{key: value for key, value in curated_view.items() if key != "exampleId"}}


def program_id(file_name: str, source: str) -> str:
    """The spec's programId: SHA-256 of the safe file name, a NUL separator and the normalised source."""
    return hashlib.sha256(file_name.encode("utf-8") + b"\0" + source.encode("utf-8")).hexdigest()


class LoopbackCompilerService:
    """The compiler service as a separate process on a loopback port, wiping its own temporary workspace."""

    def __init__(self) -> None:
        self.workspace = tempfile.TemporaryDirectory()
        self.process = subprocess.Popen(
            [sys.executable, "-m", "src.backend.toolchain.compiler_service", "--host", "127.0.0.1", "--port", "0",
             "--toolchain", str(FAKE_TOOLCHAIN), "--workspace", self.workspace.name, "--timeout", "30",
             "--compiler-image", "sha256:fake-compiler-image", "--libc-version", "2.39-0ubuntu8.fake"],
            cwd=curated.REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
        assert self.process.stdout is not None
        ready = self.process.stdout.readline()
        if not ready.startswith("Compiler service listening on "):
            self.stop()
            raise RuntimeError(f"compiler service did not start: {ready!r}")
        self.url = ready.removeprefix("Compiler service listening on ").strip()

    def stop(self) -> None:
        self.process.terminate()
        self.process.wait(timeout=10)
        if self.process.stdout is not None:
            self.process.stdout.close()
        self.workspace.cleanup()


class UserProgramsApiTests(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls) -> None:
        # One compiler service serves the whole class; each test starts its own app, so with an empty store.
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

    def test_each_unedited_curated_source_is_created_then_held_and_answers_as_its_curated_example(self) -> None:
        for example in curated.list_examples():
            with self.subTest(example=example):
                source = curated_source(example)
                created = self.post(f"{example}.c", source)
                self.assertEqual(created.status_code, 201, created.text)
                body = created.json()
                self.assertEqual(body["programId"], program_id(f"{example}.c", source))
                self.assertEqual(body["fileName"], f"{example}.c")
                self.assertEqual(body["sha256"], hashlib.sha256(source.encode("utf-8")).hexdigest())
                self.assertEqual(set(body["manifest"]), MANIFEST_FIELDS)

                again = self.post(f"{example}.c", source)
                self.assertEqual((again.status_code, again.json()), (200, body))
                self.assertEqual(self.client.get(f"/api/programs/{body['programId']}").json(), body)
                self.assert_mirrors_curated(f"/api/programs/{body['programId']}", f"/api/examples/{example}",
                                            body["programId"])

    def assert_mirrors_curated(self, program_root: str, curated_root: str, program: str) -> None:
        def both(path: str):
            program_response = self.client.get(program_root + path)
            curated_response = self.client.get(curated_root + path)
            self.assertEqual(program_response.status_code, 200, program_response.text)
            self.assertEqual(curated_response.status_code, 200, curated_response.text)
            return program_response.json(), curated_response.json()

        states, curated_states = both("/states")
        self.assertEqual(without_commands(states), without_commands(curated_states))
        # Each state's origin is the command, among those the compiler service ran, that wrote its IR.
        commands = self.client.get(program_root).json()["manifest"]["commands"]
        self.assertEqual([state["originCommand"] for state in states["states"]],
                         [commands[0], *commands[2:-1]])
        source, curated_source_view = both("/source")
        self.assertEqual(source, with_program_id(curated_source_view, program))
        for ordinal in range(len(states["states"])):
            ir, curated_ir = both(f"/states/{ordinal}/ir")
            self.assertEqual(ir, curated_ir)
            for function in ir["functions"]:
                query = f"?functionId={function['id']}"
                cfg, curated_cfg = both(f"/states/{ordinal}/cfg{query}")
                self.assertEqual(cfg, curated_cfg)
                mappings, curated_mappings = both(f"/states/{ordinal}/source-mappings{query}")
                self.assertEqual(mappings, with_program_id(curated_mappings, program))
        for from_ordinal, to_ordinal in ((0, 1), (3, 4), (12, 13), (0, 13), (13, 0)):
            report, curated_report = both(f"/comparison-report?fromOrdinal={from_ordinal}&toOrdinal={to_ordinal}")
            # Link evidence can quote a debug location's full path, which differs only in its directory.
            self.assertEqual(without_commands(paths_as_curated(report)),
                             without_commands(with_program_id(curated_report, program)))

    def test_the_manifest_records_the_toolchain_and_runs_exactly_the_curated_commands(self) -> None:
        source = curated_source("binary_search")
        posted = self.post("binary_search.c", source).json()

        response = self.client.get(f"/api/programs/{posted['programId']}")

        self.assertEqual(response.status_code, 200)
        manifest = response.json()["manifest"]
        curated_manifest = curated.manifest_path("binary_search").read_text(encoding="utf-8")
        self.assertIn(f"clang: {manifest['clang']}\n", curated_manifest)
        self.assertIn(f"opt: {manifest['opt']}\n", curated_manifest)
        self.assertEqual(manifest["targetTriple"], "x86_64-unknown-linux-gnu")
        self.assertEqual((manifest["compilerImage"], manifest["libcVersion"]),
                         ("sha256:fake-compiler-image", "2.39-0ubuntu8.fake"))
        workspace = Path(self.compiler.workspace.name).resolve()
        self.assertEqual(manifest["commands"], [
            format_command(command) for command in pass_sequence_commands(
                f"{workspace}/user-programs/binary_search.c", f"{workspace}/out", "binary_search")
        ])

    def test_an_id_that_is_not_held_is_an_unknown_program(self) -> None:
        held = self.post("score.c", curated_source("score")).json()["programId"]
        for program in ("0" * 64, held.upper(), "score", "not-a-program-id"):
            for route in PROGRAM_ROUTES:
                with self.subTest(program=program, route=route):
                    response = self.client.get(f"/api/programs/{program}{route}")
                    self.assertEqual((response.status_code, response.json()["error"]["code"]),
                                     (404, "unknown_program"))

    def test_curated_routes_never_resolve_a_program_id(self) -> None:
        program = self.post("score.c", curated_source("score")).json()["programId"]
        for route in PROGRAM_ROUTES[1:]:
            with self.subTest(route=route):
                response = self.client.get(f"/api/examples/{program}{route}")
                self.assertEqual((response.status_code, response.json()["error"]["code"]), (404, "not_found"))

    def test_the_store_holds_sixteen_programs_least_recently_used_out_first(self) -> None:
        source = curated_source("score")
        ids = [self.post(f"score_{index}.c", source).json()["programId"] for index in range(16)]
        self.assertEqual(self.client.get(f"/api/programs/{ids[0]}/states").status_code, 200)

        newest = self.post("score_16.c", source)

        self.assertEqual(newest.status_code, 201)
        evicted = self.client.get(f"/api/programs/{ids[1]}")
        self.assertEqual((evicted.status_code, evicted.json()["error"]["code"]), (404, "unknown_program"))
        for program in (ids[0], *ids[2:], newest.json()["programId"]):
            self.assertEqual(self.client.get(f"/api/programs/{program}").status_code, 200)

    def test_a_source_with_no_recording_fails_as_the_fake_says_not_as_a_compile_error(self) -> None:
        response = self.post("unrecorded.c", "int unrecorded(void) { return 0; }\n")

        self.assertEqual(response.status_code, 422, response.text)
        error = response.json()["error"]
        self.assertEqual(error["code"], "compile_failed")
        self.assertIn("irx-fake: no recording for source sha256", error["output"])
        program = program_id("unrecorded.c", "int unrecorded(void) { return 0; }\n")
        self.assertEqual(self.client.get(f"/api/programs/{program}").json()["error"]["code"], "unknown_program")

    def test_a_malformed_post_is_an_invalid_request(self) -> None:
        source = curated_source("score")
        for body in ({}, {"fileName": "score.c"}, {"source": source}, {"fileName": 1, "source": source},
                     {"fileName": "score.c", "source": None}, {"fileName": "score.c", "source": source, "x": 1},
                     # Until names are rewritten to safe ones, a name that is not already safe is refused.
                     {"fileName": "../score.c", "source": source}):
            with self.subTest(body=body):
                response = self.client.post("/api/programs", json=body)
                self.assertEqual((response.status_code, response.json()["error"]["code"]), (422, "invalid_request"))


if __name__ == "__main__":
    unittest.main()
