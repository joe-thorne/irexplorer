// User programs acceptance. Node 22+ and an isolated headless Chrome CDP, against a host runner with the
// user programs setting on and a compiler service on loopback over the fake toolchain (check_browser.sh
// phase 3). Uploads are the unedited curated sources, which the fake toolchain has recordings for.
// Each scenario starts from a freshly loaded Explore page with empty session storage; add a scenario
// to `scenarios` for each new behaviour. Optional IREXPLORER_CHECK_OUTPUT directory for screenshots.
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const curatedSources = join(import.meta.dirname, '..', 'examples', 'curated');
const release = await (await fetch(base + '/api/release')).json();
if (release.config?.userPrograms !== true) throw Error(`Failed: /api/release reports user programs on; observed=${JSON.stringify(release.config)}`);

const page = await (await fetch(`${cdp}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let sequence = 0, fileChooser = null;
const waiting = new Map(), exceptions = [], consoleErrors = [], checks = [], requests = [], held = [];
ws.addEventListener('message', ({ data }) => {
  const message = JSON.parse(data);
  if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails);
  if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
    const { source, text, url } = message.params.entry;
    consoleErrors.push({ source, text, url });
  }
  if (message.method === 'Network.requestWillBeSent') {
    const { method, url } = message.params.request;
    requests.push({ method, path: new URL(url).pathname });
  }
  if (message.method === 'Page.fileChooserOpened') fileChooser = message.params.backendNodeId;
  // POST /api/programs is held here until the scenario releases it, so the compile state can be checked.
  if (message.method === 'Fetch.requestPaused') held.push(message.params.requestId);
  if (waiting.has(message.id)) {
    const [resolve, reject] = waiting.get(message.id); waiting.delete(message.id);
    message.error ? reject(message.error) : resolve(message.result);
  }
});
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const id = ++sequence; waiting.set(id, [resolve, reject]); ws.send(JSON.stringify({ id, method, params })); });
}
async function value(expression) {
  const result = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true, userGesture: true });
  if (result.exceptionDetails) throw Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(expression, attempts = 200) {
  for (let attempt = 0; attempt < attempts; attempt += 1) { if (await value(expression)) return; await pause(75); }
  throw Error(`Timed out: ${expression}; observed=${JSON.stringify(await observed())}`);
}
function observed() {
  return value(`({ hash: location.hash, heading: document.querySelector('#source-summary')?.textContent, card: document.querySelector('#program-card')?.innerText, notice: document.querySelector('#notice').textContent, error: document.querySelector('.error-state')?.innerText, programId: appState.programId, exampleId: appState.exampleId, ready: window.StudyWorkspace.ready })`);
}
async function check(name, expression) {
  if (await value(expression)) { checks.push(name); return; }
  throw Error(`Failed: ${name}; observed=${JSON.stringify(await observed())}`);
}
const click = selector => value(`document.querySelector(${JSON.stringify(selector)}).click()`);
async function select(selector, selected) {
  await value(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e.value = ${JSON.stringify(selected)}; e.dispatchEvent(new Event('change', { bubbles: true })); })()`);
}
const visible = selector => `(() => { const e = document.querySelector(${JSON.stringify(selector)}); return Boolean(e) && e.getClientRects().length > 0; })()`;
async function snap(name) {
  if (!captures) return;
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(join(captures, name), Buffer.from(data, 'base64'));
}
const posts = () => requests.filter(request => request.method === 'POST' && request.path === '/api/programs').length;

// Click a button that opens the file chooser, then pick `file` in it, as a person would.
async function chooseFile(buttonSelector, file) {
  fileChooser = null;
  await click(buttonSelector);
  for (let attempt = 0; fileChooser === null; attempt += 1) {
    if (attempt === 100) throw Error(`No file chooser opened from ${buttonSelector}`);
    await pause(30);
  }
  await send('DOM.setFileInputFiles', { files: [file], backendNodeId: fileChooser });
}
async function holdCompiles(hold) {
  if (hold) await send('Fetch.enable', { patterns: [{ urlPattern: '*/api/programs', requestStage: 'Request' }] });
  else await send('Fetch.disable');
}
async function releaseCompile() {
  for (let attempt = 0; !held.length; attempt += 1) {
    if (attempt === 100) throw Error('No POST /api/programs was sent');
    await pause(30);
  }
  await send('Fetch.continueRequest', { requestId: held.shift() });
}

