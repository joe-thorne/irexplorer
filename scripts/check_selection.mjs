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
