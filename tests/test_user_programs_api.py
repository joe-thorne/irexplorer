"""User programs over /api/programs, through the app's HTTP boundary.

The app runs in-process with user programs on, pointed at the real compiler service, started by its
entry point on a loopback port over the fake clang and opt in tests/fake_toolchain. No Docker or LLVM.
"""

import contextlib
import hashlib
import json
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.request
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError

import uvicorn
from fastapi.testclient import TestClient
from test_accepted_programs import CASES, expand

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

    def __init__(self, *, timeout: float = 30) -> None:
        self.workspace = tempfile.TemporaryDirectory()
        self.process = subprocess.Popen(
            [sys.executable, "-m", "src.backend.toolchain.compiler_service", "--host", "127.0.0.1", "--port", "0",
             "--toolchain", str(FAKE_TOOLCHAIN), "--workspace", self.workspace.name, "--timeout", str(timeout),
             "--compiler-image", "sha256:fake-compiler-image", "--libc-version", "2.39-0ubuntu8.fake"],
            cwd=curated.REPO_ROOT, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
        )
        assert self.process.stdout is not None
        ready = self.process.stdout.readline()
        if not ready.startswith("Compiler service listening on "):
            self.stop()
            raise RuntimeError(f"compiler service did not start: {ready!r}")
        self.url = ready.removeprefix("Compiler service listening on ").strip()

    def wait_until_compiling(self) -> None:
        """Return once a program's source is in the work directory, so a compile is under way."""
        programs = Path(self.workspace.name) / "user-programs"
        deadline = time.monotonic() + 10
        while not (programs.is_dir() and any(programs.iterdir())):
            if time.monotonic() > deadline:
                raise AssertionError("no compile started")
            time.sleep(0.02)

    def stop(self) -> None:
        self.process.terminate()
        self.process.wait(timeout=10)
        if self.process.stdout is not None:
            self.process.stdout.close()
        self.workspace.cleanup()