// Study (#/study…) is unchanged by user programs: none of their controls exist there, and the source
// panel is the curated one. `studySurface` reads what a participant's source panel is made of.
const programControls = ['#source-mode', '#your-file-control', '#your-file-select', '#program-upload', '#program-file-input', '#program-drop', '#program-chip', '#program-card', '.source-title'];
const noProgramControls = `${JSON.stringify(programControls)}.every(selector => !document.querySelector(selector))`;
const curatedExamples = (await (await fetch(base + '/api/examples')).json()).examples;
const curatedSourcePanel = `(() => { const panel = document.querySelector('#source-panel'), options = [...document.querySelectorAll('#example-select option')].map(option => option.value).filter(Boolean);
  return !panel.hasAttribute('data-mode') && document.querySelector('#source-summary').parentElement.matches('#source-panel > .source-heading') && !document.querySelector('label[for="example-select"]').hidden
    && !document.querySelector('#source-lines').inert && !document.querySelector('#source-lines').classList.contains('is-pending') && !document.querySelector('#workspace-shell').hasAttribute('aria-busy')
    && document.querySelector('#empty-state h2').textContent === 'Choose a curated file to start comparing.' && options.join() === ${JSON.stringify(curatedExamples.join())}; })()`;
const studySurface = `(() => { const heading = document.querySelector('#source-panel > .source-heading').cloneNode(true);
  for (const select of heading.querySelectorAll('select')) select.replaceChildren();
  const attributes = selector => [...document.querySelector(selector).attributes].map(a => a.name + '=' + a.value).sort().join(' ');
  return [heading.outerHTML, [...document.querySelector('#source-panel').children].map(child => child.id || child.className).join(), ...['#source-panel', '#source-lines', '#empty-state', '#workspace'].map(attributes)].join('\\n'); })()`;
const study = await (await fetch(base + '/api/study/content')).json();
const onTask = id => until(`document.querySelector('#survey-form')?.dataset.section === '${id}' && window.StudyWorkspace.ready`);
const fill = (name, text) => value(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(text)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`);
// From Explore, consent, answer the pre-survey and move on to T6, which inherits T5's declared workspace.
async function studyToT6() {
  await value(`location.hash = '/study'`);
  await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
  for (const id of study.membership.consent) await click('#' + id);
  await click('[data-action="start"]');
  await until(`document.querySelector('#route-heading')?.textContent === 'Pre-survey'`);
  await click('input[name="P1"][value="1"]'); await fill('P13', 'Synthetic initial account');
  await click('#survey-form button[type="submit"]');
  await onTask('T0'); await click('#survey-form button[type="submit"]');
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5']) { await onTask(id); await click('[data-action="skip-task"]'); }
  await onTask('T6');
}

async function openExplore() {
  await send('Page.navigate', { url: `${base}/#/explore` });
  await until(`document.readyState === 'complete'`);
  await value('sessionStorage.clear()');
  await send('Page.reload');
  await until(`document.readyState === 'complete' && document.querySelectorAll('#example-select option').length === 4`);
  await until(`document.querySelector('#source-mode') !== null`);
}

