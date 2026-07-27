import json
import errno
from threading import Thread
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from src.backend.api import QueryError, QueryService, create_server


class QueryServiceTests(unittest.TestCase):
    def test_queries_use_prebaked_records_and_preserve_session_focus(self) -> None:
        service = QueryService()
        self.assertEqual(service.list_examples()["examples"], ["binary_search", "quick_sort", "score"])
        with self.assertRaises(QueryError):
            service.list_states()

        session = service.load_example("score")
        self.assertEqual([state["stateId"] for state in session["states"]], ["O0", "O3"])
        timeline_id = id(service._session.timeline)  # session retention, not reprocessing

        ir = service.ir(0)
        self.assertEqual(ir["functions"][0]["name"], "score")
        entry = ir["functions"][0]["blocks"][0]
        self.assertGreater(len(entry["instructions"]), 0)

        cfg = service.cfg(0, "fn0")
        self.assertEqual(len(cfg["blocks"]), 4)
        self.assertGreater(len(cfg["edges"]), 0)

        focus = service.set_focus(0, entry["instructions"][0]["id"])
        self.assertEqual(focus["focusedNodeId"], entry["instructions"][0]["id"])
        self.assertEqual(id(service._session.timeline), timeline_id)

        counterparts = service.counterparts(0, entry["instructions"][0]["id"])
        self.assertIn(counterparts["relation"], {"removed", "renamed", "simplifiedInto"})
        self.assertIn(counterparts["confidence"], {"exact", "approximate", "none"})
        self.assertIn("anchor comparison", service.summary()["context"])

    def test_navigation_and_invalid_queries_are_controlled(self) -> None:
        service = QueryService()
        service.load_example("score")

        children = service.children(0, "fn0")
        self.assertEqual(children["children"][0]["kind"], "BasicBlock")
        parent = service.parent(0, "fn0/bb0")
        self.assertEqual(parent["parent"]["id"], "fn0")
        with self.assertRaises(QueryError):
            service.cfg(0, "missing")
        with self.assertRaises(QueryError):
            service.set_focus(9)


class LocalhostApiTests(unittest.TestCase):
    def setUp(self) -> None:
        try:
            self.server = create_server(port=0)
        except PermissionError as exc:
            if exc.errno == errno.EPERM:
                self.skipTest("sandbox does not permit localhost socket binding")
            raise
        self.thread = Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base_url = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self) -> None:
        self.server.shutdown()
        self.thread.join()
        self.server.server_close()

    def test_localhost_routes_load_and_query_score(self) -> None:
        self.assertEqual(_get_json(f"{self.base_url}/api/health"), {"status": "ok"})
        self.assertIn("score", _get_json(f"{self.base_url}/api/examples")["examples"])

        session = _post_json(f"{self.base_url}/api/session", {"exampleId": "score"})
        self.assertEqual(session["exampleId"], "score")
        self.assertEqual(
            _get_json(f"{self.base_url}/api/ir?ordinal=1")["stateId"], "O3"
        )
        summary = _get_json(f"{self.base_url}/api/summary")
        self.assertIn("anchor comparison", summary["context"])

        with self.assertRaises(HTTPError) as context:
            urlopen(f"{self.base_url}/api/cfg?ordinal=0&functionId=missing")
        self.assertEqual(context.exception.code, 404)
        context.exception.close()

    def test_localhost_server_serves_the_browser_frontend(self) -> None:
        with urlopen(f"{self.base_url}/") as response:
            html = response.read().decode("utf-8")
            self.assertEqual(response.headers.get_content_type(), "text/html")
        self.assertIn("irexplorer", html)
        self.assertIn('src="/app.js"', html)

        with urlopen(f"{self.base_url}/app.js") as response:
            javascript = response.read().decode("utf-8")
            self.assertEqual(response.headers.get_content_type(), "text/javascript")
        self.assertIn("/api/session", javascript)


def _get_json(url: str) -> dict:
    with urlopen(url) as response:
        return json.loads(response.read().decode("utf-8"))


def _post_json(url: str, body: dict) -> dict:
    request = Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request) as response:
        return json.loads(response.read().decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