@contextlib.contextmanager
def answering(status: int, body: bytes) -> Iterator[str]:
    """A stand-in compiler service that answers every compile with this status and body; yields its URL."""

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            self.rfile.read(int(self.headers["Content-Length"]))
            self.send_response(status)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args) -> None:
            pass

    with ThreadingHTTPServer(("127.0.0.1", 0), Handler) as http:
        thread = threading.Thread(target=http.serve_forever, daemon=True)
        thread.start()
        try:
            yield f"http://127.0.0.1:{http.server_port}"
        finally:
            http.shutdown()


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

    def test_a_compile_during_another_is_refused_as_busy_while_held_programs_still_answer(self) -> None:
        held = self.post("binary_search.c", curated_source("binary_search")).json()
        # The fake clang takes a couple of seconds over a source carrying the slow marker.
        slow_source = curated_source("score") + "// irx-fake: slow\n"
        with ThreadPoolExecutor(max_workers=1) as background:
            slow = background.submit(self.post, "slow.c", slow_source)
            self.compiler.wait_until_compiling()

            busy = self.post("score.c", curated_source("score"))
            held_again = self.post("binary_search.c", curated_source("binary_search"))
            held_view = self.client.get(f"/api/programs/{held['programId']}/states")

            self.assertEqual(slow.result().status_code, 201, slow.result().text)
        self.assertEqual(busy.status_code, 409, busy.text)
        self.assertEqual(busy.json()["error"]["code"], "compiler_busy")
        self.assertIn("busy", busy.json()["error"]["message"])
        self.assertEqual(busy.headers["cache-control"], "no-store")
        self.assertEqual((held_again.status_code, held_again.json()), (200, held))
        self.assertEqual(held_view.status_code, 200)
        refused = self.client.get(f"/api/programs/{program_id('score.c', curated_source('score'))}")
        self.assertEqual(refused.json()["error"]["code"], "unknown_program")
        # Nothing queued: once the slow compile is over, the same program compiles.
        self.assertEqual(self.post("score.c", curated_source("score")).status_code, 201)

    def test_a_malformed_post_is_an_invalid_request(self) -> None:
        source = curated_source("score")
        for body in ({}, {"fileName": "score.c"}, {"source": source}, {"fileName": 1, "source": source},
                     {"fileName": "score.c", "source": None}, {"fileName": "score.c", "source": source, "x": 1}):
            with self.subTest(body=body):
                response = self.client.post("/api/programs", json=body)
                self.assertEqual((response.status_code, response.json()["error"]["code"]), (422, "invalid_request"))

    def test_a_body_that_is_not_utf8_is_an_invalid_request_not_a_wrong_method(self) -> None:
        # Raw bytes that are not UTF-8 never reach the route: the framework refuses the body with 400.
        response = self.client.post("/api/programs", content=b'{"fileName": "score.c", "source": "\xff"}',
                                    headers={"Content-Type": "application/json"})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["error"]["code"], "invalid_request")
        self.assertEqual(self.client.put("/api/programs").json()["error"]["code"], "method_not_allowed")

    def test_each_refusal_is_an_invalid_program_with_its_reason_and_message(self) -> None:
        refused = [case for case in CASES if "refused" in case]
        self.assertEqual({case["refused"]["reason"] for case in refused},
                         {"not_c_file", "empty", "invalid_utf8", "nul_character", "too_many_lines", "too_large"})
        for case in refused:
            with self.subTest(case["name"]):
                # json.dumps escapes a lone surrogate as \u, as a browser's JSON.stringify does.
                response = self.client.post(
                    "/api/programs", headers={"Content-Type": "application/json"},
                    content=json.dumps({"fileName": expand(case["fileName"]), "source": expand(case["source"])}))
                self.assertEqual(response.status_code, 400, response.text)
                self.assertEqual(response.json(), {"error": {"code": "invalid_program", **case["refused"]}})
                self.assertEqual(response.headers["cache-control"], "no-store")

    def test_normalising_the_source_preserves_the_program_id(self) -> None:
        source = curated_source("score")
        created = self.post("score.c", source).json()
        for name, variant in (("CRLF", source.replace("\n", "\r\n")), ("CR", source.replace("\n", "\r")),
                              ("BOM", "\ufeff" + source), ("BOM and CRLF", "\ufeff" + source.replace("\n", "\r\n"))):
            with self.subTest(name):
                response = self.post("score.c", variant)
                self.assertEqual((response.status_code, response.json()), (200, created))
        self.assertEqual(self.client.get(f"/api/programs/{created['programId']}/source").json()["text"], source)

    def test_a_rewritten_name_is_the_saved_name_and_changes_the_program_id(self) -> None:
        source = curated_source("score")
        score = self.post("score.c", source).json()["programId"]
        for posted, safe in (("My Program (2).c", "My_Program_2_.c"), ("SCORE.C", "SCORE.c")):
            with self.subTest(posted):
                created = self.post(posted, source)
                self.assertEqual(created.status_code, 201, created.text)
                body = created.json()
                self.assertEqual((body["fileName"], body["programId"]), (safe, program_id(safe, source)))
                self.assertNotEqual(body["programId"], score)
                self.assertEqual(self.client.get(f"/api/programs/{body['programId']}/source").json()["file"], safe)
                # The safe name posted as it is names the same program.
                again = self.post(safe, source)
                self.assertEqual((again.status_code, again.json()), (200, body))


