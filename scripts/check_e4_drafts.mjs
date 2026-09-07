// Behavioural state/validation tests using built-in Node APIs; synthetic values only.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import vm from 'node:vm';
import { webcrypto } from 'node:crypto';
const content = JSON.parse(await readFile(new URL('../src/backend/evaluation/participant-content.json', import.meta.url)));
const context = { window: {}, crypto: webcrypto };
vm.createContext(context);
vm.runInContext(await readFile(new URL('../src/frontend/study-draft.js', import.meta.url), 'utf8'), context);
const D = context.window.StudyDraft, checks = [];
function check(name, fn) { fn(); checks.push(name); }
const consent = Object.fromEntries(content.fields.filter(f => f.id.startsWith('C')).map(f => [f.id, true]));
const draft = D.create(content, consent), answered = value => ({ status: 'answered', value });
check('Consent is mandatory before identifiers/draft creation', () => assert.throws(() => D.create(content, {})));
check('Missing P1 blocks completion; other pre/post items optional', () => {
  assert.equal(Object.keys(D.validate(content, 'pre', draft.pre, true)).join(), 'P1');
  assert.equal(Object.keys(D.validate(content, 'post', draft.post, true)).length, 0);
});
check('Unanswered and not applicable stay distinct from neutral', () => {
  assert.equal(Object.keys(D.validate(content, 'post', { Q1: { status: 'not_applicable', value: null } })).length, 0);
  assert.equal(Object.keys(D.validate(content, 'post', { Q19: { status: 'not_applicable', value: null } })).join(), 'Q19');
  assert.equal(Object.keys(D.validate(content, 'pre', { P2: answered(6) })).join(), 'P2');
});
check('Mutually exclusive and conditional values rejected when inconsistent', () => {
  assert.equal(Object.keys(D.validate(content, 'pre', { P3: answered([6, 1]) })).join(), 'P3');
  assert.equal(Object.keys(D.validate(content, 'pre', { 'P1.other': answered('Synthetic') })).join(), 'P1.other');
});
check('Unicode limit counts code points; oversized draft can recover without truncation', () => {
  draft.post.Q14 = answered('🙂'.repeat(4001));
  assert.equal(Object.keys(D.validate(content, 'post', draft.post)).join(), 'Q14');
  assert.equal(D.decode(JSON.stringify(draft), content).post.Q14.value, draft.post.Q14.value);
  draft.post.Q14 = D.blank();
});
check('Bad versions, consent, types, progress and unknown fields cannot unlock routes', () => {
  for (const change of [d => d.studyVersion = 'live', d => d.consent.acknowledgements.C1 = false, d => d.preComplete = 'true', d => d.previewTaskComplete = true, d => d.pre.P1 = answered(true), d => d.extra = 'x']) {
    const d = JSON.parse(JSON.stringify(draft)); change(d); assert.throws(() => D.decode(JSON.stringify(d), content));
  }
});
let values = new Map(), writes = 0;
const storage = { getItem: key => values.get(key) ?? null, setItem: (key, value) => { writes++; values.set(key, value); }, removeItem: key => values.delete(key) };
let store = D.storage(content, () => storage);
check('Reading empty storage creates no data', () => { assert.equal(store.read(), null); assert.equal(writes, 0); });
check('Draft recovery preserves identifier and answer/lock state', () => {
  draft.pre.P1 = answered(1); draft.preComplete = true; draft.p13Locked = true;
  store.save(draft); const restored = store.read();
  assert.equal(restored.participantCode, draft.participantCode); assert.equal(restored.p13Locked, true);
});
check('Incomplete background correction preserves a previously locked P13', () => {
  const correction = JSON.parse(JSON.stringify(draft)); correction.preComplete = false; correction.pre.P1 = D.blank();
  assert.equal(D.decode(JSON.stringify(correction), content).p13Locked, true);
});
check('Quota failure removes old snapshot and requires explicit memory continuation', () => {
  const broken = { ...storage, setItem() { throw Error('Quota'); } };
  store = D.storage(content, () => broken); store.read();
  assert.equal(store.save(draft), false); assert.equal(store.mode, 'blocked'); assert.equal(values.size, 0);
  assert.equal(store.memory(), true); assert.equal(store.save(draft), true); assert.equal(values.size, 0);
});
check('Discard failure cannot claim that saved data was removed', () => {
  store = D.storage(content, () => ({ ...storage, removeItem() { throw Error('Blocked'); } }));
  store.save(draft); assert.equal(store.discard(), false); assert.equal(store.stale, true);
});
check('Damaged/older draft requires explicit discard', () => {
  storage.setItem(D.KEY, '{broken'); store = D.storage(content, () => storage);
  assert.equal(store.read(), null); assert.equal(store.mode, 'invalid'); assert.equal(store.memory(), false);
  assert.equal(store.discard(), true); assert.equal(values.size, 0);
});
await writeFile(new URL('../docs/evaluation-captures/e4-draft-checks.json', import.meta.url), JSON.stringify({ checks, count: checks.length }, null, 2) + '\n');
console.log(`${checks.length} draft/validation checks passed.`);
