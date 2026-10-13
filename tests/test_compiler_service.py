"""The compiler service's own HTTP boundary, for what the app cannot show: its work directory.

The app's view of the compiler service is covered in test_user_programs_api.py.
"""

import json
import socket
import tempfile
import threading
import time
import unittest
import urllib.request
from pathlib import Path
from urllib.error import HTTPError

from src.backend.toolchain import curated
from src.backend.toolchain.compiler_service import CompilerService, server

FAKE_TOOLCHAIN = curated.REPO_ROOT / "tests" / "fake_toolchain"


class CompilerServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.workspace = Path(directory.name).resolve()
        http = server(CompilerService(toolchain=FAKE_TOOLCHAIN, workspace=self.workspace), "127.0.0.1", 0)
        thread = threading.Thread(target=http.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(http.server_close)
        self.addCleanup(http.shutdown)
        self.port = http.server_port
        self.url = f"http://127.0.0.1:{self.port}/compile"
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def compile(self, file_name: str, source: str) -> tuple[int, dict]:
        request = urllib.request.Request(
            self.url, data=json.dumps({"fileName": file_name, "source": source}).encode("utf-8"),
            headers={"Content-Type": "application/json"}, method="POST",
        )
        try:
            with self.opener.open(request, timeout=30) as response:
                return response.status, json.loads(response.read())
        except HTTPError as exc:
            with exc:
                return exc.code, json.loads(exc.read())

    def wait_until(self, condition, what: str) -> None:
        deadline = time.monotonic() + 5
        while not condition():
            if time.monotonic() > deadline:
                raise AssertionError(f"timed out waiting until {what}")
            time.sleep(0.02)

    def start_hanging_compile_then_disconnect(self) -> None:
        # The fake clang hangs in a child process that keeps writing into the work directory, so files
        # reappear unless the whole command, child included, is killed.
        body = json.dumps({"fileName": "hang.c", "source": "int main(void) { return 0; }\n// irx-fake: hang\n"})
        with socket.create_connection(("127.0.0.1", self.port)) as client:
            client.sendall(f"POST /compile HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\n"
                           f"Content-Length: {len(body)}\r\n\r\n{body}".encode())
            self.wait_until(lambda: (self.workspace / "out" / "hang_O0.ll").exists(), "clang is running")

    def test_a_client_that_disconnects_mid_compile_stops_the_commands_and_frees_the_service(self) -> None:
        self.start_hanging_compile_then_disconnect()
        # The client has gone: the service stops the compile at once, well inside its 30 s timeout.
        self.wait_until(lambda: list(self.workspace.iterdir()) == [], "the work directory is wiped")
        time.sleep(0.2)
        self.assertEqual(list(self.workspace.iterdir()), [])
        # Free again: the next program compiles rather than being refused as busy.
        score = (curated.EXAMPLES_ROOT / "score.c").read_text(encoding="utf-8")
        self.assertEqual(self.compile("score.c", score)[0], 200)

    def test_a_program_sent_the_moment_a_client_disconnects_is_compiled_not_refused_as_busy(self) -> None:
        # Cancel, then upload again at once: the cancelled compile is still stopping when the next arrives.
        self.start_hanging_compile_then_disconnect()
        score = (curated.EXAMPLES_ROOT / "score.c").read_text(encoding="utf-8")

        self.assertEqual(self.compile("score.c", score)[0], 200)
        time.sleep(0.2)
        self.assertEqual(list(self.workspace.iterdir()), [])

    def test_the_work_directory_is_wiped_after_every_program(self) -> None:
        score = (curated.EXAMPLES_ROOT / "score.c").read_text(encoding="utf-8")
        for file_name, source, status in (("score.c", score, 200),
                                          ("unrecorded.c", "int unrecorded(void) { return 0; }\n", 422)):
            with self.subTest(file_name=file_name):
                self.assertEqual(self.compile(file_name, source)[0], status)
                self.assertEqual(list(self.workspace.iterdir()), [])

    def test_only_text_leaves_the_service(self) -> None:
        status, body = self.compile("score.c", (curated.EXAMPLES_ROOT / "score.c").read_text(encoding="utf-8"))

        self.assertEqual(status, 200)
        self.assertEqual(set(body), {"states", "optRecord", "rpass", "manifest"})
        self.assertEqual([state["stateId"] for state in body["states"]],
                         [state.state_id for state in curated.PASS_STATES])
        self.assertTrue(all(set(state) == {"stateId", "ir", "remarks", "command"} for state in body["states"]))

    def test_a_file_name_that_could_leave_the_workspace_is_refused(self) -> None:
        for file_name in ("../score.c", "/tmp/score.c", "sub/score.c", "score.h", ".c", "a" * 65 + ".c"):
            with self.subTest(file_name=file_name):
                status, body = self.compile(file_name, "int main(void) { return 0; }\n")
                self.assertEqual((status, body["error"]["code"]), (400, "invalid_request"))
                self.assertEqual(list(self.workspace.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
