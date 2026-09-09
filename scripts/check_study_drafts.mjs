// Behavioural state/validation tests using built-in Node APIs; synthetic values only.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
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
  for (const change of [d => d.studyVersion = 'live', d => d.consent.acknowledgements.C1 = false, d => d.preComplete = 'true', d => d.tasks.T1.started = true, d => d.pre.P1 = answered(true), d => d.extra = 'x']) {
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
// E5 task-state and monotonic-clock regressions.
vm.runInContext(await readFile(new URL('../src/frontend/task-clock.js', import.meta.url), 'utf8'), context);
const fresh = () => D.create(content, consent);
check('Fixed task inventory: T0 has no fields; T5/T6 have no invented confidence', () => {
  const d = fresh();
  assert.equal(Object.keys(d.tasks).join(), 'T0,T1,T2,T3,T4,T5,T6');
  assert.equal(Object.keys(d.tasks.T0.answers).length, 0);
  assert.equal(D.fieldsFor(content, 'T5').map(f => f.id).join(), 'T5a,T5b,T5c');
  assert.equal(D.fieldsFor(content, 'T6').some(f => f.scale === 'confidence'), false);
});
check('Task inability and not-applicable preserve null independently from numeric answers', () => {
  for (const [stage, id, status] of [['T2','T2a','could_not_work_out'], ['T3','T3a','could_not_work_out'], ['T4','T4a','could_not_work_out'], ['T4','T4c','not_applicable']]) {
    assert.equal(Object.keys(D.validate(content, stage, {[id]: {status, value:null}})).length, 0);
  }
  assert.equal(Object.keys(D.validate(content, 'T2', {T2a: answered(11)})).join(), 'T2a');
  assert.equal(Object.keys(D.validate(content, 'T5', {T5a: {status:'not_applicable',value:null}})).join(), 'T5a');
});
check('Skipped/inability tasks retain partial responses and optional missing confidence', () => {
  const d = fresh(); d.p13Locked = true; d.pre.P1 = answered(1); d.preComplete = true;
  Object.assign(d.tasks.T0, {started:true,status:'completed'});
  Object.assign(d.tasks.T1, {started:true,status:'skipped'}); d.tasks.T1.answers.T1a = answered('Synthetic partial response');
  Object.assign(d.tasks.T2, {started:true,status:'could_not_work_out'});
  const restored = D.decode(JSON.stringify(d),content);
  assert.equal(restored.tasks.T1.answers.T1a.value, 'Synthetic partial response');
  assert.equal(restored.tasks.T1.answers.T1b.status, 'unanswered');
  assert.equal(D.currentTask(restored), 'T3');
  assert.equal(D.tasksComplete(restored), false);
});
check('Corrupt timing, unknown outcomes, skipped T0 and out-of-order progress fail closed', () => {
  for (const change of [d=>d.tasks.T0.durationMs=-1, d=>d.tasks.T0.durationMs='3', d=>d.tasks.T0.status='skipped', d=>d.tasks.T0.started=true,
    d=>d.tasks.T1.status='completed',d=>d.reviewReady=true,d=>d.tasks.T1.answers.T1a=answered('Premature'),d=>d.tasks.T0.extra=true]) {
    const d=fresh(); change(d); assert.throws(()=>D.decode(JSON.stringify(d),content));
  }
});
check('Task Unicode bounds retain oversized drafts; completion validates without truncation', () => {
  const d=fresh();d.p13Locked=true;
  for (const id of ['T0','T1','T2']) Object.assign(d.tasks[id], {started:true,status:'completed'});
  d.tasks.T3.started=true;d.tasks.T3.answers.T3a=answered('🙂'.repeat(257));
  assert.equal(Object.keys(D.validate(content,'T3',d.tasks.T3.answers)).join(),'T3a');
  assert.equal(D.decode(JSON.stringify(d),content).tasks.T3.answers.T3a.value,d.tasks.T3.answers.T3a.value);
});
check('Timing starts only on resume, checkpoints accumulate once, repeated resume cannot double count', () => {
  let now=100;const r={durationMs:0,status:'pending',started:true,paused:false,interrupted:false};
  const c=context.window.TaskClock(r,()=>now);now=1000;c.checkpoint();assert.equal(r.durationMs,0);
  c.resume();now=1100;c.checkpoint();c.resume();now=1200;c.checkpoint();assert.equal(r.durationMs,200);
  c.stop();now=10000;c.checkpoint();assert.equal(r.durationMs,200);
});
check('Hide/pause and refresh downtime excluded; recovered accumulation counted once', () => {
  let now=0;const r={durationMs:300,status:'pending',started:true,paused:false,interrupted:false};
  const c=context.window.TaskClock(r,()=>now);c.resume();now=200;c.stop(true);assert.equal(r.durationMs,500);assert.equal(r.interrupted,true);
  now=50000;c.resume();now=50100;c.stop();assert.equal(r.durationMs,600);
  const recovered=JSON.parse(JSON.stringify(r));now=200000;const next=context.window.TaskClock(recovered,()=>now);next.resume();now+=50;next.stop();assert.equal(recovered.durationMs,650);
  recovered.paused=true;next.resume();now+=1000;next.checkpoint();assert.equal(recovered.durationMs,650);
});
check('Completion freezes time and cannot acquire an interruption on read-only navigation', () => {
  let now=0;const r={durationMs:0,status:'pending',started:true,paused:false,interrupted:false};const c=context.window.TaskClock(r,()=>now);
  c.resume();now=20;c.stop();r.status='completed';c.stop(true);c.resume();now=50;c.checkpoint();assert.equal(r.durationMs,20);assert.equal(r.interrupted,false);
});
console.log(`${checks.length} draft/validation/timing checks passed.`);