const scenarios = {
  async 'Choose a curated source in Your files and explore it as a user program'() {
    await check('Explore offers Curated examples | Your files above the C source controls, on Curated examples',
      `(() => { const mode = document.querySelector('#source-mode'), labels = [...mode.querySelectorAll('label')].map(l => l.textContent.trim()); return labels.join('|') === 'Curated examples|Your files' && mode.querySelector('input[value="curated"]').checked && ['label[for="example-select"]', '#function-control'].every(selector => mode.compareDocumentPosition(document.querySelector(selector)) & Node.DOCUMENT_POSITION_FOLLOWING); })()`);
    await check('Curated examples shows the File select and no upload controls', `${visible('#example-select')} && !${visible('#your-file-select')} && !${visible('#program-upload')} && !${visible('#program-drop')}`);
    await click('#source-mode input[value="yours"]');
    await check('Your files replaces File with a Your file select and Upload…', `!${visible('#example-select')} && ${visible('#your-file-select')} && document.querySelector('#program-upload').textContent === 'Upload…'`);
    await check('With no user program open the source lines area offers Choose a file… and states the limits',
      `${visible('#program-drop')} && !${visible('#source-lines')} && document.querySelector('#program-drop button').textContent === 'Choose a file…' && /One C file, up to 200 lines\\. Standard headers are allowed\\./.test(document.querySelector('#program-drop').textContent)`);
    await check('Nothing visible says "Choose a curated file" while Your files is selected', `!document.querySelector('#workspace-shell').innerText.includes('Choose a curated file')`);
    await snap('user-programs-your-files.png');

    await holdCompiles(true);
    const before = posts();
    await chooseFile('#program-drop button', join(curatedSources, 'score.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling score.c')`);
    await check('The source is shown at once, dimmed and read-only, while it compiles',
      `(() => { const lines = document.querySelector('#source-lines'); return ${visible('#source-lines')} && !${visible('#program-drop')} && lines.inert && parseFloat(getComputedStyle(lines).opacity) < 1 && lines.querySelectorAll('.source-line').length > 5 && document.querySelector('#source-summary').textContent === 'C source · score.c'; })()`);
    await check('A compile card replaces the panels and the comparison and explains the wait',
      `(() => { const card = document.querySelector('#program-card'), text = card.innerText; return ${visible('#program-card')} && !${visible('#left-panel')} && !${visible('#right-panel')} && !${visible('.comparison-status')} && !${visible('#empty-state')} && /Compiling score\\.c · \\d+ s/.test(text) && text.includes('-O0') && text.includes('curated pass sequence') && text.includes('recompiled O3 state') && text.includes('about 5 s'); })()`);
    await check('The elapsed seconds are hidden from assistive technology and the status is announced once',
      `document.querySelector('#program-card .program-elapsed').getAttribute('aria-hidden') === 'true' && document.querySelector('#notice').textContent === 'Compiling score.c.' && !document.querySelector('#program-card').hasAttribute('aria-live')`);
    await check('The switch, selects and upload buttons are disabled and the workbench is busy during the compile',
      `[...document.querySelectorAll('#source-mode input, #example-select, #your-file-select, #program-upload, #program-drop button')].every(control => control.disabled) && document.querySelector('#workspace-shell').getAttribute('aria-busy') === 'true'`);
    await snap('user-programs-compiling.png');
    const ticked = await value(`document.querySelector('#program-card .program-elapsed').textContent`);
    await pause(1100);
    await check('The elapsed time ticks', `document.querySelector('#program-card .program-elapsed').textContent !== ${JSON.stringify(ticked)}`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent', `${posts() - before === 1}`);

    await check('The user program opens with the heading and the Your file chip',
      `document.querySelector('#source-summary').textContent === 'C source · score.c' && ${visible('#program-chip')} && document.querySelector('#program-chip').textContent === 'Your file'`);
    await check('Its id is a programId, read through /api/programs, never the curated score',
      `/^[0-9a-f]{64}$/.test(appState.programId) && appState.exampleId === null`);
    await check('The compile card is gone, controls are enabled and the workbench is not busy',
      `!${visible('#program-card')} && ${visible('#left-panel')} && ${visible('.comparison-status')} && [...document.querySelectorAll('#source-mode input, #your-file-select, #program-upload')].every(control => !control.disabled) && document.querySelector('#workspace-shell').getAttribute('aria-busy') !== 'true' && !document.querySelector('#source-lines').inert`);
    await check('Every state of the curated pass sequence is listed, with IR in both panels',
      `document.querySelector('#left-state').options.length === 14 && document.querySelector('#left-state').options[13].textContent.includes('Separately compiled with -O3') && document.querySelectorAll('#left-viewer .ir-line').length > 0 && document.querySelectorAll('#right-viewer .ir-line').length > 0`);
    await check('The comparison report is shown', `document.querySelector('#comparison-action').textContent.includes('curated pass sequence') && document.querySelector('#left-selected-state').textContent.includes('State 0')`);
    await select('#right-view', 'cfg'); await until(`window.StudyWorkspace.ready && document.querySelector('#right-view').value === 'cfg'`);
    await check('The CFG view draws the user program', visible('#right-viewer .cfg-svg'));
    await select('#right-view', 'ir'); await until(`window.StudyWorkspace.ready && document.querySelector('#right-view').value === 'ir'`);
    await click('.source-line[data-line="4"]'); await until('Boolean(appState.selection?.trace)');
    await check('Source mappings link a C line to its instructions', `/instructions? in Left maps? to the selected C location/.test(document.querySelector('#source-status').textContent) && document.querySelectorAll('#left-viewer .ir-line.is-source, #left-viewer .ir-line.is-linked').length > 0`);
    const programPaths = requests.filter(request => request.path.startsWith('/api/programs/'));
    await check('Its views were read through /api/programs/{programId}', `${programPaths.length > 0 && !requests.some(request => request.path.startsWith('/api/examples/score'))}`);
    await snap('user-programs-open.png');
    await check('The upload is listed in Your file and selected',
      `(() => { const select = document.querySelector('#your-file-select'), options = [...select.options].filter(option => option.value); return options.length === 1 && options[0].textContent === 'score.c' && select.value === appState.programId; })()`);
    const programId = await value('appState.programId');

    await click('#source-mode input[value="curated"]');
    await check('Curated examples closes the user program and asks for a curated file', `!appState.programId && !${visible('#program-chip')} && ${visible('#example-select')} && document.querySelector('#empty-state h2').textContent === 'Choose a curated file to start comparing.'`);
    await select('#example-select', 'score'); await until(`window.StudyWorkspace.ready && appState.exampleId === 'score'`);
    await check('The curated score is distinct from the uploaded score.c: no chip, curated routes',
      `!${visible('#program-chip')} && !appState.programId && document.querySelector('#source-summary').textContent === 'C source · score.c'`);
    await check('The curated score was read through /api/examples', `${requests.some(request => request.path === '/api/examples/score/states')}`);

    await click('#source-mode input[value="yours"]');
    await check('Your files closes the curated example and offers the drop zone again', `!appState.exampleId && ${visible('#program-drop')} && !${visible('#program-chip')}`);
    const reopenedFrom = requests.length, postsBefore = posts();
    await select('#your-file-select', programId);
    await check('Reopening an upload shows its source at once', `document.querySelector('#source-summary').textContent === 'C source · score.c' && ${visible('#program-chip')} && !${visible('#program-card')}`);
    await until(`window.StudyWorkspace.ready && appState.programId === ${JSON.stringify(programId)}`);
    await check('Reopening an upload sends no POST', `${posts() === postsBefore && requests.slice(reopenedFrom).some(request => request.path === `/api/programs/${programId}/states`)}`);
  },

  async 'Study never builds the upload controls, even while a compile is under way'() {
    await click('#source-mode input[value="yours"]');
    await holdCompiles(true);
    await chooseFile('#program-drop button', join(curatedSources, 'score.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling score.c')`);
    await value(`location.hash = '/study'`);
    await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
    await check('Leaving Explore for #/study removes every user programs control', noProgramControls);
    await check('The source panel is the curated one: File select of curated examples only, nothing pending or busy', curatedSourcePanel);
    const openedFrom = requests.length;
    await releaseCompile();
    await holdCompiles(false);
    await until(`performance.getEntriesByType('resource').some(entry => new URL(entry.name).pathname === '/api/programs' && entry.responseEnd > 0)`);
    await pause(500);
    await check('A compile that finishes in Study opens nothing there',
      `${!requests.slice(openedFrom).some(request => request.path.startsWith('/api/programs/'))} && !appState.programId && ${noProgramControls} && ${curatedSourcePanel}`);
    await value(`location.hash = '/explore'`);
    await until(`document.querySelector('#source-mode') !== null`);
    await check('Back in Explore the controls return on Curated examples, with the finished upload kept in Your file',
      `document.querySelector('#source-mode input[value="curated"]').checked && ${visible('#example-select')} && [...document.querySelector('#your-file-select').options].some(option => option.textContent === 'score.c')`);
    await value(`history.replaceState(null, '', '/#/study')`); await send('Page.reload');
    await until(`document.readyState === 'complete' && document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
    await until(`document.querySelectorAll('#example-select option').length === ${curatedExamples.length + 1}`);
    await pause(500);
    await check('A page loaded on #/study never builds them', `${noProgramControls} && ${curatedSourcePanel}`);
  },

  async 'An inheriting Study task opens its curated workspace, never a user program on screen'() {
    await studyToT6();
    await value(`location.hash = '/explore'`);
    await until(`document.querySelector('#source-mode') !== null`);
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', join(curatedSources, 'score.c'));
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await value(`location.hash = '/study/tasks/T6'`);
    await onTask('T6');
    await check('T6 opens the inherited curated workspace (quick_sort, State 0 IR in both panels), not the user program',
      `(() => { const s = window.StudyWorkspace.snapshot(); return !appState.programId && s?.exampleId === 'quick_sort' && s.panels.left.ordinal === 0 && s.panels.left.viewType === 'ir' && s.panels.right.ordinal === 0 && s.panels.right.viewType === 'ir' && document.querySelector('#source-summary').textContent === 'C source · quick_sort.c'; })()`);
    await check('The task shows no user programs control and the curated source panel', `${noProgramControls} && ${curatedSourcePanel}`);
    const entered = await value(studySurface);
    await send('Page.reload');
    await onTask('T6');
    await check('A page loaded on the task never builds the controls', noProgramControls);
    await check('The task looks exactly as on a page that never built them', `${JSON.stringify(entered)} === ${studySurface}`);
  },
};

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable'); await send('Log.enable'); await send('DOM.enable');
  await send('Page.setInterceptFileChooserDialog', { enabled: true });
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  for (const [name, scenario] of Object.entries(scenarios)) {
    await openExplore();
    try { await scenario(); } catch (error) { error.message = `${name}: ${error.message}`; throw error; }
  }
  const cspViolations = consoleErrors.filter(entry => entry.source === 'security' || /Content Security Policy/i.test(entry.text));
  if (exceptions.length) throw Error(`Browser runtime exceptions: ${JSON.stringify(exceptions)}`);
  if (cspViolations.length) throw Error(`Browser Content Security Policy violations: ${JSON.stringify(cspViolations)}`);
  console.log(JSON.stringify({ release, assertions: checks.length, checks, runtimeExceptions: exceptions.length, consoleErrors, cspViolations }));
} finally {
  ws.close();
  await fetch(`${cdp}/json/close/${page.id}`);
}
