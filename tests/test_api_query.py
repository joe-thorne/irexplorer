import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

from fastapi.testclient import TestClient

from src.backend.api import (
    DataUnavailableError,
    QueryError,
    QueryService,
    create_app,
)
from src.backend.ingest import load_curated_timeline
from src.backend.model import deserialise_timeline, serialise_timeline


class QueryServiceTests(unittest.TestCase):
    def test_queries_are_scoped_to_immutable_prebaked_examples(self) -> None:
        service = QueryService()
        self.assertEqual(
            service.list_examples()["examples"],
            ["binary_search", "quick_sort", "score"],
        )
        self.assertEqual(set(service._examples), {"binary_search", "quick_sort", "score"})

        states = service.list_states("score")["states"]
        self.assertEqual(len(states), 14)
        self.assertEqual(states[1]["step"]["passName"], "mem2reg")
        self.assertTrue(states[4]["step"]["noOp"])
        self.assertEqual(states[-1]["step"]["kind"], "recompiled")
        timeline_id = id(service._examples["score"].timeline)

        ir = service.ir("score", 0)
        self.assertEqual(ir["functions"][0]["name"], "score")
        entry = ir["functions"][0]["blocks"][0]
        instruction = entry["instructions"][0]
        self.assertGreater(len(entry["instructions"]), 0)
        self.assertEqual(
            set(instruction),
            {"id", "kind", "displayName", "text", "opcode"},
        )

        cfg = service.cfg("score", 0, "fn0")
        self.assertEqual(len(cfg["blocks"]), 4)
        self.assertGreater(len(cfg["edges"]), 0)

        self.assertEqual(id(service._examples["score"].timeline), timeline_id)

    def test_invalid_queries_are_controlled(self) -> None:
        service = QueryService()

        with self.assertRaises(QueryError):
            service.list_states("missing")
        with self.assertRaises(QueryError):
            service.cfg("score", 0, "missing")
        with self.assertRaises(QueryError):
            service.ir("score", 14)

    def test_prebaked_data_failures_are_not_reported_as_missing_queries(self) -> None:
        service = QueryService(preload=False)
        internal_failure = FileNotFoundError("/private/model/timeline.json")

        with patch(
            "src.backend.api.query.load_curated_timeline_record",
            side_effect=internal_failure,
        ), self.assertRaises(DataUnavailableError) as context:
            service.list_states("score")

        self.assertEqual(
            str(context.exception),
            "Model records are temporarily unavailable.",
        )
        self.assertIs(context.exception.__cause__, internal_failure)

    def test_largest_curated_function_remains_scoped_and_queryable(self) -> None:
        service = QueryService()

        state = service.ir("quick_sort", 0)
        partition = next(
            function for function in state["functions"] if function["name"] == "partition"
        )
        self.assertEqual(len(partition["blocks"]), 7)
        self.assertEqual(
            sum(len(block["instructions"]) for block in partition["blocks"]),
            93,
        )
        cfg = service.cfg("quick_sort", 0, partition["id"])
        self.assertEqual(len(cfg["blocks"]), len(partition["blocks"]))
        self.assertTrue(cfg["edges"])

    def test_concurrent_queries_cannot_replace_another_examples_data(self) -> None:
        service = QueryService()
        expected_functions = {
            "binary_search": "binary_search",
            "quick_sort": "quick_sort",
            "score": "score",
        }

        def query(example_id: str) -> tuple[str, set[str]]:
            names = {
                function["name"] for function in service.ir(example_id, 0)["functions"]
            }
            return example_id, names

        example_ids = list(expected_functions) * 10
        with ThreadPoolExecutor(max_workers=30) as executor:
            results = list(executor.map(query, example_ids))

        for example_id, names in results:
            self.assertIn(expected_functions[example_id], names)


class FastApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(create_app())

    def tearDown(self) -> None:
        self.client.close()

    def assert_security_headers(self, response) -> None:
        self.assertEqual(
            response.headers.get("content-security-policy"),
            "default-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'",
        )
        self.assertEqual(response.headers.get("x-content-type-options"), "nosniff")
        self.assertEqual(response.headers.get("referrer-policy"), "no-referrer")

    def test_development_hides_docs_and_every_response_has_security_headers(self) -> None:
        paths = (
            ("/", 200),
            ("/api/health", 200),
            ("/api/study/content", 200),
            ("/api/examples/missing/states", 404),
            ("/api/examples/score/states/nope/ir", 422),
            ("/missing", 404),
            ("/docs", 404),
            ("/openapi.json", 404),
        )
        for path, expected_status in paths:
            with self.subTest(path=path):
                response = self.client.get(path)
                self.assertEqual(response.status_code, expected_status)
                self.assert_security_headers(response)
                if path in ("/docs", "/openapi.json"):
                    self.assertEqual(response.json()["error"]["code"], "not_found")

        submission = self.client.post(
            "/api/study/submissions",
            json={},
            headers={
                "Origin": "http://127.0.0.1:8000",
                "Sec-Fetch-Site": "same-origin",
            },
        )
        self.assertEqual(submission.status_code, 422)
        self.assert_security_headers(submission)

    def test_packaged_release_hides_docs_and_openapi_with_controlled_not_found(self) -> None:
        with patch("src.backend.api.app.metadata", return_value={"version": "0.1.36"}):
            packaged = TestClient(create_app())
        self.addCleanup(packaged.close)

        for path in ("/docs", "/openapi.json"):
            with self.subTest(path=path):
                response = packaged.get(path)
                self.assertEqual(response.status_code, 404)
                self.assertEqual(response.json()["error"]["code"], "not_found")
                self.assert_security_headers(response)

    def test_unhandled_server_errors_are_controlled_and_keep_security_headers(self) -> None:
        with patch(
            "src.backend.api.query.QueryService.list_examples",
            side_effect=RuntimeError("internal detail must not leak"),
        ), self.assertLogs("src.backend.api.app", level="ERROR"):
            client = TestClient(create_app(), raise_server_exceptions=False)
            self.addCleanup(client.close)
            response = client.get("/api/examples")

        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.json()["error"]["code"], "internal_error")
        self.assertNotIn("internal detail", response.text)
        self.assert_security_headers(response)

    def test_stateless_routes_supply_the_two_panel_data(self) -> None:
        self.assertEqual(self.client.get("/api/health").json(), {"status": "ok"})
        self.assertIn("score", self.client.get("/api/examples").json()["examples"])

        states = self.client.get("/api/examples/score/states")
        self.assertEqual(states.status_code, 200)
        self.assertEqual(len(states.json()["states"]), 14)

        ir = self.client.get("/api/examples/score/states/1/ir")
        self.assertEqual(ir.status_code, 200)
        self.assertEqual(ir.json()["stateId"], "mem2reg")

        cfg = self.client.get("/api/examples/score/states/0/cfg?functionId=fn0")
        self.assertEqual(cfg.status_code, 200)
        self.assertEqual(len(cfg.json()["blocks"]), 4)

    def test_app_assets_bypass_legacy_cache_on_normal_and_conditional_reload(self):
        for path in ("/", "/index.html", "/app.js", "/app.js?v=e7-walkthrough-1",
                     "/vendor/dagre-1.1.5.min.js", "/source.js", "/comparison.js", "/study.js", "/study-draft.js",
                     "/study-messages.js", "/task-clock.js", "/style.css"):
            with self.subTest(path=path):
                first = self.client.get(path)
                self.assertEqual(first.status_code, 200)
                self.assertEqual(first.headers["cache-control"], "no-store")
                conditional = self.client.get(path, headers={
                    "If-None-Match": first.headers["etag"],
                    "If-Modified-Since": first.headers["last-modified"],
                })
                self.assertEqual(conditional.status_code, 200)
                self.assertEqual(conditional.content, first.content)
                self.assertEqual(conditional.headers["cache-control"], "no-store")
        html = self.client.get("/").text
        for name in ("vendor/dagre-1.1.5.min.js", "app.js", "source.js", "comparison.js", "study.js", "study-draft.js",
                     "study-messages.js", "task-clock.js", "style.css"):
            self.assertIn(f'/{name}"', html)

    def test_errors_are_typed_and_controlled(self) -> None:
        for retired_route in (
            "/api/source?ordinal=0",
            "/api/summary?fromOrdinal=0&toOrdinal=1",
            "/api/examples/score/summary?fromOrdinal=0&toOrdinal=1",
            "/api/focus",
            "/api/examples/score/states/2/counterparts?nodeId=fn0%2Fbb0&toOrdinal=3",
        ):
            with self.subTest(retired_route=retired_route):
                response = self.client.get(retired_route)
                self.assertEqual(response.status_code, 404)
                self.assertEqual(response.json()["error"]["code"], "not_found")

        report = self.client.get(
            "/api/examples/score/comparison-report?fromOrdinal=0&toOrdinal=1"
        )
        self.assertEqual(report.status_code, 200)
        report_data = report.json()
        self.assertIn("steps", report_data)
        self.assertIn("structuralClaims", report_data)
        self.assertNotIn("items", report_data)
        self.assertIn("step", report_data["states"][1])
        self.assertNotIn("transition", report_data["states"][1])

        source_submission = self.client.post(
            "/api/analysis",
            json={"language": "c", "source": "int main(void) { return 0; }"},
        )
        self.assertIn(source_submission.status_code, {404, 405})

        unknown = self.client.get("/api/examples/missing/states")
        self.assertEqual(unknown.status_code, 404)
        self.assertEqual(unknown.json()["error"]["code"], "not_found")

        invalid_ordinal = self.client.get("/api/examples/score/states/nope/ir")
        self.assertEqual(invalid_ordinal.status_code, 422)
        self.assertEqual(invalid_ordinal.json()["error"]["code"], "invalid_request")

        missing_function = self.client.get(
            "/api/examples/score/states/0/cfg?functionId=missing"
        )
        self.assertEqual(missing_function.status_code, 404)
        self.assertEqual(missing_function.json()["error"]["code"], "not_found")

    def test_missing_model_format_version_is_logged_and_sanitised(self) -> None:
        service = QueryService(preload=False)
        client = TestClient(create_app(service))
        self.addCleanup(client.close)
        invalid_record = serialise_timeline(load_curated_timeline("score"))
        del invalid_record["formatVersion"]

        with patch(
            "src.backend.api.query.load_curated_timeline_record",
            side_effect=lambda _example_id: deserialise_timeline(invalid_record),
        ), self.assertLogs("src.backend.api.app", level="ERROR") as logs:
            response = client.get("/api/examples/score/states")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["error"]["code"], "data_unavailable")
        self.assertEqual(
            response.json()["error"]["message"],
            "Model records are temporarily unavailable.",
        )
        self.assertNotIn("formatVersion", response.text)
        self.assertIn("formatVersion", "\n".join(logs.output))

    def test_openapi_and_interactive_docs_are_not_exposed(self) -> None:
        for path in ("/docs", "/openapi.json"):
            with self.subTest(path=path):
                response = self.client.get(path)
                self.assertEqual(response.status_code, 404)
                self.assertEqual(response.json()["error"]["code"], "not_found")

    def test_application_serves_the_lean_browser_frontend(self) -> None:
        html = self.client.get("/")
        self.assertEqual(html.status_code, 200)
        self.assertEqual(html.headers["content-type"].split(";")[0], "text/html")
        self.assertIn("irexplorer", html.text)
        self.assertIn('src="/app.js"', html.text)
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
            self.assertIn(f'id="{element_id}"', html.text)
        for retired_element_id in (
            "guided-timeline",
            "learning-task",
            "full-artefact",
            "full-source-view",
            "selection-inspector",
            "ir-filter",
            "cfg-neighbourhood",
        ):
            self.assertNotIn(f'id="{retired_element_id}"', html.text)

        javascript = self.client.get("/app.js")
        self.assertEqual(javascript.status_code, 200)
        self.assertEqual(javascript.headers["content-type"].split(";")[0], "text/javascript")
        for implementation_detail in ("apiRoot", "selectNode", "displayNodeIds", "PASS_ACTIONS"):
            self.assertIn(implementation_detail, javascript.text)
        for retired_detail in (
            "/api/session",
            "CURATED_LEARNING_TASKS",
            "renderLearningTask",
        ):
            self.assertNotIn(retired_detail, javascript.text)

        # Selection now consumes the already-loaded comparison synchronously.
        # Serve both frontend modules; behaviour/races are covered in browser checks.
        for path in ("/selection.js", "/tooltips.js"):
            self.assertIn(f'src="{path}"', html.text)
            response = self.client.get(path)
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.headers["content-type"].split(";")[0], "text/javascript")
        self.assertIn('svg.setAttribute("role", "group")', javascript.text)
        self.assertNotIn('svg.setAttribute("role", "img")', javascript.text)

        stylesheet = self.client.get("/style.css")
        self.assertEqual(stylesheet.status_code, 200)
        self.assertEqual(stylesheet.headers["content-type"].split(";")[0], "text/css")
        self.assertIn(".panel-grid", stylesheet.text)
        self.assertIn(".ir-line.is-linked", stylesheet.text)
        self.assertIn("@media (prefers-reduced-motion: reduce)", stylesheet.text)
        self.assertIn("@media (forced-colors: active)", stylesheet.text)
        self.assertIn("@media (max-width: 900px)", stylesheet.text)
        self.assertIn(".site-header .eyebrow { color: #67e8f9; }", stylesheet.text)
        self.assertIn(
            "button:focus-visible, select:focus-visible, .ir-line:focus-visible, .cfg-node:focus-visible",
            stylesheet.text,
        )
        self.assertNotIn("outline: none", stylesheet.text)
        self.assertNotIn(".learning-task", stylesheet.text)


if __name__ == "__main__":
    unittest.main()
