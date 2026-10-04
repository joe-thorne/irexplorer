// Behavioural state/validation tests using built-in Node APIs; synthetic values only.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import { webcrypto } from 'node:crypto';
const packageFile = JSON.parse(await readFile(new URL('../src/backend/evaluation/participant-package-v2.json', import.meta.url)));
const content = packageFile.content;
const examples = JSON.parse(await readFile(new URL('../tests/data/study-validation-examples.json', import.meta.url)));
const study = await readFile(new URL('../src/frontend/study.js', import.meta.url), 'utf8');
const context = { window: {}, crypto: webcrypto };
vm.createContext(context);
vm.runInContext(await readFile(new URL('../src/frontend/study-draft.js', import.meta.url), 'utf8'), context);
const D = context.window.StudyDraft, checks = [];
function check(name, fn) { fn(); checks.push(name); }
const consent = Object.fromEntries(content.membership.consent.map(id => [id, true]));
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
  assert.equal(Object.keys(D.validate(content, 'pre', { P3: answered([8, 1]) })).join(), 'P3');
  assert.equal(Object.keys(D.validate(content, 'pre', { 'P1.other': answered('Synthetic') })).join(), 'P1.other');
});
check('Unicode limit counts code points; oversized draft can recover without truncation', () => {
  draft.post.Q14 = answered('🙂'.repeat(4001));
  assert.equal(Object.keys(D.validate(content, 'post', draft.post)).join(), 'Q14');
  assert.equal(D.decode(JSON.stringify(draft), content).post.Q14.value, draft.post.Q14.value);
  draft.post.Q14 = D.blank();
});
check('Bad versions, consent, types, progress and unknown fields cannot unlock routes', () => {
  for (const change of [d => d.studyVersion = 'live', d => d.consent.acknowledgements.C1 = false, d => d.preComplete = 'true', d => d.tasks.T1.presented = true, d => d.pre.P1 = answered(true), d => d.extra = 'x']) {
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
check('Short text input enforces supplementary-character limits in code points', () => {
  const inputContent = structuredClone(content);
  const field = inputContent.fields.find(item => item.id === 'P13');
  field.type = 'short_text'; field.presentation.control = 'input'; field.maxLength = 4;
  const atLimit = {P13: {status: 'answered', value: '🙂'.repeat(4)}};
  const overLimit = {P13: {status: 'answered', value: '🙂'.repeat(5)}};
  assert.deepEqual(Object.keys(D.validate(inputContent, 'pre', atLimit)), []);
  assert.deepEqual(Object.keys(D.validate(inputContent, 'pre', overLimit)), ['P13']);
});
check('Browser validation matches the common browser/server response examples', () => {
  for (const example of examples) {
    const answers = JSON.parse(JSON.stringify(example.answers));
    for (const answer of Object.values(answers)) if ('repeat' in answer) {
      answer.value = answer.repeat.repeat(answer.times); delete answer.repeat; delete answer.times;
    }
    assert.deepEqual(Object.keys(D.validate(content, example.section, answers, example.complete || false)).sort(),
      [...example.errorFields].sort(), example.name);
  }
});
check('Task inability and not-applicable preserve null independently from numeric answers', () => {
  for (const [stage, id, status] of [['T2','T2a','could_not_work_out'], ['T3','T3a','could_not_work_out'], ['T4','T4a','could_not_work_out'], ['T5','T5a','could_not_work_out']]) {
    assert.equal(Object.keys(D.validate(content, stage, {[id]: {status, value:null}})).length, 0);
  }
  assert.equal(Object.keys(D.validate(content, 'T2', {T2a: answered(12)})).join(), 'T2a');
  assert.equal(Object.keys(D.validate(content, 'T5', {T5a: {status:'not_applicable',value:null}})).join(), 'T5a');
});
check('Skipped/inability tasks retain partial responses and optional missing confidence', () => {
  const d = fresh(); d.p13Locked = true; d.pre.P1 = answered(1); d.preComplete = true;
  Object.assign(d.tasks.T0, {presented:true,status:'completed'});
  Object.assign(d.tasks.T1, {presented:true,status:'skipped'}); d.tasks.T1.answers.T1a = answered('Synthetic partial response');
  Object.assign(d.tasks.T2, {presented:true,status:'could_not_work_out'});
  const restored = D.decode(JSON.stringify(d),content);
  assert.equal(restored.tasks.T1.answers.T1a.value, 'Synthetic partial response');
  assert.equal(restored.tasks.T1.answers.T1b.status, 'unanswered');
  assert.equal(D.currentTask(restored), 'T3');
  assert.equal(D.tasksComplete(restored), false);
});
check('Corrupt timing, unknown outcomes, skipped T0 and out-of-order progress fail closed', () => {
  for (const change of [d=>d.tasks.T0.durationMs=-1, d=>d.tasks.T0.durationMs='3', d=>d.tasks.T0.status='skipped', d=>d.tasks.T0.presented=true,
    d=>d.tasks.T1.status='completed',d=>d.reviewReady=true,d=>d.tasks.T1.answers.T1a=answered('Premature'),d=>d.tasks.T0.extra=true]) {
    const d=fresh(); change(d); assert.throws(()=>D.decode(JSON.stringify(d),content));
  }
});
check('Task Unicode bounds retain oversized drafts; completion validates without truncation', () => {
  const d=fresh();d.p13Locked=true;
  for (const id of ['T0','T1','T2']) Object.assign(d.tasks[id], {presented:true,status:'completed'});
  d.tasks.T3.presented=true;d.tasks.T3.answers.T3a=answered('🙂'.repeat(257));
  assert.equal(Object.keys(D.validate(content,'T3',d.tasks.T3.answers)).join(),'T3a');
  assert.equal(D.decode(JSON.stringify(d),content).tasks.T3.answers.T3a.value,d.tasks.T3.answers.T3a.value);
});
check('Tasks may complete, skip, or report inability without the requested comparison', () => {
  const d=D.create(content,consent);d.pre.P1=answered(1);d.preComplete=true;d.p13Locked=true;
  Object.assign(d.tasks.T0,{presented:true,status:'completed'});
  d.tasks.T1.presented=true;d.tasks.T1.status='skipped';d.tasks.T2.presented=true;d.tasks.T2.status='could_not_work_out';
  const restored=D.decode(JSON.stringify(d),content);
  assert.equal(D.currentTask(restored),'T3');assert.equal(restored.tasks.T1.presented,true);
  assert.equal(restored.tasks.T2.durationMs,0);
  const completed = JSON.parse(JSON.stringify(d)); completed.tasks.T1.status='completed'; completed.tasks.T1.durationMs=1;
  assert.equal(D.decode(JSON.stringify(completed),content).tasks.T1.status,'completed');
  for (const change of [x=>{x.tasks.T1.presented=false;x.tasks.T1.status='completed'},
    x=>{x.tasks.T1.presented=false;x.tasks.T1.answers.T1a=answered('Not presented')}, x=>x.p13Locked=false]) {
    const bad=JSON.parse(JSON.stringify(d));change(bad);assert.throws(()=>D.decode(JSON.stringify(bad),content));
  }
});
check('v0.11 course exposure selections and historical draft identities stay distinct', () => {
  assert.equal(D.KEY, 'irexplorer.study.v0.11');
  assert.equal(Object.keys(D.validate(content,'post',{Q8:answered([1,2,3])})).length,0);
  for (const value of [1,[1,4]]) assert.equal(Object.keys(D.validate(content,'post',{Q8:answered(value)})).join(),'Q8');
  const d=D.create(content,consent);d.instrumentVersion='v0.5';d.contentVersion='v0.5-preview-1';d.studyVersion='v0.5-synthetic-1';assert.throws(()=>D.decode(JSON.stringify(d),content));
  const course=content.fields.find(f=>f.id==='P3');
  assert.equal(course.type, 'multiple');
  assert.deepEqual(course.options.map(option=>option.value), [1,2,3,4,5,6,7,8,9]);
  assert.equal(course.exclusiveValue, 8);
  assert.equal(Object.keys(D.validate(content,'pre',{P3:answered([8,1])})).join(),'P3');
  assert.equal(Object.keys(D.validate(content,'pre',{P3_other_name:answered('Synthetic course')})).join(),'P3_other_name');
  assert.equal(Object.keys(D.validate(content,'pre',{P3:answered([9]),P3_other_name:answered('Synthetic course')})).length,0);
  assert.equal(Object.keys(D.validate(content,'pre',{P3:answered([1,9])},true)).includes('P3_other_name'),true);
  assert.equal(Object.keys(D.validate(content,'pre',{P3:{status:'unanswered',value:null}})).length,0);
  assert.equal(Object.keys(D.validate(content,'pre',{P3:answered([8])})).length,0);
});
check('Timing starts only on resume, checkpoints accumulate once, repeated resume cannot double count', () => {
  let now=100;const r={durationMs:0,status:'pending',presented:true,paused:false,interrupted:false};
  const c=context.window.TaskClock(r,()=>now);now=1000;c.checkpoint();assert.equal(r.durationMs,0);
  c.resume();now=1100;c.checkpoint();c.resume();now=1200;c.checkpoint();assert.equal(r.durationMs,200);
  c.stop();now=10000;c.checkpoint();assert.equal(r.durationMs,200);
});
check('Hide/pause and refresh downtime excluded; recovered accumulation counted once', () => {
  let now=0;const r={durationMs:300,status:'pending',presented:true,paused:false,interrupted:false};
  const c=context.window.TaskClock(r,()=>now);c.resume();now=200;c.stop(true);assert.equal(r.durationMs,500);assert.equal(r.interrupted,true);
  now=50000;c.resume();now=50100;c.stop();assert.equal(r.durationMs,600);
  const recovered=JSON.parse(JSON.stringify(r));now=200000;const next=context.window.TaskClock(recovered,()=>now);next.resume();now+=50;next.stop();assert.equal(recovered.durationMs,650);
  recovered.paused=true;next.resume();now+=1000;next.checkpoint();assert.equal(recovered.durationMs,650);
});
check('Completion freezes time and cannot acquire an interruption on read-only navigation', () => {
  let now=0;const r={durationMs:0,status:'pending',presented:true,paused:false,interrupted:false};const c=context.window.TaskClock(r,()=>now);
  c.resume();now=20;c.stop();r.status='completed';c.stop(true);c.resume();now=50;c.checkpoint();assert.equal(r.durationMs,20);assert.equal(r.interrupted,false);
});
check('Stop and discard requires a separate destructive confirmation', () => {
  assert.match(study, /data-action="confirm-stop"/);
  assert.match(study, /action === 'stop'\) \{ stopConfirming = true; render\(\); return; \}/);
  assert.match(study, /action === 'confirm-stop'.*?discard\('/s);
});
// Journey messages: the compiled catalogue supplies the wording; keys and placeholders are validated.
vm.runInContext(await readFile(new URL('../src/frontend/study-messages.js', import.meta.url), 'utf8'), context);
const Messages = context.window.StudyMessages, messages = Messages.catalogue(content.messages);
const say = reference => messages.text(reference);
check('Every compiled journey message is displayed by the journey or its loading state', () => {
  assert.deepEqual(Object.keys(content.messages).filter(key => !Object.hasOwn(Messages.USED, key) && !Object.hasOwn(Messages.BOOTSTRAP, key)), []);
  for (const [key, text] of Object.entries(Messages.BOOTSTRAP)) assert.equal(text, content.messages[key], key);
});
// A closed collection's wording is participant content: only a catalogue that carries it loads.
const CLOSED = ['closed.title', 'closed.detail', 'closed.draft', 'closed.not-stored', 'actions.discard-closed'];
check('Only a catalogue carrying every closed-collection message, without placeholders, is accepted', () => {
  for (const key of CLOSED) {
    assert.equal(Messages.USED[key]?.length, 0, key);
    const missing = structuredClone(content.messages); delete missing[key];
    assert.throws(() => Messages.catalogue(missing), new RegExp(`Unsupported journey message: ${key}`));
    const placeholder = structuredClone(content.messages); placeholder[key] += ' {participantCode}';
    assert.throws(() => Messages.catalogue(placeholder), new RegExp(`Unsupported journey message: ${key}`));
  }
});
// The view branches on the served flag: closed content shows the closed screen instead of the journey.
const closedView = /function closedHtml\(\) \{[\s\S]*?\n  \}/.exec(study)?.[0] || '';
check('Study content whose submissionEnabled is missing or not a boolean is unsupported', () => {
  assert.match(study, /typeof candidate\.submissionEnabled !== 'boolean'/);
  assert.match(study, /collectionClosed = !candidate\.submissionEnabled/);
});
check('Closed collection replaces information and consent, starting no participant journey and making no participant code', () => {
  assert.match(closedView, /heading\(messageHtml\('closed\.title'\)\) \+ `<p>\$\{messageHtml\('closed\.detail'\)\}<\/p>/);
  assert.match(closedView, /<a href="#\/explore">\$\{messageHtml\('actions\.explore'\)\}<\/a>/);
  assert.doesNotMatch(closedView, /acknowledgement|participant-code|submit-responses|'actions\.start'/);
  assert.ok(study.indexOf('html = closedHtml()') > 0 && study.indexOf('html = closedHtml()') < study.indexOf("html = heading(messageHtml('information.title')) + info()"));
  assert.match(study, /if \(closedJourney\(\) && !explore && route !== '\/study'\) return go\('\/study', true\)/);
  assert.match(study, /if \(submission\.state \|\| submission\.recoveryBlocked \|\| collectionClosed\) return;/);
});
check('A closed collection offers a local draft only an explicit discard, never Submit or a journey route', () => {
  assert.match(closedView, /local \? `<p>\$\{messageHtml\('closed\.draft'\)\}<\/p>/);
  assert.match(closedView, /button\('discard-closed', 'actions\.discard-closed'\)/);
  assert.match(closedView, /discardFailed \? `<p role="alert">\$\{messageHtml\('storage\.discard-failed'\)\}<\/p>`/);
  assert.match(study, /else if \(closedJourney\(\)\) \{ discardFailed = !store\.discard\(\); if \(!discardFailed\) draft = null; render\(\); \}/);
  assert.match(study, /if \(draft && !collectionClosed\) \{ const t = draft\.tasks/);
  // Submit is offered only by the review, which an open collection alone reaches.
  assert.match(study, /button\('submit-responses', 'actions\.submit', true\)/);
});
check('A refused submission says nothing was saved and offers a discard that removes the record and the draft', () => {
  const notStored = /function notStoredHtml\(\) \{[\s\S]*?\n  \}/.exec(study)?.[0] || '';
  assert.match(notStored, /heading\(messageHtml\('closed\.title'\)\) \+ `<p role="alert">\$\{messageHtml\('closed\.not-stored'\)\}<\/p>/);
  assert.match(notStored, /messageHtml\('submission\.participant-code'/);
  assert.match(notStored, /button\('discard-closed', 'actions\.discard-closed'\)/);
  assert.doesNotMatch(notStored, /submission\.uncertain|submission\.retry|retry-submit/);
  assert.match(study, /if \(submission\.closed\) \{ if \(submission\.discardClosed\(\(\) => store\.discard\(\)\)\) \{ draft = null; go\('\/study', true\); \} else render\(\); \}/);
});
check('A catalogue missing a key or breaking a placeholder contract is rejected', () => {
  for (const change of [m => delete m['receipt.title'], m => { m['task.entry'] = 'Opens at State 0.'; }, m => { m['receipt.saved'] = 'Saved {receiptId}.'; },
    m => { m['timing.paused'] = 'Paused {'; }, m => { m['timing.paused'] = 'Paused }'; }, m => { m['task.title'] = '{taskId} {title} {0}'; }, m => { m['actions.skip'] = ''; }, m => { m['actions.skip'] = 3; }]) {
    const changed = structuredClone(content.messages); change(changed);
    assert.throws(() => Messages.catalogue(changed));
  }
  assert.throws(() => Messages.catalogue(null));
});
check('Messages interpolate declared placeholders and display prose as text', () => {
  assert.equal(messages.text('task.entry', { example: 'score' }), content.messages['task.entry'].replace('{example}', 'score'));
  assert.throws(() => messages.text('task.entry', {}));
  assert.throws(() => messages.text('no.such-key'));
  const unsafe = structuredClone(content.messages);
  unsafe['receipt.code'] = '<b>Receipt</b> {{literal}}: {receiptId}';
  const rendered = Messages.catalogue(unsafe);
  assert.equal(rendered.text('receipt.code', { receiptId: 'r<1>' }), '<b>Receipt</b> {literal}: r<1>');
  assert.equal(rendered.html('receipt.code', { receiptId: 'r<1>' }, ['receiptId']), '&lt;b&gt;Receipt&lt;/b&gt; {literal}: <code>r&lt;1&gt;</code>');
  assert.equal(messages.text('submission.uncertain', { error: { key: 'submission.no-receipt' } }),
    content.messages['submission.uncertain'].replace('{error}', content.messages['submission.no-receipt']));
});
check('Browser validation feedback uses compiled validation messages', () => {
  const errors = D.validate(content, 'pre', { P1: D.blank(), P2: answered(99), 'P1.other': answered('Synthetic'), Unknown: answered(1) }, true);
  assert.equal(say(errors.P1), content.messages['validation.required-p1']);
  assert.equal(say(errors.P2), content.messages['validation.options']);
  assert.equal(say(errors.Unknown), content.messages['validation.unknown']);
  const limit = D.validate(content, 'post', { Q14: answered('🙂'.repeat(4001)) }).Q14;
  assert.equal(say(limit), content.messages['validation.text-limit'].replace('{maxLength}', (4000).toLocaleString()));
  assert.equal(say(D.validate(content, 'pre', { P1: 'invalid' }).P1), content.messages['validation.invalid']);
  const followUp = content.fields.find(f => f.condition && f.required && content.membership.pre.includes(f.id));
  if (followUp) {
    const parent = content.fields.find(f => f.id === followUp.condition.field);
    const value = parent.type === 'multiple' ? [followUp.condition.values[0]] : followUp.condition.values[0];
    assert.equal(say(D.validate(content, 'pre', { P1: answered(1), [parent.id]: answered(value) }, true)[followUp.id]), content.messages['validation.required-followup']);
  }
});
check('Local storage failures report compiled storage messages', () => {
  let s = D.storage(content, () => { throw Error('Blocked'); }); s.read();
  assert.equal(say(s.issue), content.messages['storage.unavailable']);
  s = D.storage(content, () => ({ getItem: () => '{broken', setItem() {}, removeItem() {} })); s.read();
  assert.equal(say(s.issue), content.messages['storage.incompatible']);
  s = D.storage(content, () => ({ getItem: () => null, setItem() { throw Error('Quota'); }, removeItem() {} }));
  s.save(fresh()); assert.equal(say(s.issue), content.messages['storage.save-failed']);
  s = D.storage(content, () => ({ getItem: () => null, setItem() {}, removeItem() { throw Error('Blocked'); } }));
  s.save(fresh()); s.discard(); assert.equal(say(s.issue), content.messages['storage.discard-failed']);
  assert.equal(s.retry(fresh()), true); assert.equal(s.issue, null);
});
console.log(`${checks.length} draft/validation/timing checks passed.`);
