import errno
import json
from threading import Thread
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from src.backend.api import QueryError, QueryService, create_server


class QueryServiceTests(unittest.TestCase):
    def test_queries_load_prebaked_records_without_server_side_focus(self) -> None:
        service = QueryService()
        self.assertEqual(service.list_examples()["examples"], ["binary_search", "quick_sort", "score"])
        with self.assertRaises(QueryError):
            service.list_states()

        loaded = service.load_example("score")
        self.assertEqual(set(loaded), {"exampleId", "states"})
        self.assertEqual(len(loaded["states"]), 14)
        self.assertEqual(loaded["states"][1]["transition"]["passName"], "mem2reg")
        self.assertTrue(loaded["states"][4]["transition"]["noOp"])
        self.assertEqual(loaded["states"][-1]["transition"]["kind"], "recompiled")
        timeline_id = id(service._loaded.timeline)  # cached artefacts, not reprocessed

        ir = service.ir(0)
        self.assertEqual(ir["functions"][0]["name"], "score")
        entry = ir["functions"][0]["blocks"][0]
        instruction = entry["instructions"][0]
        self.assertGreater(len(entry["instructions"]), 0)
        self.assertEqual(set(instruction), {"id", "kind", "displayName", "text", "opcode"})

        cfg = service.cfg(0, "fn0")
        self.assertEqual(len(cfg["blocks"]), 4)
        self.assertGreater(len(cfg["edges"]), 0)

        mapping = service.counterparts(2, "fn0/bb0", 3)
        self.assertEqual(mapping["counterpartOrdinal"], 3)
        self.assertEqual(mapping["counterparts"][0]["kind"], "BasicBlock")
        reverse_mapping = service.counterparts(3, "fn0/bb0", 2)
        self.assertEqual(reverse_mapping["counterpartOrdinal"], 2)
        self.assertEqual(id(service._loaded.timeline), timeline_id)

    def test_invalid_queries_are_controlled(self) -> None:
        service = QueryService()
        service.load_example("score")

        with self.assertRaises(QueryError):
            service.cfg(0, "missing")
        with self.assertRaises(QueryError):
            service.ir(14)
        with self.assertRaises(QueryError):
            service.counterparts(0, "fn0/bb0", 0)
        with self.assertRaises(QueryError):
            service.counterparts(0, "missing", 1)

    def test_largest_curated_function_remains_scoped_and_queryable(self) -> None:
        service = QueryService()
        service.load_example("quick_sort")

        state = service.ir(0)
        partition = next(function for function in state["functions"] if function["name"] == "partition")
        self.assertEqual(len(partition["blocks"]), 7)
        self.assertEqual(
            sum(len(block["instructions"]) for block in partition["blocks"]),
            93,
        )
        cfg = service.cfg(0, partition["id"])
        self.assertEqual(len(cfg["blocks"]), len(partition["blocks"]))
        self.assertTrue(cfg["edges"])


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

    def test_localhost_routes_supply_the_two_panel_data(self) -> None:
        self.assertEqual(_get_json(f"{self.base_url}/api/health"), {"status": "ok"})
        self.assertIn("score", _get_json(f"{self.base_url}/api/examples")["examples"])

        loaded = _post_json(f"{self.base_url}/api/session", {"exampleId": "score"})
        self.assertEqual(set(loaded), {"exampleId", "states"})
        self.assertEqual(
            _get_json(f"{self.base_url}/api/ir?ordinal=1")["stateId"], "mem2reg"
        )
        cfg = _get_json(f"{self.base_url}/api/cfg?ordinal=0&functionId=fn0")
        self.assertEqual(len(cfg["blocks"]), 4)
        mapping = _get_json(
            f"{self.base_url}/api/counterparts?ordinal=2&nodeId=fn0%2Fbb0&toOrdinal=3"
        )
        self.assertEqual(mapping["counterpartOrdinal"], 3)

        for retired_route in (
            f"{self.base_url}/api/source?ordinal=0",
            f"{self.base_url}/api/summary?fromOrdinal=0&toOrdinal=1",
            f"{self.base_url}/api/focus",
        ):
            with self.subTest(retired_route=retired_route):
                with self.assertRaises(HTTPError) as context:
                    if retired_route.endswith("/focus"):
                        _post_json(retired_route, {"ordinal": 0, "nodeId": "fn0/bb0"})
                    else:
                        urlopen(retired_route)
                self.assertEqual(context.exception.code, 404)
                context.exception.close()

        with self.assertRaises(HTTPError) as context:
            urlopen(f"{self.base_url}/api/cfg?ordinal=0&functionId=missing")
        self.assertEqual(context.exception.code, 404)
        context.exception.close()

    def test_localhost_server_does_not_expose_user_source_analysis(self) -> None:
        with self.assertRaises(HTTPError) as context:
            _post_json(
                f"{self.base_url}/api/analysis",
                {"language": "c", "source": "int main(void) { return 0; }"},
            )
        self.assertEqual(context.exception.code, 404)
        context.exception.close()

    def test_localhost_server_serves_the_lean_browser_frontend(self) -> None:
        with urlopen(f"{self.base_url}/") as response:
            html = response.read().decode("utf-8")
            self.assertEqual(response.headers.get_content_type(), "text/html")
        self.assertIn("irexplorer", html)
        self.assertIn('src="/app.js"', html)
        for element_id in (
            "example-select",
            "function-select",
            "workspace",
            "comparison-action",
            "selection-status",
            "left-state",
            "left-view",
            "left-viewer",
            "right-state",
            "right-view",
            "right-viewer",
        ):
            self.assertIn(f'id="{element_id}"', html)
        for retired_element_id in (
            "guided-timeline",
            "learning-task",
            "full-artefact",
            "full-source-view",
            "selection-inspector",
            "ir-filter",
            "cfg-neighbourhood",
        ):
            self.assertNotIn(f'id="{retired_element_id}"', html)

        with urlopen(f"{self.base_url}/app.js") as response:
            javascript = response.read().decode("utf-8")
        self.assertEqual(response.headers.get_content_type(), "text/javascript")
        for api_path in ("/api/session", "/api/ir", "/api/cfg", "/api/counterparts"):
            self.assertIn(api_path, javascript)
        for implementation_detail in ("selectNode", "displayNodeIds", "PASS_ACTIONS"):
            self.assertIn(implementation_detail, javascript)
        for retired_detail in ("/api/focus", "CURATED_LEARNING_TASKS", "renderLearningTask", "renderSummary", "renderSource"):
            self.assertNotIn(retired_detail, javascript)

        with urlopen(f"{self.base_url}/style.css") as response:
            stylesheet = response.read().decode("utf-8")
            self.assertEqual(response.headers.get_content_type(), "text/css")
        self.assertIn(".panel-grid", stylesheet)
        self.assertIn(".ir-line.is-linked", stylesheet)
        self.assertIn("@media (prefers-reduced-motion: reduce)", stylesheet)
        self.assertIn("@media (forced-colors: active)", stylesheet)
        self.assertIn("@media (max-width: 900px)", stylesheet)
        self.assertNotIn(".learning-task", stylesheet)


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
