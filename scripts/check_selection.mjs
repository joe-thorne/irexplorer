// Pure selection regressions: node scripts/check_selection.mjs
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
const context = vm.createContext({});
vm.runInContext(await readFile(new URL('../src/frontend/selection.js', import.meta.url), 'utf8'), context);
const panel = (ordinal, ids, mappings = []) => ({
  ordinal, function: { blocks: [{ id: 'block' + ordinal, instructions: ids.map(id => ({ id })) }] },
  mappings: mappings.map(([instructionId, line]) => ({ instructionId, location: { file: 'test.c', line } })),
});
const left = panel(0, ['a', 'b', 'c', 'unknown'], [['a', 1], ['b', 2], ['c', 2]]);
const right = panel(1, ['x', 'y', 'z', 'other'], [['x', 1], ['y', 2], ['z', 2]]);
const summary = { links: [
  { fromNodeIds: ['a'], toNodeIds: ['x'], relation: 'same', confidence: 'exact' },
  { fromNodeIds: ['b', 'c'], toNodeIds: ['y', 'z'], relation: 'merged', confidence: 'approximate' },
  { fromNodeIds: ['unknown'], toNodeIds: ['other'], relation: 'changed', confidence: 'none' },
], items: [
  { text: 'The selected instruction remains.', linkIndices: [0], remarkIndices: [] },
  { text: 'A recorded compiler remark for the selected instruction.', linkIndices: [], remarkIndices: [0] },
  { text: 'The selected pair is merged.', linkIndices: [1], remarkIndices: [2] },
  { text: 'An unrelated structural change.', linkIndices: [2], remarkIndices: [] },
], steps: [{ fromOrdinal: 0, toOrdinal: 1, remarks: [
  { pass_name: 'instcombine', name: 'Simplified', raw: 'selected remark', location: { file: 'examples/curated/test.c', line: 1 } },
  { pass_name: 'instcombine', name: 'Unrelated', raw: 'unrecorded remark', location: { file: 'examples/curated/test.c', line: 1 } },
] }], optimisations: [
  { name: 'One optimisation', purpose: 'Test grouping.', change: 'First change.', certainty: 'detected', fromOrdinal: 0, toOrdinal: 1, fromStateId: 'before', toStateId: 'after', linkIndices: [0] },
  { name: 'One optimisation', purpose: 'Test grouping.', change: 'Second change.', certainty: 'detected', fromOrdinal: 0, toOrdinal: 1, fromStateId: 'before', toStateId: 'after', linkIndices: [0] },
]};
const trace = selection => context.buildSelectionTrace({ left, right }, summary, selection);
const ids = set => [...set].sort();
const node = (side, nodeId) => ({ kind: 'node', side, nodeId });
const source = (...lines) => ({ kind: 'source', anchors: lines.map(line => ({ file: 'test.c', line })) });
let checks = 0;
function check(name, run) { run(); checks++; console.log('PASS ' + name); }
check('Equivalent C and IR selections trace the same link and members', () => {
  const c = trace(source(1)), ir = trace(node('left', 'a'));
  assert.deepEqual(ids(c.members.left), ids(ir.members.left));
  assert.deepEqual(ids(c.members.right), ids(ir.members.right));
  assert.equal(context.traceDescription(c), context.traceDescription(ir));
});
check('Right-side selection follows the same evidence in reverse', () => {
  assert.deepEqual(ids(trace(node('right', 'x')).members.left), ['a']);
  const reversed = context.buildSelectionTrace({ left: right, right: left }, summary, node('left', 'x'));
  assert.deepEqual(ids(reversed.members.right), ['a']);
});
check('Existing grouped links retain every member', () => {
  const result = trace(node('left', 'b'));
  assert.deepEqual(ids(result.members.left), ['b', 'c']);
  assert.deepEqual(ids(result.members.right), ['y', 'z']);
  assert.equal(result.links.length, 1);
});
check('Selection evidence is render-ready across every confidence wording', () => {
  const currentTrace = {
    ...trace(source(1, 2)),
    links: [
      ...summary.links.slice(0, 2),
      { fromNodeIds: ['a'], toNodeIds: ['x'], relation: 'changed', confidence: 'plausible' },
      summary.links[2],
    ],
  };
  const evidence = context.buildComparisonEvidence(summary, currentTrace);
  assert.equal(evidence.trace, currentTrace);
  assert.deepEqual(evidence.links, currentTrace.links);
  assert.equal(JSON.stringify(evidence.relationGroups), JSON.stringify([
    { wording: 'same · exact confidence', count: 1 },
    { wording: 'merged · approximate confidence', count: 1 },
    { wording: 'changed · plausible but unconfirmed confidence', count: 1 },
    { wording: 'unresolved', count: 1 },
  ]));
});
check('Selection evidence retains only structural claims recorded for its links', () => {
  const evidence = context.buildComparisonEvidence(summary, trace(source(1)));
  assert.equal(JSON.stringify(evidence.structuralClaims), JSON.stringify([
    { text: 'The selected instruction remains.', linkIndices: [0], remarkIndices: [] },
    { text: 'A recorded compiler remark for the selected instruction.', linkIndices: [], remarkIndices: [0] },
  ]));
});
check('Selection evidence retains only recorded relevant compiler remarks with their transition', () => {
  const evidence = context.buildComparisonEvidence(summary, trace(source(1)));
  assert.equal(JSON.stringify(evidence.remarks), JSON.stringify([{
    pass_name: 'instcombine', name: 'Simplified', raw: 'selected remark',
    location: { file: 'examples/curated/test.c', line: 1 }, fromOrdinal: 0, toOrdinal: 1,
  }]));
});
check('Equivalent optimisation records group without dropping concrete changes', () => {
  const evidence = context.buildComparisonEvidence(summary, trace(source(1)));
  assert.equal(JSON.stringify(evidence.optimisationGroups), JSON.stringify([{
    name: 'One optimisation', purpose: 'Test grouping.', certainty: 'detected', fromOrdinal: 0,
    toOrdinal: 1, fromStateId: 'before', toStateId: 'after', changes: ['First change.', 'Second change.'],
  }]));
});
check('Equivalent C, IR, and CFG selections use the same evidence interface', () => {
  const singleLeft = panel(0, ['a'], [['a', 1]]);
  const singleRight = panel(1, ['x'], [['x', 1]]);
  const selections = [source(1), node('left', 'a'), node('left', 'block0')];
  const evidence = selections.map(selection => {
    const currentTrace = context.buildSelectionTrace({ left: singleLeft, right: singleRight }, summary, selection);
    const result = context.buildComparisonEvidence(summary, currentTrace);
    assert.equal(result.trace, currentTrace);
    return result;
  });
  const summaries = evidence.map(result => ({
    links: result.links,
    members: { left: ids(result.trace.members.left), right: ids(result.trace.members.right) },
  }));
  assert.equal(JSON.stringify(summaries), JSON.stringify([{
    links: [summary.links[0]], members: { left: ['a'], right: ['x'] },
  }, {
    links: [summary.links[0]], members: { left: ['a'], right: ['x'] },
  }, {
    links: [summary.links[0]], members: { left: ['a'], right: ['x'] },
  }]));
});
check('CFG selection preserves all instructions including ones without C mappings', () => {
  const result = trace(node('left', 'block0'));
  assert.deepEqual(ids(result.seeds.left), ['a', 'b', 'c', 'unknown']);
  assert.equal(result.unresolved, true);
  assert.deepEqual(ids(result.members.right), ['x', 'y', 'z']);
});
check('C ranges aggregate links without duplicate relations', () => {
  const result = trace(source(1, 2));
  assert.equal(result.links.length, 2);
  assert.deepEqual(ids(result.members.left), ['a', 'b', 'c']);
});
check('Unresolved records do not manufacture counterparts', () => {
  const result = trace(node('left', 'unknown'));
  assert.deepEqual(ids(result.members.right), []);
  assert.match(context.traceDescription(result), /unresolved/);
});
check('Plausible records retain qualified counterparts', () => {
  const result = context.buildSelectionTrace({ left, right }, { links: [
    { fromNodeIds: ['a'], toNodeIds: ['x'], relation: 'same', confidence: 'plausible' },
  ] }, node('left', 'a'));
  assert.deepEqual(ids(result.members.right), ['x']);
  assert.equal(result.unresolved, false);
  assert.match(context.traceDescription(result), /same \(plausible confidence\)/);
});
check('Missing source locations do not prevent an IR trace', () => {
  const result = context.buildSelectionTrace(
    { left: panel(0, ['a']), right }, summary, node('left', 'a'));
  assert.deepEqual(ids(result.members.right), ['x']);
  assert.equal(result.anchors[0].line, 1);
});
check('Unmapped C selections do not assert removal', () => {
  const result = trace(source(99));
  assert.equal(result.unresolved, true);
  assert.match(context.traceDescription(result), /does not establish removal/);
});
check('Same-state block selection maps exact instruction membership', () => {
  const result = context.buildSelectionTrace({ left, right: left }, { links: [] }, node('left', 'block0'));
  assert.deepEqual(ids(result.members.left), ids(result.members.right));
  assert.equal(result.unresolved, false);
});
check('Known removal and missing coverage remain distinct', () => {
  const result = context.buildSelectionTrace({ left, right }, { links: [
    { fromNodeIds: ['a'], toNodeIds: [], relation: 'removed', confidence: 'exact' },
  ] }, node('left', 'a'));
  assert.equal(result.unresolved, false);
  assert.match(context.traceDescription(result), /removed/);
  assert.equal(context.buildSelectionTrace({ left, right }, { links: [] }, node('left', 'a')).missing, 1);
});
check('Source records and links cannot leak into a different function', () => {
  const result = context.buildSelectionTrace({ left: panel(0, ['a'], [['not-in-function', 3]]), right }, summary, source(3));
  assert.deepEqual(ids(result.members.left), []);
});
console.log(checks + ' selection checks passed.');
