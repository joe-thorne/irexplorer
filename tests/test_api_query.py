from concurrent.futures import ThreadPoolExecutor
import unittest

from fastapi.testclient import TestClient

from src.backend.api import InvalidQueryError, QueryError, QueryService, create_app


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
        self.assertEqual(states[1]["transition"]["passName"], "mem2reg")
        self.assertTrue(states[4]["transition"]["noOp"])
        self.assertEqual(states[-1]["transition"]["kind"], "recompiled")
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

        mapping = service.counterparts("score", 2, "fn0/bb0", 3)
        self.assertEqual(mapping["counterpartOrdinal"], 3)
        self.assertEqual(mapping["counterparts"][0]["kind"], "BasicBlock")
        reverse_mapping = service.counterparts("score", 3, "fn0/bb0", 2)
        self.assertEqual(reverse_mapping["counterpartOrdinal"], 2)
        self.assertEqual(id(service._examples["score"].timeline), timeline_id)

    def test_invalid_queries_are_controlled(self) -> None:
        service = QueryService()

        with self.assertRaises(QueryError):
            service.list_states("missing")
        with self.assertRaises(QueryError):
            service.cfg("score", 0, "missing")
        with self.assertRaises(QueryError):
            service.ir("score", 14)
        with self.assertRaises(InvalidQueryError):
            service.counterparts("score", 0, "fn0/bb0", 0)
        with self.assertRaises(QueryError):
            service.counterparts("score", 0, "missing", 1)

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

        mapping = self.client.get(
            "/api/examples/score/states/2/counterparts?nodeId=fn0%2Fbb0&toOrdinal=3"
        )
        self.assertEqual(mapping.status_code, 200)
        self.assertEqual(mapping.json()["counterpartOrdinal"], 3)

    def test_errors_are_typed_and_controlled(self) -> None:
        for retired_route in (
            "/api/source?ordinal=0",
            "/api/summary?fromOrdinal=0&toOrdinal=1",
            "/api/focus",
        ):
            with self.subTest(retired_route=retired_route):
                response = self.client.get(retired_route)
                self.assertEqual(response.status_code, 404)
                self.assertEqual(response.json()["error"]["code"], "not_found")

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

        invalid_target = self.client.get(
            "/api/examples/score/states/0/counterparts?nodeId=fn0%2Fbb0&toOrdinal=0"
        )
        self.assertEqual(invalid_target.status_code, 422)
        self.assertEqual(invalid_target.json()["error"]["code"], "invalid_query")

        missing_function = self.client.get(
            "/api/examples/score/states/0/cfg?functionId=missing"
        )
        self.assertEqual(missing_function.status_code, 404)
        self.assertEqual(missing_function.json()["error"]["code"], "not_found")

    def test_openapi_documents_only_the_read_only_query_surface(self) -> None:
        schema = self.client.get("/openapi.json")
        self.assertEqual(schema.status_code, 200)
        self.assertEqual(
            set(schema.json()["paths"]),
            {
                "/api/health",
                "/api/examples",
                "/api/examples/{example_id}/states",
                "/api/examples/{example_id}/states/{ordinal}/ir",
                "/api/examples/{example_id}/states/{ordinal}/cfg",
                "/api/examples/{example_id}/states/{ordinal}/counterparts",
            },
        )
        self.assertEqual(self.client.get("/docs").status_code, 200)
        no_docs_client = TestClient(create_app(include_docs=False))
        self.addCleanup(no_docs_client.close)
        self.assertEqual(no_docs_client.get("/docs").status_code, 404)

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
            "renderSummary",
            "renderSource",
        ):
            self.assertNotIn(retired_detail, javascript.text)

        stylesheet = self.client.get("/style.css")
        self.assertEqual(stylesheet.status_code, 200)
        self.assertEqual(stylesheet.headers["content-type"].split(";")[0], "text/css")
        self.assertIn(".panel-grid", stylesheet.text)
        self.assertIn(".ir-line.is-linked", stylesheet.text)
        self.assertIn("@media (prefers-reduced-motion: reduce)", stylesheet.text)
        self.assertIn("@media (forced-colors: active)", stylesheet.text)
        self.assertIn("@media (max-width: 900px)", stylesheet.text)
        self.assertNotIn(".learning-task", stylesheet.text)


if __name__ == "__main__":
    unittest.main()
