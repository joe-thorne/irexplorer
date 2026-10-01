// Task-procedure acceptance. Node 22+ and an isolated headless Chrome CDP; synthetic answers only.
// Runs the packaged T0–T6 procedure, then a synthetic content variant whose declared entry
// workspaces, inheritance and membership differ, served to the browser through CDP interception.
// Nothing is submitted: every journey ends with Stop and discard.
const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const DRAFT = 'irexplorer.study.v0.11';
const packaged = await (await fetch(base + '/api/study/content')).json();

const page = await (await fetch(`${cdp}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let sequence = 0, variant = null, contentDelayMs = 0, examplesDelayMs = 0;
const waiting = new Map(), exceptions = [], consoleErrors = [], checks = [], requests = [];
ws.addEventListener('message', async ({ data }) => {
  const message = JSON.parse(data);
  if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails);
  if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
    const { source, text, url } = message.params.entry;
    consoleErrors.push({ source, text, url });
  }
  if (message.method === 'Network.requestWillBeSent') {
    const { method, url, postData } = message.params.request;
    requests.push({ method, url, postData: postData || '' });
  }
  if (message.method === 'Fetch.requestPaused' && message.params.request.url.endsWith('/api/examples')) {
    if (examplesDelayMs) await new Promise(resolve => setTimeout(resolve, examplesDelayMs));
    send('Fetch.continueRequest', { requestId: message.params.requestId });
  } else if (message.method === 'Fetch.requestPaused') {
    const content = JSON.parse(JSON.stringify(packaged));
    if (variant) variant(content);
    if (contentDelayMs) await new Promise(resolve => setTimeout(resolve, contentDelayMs));
    send('Fetch.fulfillRequest', { requestId: message.params.requestId, responseCode: 200,
      responseHeaders: [{ name: 'Content-Type', value: 'application/json' }, { name: 'Cache-Control', value: 'no-store' }],
      body: Buffer.from(JSON.stringify(content)).toString('base64') });
  }
  if (waiting.has(message.id)) {
    const [resolve, reject] = waiting.get(message.id); waiting.delete(message.id);
    message.error ? reject(message.error) : resolve(message.result);
  }
});
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const id = ++sequence; waiting.set(id, [resolve, reject]); ws.send(JSON.stringify({ id, method, params })); });
}
async function value(expression) {
  const result = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (result.exceptionDetails) throw Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
async function until(expression, attempts = 200) {
  for (let attempt = 0; attempt < attempts; attempt += 1) { if (await value(expression)) return; await pause(75); }
  throw Error(`Timed out: ${expression}; hash=${await value('location.hash')}`);
}
async function check(name, expression) {
  if (await value(expression)) { checks.push(name); return; }
  const observed = await value(`({ hash: location.hash, workspace: window.StudyWorkspace?.snapshot(), highlighted: document.querySelectorAll(${JSON.stringify(highlighted)}).length, draft: sessionStorage.getItem('${DRAFT}') })`);
  throw Error(`Failed: ${name}; observed=${JSON.stringify(observed)}`);
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const click = selector => value(`document.querySelector(${JSON.stringify(selector)}).click()`);
const fill = (name, text) => value(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(text)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`);
const select = (selector, selected) => value(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e.value = ${JSON.stringify(selected)}; e.dispatchEvent(new Event('change', { bubbles: true })); })()`);
const saved = () => value(`JSON.parse(sessionStorage.getItem('${DRAFT}'))`);
const workspaceIs = (example, left, right, fn = null) => `(() => { const s = window.StudyWorkspace.snapshot(); return window.StudyWorkspace.ready && s.exampleId === ${JSON.stringify(example)} && s.panels.left.ordinal === ${left[0]} && s.panels.left.viewType === '${left[1]}' && s.panels.right.ordinal === ${right[0]} && s.panels.right.viewType === '${right[1]}'${fn ? ` && s.functionName === '${fn}'` : ''} && document.querySelector('#left-state').value === '${left[0]}' && document.querySelector('#right-view').value === '${right[1]}'; })()`;
// Selection is observed as the participant sees it: selected or traced C lines, IR lines and CFG blocks.
const highlighted = '.is-selected, .is-source, .is-linked';
const selectionClear = `!document.querySelector(${JSON.stringify(highlighted)})`;
const selectionShown = `Boolean(document.querySelector(${JSON.stringify(highlighted)}))`;
// The task's target comparison (packaged `setup`) stays named in its open instructions.
function targetVisible(id) {
  const { example, function: fn, left, right } = packaged.tasks.find(task => task.id === id).setup;
  const named = [example, fn, `State ${left.ordinal}`, `State ${right.ordinal}`].filter(Boolean);
  return `document.querySelector('#task-instructions').open && ${JSON.stringify(named)}.every(text => document.querySelector('#task-instructions').innerText.includes(text))`;
}
const onTask = id => until(`document.querySelector('#survey-form')?.dataset.section === '${id}' && window.StudyWorkspace.ready`);

async function beginJourney() {
  await value(`sessionStorage.clear()`);
  // A hash-only navigation keeps the loaded content; reload so each journey fetches it afresh.
  await value(`history.replaceState(null, '', '/#/study')`); await send('Page.reload');
  await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
  for (const id of packaged.membership.consent) await click('#' + id);
  await click('[data-action="start"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Pre-survey'`);
  await click('input[name="P1"][value="1"]'); await fill('P13', 'Synthetic initial account');
  await click('#survey-form button[type="submit"]');
}
async function discardJourney() {
  await click('[data-action="stop"]'); await click('[data-action="confirm-stop"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Study stopped'`);
}

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable'); await send('Log.enable');
  await send('Fetch.enable', { patterns: ['*/api/study/content', '*/api/examples'].map(urlPattern => ({ urlPattern, requestStage: 'Request' })) });
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `${base}/` });
  await until(`document.readyState === 'complete'`);

  // Packaged procedure.
  await beginJourney();
  const journeyStart = requests.length;
  await onTask('T0');
  await check('P13 locks when T0 starts', `(() => { const d = JSON.parse(sessionStorage.getItem('${DRAFT}')); return d.p13Locked && d.tasks.T0.presented; })()`);
  await check('T0 enters score at State 0 with IR in both panels and no selection', `${workspaceIs('score', [0, 'ir'], [0, 'ir'])} && ${selectionClear}`);
  await check('T0 keeps its distinct target comparison visible in open instructions', targetVisible('T0'));

  // Task-presentation duration: counts visible time, excludes pause, hidden-tab time and reload downtime.
  await pause(1300);
  await click('[data-action="pause-task"]');
  const pausedAt = (await saved()).tasks.T0.durationMs;
  await check('Duration starts at presentation and counts visible time', `${pausedAt} >= 800`);
  await pause(900);
  await check('Explicit pause excludes paused time and disables answers', `JSON.parse(sessionStorage.getItem('${DRAFT}')).tasks.T0.durationMs === ${pausedAt} && document.querySelector('.task-inputs').disabled && JSON.parse(sessionStorage.getItem('${DRAFT}')).tasks.T0.paused`);
  await click('[data-action="pause-task"]');
  await value(`Object.defineProperty(document, 'hidden', { configurable: true, get: () => true }); document.dispatchEvent(new Event('visibilitychange'))`);
  const hiddenAt = (await saved()).tasks.T0.durationMs;
  await pause(900);
  await check('Hidden-tab time is excluded and marks the attempt interrupted', `(() => { const t = JSON.parse(sessionStorage.getItem('${DRAFT}')).tasks.T0; return t.durationMs === ${hiddenAt} && t.interrupted; })()`);
  await value(`delete document.hidden; document.dispatchEvent(new Event('visibilitychange'))`);
  await pause(1100);
  const beforeReload = (await saved()).tasks.T0.durationMs;
  await check('Visible time resumes after the tab returns', `${beforeReload} > ${hiddenAt}`);
  contentDelayMs = 2500;
  await send('Page.reload');
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T0'`);
  contentDelayMs = 0;
  await check('Reload downtime is excluded from task-presentation duration', `JSON.parse(sessionStorage.getItem('${DRAFT}')).tasks.T0.durationMs < ${beforeReload} + 1500`);
  await onTask('T0');
  await click('#survey-form button[type="submit"]');

  // T1–T5 entry versus target; partial, skipped, inability and completed responses.
  // Expected entries are the ticket's fixed procedure, kept independent of the package under test.
  const examples = { T1: 'score', T2: 'score', T3: 'binary_search', T4: 'binary_search', T5: 'quick_sort' };
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5']) {
    await onTask(id);
    await check(`${id} enters ${examples[id]} at State 0 with IR in both panels and no selection`, `${workspaceIs(examples[id], [0, 'ir'], [0, 'ir'])} && ${selectionClear}`);
    await check(`${id} keeps its distinct target comparison visible in instructions`, targetVisible(id));
    await check(`${id} renders exactly its declared response membership in order`, `[...document.querySelectorAll('#task-responses [data-field]')].map(e => e.dataset.field).join() === ${JSON.stringify(packaged.membership[id].join())}`);
    if (id === 'T1') { await fill('T1a', 'Synthetic brief T1 note'); await click('[data-action="skip-task"]'); }
    if (id === 'T2') { await fill('T2b', 'Synthetic partial T2 reason'); await click('[data-action="unable-task"]'); }
    if (id === 'T3') { await fill('T3b', 'Synthetic completed T3 answer'); await click('#survey-form button[type="submit"]'); }
    if (id === 'T4') await click('[data-action="skip-task"]');
    if (id === 'T5') {
      await select('#left-state', '8'); await select('#right-state', '9'); await until('window.StudyWorkspace.ready');
      await select('#function-select', 'partition'); await until(`window.StudyWorkspace.ready && window.StudyWorkspace.snapshot().functionName === 'partition'`);
      await select('#right-view', 'cfg'); await until(`window.StudyWorkspace.ready && document.querySelector('#right-view').value === 'cfg'`);
      await click('.source-line[data-line="8"]'); await until(selectionShown);
      await click('#survey-form button[type="submit"]');
    }
  }
  const afterTasks = await saved();
  await check('Skipped and inability attempts keep brief/partial answers with distinct statuses', `(() => { const t = ${JSON.stringify(afterTasks.tasks)}; return t.T1.status === 'skipped' && t.T1.answers.T1a.value === 'Synthetic brief T1 note' && t.T2.status === 'could_not_work_out' && t.T2.answers.T2b.value === 'Synthetic partial T2 reason' && t.T3.status === 'completed' && t.T4.status === 'skipped' && t.T5.status === 'completed'; })()`);

  // T6 inherits the preceding workspace with its selection cleared, including after refresh.
  await onTask('T6');
  await check('T6 inherits the T5 workspace and clears its selection', `${workspaceIs('quick_sort', [8, 'ir'], [9, 'cfg'], 'partition')} && ${selectionClear}`);
  examplesDelayMs = 1500; // Study content arrives before the curated example list.
  await send('Page.reload');
  await onTask('T6');
  examplesDelayMs = 0;
  await check('T6 restores the inherited workspace after refresh with selection cleared', `${workspaceIs('quick_sort', [8, 'ir'], [9, 'cfg'], 'partition')} && ${selectionClear}`);

  // Completed responses are read-only; revisiting a task changes nothing.
  await value(`location.hash = '/study/tasks/T1'`);
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T1'`);
  await value(`(() => { const e = document.querySelector('textarea[name="T1a"]'); e.value = 'Changed'; e.dispatchEvent(new Event('input', { bubbles: true })); })()`);
  await check('Revisited skipped task is read-only and keeps its recorded outcome', `document.querySelector('.task-inputs').disabled && document.querySelector('textarea[name="T1a"]').readOnly && !document.querySelector('[data-action="skip-task"]') && document.querySelector('#task-responses').innerText.includes('Recorded outcome: Skipped') && JSON.parse(sessionStorage.getItem('${DRAFT}')).tasks.T1.answers.T1a.value === 'Synthetic brief T1 note'`);
  await value(`location.hash = '/study/tasks/T2'`);
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T2'`);
  await check('Revisited inability task shows its distinct outcome read-only', `document.querySelector('.task-inputs').disabled && document.querySelector('#task-responses').innerText.includes('Recorded outcome: Could not work this out')`);
  await value(`location.hash = '/study/tasks/T6'`);
  await onTask('T6');
  await fill('T6a', 'Synthetic exploration note');
  await click('#survey-form button[type="submit"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Post-survey'`);
  await fill('Q14', 'Synthetic post answer');
  await click('#survey-form button[type="submit"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Review answers'`);
  await check('Review lists distinct participant task statuses', `(() => { const text = document.querySelector('.response-review').textContent; return text.includes('T1: Skipped') && text.includes('T2: Could not work this out') && text.includes('T3: Completed'); })()`);

  // Permitted background and post edits remain available until submission; P13 stays locked.
  await click('[data-action="edit-pre"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Pre-survey'`);
  await check('Background correction keeps P13 locked but other answers editable', `document.querySelector('textarea[name="P13"]').readOnly && !document.querySelector('input[name="P4"]').disabled`);
  await click('input[name="P4"][value="3"]');
  await click('#survey-form button[type="submit"]');
  await until(`location.hash === '#/study/post'`);
  await fill('Q14', 'Synthetic corrected post answer');
  await click('#survey-form button[type="submit"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Review answers'`);
  await check('Background and post corrections are kept and P13 is unchanged', `(() => { const d = JSON.parse(sessionStorage.getItem('${DRAFT}')); return d.pre.P4.value === 3 && d.post.Q14.value === 'Synthetic corrected post answer' && d.pre.P13.value === 'Synthetic initial account'; })()`);
  const journey = requests.slice(journeyStart);
  if (journey.some(r => r.method !== 'GET' || r.url.includes('/api/study/submissions') || /Synthetic/.test(r.url + r.postData)))
    throw Error(`Failed: navigation sent answers ${JSON.stringify(journey.filter(r => r.method !== 'GET'))}`);
  checks.push(`Task navigation, reload and review sent no answers (${journey.length} GET requests only)`);
  await discardJourney();

  // Synthetic declaration variant: entry, inheritance and membership come from the package.
  variant = content => {
    const task = id => content.tasks.find(t => t.id === id);
    task('T1').entryWorkspace = { example: 'binary_search', left: { ordinal: 2, view: 'cfg' }, right: { ordinal: 3, view: 'ir' }, selection: 'clear' };
    task('T4').entryWorkspace = { inherit: 'previous', selection: 'clear' };
    delete task('T6').inheritWorkspace;
    content.membership.T3 = [...content.membership.T3].reverse(); // task('T3').fields keeps the old order.
  };
  await beginJourney();
  await onTask('T0'); await click('#survey-form button[type="submit"]');
  await onTask('T1');
  await check('A declared entry workspace opens as declared with no selection', `${workspaceIs('binary_search', [2, 'cfg'], [3, 'ir'])} && ${selectionClear}`);
  await click('[data-action="skip-task"]');
  await onTask('T2'); await click('[data-action="skip-task"]');
  await onTask('T3');
  await check('Task responses follow declared membership order', `[...document.querySelectorAll('#task-responses [data-field]')].map(e => e.dataset.field).join() === 'T3c,T3b,T3a'`);
  await select('#left-state', '5'); await select('#right-state', '6'); await until('window.StudyWorkspace.ready');
  await select('#right-view', 'cfg'); await until(`window.StudyWorkspace.ready && document.querySelector('#right-view').value === 'cfg'`);
  await click('.source-line[data-line="6"]'); await until(selectionShown);
  await click('[data-action="skip-task"]');
  await onTask('T4');
  await check('A declared inheriting task continues the preceding workspace with no selection', `${workspaceIs('binary_search', [5, 'ir'], [6, 'cfg'])} && ${selectionClear}`);
  examplesDelayMs = 1500;
  await send('Page.reload');
  await onTask('T4');
  examplesDelayMs = 0;
  await check('A declared inheriting task restores after refresh', `${workspaceIs('binary_search', [5, 'ir'], [6, 'cfg'])} && ${selectionClear}`);
  await click('[data-action="skip-task"]');
  await onTask('T5'); await click('[data-action="skip-task"]');
  await onTask('T6');
  await check('Inheritance follows entryWorkspace without the legacy flag', `${workspaceIs('quick_sort', [0, 'ir'], [0, 'ir'])} && ${selectionClear} && document.querySelector('#task-instructions').innerText.includes('Your workspace continues from') && !document.querySelector('#task-instructions').innerText.includes('The workspace opens on')`);
  await discardJourney();

  const cspViolations = consoleErrors.filter(entry => entry.source === 'security' || /Content Security Policy/i.test(entry.text));
  if (exceptions.length) throw Error(`Browser runtime exceptions: ${JSON.stringify(exceptions)}`);
  if (cspViolations.length) throw Error(`Browser Content Security Policy violations: ${JSON.stringify(cspViolations)}`);
  console.log(JSON.stringify({ assertions: checks.length, checks, runtimeExceptions: exceptions.length, consoleErrors, cspViolations }, null, 1));
} finally {
  ws.close();
  await fetch(`${cdp}/json/close/${page.id}`);
}
