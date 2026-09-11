import unittest

from src.backend.analysis import compare_states, compare_timeline_step, compose_correspondences
from src.backend.ingest import parse_ir_state, load_prebaked_curated_timeline
from src.backend.api import QueryService


def state(body, ordinal, *, column=4, function="f"):
    return parse_ir_state(
        f'''source_filename = "groups.c"
define i32 @{function}(i32 %x, i32 %y) {{
entry:
{body}
}}
!1 = !DILocation(line: 5, column: {column}, scope: !0)
!2 = !DILocation(line: 6, column: 3, scope: !0)
''', ordinal=ordinal, state_id=f"s{ordinal}")


SINGLE = """  %result = mul i32 %x, 3, !dbg !1
  ret i32 %result, !dbg !2"""
CHAIN = """  %shift = shl i32 %x, 1, !dbg !1
  %result = add i32 %shift, %x, !dbg !1
  ret i32 %result, !dbg !2"""


def grouped(result):
    return [link for link in result.correspondence.links
            if link.relation in {"split", "merged"}]


class InstructionGroupTests(unittest.TestCase):
    def test_split_and_merge_keep_all_members_and_validate_coverage(self):
        for before, after, relation, sizes in (
            (SINGLE, CHAIN, "split", (1, 2)), (CHAIN, SINGLE, "merged", (2, 1))
        ):
            with self.subTest(relation=relation):
                a, b = state(before, 0), state(after, 1)
                result = compare_states(a, b)
                result.correspondence.validate(a, b)
                links = grouped(result)
                self.assertEqual(len(links), 1)
                link = links[0]
                self.assertEqual(link.relation, relation)
                self.assertEqual((len(link.from_node_ids), len(link.to_node_ids)), sizes)
                self.assertEqual(link.confidence, "approximate")
                self.assertIn("result-use", link.evidence)
                self.assertTrue(any(relation in item.text for item in result.summary.items))
                self.assertEqual(result, compare_states(a, b))

    def test_rejects_same_source_without_connected_value_flow(self):
        disconnected = CHAIN.replace("add i32 %shift, %x", "add i32 %x, 2")
        self.assertFalse(grouped(compare_states(state(SINGLE, 0), state(disconnected, 1))))

    def test_rejects_different_external_inputs(self):
        self.assertFalse(grouped(compare_states(
            state(SINGLE, 0), state(CHAIN.replace("%x", "%y"), 1))))

    def test_rejects_different_result_use(self):
        changed_use = CHAIN.replace("ret i32 %result", "%use = sub i32 4, %result\n  ret i32 %use")
        self.assertFalse(grouped(compare_states(state(SINGLE, 0), state(changed_use, 1))))

    def test_requires_precise_same_source_and_function(self):
        for changes in ({"column": 0}, {"column": 8}, {"function": "g"}):
            with self.subTest(changes=changes):
                self.assertFalse(grouped(compare_states(
                    state(SINGLE, 0), state(CHAIN, 1, **changes))))

    def test_does_not_group_through_memory_operations(self):
        memory = """  %shift = load i32, ptr %x, !dbg !1
  %result = add i32 %shift, %x, !dbg !1
  ret i32 %result, !dbg !2"""
        self.assertFalse(grouped(compare_states(state(SINGLE, 0), state(memory, 1))))

    def test_requires_a_surviving_user(self):
        self.assertFalse(grouped(compare_states(
            state(SINGLE.replace("ret i32 %result", "ret i32 0"), 0),
            state(CHAIN.replace("ret i32 %result", "ret i32 0"), 1))))

    def test_does_not_infer_arbitrary_many_to_many_groups(self):
        longer = CHAIN.replace("  ret", "  %extra = add i32 %result, 1, !dbg !1\n  ret").replace(
            "ret i32 %result", "ret i32 %extra")
        self.assertFalse(grouped(compare_states(state(CHAIN, 0), state(longer, 1))))

    def test_groups_compose_without_claiming_exact_equivalence(self):
        a, b, c = state(SINGLE, 0), state(CHAIN, 1), state(SINGLE, 2)
        first, second = compare_states(a, b).correspondence, compare_states(b, c).correspondence
        composed = compose_correspondences(first, second, a, b, c)
        composed.validate(a, c)
        link = next(link for link in composed.links if link.confidence == "approximate")
        self.assertEqual(len(link.from_node_ids), 1)
        self.assertEqual(len(link.to_node_ids), 1)

    def test_curated_indvars_merge_and_conservative_anchor(self):
        timeline = load_prebaked_curated_timeline("quick_sort")
        links = grouped(compare_timeline_step(timeline, 8))
        self.assertEqual(len(links), 1)
        self.assertEqual((len(links[0].from_node_ids), len(links[0].to_node_ids)), (2, 1))
        self.assertEqual(
            {timeline.state(8).by_id[node].attributes["opcode"] for node in links[0].from_node_ids},
            {"sext", "getelementptr"})
        self.assertFalse(grouped(compare_timeline_step(timeline, 12)))


    def test_baked_group_is_queryable_in_both_directions(self):
        service = QueryService()
        summary = service.summary("quick_sort", 8, 9)
        group = next(link for link in summary["links"] if link["relation"] == "merged")
        for node in group["fromNodeIds"]:
            result = service.counterparts("quick_sort", 8, node, 9)
            self.assertEqual([n["id"] for n in result["counterparts"]], group["toNodeIds"])
        reverse = service.counterparts("quick_sort", 9, group["toNodeIds"][0], 8)
        self.assertEqual([n["id"] for n in reverse["counterparts"]], group["fromNodeIds"])

    def test_consumed_group_does_not_upgrade_other_ambiguity(self):
        timeline = load_prebaked_curated_timeline("quick_sort")
        result = compare_timeline_step(timeline, 8)
        added_extensions = [
            link for link in result.correspondence.links
            if link.relation == "added" and any(
                timeline.state(9).by_id[node].attributes.get("opcode") == "sext"
                for node in link.to_node_ids)
        ]
        self.assertTrue(added_extensions)
        self.assertTrue(all(link.confidence == "none" for link in added_extensions))