class CompilerTimeoutTests(unittest.TestCase):
    """A compile that runs past the compiler service's timeout, shortened here so it takes half a second."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.compiler = LoopbackCompilerService(timeout=0.5)

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

    def test_a_compile_past_the_timeout_is_stopped_and_its_work_directory_wiped(self) -> None:
        # The fake clang hangs in a child process that keeps writing into the work directory, as clang's
        # own -cc1 child would, so a compile that kills only its direct child leaves files behind.
        source = "int main(void) { return 0; }\n// irx-fake: hang\n"
        workspace = Path(self.compiler.workspace.name)
        for attempt in range(2):
            with self.subTest(attempt=attempt):
                response = self.client.post("/api/programs", json={"fileName": "hang.c", "source": source})

                self.assertEqual(response.status_code, 504, response.text)
                self.assertEqual(response.json()["error"]["code"], "compile_timeout")
                self.assertIn("0.5 s", response.json()["error"]["message"])
                self.assertEqual(response.headers["cache-control"], "no-store")
                time.sleep(0.3)
                self.assertEqual(list(workspace.iterdir()), [])
                # Nothing is held, and the compiler is free again: the second attempt times out too, not busy.
                held = self.client.get(f"/api/programs/{program_id('hang.c', source)}")
                self.assertEqual(held.json()["error"]["code"], "unknown_program")


class CompileCancelTests(unittest.TestCase):
    """A browser that drops its POST mid-compile (Cancel). The app runs under a real HTTP server here,
    since the in-process test client cannot drop a request."""

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
        listening = socket.socket()
        listening.bind(("127.0.0.1", 0))
        # Listening before uvicorn starts queues the test's connections until the server accepts them, so the
        # test never races the server thread (Linux refuses a connection to a socket that is not listening).
        listening.listen()
        self.addCleanup(listening.close)
        self.port = listening.getsockname()[1]
        server = uvicorn.Server(uvicorn.Config(app, log_level="warning"))
        thread = threading.Thread(target=server.run, kwargs={"sockets": [listening]}, daemon=True)
        thread.start()
        self.addCleanup(thread.join, 10)
        self.addCleanup(setattr, server, "should_exit", True)

    def post(self, file_name: str, source: str) -> tuple[int, dict]:
        request = urllib.request.Request(
            f"http://127.0.0.1:{self.port}/api/programs", method="POST",
            data=json.dumps({"fileName": file_name, "source": source}).encode(),
            headers={"Content-Type": "application/json"})
        try:
            with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=30) as response:
                return response.status, json.loads(response.read())
        except HTTPError as exc:
            with exc:
                return exc.code, json.loads(exc.read())

    def test_dropping_a_compile_request_frees_the_compiler(self) -> None:
        body = json.dumps({"fileName": "hang.c", "source": "int main(void) { return 0; }\n// irx-fake: hang\n"})
        with socket.create_connection(("127.0.0.1", self.port)) as browser:
            browser.sendall(f"POST /api/programs HTTP/1.1\r\nHost: 127.0.0.1\r\n"
                            f"Content-Type: application/json\r\nContent-Length: {len(body)}\r\n\r\n{body}".encode())
            self.compiler.wait_until_compiling()
        dropped = time.monotonic()

        # The app drops its own request, so the compiler service stops the hanging compile and wipes its
        # work directory at once rather than at its 30 s timeout.
        workspace = Path(self.compiler.workspace.name)
        while list(workspace.iterdir()):
            self.assertLess(time.monotonic() - dropped, 3, "the compile was not stopped")
            time.sleep(0.02)
        status, created = self.post("score.c", curated_source("score"))
        self.assertEqual(status, 201, created)


class CompilerUnavailableTests(unittest.TestCase):
    """A compiler service that cannot be reached, or that never answers: no compiler service runs here."""

    def start(self, compiler_url: str, **setting) -> TestClient:
        study = tempfile.TemporaryDirectory()
        self.addCleanup(study.cleanup)
        app = create_app(study_config=Config(Path(study.name), collection_mode="local"),
                         user_programs=UserProgramsSetting(True, compiler_url, **setting))
        client = TestClient(app)
        self.addCleanup(client.close)
        return client

    def assert_unavailable(self, client: TestClient) -> None:
        source = curated_source("score")
        response = client.post("/api/programs", json={"fileName": "score.c", "source": source})

        self.assertEqual(response.status_code, 503, response.text)
        self.assertEqual(response.json()["error"]["code"], "compiler_unavailable")
        self.assertIn("compiler service", response.json()["error"]["message"])
        self.assertEqual(response.headers["cache-control"], "no-store")
        held = client.get(f"/api/programs/{program_id('score.c', source)}")
        self.assertEqual(held.json()["error"]["code"], "unknown_program")

    def test_a_compiler_service_that_cannot_be_reached_is_unavailable(self) -> None:
        with socket.socket() as reserved:
            reserved.bind(("127.0.0.1", 0))
            port = reserved.getsockname()[1]
        # Nothing listens on the port any more, so the connection is refused.
        self.assert_unavailable(self.start(f"http://127.0.0.1:{port}"))

    def test_a_compiler_service_that_answers_in_a_way_the_app_does_not_understand_is_unavailable(self) -> None:
        for status, body in ((500, b'{"error": {"code": "internal", "message": "Something broke."}}'),
                             (502, b"<html><body>Bad gateway</body></html>"),
                             (200, b"not json"),
                             (200, b"{}")):
            with (self.subTest(status=status, body=body), answering(status, body) as url,
                  self.assertLogs("src.backend.programs.compiler", "WARNING")):
                self.assert_unavailable(self.start(url))

    def test_a_compiler_service_that_does_not_answer_in_time_is_unavailable(self) -> None:
        # The connection is accepted (queued by the listening socket) but never answered.
        with socket.socket() as silent:
            silent.bind(("127.0.0.1", 0))
            silent.listen()
            client = self.start(f"http://127.0.0.1:{silent.getsockname()[1]}", compiler_timeout=0.3)
            started = time.monotonic()
            self.assert_unavailable(client)
            self.assertLess(time.monotonic() - started, 5)


if __name__ == "__main__":
    unittest.main()
