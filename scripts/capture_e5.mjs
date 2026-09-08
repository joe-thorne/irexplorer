// E5 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9227.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'study-draft.js', 'source.js', 'comparison.js', 'task-clock.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9227/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9227.');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let id = 0;
const pending = new Map(), errors = [], requests = [], checks = [];
ws.addEventListener('message', ({ data }) => {
  const m = JSON.parse(data);
  if (m.method === 'Network.requestWillBeSent') requests.push({method: m.params.request.method, url: m.params.request.url});
  if (m.method === 'Runtime.exceptionThrown') errors.push(m.params.exceptionDetails);
  if (pending.has(m.id)) { const [resolve, reject] = pending.get(m.id); pending.delete(m.id); m.error ? reject(m.error) : resolve(m.result); }
});
function send(method, params = {}) { return new Promise((resolve, reject) => { const n = ++id; pending.set(n, [resolve, reject]); ws.send(JSON.stringify({ id: n, method, params })); }); }
async function evaluate(expression) {
  const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails));
  return r.result.value;
}
async function until(expression) {
  for (let n = 0; n < 100; n++) { if (await evaluate(expression)) return; await new Promise(r => setTimeout(r, 100)); }
  throw new Error(`Timed out: ${expression}`);
}
async function select(selector, value) {
  await evaluate(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e.value = ${JSON.stringify(value)}; e.dispatchEvent(new Event('change', { bubbles: true })); })()`);
}
async function viewport(width, height) { await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false }); }
async function capture(name, full = false) {
  await evaluate('document.activeElement.blur(); window.scrollTo(0, 0)');
  const params = { format: 'png', captureBeyondViewport: full };
  if (full) { const { cssContentSize: s } = await send('Page.getLayoutMetrics'); params.clip = { x: 0, y: 0, width: s.width, height: s.height, scale: 1 }; }
  const { data } = await send('Page.captureScreenshot', params);
  await writeFile(new URL(name, root), Buffer.from(data, 'base64'));
}
async function check(name, expression) {
  const result = await evaluate(expression);
  if (!result) throw new Error(`Failed: ${name}`);
  checks.push(name);
}
async function click(selector) { await evaluate(`document.querySelector(${JSON.stringify(selector)}).click()`); }
async function route(path) {
  await evaluate(`location.hash = ${JSON.stringify(path)}`);
}
async function screen(title) {
  await until(`document.querySelector('#route-heading')?.textContent === ${JSON.stringify(title)}`);
  await check(`Focus: ${title}`, `document.activeElement.id === 'route-heading'`);
}
async function navigate(path) {
  const stamp = Date.now();
  await send('Page.navigate', {url: `http://127.0.0.1:8000/?e5=${stamp}#${path}`});
  await until(`location.search === '?e5=${stamp}' && document.readyState === 'complete' && document.querySelector('#preview-controls')?.hidden === false`);
}
async function key(key, code, n, text) {
  await send('Input.dispatchKeyEvent', {type:'keyDown',key,code,windowsVirtualKeyCode:n,...(text ? {text} : {})});
  await send('Input.dispatchKeyEvent', {type:'keyUp',key,code,windowsVirtualKeyCode:n});
}
async function choose(name, value) { await click(`input[name="${name}"][value="${value}"]`); }
async function fill(name, value) { await evaluate(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(value)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`); }
async function submit() { await evaluate(`document.querySelector('#survey-form').requestSubmit()`); }
async function consent() { for (let i = 1; i <= 6; i++) await click('#C' + i); await click('[data-action="start"]'); await screen('Pre-survey'); }
const stored = `JSON.parse(sessionStorage.getItem('irexplorer.study.e4'))`;
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
async function task(id) {
  await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}' && !document.querySelector('.task-inputs').disabled`);
  await check(`${id} prompt ready with route focus`, `document.activeElement.id === 'route-heading' && location.hash === '#/study/tasks/${id}'`);
}
async function setup(left, right, lview='ir', rview='ir', example) {
  await check(`Setup ${example}: ${left}/${right} ${lview}/${rview}`, `document.querySelector('#example-select').value === '${example}' && document.querySelector('#left-state').value === '${left}' && document.querySelector('#right-state').value === '${right}' && document.querySelector('#left-view').value === '${lview}' && document.querySelector('#right-view').value === '${rview}' && window.StudyWorkspace.ready`);
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  const version = await send('Browser.getVersion');
  await send('Page.setWebLifecycleState', {state:'active'});
  await send('Emulation.setFocusEmulationEnabled', {enabled:true});
  await viewport(1440, 1100); await navigate('/explore');
  await evaluate('sessionStorage.clear(); localStorage.clear()'); await navigate('/study/tasks/T4'); await screen('Information and consent');
  await check('No consent bypass, pre-consent storage or identifier', `sessionStorage.length === 0 && localStorage.length === 0 && !document.querySelector('.participant-code')`);
  await consent(); await submit();
  await check('Required P1 still prevents exposure', `location.hash === '#/study/pre' && !${stored}.p13Locked`);
  await choose('P1', 1); await fill('P13','Synthetic pre-exposure expectation'); await submit(); await task('T0');
  await setup(0,1,'ir','ir','score');
  await check('T0 locks P13, has no responses, and starts only with workspace ready', `${stored}.p13Locked && ${stored}.tasks.T0.started && Object.keys(${stored}.tasks.T0.answers).length === 0 && document.querySelectorAll('[data-field]').length === 0 && !document.querySelector('[data-action="skip-task"]')`);
  await check('Canonical source is visible; setup never selects a node', `document.querySelector('#source-lines button') && !document.querySelector('.ir-line.selected, .cfg-node.selected')`);
  await capture('e5-t0-desktop.png');
  await select('#right-view','cfg'); await until('window.StudyWorkspace.ready');
  await select('#right-view','ir'); await until('window.StudyWorkspace.ready');
  await wait(1100); await submit(); await task('T1'); await setup(0,12,'ir','ir','score');
  await check('T0 completion freezes duration without a false interruption', `${stored}.tasks.T0.status === 'completed' && ${stored}.tasks.T0.durationMs > 1000 && !${stored}.tasks.T0.interrupted`);
  await fill('T1a','Synthetic difference one\nSynthetic difference two <script>window.taskLeak=true</script>'); await choose('T1b',3);
  await check('Original T1 response/confidence inventory; no manual T1c', `[...document.querySelectorAll('[data-field]')].map(e=>e.dataset.field).join() === 'T1a,T1b' && ${stored}.tasks.T1.answers.T1b.value === 3`);
  await select('#right-state','13'); await until('window.StudyWorkspace.ready');
  await check('Answers survive state changes and separate O3 remains reachable', `${stored}.tasks.T1.answers.T1a.value.includes('Synthetic difference') && document.querySelector('textarea[name="T1a"]').value.includes('<script>') && document.querySelector('#right-state-label').textContent.includes('Separately compiled') && !window.taskLeak`);
  await click('[data-action="task-setup"]'); await until('window.StudyWorkspace.ready && document.querySelector("#right-state").value === "12"');
  await check('Reopening setup preserves answers and does not flag normal state changes as interruptions', `${stored}.tasks.T1.answers.T1b.value === 3 && !${stored}.tasks.T1.interrupted`);
  await wait(1100); await click('[data-action="pause-task"]');
  const paused = await evaluate(`${stored}.tasks.T1.durationMs`);
  await wait(1200);
  await check('Explicit pause freezes time and response controls', `${stored}.tasks.T1.durationMs === ${paused} && ${stored}.tasks.T1.paused && document.querySelector('.task-inputs').disabled`);
  await send('Page.reload'); await until(`document.querySelector('#task-timing')?.textContent.startsWith('Paused.')`);
  await check('Refresh retains pause and prior accumulation once', `${stored}.tasks.T1.durationMs === ${paused} && ${stored}.tasks.T1.interrupted && document.querySelector('textarea[name="T1a"]').value.includes('Synthetic difference')`);
  await click('[data-action="pause-task"]'); await wait(1100);
  await check('Resume adds active time to prior accumulation', `${stored}.tasks.T1.durationMs > ${paused} && ${stored}.tasks.T1.durationMs < ${paused + 2500}`);
  // The headless browser's lifecycle transition dispatches its real hidden visibility event.
  await send('Emulation.setFocusEmulationEnabled', {enabled:false});
  await send('Page.setWebLifecycleState', {state:'frozen'});
  await check('Browser lifecycle freeze makes the document hidden', 'document.hidden');
  const hidden = await evaluate(`${stored}.tasks.T1.durationMs`);
  await wait(1200);
  await check('Hidden tab time excluded', `${stored}.tasks.T1.durationMs === ${hidden}`);
  await send('Page.setWebLifecycleState',{state:'active'}); await send('Page.bringToFront'); await send('Emulation.setFocusEmulationEnabled',{enabled:true});
  await until('!document.hidden'); await wait(1100);
  await check('Visible resume adds one segment', `${stored}.tasks.T1.durationMs > ${hidden} && ${stored}.tasks.T1.durationMs < ${hidden+2600}`);
  await click('[data-action="pause-task"]');
  const beforeRefresh = await evaluate(`${stored}.tasks.T1.durationMs`);
  await click('[data-action="pause-task"]'); await send('Page.reload'); await task('T1'); await click('[data-action="pause-task"]');
  await check('Active refresh retains answers and excludes downtime without doubling time', `${stored}.tasks.T1.durationMs >= ${beforeRefresh} && ${stored}.tasks.T1.durationMs < ${beforeRefresh+1600} && ${stored}.tasks.T1.answers.T1b.value === 3`);
  await click('[data-action="pause-task"]');
  await route('/study/tasks/T6'); await task('T1');
  await check('Future task deep link gated to earliest unfinished task', `location.hash === '#/study/tasks/T1'`);
  await route('/study/pre'); await screen('Pre-survey'); await click('[data-action="edit-pre"]'); await screen('Pre-survey');
  await check('Background corrections available, P13 locked at real T0 boundary', `document.querySelector('textarea[name="P13"]').readOnly && !document.querySelector('input[name="P1"]').disabled`);
  await click('[data-clear="P1"]'); await send('Page.reload'); await screen('Pre-survey');
  await check('Incomplete background correction recovers task responses and duration', `${stored}.tasks.T1.answers.T1b.value === 3 && ${stored}.p13Locked && !${stored}.preComplete`);
  await route('/study/tasks/T2'); await screen('Pre-survey'); await choose('P1',4); await submit(); await task('T1');
  await capture('e5-t1-desktop.png');
  await submit(); await task('T2'); await setup(0,0,'ir','ir','score');
  const frozenT1 = await evaluate(`${stored}.tasks.T1.durationMs`);
  await check('T2 starts at beginning, no selected line or preselected answer', `document.querySelectorAll('input[name="T2a"]:checked').length === 0 && !document.querySelector('.ir-line.selected, .cfg-node.selected') && document.querySelectorAll('input[name="T2a"]').length === 11`);
  await choose('T2a',11); await fill('T2b','Synthetic inability explanation');
  await check('T2 explicit inability is null, not rating or pass code', `${stored}.tasks.T2.answers.T2a.status === 'could_not_work_out' && ${stored}.tasks.T2.answers.T2a.value === null`);
  await viewport(390,844); await route('/study/tasks/T1'); await until(`document.querySelector('#survey-form')?.dataset.stage === 'T1'`); await route('/study/tasks/T2'); await task('T2'); await capture('e5-t2-narrow.png');
  await check('Narrow task instructions and responses expand independently', `!document.querySelector('#task-instructions').open && !document.querySelector('.task-responses').open`);
  await check('390px task screen has bounded page width', 'document.documentElement.scrollWidth <= innerWidth');
  await click('a[href="#task-responses"]');
  await check('Response jump reveals its disclosure and preserves route/context', `document.activeElement.id === 'task-responses' && document.querySelector('.task-responses').open && location.hash === '#/study/tasks/T2'`);
  await click('a[href="#workspace-shell"]');
  await check('Workspace jump retains task hash and focuses workspace', `document.activeElement.id === 'workspace-shell' && location.hash === '#/study/tasks/T2'`);
  await evaluate(`document.querySelector('a[href="#task-responses"]').focus()`); await key('Enter','Enter',13,'\r');
  await check('Native Enter returns keyboard focus to task responses', `document.activeElement.id === 'task-responses'`);
  await evaluate(`document.querySelector('#task-responses').scrollIntoView({block:'start'})`);
  await writeFile(new URL('e5-t2-narrow-responses.png',root),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
  await viewport(1440,1100); await route('/study/tasks/T1'); await until(`document.querySelector('#survey-form')?.dataset.stage === 'T1'`);
  await check('Completed task revisits are read-only and retain escaped text', `document.querySelector('.task-inputs').disabled && document.querySelector('textarea[name="T1a"]').readOnly && document.querySelector('input[name="T1b"]:checked').value === '3' && !window.taskLeak`);
  await fill('T1a','Attempted late replacement'); await wait(1100);
  await check('Completed answers and time cannot be changed by synthetic input or revisit', `${stored}.tasks.T1.answers.T1a.value.startsWith('Synthetic difference') && ${stored}.tasks.T1.durationMs === ${frozenT1}`);
  await route('/study/tasks/T2'); await task('T2');
  await check('Unfinished T2 answers survive leaving, returning and setup', `${stored}.tasks.T2.answers.T2a.status === 'could_not_work_out' && document.querySelector('textarea[name="T2b"]').value === 'Synthetic inability explanation'`);
  await click('[data-action="unable-task"]'); await task('T3'); await setup(3,3,'ir','cfg','binary_search');
  await check('Task inability outcome preserves partial fields separately', `${stored}.tasks.T2.status === 'could_not_work_out' && ${stored}.tasks.T2.answers.T2c.status === 'unanswered'`);
  await click('input[data-inability]');
  await check('T3a offers original item-level inability without a guessed block', `${stored}.tasks.T3.answers.T3a.status === 'could_not_work_out'`);
  await fill('T3a','🙂'.repeat(257)); await submit();
  await check('Short text technical bound validated inline without truncation', `location.hash === '#/study/tasks/T3' && [...${stored}.tasks.T3.answers.T3a.value].length === 257 && document.activeElement.name === 'T3a' && document.querySelector('#error-T3a').textContent.includes('256')`);
  await fill('T3a','Synthetic block'); await fill('T3b','Synthetic partial graph observation');
  await capture('e5-t3-desktop.png');
  await click('[data-action="skip-task"]'); await task('T4'); await setup(6,7,'cfg','cfg','binary_search');
  await check('Skip locks task and retains partial response; missing confidence stays unanswered', `${stored}.tasks.T3.status === 'skipped' && ${stored}.tasks.T3.answers.T3b.status === 'answered' && ${stored}.tasks.T3.answers.T3c.value === null`);
  await click('input[data-inability]'); await fill('T4b','Synthetic interpretation'); await choose('T4c','na'); await choose('T4d',2);
  await check('T4 original item-level inability, separate NA and confidence retained', `${stored}.tasks.T4.answers.T4a.status === 'could_not_work_out' && ${stored}.tasks.T4.answers.T4c.status === 'not_applicable' && ${stored}.tasks.T4.answers.T4d.value === 2`);
  await click('#source-summary'); await click('a[href="#task-responses"]');
  await evaluate(`document.querySelector('#workspace').scrollIntoView({block:'start'})`);
  await writeFile(new URL('e5-t4-desktop.png',root),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64')); await submit(); await task('T5'); await setup(0,9,'ir','ir','quick_sort');
  await check('T5 has its three original responses and both functions, no invented confidence', `[...document.querySelectorAll('[data-field]')].map(e=>e.dataset.field).join() === 'T5a,T5b,T5c' && document.querySelector('#function-select').options.length === 2 && !document.querySelector('.rating-options')`);
  await choose('T5a',3); await fill('T5b','Synthetic uncertainty interpretation'); await choose('T5c',4);
  await select('#function-select','quick_sort'); await until('window.StudyWorkspace.ready');
  await click('[data-action="task-setup"]'); await until('window.StudyWorkspace.ready');
  await check('Reopening setup preserves participant function choice and responses', `document.querySelector('#function-select').value === 'quick_sort' && ${stored}.tasks.T5.answers.T5c.value === 4 && !document.querySelector('.ir-line.selected, .cfg-node.selected')`);
  await evaluate(`(() => { const e=document.querySelector('#example-select'); for(const value of ['score','binary_search','quick_sort']) { e.value=value;e.dispatchEvent(new Event('change')); } })()`);
  await until(`window.StudyWorkspace.ready && document.querySelector('#source-summary').textContent.includes('quick_sort')`);
  await evaluate(`(() => { const e=document.querySelector('#function-select'); for(const o of [...e.options].reverse()) {e.value=o.value;e.dispatchEvent(new Event('change'));} })()`);
  await until('window.StudyWorkspace.ready');
  await check('Rapid example/function changes leave latest workspace with task responses intact', `${stored}.tasks.T5.answers.T5b.value === 'Synthetic uncertainty interpretation' && document.querySelector('textarea[name="T5b"]').value === 'Synthetic uncertainty interpretation' && document.querySelector('#example-select').value === 'quick_sort'`);
  // Delay a genuine setup response while a newer example load completes.
  await evaluate(`window.originalFetch=window.fetch;window.fetch=async (...args)=>{const response=await window.originalFetch(...args);if(String(args[0]).endsWith('/quick_sort/source'))await new Promise(r=>setTimeout(r,600));return response;};`);
  await click('[data-action="task-setup"]'); await select('#example-select','score');
  await until(`window.StudyWorkspace.ready && document.querySelector('#example-select').value === 'score'`); await wait(800);
  await check('Late task setup cannot overwrite newer example/function state or responses', `document.querySelector('#source-summary').textContent.includes('score.c') && document.querySelector('#function-select').value === 'score' && ${stored}.tasks.T5.answers.T5c.value === 4`);
  await evaluate('window.fetch=window.originalFetch'); await click('[data-action="task-setup"]');
  await until(`window.StudyWorkspace.ready && document.querySelector('#example-select').value === 'quick_sort' && !document.querySelector('.task-inputs').disabled`);
  await capture('e5-t5-desktop.png');
  const finalWorkspace = await evaluate(`['example-select','function-select','left-state','right-state','left-view','right-view'].map(id=>document.getElementById(id).value).join('|')`);
  await submit(); await task('T6');
  await check('T6 preserves exploration setup and adds no confidence or automatic deadline', `['example-select','function-select','left-state','right-state','left-view','right-view'].map(id=>document.getElementById(id).value).join('|') === ${JSON.stringify(finalWorkspace)} && document.querySelectorAll('[data-field]').length === 3 && !document.querySelector('.rating-options') && !document.querySelector('[data-action="task-setup"]')`);
  await fill('T6a','Synthetic exploration'); await fill('T6b','Synthetic surprise'); await fill('T6c','Synthetic desired action');
  await select('#example-select','score'); await until('window.StudyWorkspace.ready');
  await check('T6 permits any example without losing responses', `${stored}.tasks.T6.answers.T6c.value === 'Synthetic desired action'`);
  await send('Page.reload');
  await until(`document.querySelector('#task-timing')?.textContent.startsWith('Timing is waiting')`);
  const t6Recovered=await evaluate(`${stored}.tasks.T6.durationMs`); await wait(1100);
  await check('T6 refresh retains responses/time and waits for a chosen workspace', `${stored}.tasks.T6.answers.T6a.value === 'Synthetic exploration' && ${stored}.tasks.T6.durationMs === ${t6Recovered} && ${stored}.tasks.T6.interrupted`);
  await select('#example-select','binary_search'); await until(`window.StudyWorkspace.ready && !document.querySelector('.task-inputs').disabled`);
  await check('T6 resumes freely after choosing a workspace, without discarding answers', `document.querySelector('textarea[name="T6c"]').value === 'Synthetic desired action'`);
  const ax=await send('Accessibility.getFullAXTree');
  if (!ax.nodes.some(n=>n.role?.value==='group' && n.name?.value.startsWith('T6a.'))) throw Error('Missing accessible task question group');
  checks.push('Accessible task groups have native prompt names');
  await submit(); await screen('Post-survey');
  await check('Full T0–T6 sequence unlocks post; all outcomes/durations retained', `Object.values(${stored}.tasks).every(t=>t.status !== 'pending' && t.durationMs >= 0) && ${stored}.tasks.T6.durationMs < 300000`);
  await choose('Q1','na'); await fill('Q14','Synthetic post-exposure expectation'); await submit(); await screen('Review responses — submission pending');
  await check('Review shows task durations/outcomes with disabled submission and P13/Q14 pairing', `document.querySelector('.response-review').textContent.includes('T3: Skipped') && document.querySelector('button:disabled').textContent.includes('pending E6') && ${stored}.pre.P13.value === 'Synthetic pre-exposure expectation' && ${stored}.post.Q14.value === 'Synthetic post-exposure expectation'`);
  await click('.response-review summary'); await capture('e5-review-desktop.png');
  const participant=await evaluate(`${stored}.participantCode`);
  await send('Page.reload'); await screen('Review responses — submission pending');
  await check('Complete draft refresh recovers all task outcomes and same participant code', `${stored}.participantCode === ${JSON.stringify(participant)} && ${stored}.tasks.T2.status === 'could_not_work_out' && ${stored}.tasks.T3.status === 'skipped' && ${stored}.tasks.T1.durationMs === ${frozenT1}`);
  await click('[data-action="stop"]'); await screen('Preview stopped');
  await check('Stop clears the complete synthetic draft and code', 'sessionStorage.length === 0 && !document.querySelector(".participant-code")');
  await evaluate('history.back()'); await screen('Information and consent');
  await check('Back cannot restore stopped study', 'sessionStorage.length === 0');
  // Required workspace failure: no timing or progression before successful retry.
  await consent(); await choose('P1',1);
  await send('Network.setBlockedURLs',{urls:['*api/examples/score/source']}); await submit();
  await until(`document.querySelector('#task-timing')?.textContent.startsWith('Timing is waiting')`);
  await check('Initial workspace failure does not start timing or enable task completion', `${stored}.tasks.T0.started === false && ${stored}.tasks.T0.durationMs === 0 && document.querySelector('.task-inputs').disabled`);
  await send('Network.setBlockedURLs',{urls:[]}); await click('[data-action="task-setup"]');
  await until(`!document.querySelector('.task-inputs').disabled`);
  await check('Workspace retry starts the existing task and code', `${stored}.tasks.T0.started && window.StudyWorkspace.ready`);
  await evaluate(`window.originalRemove=Storage.prototype.removeItem;Storage.prototype.removeItem=function(){throw new DOMException('Blocked','SecurityError');}`);
  await click('[data-action="stop"]');
  await check('Failed discard stays honest and leaves task recoverable', `location.hash === '#/study/tasks/T0' && document.querySelector('#draft-status').textContent.includes('could not be removed')`);
  await evaluate('Storage.prototype.removeItem=window.originalRemove'); await click('[data-action="retry-storage"]');
  await click('[data-action="pause-task"]');
  await check('Task clock remains attached after failed discard and retry', `${stored}.tasks.T0.paused`);
  await click('[data-action="pause-task"]'); await submit(); await task('T1');
  // Failure during the commit-to-local-storage transition must recover a locked task.
  await fill('T1a','Synthetic save retry');
  await evaluate(`window.originalSet=Storage.prototype.setItem;Storage.prototype.setItem=function(){throw new DOMException('Quota','QuotaExceededError');}`);
  await submit();
  await check('Local task-save failure never advances silently', `location.hash === '#/study/tasks/T1' && document.querySelector('#draft-status').textContent.includes('could not be saved')`);
  await evaluate('Storage.prototype.setItem=window.originalSet'); await click('[data-action="retry-storage"]');
  await check('Retry saves locked task with a reachable next stage', `${stored}.tasks.T1.status === 'completed' && !!document.querySelector('a[href="#/study/tasks/T2"]') && document.querySelector('.task-inputs').disabled`);
  await click('[data-action="stop"]'); await screen('Preview stopped');
  const content=await (await fetch('http://127.0.0.1:8000/api/study/content')).json();
  const publicBodies = await Promise.all(['/api/study/content','/index.html','/preview.js','/study-draft.js','/task-clock.js','/app.js'].map(async path=>(await fetch('http://127.0.0.1:8000'+path)).text()));
  const forbidden=['Marking key','Expected observations','anticipated wrong answer','reverse-scored','stratification','researcherScore','Facilitator note'];
  if(publicBodies.some(body=>forbidden.some(text=>body.includes(text)))) throw Error('Private analysis material in public content');
  checks.push('Served task/API/assets contain no marking key, expected observations, scoring, stratification or facilitator notes');
  if(content.tasks.length!==7 || content.fields.length!==60 || content.submissionEnabled!==false) throw Error('Public task inventory mismatch');
  checks.push('Public definition exposes 60 original fields and seven tasks, preview only');
  for(const path of ['/Docs/evaluation/instruments/02-task-runsheet.md','/docs/evaluation-captures/e0-task-evidence.json','/docs/evaluation-captures/e5-browser-checks.json']) {
    if((await fetch('http://127.0.0.1:8000'+path)).status!==404) throw Error('Private evidence publicly retrievable');
  }
  checks.push('Researcher instrument/evidence paths not publicly retrievable');
  if(!requests.every(r=>r.method==='GET' && !r.url.includes('Synthetic') && !r.url.includes(participant))) throw Error('Unexpected study data request');
  checks.push('All observed app requests are GET with no answer or participant code in URLs');
  if(errors.length) throw Error(JSON.stringify(errors));
  const screenshots=['e5-t0-desktop.png','e5-t1-desktop.png','e5-t2-narrow.png','e5-t2-narrow-responses.png','e5-t3-desktop.png','e5-t4-desktop.png','e5-t5-desktop.png','e5-review-desktop.png'];
  await writeFile(new URL('e5-browser-checks.json',root),JSON.stringify({date:new Date().toISOString(),revision,sourceHashes,browser:version.product,count:checks.length,checks,runtimeExceptions:errors.length,requestMethods:[...new Set(requests.map(r=>r.method))],screenshots},null,2)+'\n');
  console.log(`${checks.length} E5 browser assertions passed; ${screenshots.length} screenshots.`);
} finally { ws.close(); }