class MinMaxRewriteTests(unittest.TestCase):
    pair = """  %cmp = icmp sgt i32 %x, %y
  %result = select i1 %cmp, i32 %y, i32 %x
  ret i32 %result"""
    call = """  %result = call i32 @llvm.smin.i32(i32 %x, i32 %y)
  ret i32 %result"""

    def test_predicates_operand_orders_and_reverse_direction(self):
        for sign in ('s', 'u'):
            for predicate in ('gt', 'ge', 'lt', 'le'):
                for swapped in (False, True):
                    pair = self.pair.replace('sgt', sign + predicate)
                    if swapped:
                        pair = pair.replace('i32 %y, i32 %x', 'i32 %x, i32 %y')
                    operation = sign + ('max' if (predicate[0] == 'g') == swapped else 'min')
                    call = self.call.replace('smin', operation)
                    for before, after, relation in ((pair, call, 'merged'), (call, pair, 'split')):
                        with self.subTest(operation=operation, predicate=predicate, swapped=swapped, relation=relation):
                            a, b = state(before, 0), state(after, 1)
                            result = compare_states(a, b)
                            result.correspondence.validate(a, b)
                            self.assertEqual([link.relation for link in grouped(result)], [relation])

    def test_rejects_near_misses(self):
        for pair, call in (
            (self.pair, self.call.replace('smin', 'smax')),
            (self.pair, self.call.replace('smin', 'umin')),
            (self.pair, self.call.replace('i32 %y)', 'i32 7)')),
            (self.pair, self.call.replace('@llvm.smin.i32', '@ordinary')),
            (self.pair.replace('i32 %y, i32 %x', 'i32 7, i32 %x'), self.call),
            (self.pair.replace('  ret', '  %other = select i1 %cmp, i32 %x, i32 %y\n  ret'), self.call),
            (self.pair, self.call.replace('ret i32 %result', '%use = add i32 %result, 1\n  ret i32 %use')),
            (self.pair, self.call.replace('smin.i32', 'smin.i64')),
        ):
            with self.subTest(pair=pair, call=call):
                self.assertFalse(grouped(compare_states(state(pair, 0), state(call, 1))))

    def test_score_cleanup_links_both_original_instructions(self):
        timeline = load_prebaked_curated_timeline('score')
        result = compare_timeline_step(timeline, 4)
        links = grouped(result)
        self.assertEqual(len(links), 1)
        self.assertEqual([timeline.state(4).by_id[node].attributes['opcode']
                          for node in links[0].from_node_ids], ['icmp', 'select'])
        self.assertEqual([timeline.state(5).by_id[node].attributes['opcode']
                          for node in links[0].to_node_ids], ['call'])

    def test_baked_score_counterparts_in_both_directions(self):
        service = QueryService()
        group = next(link for link in service.summary('score', 4, 5)['links']
                     if link['relation'] == 'merged')
        reverse = service.counterparts('score', 5, group['toNodeIds'][0], 4)
        self.assertEqual([node['id'] for node in reverse['counterparts']], group['fromNodeIds'])
        for node in group['fromNodeIds']:
            forward = service.counterparts('score', 4, node, 5)
            self.assertEqual([item['id'] for item in forward['counterparts']], group['toNodeIds'])
