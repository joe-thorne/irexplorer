import unittest

from src.backend.analysis import compare_states
from src.backend.analysis.optimisations import detect_optimisations
from src.backend.api import QueryService
from src.backend.ingest import parse_ir_state
from src.backend.model.timeline import PassStep, StepOrigin


def state(body, ordinal):
    body = "\n".join(line + ", !dbg !2" if line.startswith("ret ") else line for line in body.splitlines())
    return parse_ir_state(
        f'''source_filename = "explanations.c"
define i32 @f(i32 %x) {{
entry:
{body}
}}
!1 = !DILocation(line: 2, column: 4, scope: !0)
!2 = !DILocation(line: 3, column: 1, scope: !0)
''', ordinal=ordinal, state_id=f"s{ordinal}")


def detect(old, new, kind="derived", pass_name="test"):
    a, b = state(old, 0), state(new, 1)
    step = PassStep(0, 1, kind, StepOrigin("test", pass_name=pass_name))
    correspondence = compare_states(a, b, step=step).correspondence
    return detect_optimisations(a, b, correspondence, step)


class OptimisationExplanationTests(unittest.TestCase):
    def test_strength_reduction_uses_instructions_not_pass_name(self):
        events = detect(
            "%v = mul i32 %x, 32, !dbg !1\nret i32 %v",
            "%v = shl i32 %x, 5, !dbg !1\nret i32 %v")
        event = next(e for e in events if e["name"] == "Strength reduction")
        self.assertEqual(event["change"], "Multiplication by 32 becomes a left shift by 5.")
        self.assertTrue(event["purpose"])
        self.assertEqual(event["certainty"], "detected")

    def test_unrelated_shift_is_not_strength_reduction(self):
        events = detect(
            "%v = mul i32 %x, 31, !dbg !1\nret i32 %v",
            "%v = shl i32 %x, 5, !dbg !1\nret i32 %v")
        self.assertNotIn("Strength reduction", [e["name"] for e in events])

    def test_constant_folding_requires_the_replacement_in_uses(self):
        events = detect("%v = add i32 2, 3, !dbg !1\nret i32 %v", "ret i32 5")
        self.assertIn("Constant folding", [e["name"] for e in events])
        events = detect("%v = add i32 2, 3, !dbg !1\nret i32 %v", "ret i32 6")
        self.assertNotIn("Constant folding", [e["name"] for e in events])

    def test_overflow_is_not_explained_as_simple_folding(self):
        events = detect("%v = add nsw i32 2147483647, 1, !dbg !1\nret i32 %v", "ret i32 -2147483648")
        self.assertNotIn("Constant folding", [e["name"] for e in events])

    def test_unused_pure_computation_is_dead_code(self):
        events = detect("%v = mul i32 %x, 3, !dbg !1\nret i32 %x", "ret i32 %x")
        self.assertIn("Dead-code elimination", [e["name"] for e in events])

    def test_used_computation_is_not_called_dead_just_because_absent(self):
        events = detect("%v = mul i32 %x, 3, !dbg !1\nret i32 %v", "ret i32 %x")
        self.assertNotIn("Dead-code elimination", [e["name"] for e in events])

    def test_pass_name_alone_does_not_trigger_explanation(self):
        body = "%v = add i32 %x, 1, !dbg !1\nret i32 %v"
        self.assertEqual(detect(body, body, pass_name="instcombine"), [])

    def test_independent_recompilation_is_not_an_optimisation_step(self):
        self.assertEqual(detect(
            "%v = mul i32 %x, 32, !dbg !1\nret i32 %v",
            "%v = shl i32 %x, 5, !dbg !1\nret i32 %v", kind="recompiled"), [])

    def test_curated_explanations_are_selection_scoped_and_traceable(self):
        service = QueryService()
        for example, lower, higher in (
            ("score", 0, 1), ("score", 1, 2), ("score", 0, 12),
            ("binary_search", 2, 3), ("quick_sort", 8, 9),
        ):
            with self.subTest(example=example, span=(lower, higher)):
                response = service.summary(example, lower, higher)
                self.assertTrue(response["optimisations"])
                self.assertEqual(response, service.summary(example, higher, lower))
                timeline = service._example(example).timeline
                for event in response["optimisations"]:
                    self.assertTrue(event["linkIndices"])
                    self.assertTrue(all(0 <= i < len(response["links"]) for i in event["linkIndices"]))
                    self.assertEqual(event["toOrdinal"], event["fromOrdinal"] + 1)
                    for key in ("name", "purpose", "change"):
                        self.assertTrue(event[key])
                    self.assertTrue(all(node in timeline.state(event["fromOrdinal"]).by_id
                                        for node in event["fromNodeIds"]))
                    self.assertTrue(all(node in timeline.state(event["toOrdinal"]).by_id
                                        for node in event["toNodeIds"]))
        events = service.summary("score", 0, 12)["optimisations"]
        strength = next(e for e in events if e["name"] == "Strength reduction")
        self.assertEqual((strength["fromOrdinal"], strength["toOrdinal"]), (1, 2))
        cancellation = next(e for e in events if e["name"] == "Algebraic simplification")
        self.assertEqual(cancellation["certainty"], "likely")
        self.assertEqual(service.summary("score", 1, 1)["optimisations"], [])
        self.assertEqual(service.summary("score", 12, 13)["optimisations"], [])
