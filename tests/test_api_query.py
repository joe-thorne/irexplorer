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
        self.assertEqual(len(session["states"]), 14)
        self.assertEqual(session["states"][1]["transition"]["passName"], "mem2reg")
        self.assertTrue(session["states"][4]["transition"]["noOp"])
        self.assertEqual(session["states"][-1]["transition"]["kind"], "recompiled")
        timeline_id = id(service._session.timeline)  # session retention, not reprocessing

        ir = service.ir(0)
        self.assertEqual(ir["functions"][0]["name"], "score")
        entry = ir["functions"][0]["blocks"][0]
        self.assertGreater(len(entry["instructions"]), 0)

        source = service.source(0)
        self.assertEqual(source["filename"], "score.c")
        source_instruction_ids = {
            instruction_id
            for line in source["lines"]
            for instruction_id in line["instructionIds"]
        }
        mapped_instruction = next(
            instruction
            for block in ir["functions"][0]["blocks"]
            for instruction in block["instructions"]
            if instruction["source"] is not None
        )
        self.assertIn(mapped_instruction["id"], source_instruction_ids)
        self.assertTrue(any(not line["instructionIds"] for line in source["lines"]))

        cfg = service.cfg(0, "fn0")
        self.assertEqual(len(cfg["blocks"]), 4)
        self.assertGreater(len(cfg["edges"]), 0)

        focus = service.set_focus(0, entry["instructions"][0]["id"])
        self.assertEqual(focus["focusedNodeId"], entry["instructions"][0]["id"])
        self.assertEqual(id(service._session.timeline), timeline_id)

        counterparts = service.counterparts(0, entry["instructions"][0]["id"])
        self.assertIn(counterparts["relation"], {"removed", "renamed", "simplifiedInto"})
        self.assertIn(counterparts["confidence"], {"exact", "approximate", "none"})
        self.assertIn("Composed comparison", service.summary()["context"])
        composed = service.summary(0, 13)
        self.assertIn("recompiled -O3 anchor", composed["context"])
        self.assertTrue(service.step(3)["noOp"])
        derived_step = service.step(0)
        self.assertIsInstance(derived_step["remarks"], list)
        for remark in derived_step["remarks"]:
            self.assertEqual(remark["type"], "remark")
            self.assertIn("instructionIds", remark)
        step_summary = service.summary(0, 1)
        self.assertTrue(
            all(item["evidence"] for item in step_summary["items"])
        )
        self.assertTrue(
            any(
                evidence["type"] == "link"
                for item in step_summary["items"]
                for evidence in item["evidence"]
            )
        )

        service.load_example("quick_sort")
        remark_summary = service.summary(3, 4)
        pass_remarks = [
            evidence
            for item in remark_summary["items"]
            for evidence in item["evidence"]
            if evidence["type"] == "remark"
        ]
        self.assertTrue(pass_remarks)
        self.assertTrue(any(remark["instructionIds"] for remark in pass_remarks))
        self.assertTrue(all("raw" in remark for remark in pass_remarks))
        self.assertEqual(service.step(12)["kind"], "recompiled")

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
            service.set_focus(14)
        with self.assertRaises(QueryError):
            service.summary(3, 3)
        with self.assertRaises(QueryError):
            service.step(-1)
        with self.assertRaises(QueryError):
            service.source(14)

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

    def test_localhost_routes_load_and_query_score(self) -> None:
        self.assertEqual(_get_json(f"{self.base_url}/api/health"), {"status": "ok"})
        self.assertIn("score", _get_json(f"{self.base_url}/api/examples")["examples"])

        session = _post_json(f"{self.base_url}/api/session", {"exampleId": "score"})
        self.assertEqual(session["exampleId"], "score")
        self.assertEqual(
            _get_json(f"{self.base_url}/api/ir?ordinal=1")["stateId"], "mem2reg"
        )
        source = _get_json(f"{self.base_url}/api/source?ordinal=1")
        self.assertEqual(source["filename"], "score.c")
        summary = _get_json(f"{self.base_url}/api/summary?fromOrdinal=0&toOrdinal=13")
        self.assertIn("recompiled -O3 anchor", summary["context"])
        self.assertTrue(_get_json(f"{self.base_url}/api/step?fromOrdinal=3")["noOp"])

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

    def test_localhost_server_serves_the_browser_frontend(self) -> None:
        with urlopen(f"{self.base_url}/") as response:
            html = response.read().decode("utf-8")
            self.assertEqual(response.headers.get_content_type(), "text/html")
        self.assertIn("irexplorer", html)
        self.assertIn('src="/app.js"', html)
        self.assertIn('id="guided-timeline"', html)
        self.assertIn('id="full-pipeline"', html)
        self.assertIn('id="story-outcomes"', html)
        self.assertNotIn('id="timeline-scrubber"', html)
        self.assertNotIn('id="state-options"', html)
        self.assertIn('id="ir-filter"', html)
        self.assertIn('id="ir-scope"', html)
        self.assertIn('id="cfg-neighbourhood"', html)
        self.assertIn('aria-live="polite"', html)
        self.assertIn('tabindex="-1"', html)

        with urlopen(f"{self.base_url}/app.js") as response:
            javascript = response.read().decode("utf-8")
        self.assertEqual(response.headers.get_content_type(), "text/javascript")
        self.assertIn("/api/session", javascript)
        self.assertIn("instructionMatchesFilter", javascript)
        self.assertIn("cfgNeighbourhood", javascript)
        self.assertIn("meaningfulTimelineStates", javascript)
        self.assertIn("const storyStates = meaningfulTimelineStates()", javascript)
        self.assertIn("PASS_ROLES", javascript)
        self.assertIn("fullPipeline", javascript)


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
