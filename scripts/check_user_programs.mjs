// User programs acceptance. Node 22+ and an isolated headless Chrome CDP, against a host runner with the
// user programs setting on and a compiler service on loopback over the fake toolchain (check_browser.sh
// phase 3). Uploads and programs compiled from the editor are the unedited curated sources and the recorded
// corpus in tests/data/user-programs (the editor's starter function among them), which the fake toolchain
// has recordings for.
// Each scenario starts from a freshly loaded Explore page with empty session storage; add a scenario
// to `scenarios` for each new behaviour. Optional IREXPLORER_CHECK_OUTPUT directory for screenshots.
// IREXPLORER_COMPILER_PID is the compiler service's process, which a scenario pauses to make it unavailable.
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const curatedSources = join(import.meta.dirname, '..', 'examples', 'curated');
// The recorded user-program corpus, which the fake toolchain replays as the real toolchain answered it.
const userProgramSources = join(import.meta.dirname, '..', 'tests', 'data', 'user-programs');
// The acceptance cases the server is tested against too (tests/test_accepted_programs.py).
const acceptance = JSON.parse(await readFile(join(import.meta.dirname, '..', 'tests', 'data', 'user-program-acceptance.json'), 'utf8'));
const expand = text => typeof text === 'string' ? text : text.map(part => typeof part === 'string' ? part : part[0].repeat(part[1])).join('');
// Sources written for a scenario, such as ones carrying a fake toolchain marker (tests/fake_toolchain).
const writtenSources = await mkdtemp(join(tmpdir(), 'irexplorer-user-programs-'));
async function file(name, contents) {
  await writeFile(join(writtenSources, name), contents);
  return join(writtenSources, name);
}
// A curated source under another name: the same recording, but a programId the server does not hold yet.
async function renamedCopy(example, fileName) {
  const path = join(writtenSources, fileName);
  await writeFile(path, await readFile(join(curatedSources, `${example}.c`)));
  return path;
}
const release = await (await fetch(base + '/api/release')).json();
if (release.config?.userPrograms !== true) throw Error(`Failed: /api/release reports user programs on; observed=${JSON.stringify(release.config)}`);

const page = await (await fetch(`${cdp}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let sequence = 0, fileChooser = null;
const waiting = new Map(), exceptions = [], consoleErrors = [], checks = [], requests = [], responses = [], held = [];
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
  if (message.method === 'Network.responseReceived') {
    const { status, url } = message.params.response;
    responses.push({ status, path: new URL(url).pathname });
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
// Clicks the failure card's button with exactly this text.
const cardButton = text => value(`[...document.querySelectorAll('#program-card button')].find(button => button.textContent === ${JSON.stringify(text)}).click()`);
const cardButtons = `[...document.querySelectorAll('#program-card button')].map(button => button.textContent).join('|')`;
// A POST from outside this page, as another tab's would be.
function postElsewhere(fileName, source) {
  return fetch(base + '/api/programs', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ fileName, source }) });
}
// Waits until the compiler takes a program again: a source with no recording then fails to compile, not busy.
async function compilerFree() {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const response = await postElsewhere('probe.c', 'int probe(void) { return 0; }\n');
    if (response.status !== 409) return;
    await pause(100);
  }
  throw Error('The compiler service stayed busy');
}

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
// Drag `file` in from outside the page and drop it on the centre of `selector`, as a person would.
async function dropFile(selector, file) {
  const { x, y } = await value(`(() => { const box = document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect(); return { x: box.left + box.width / 2, y: box.top + box.height / 2 }; })()`);
  const data = { items: [], files: [file], dragOperationsMask: 1 };
  for (const type of ['dragEnter', 'dragOver', 'drop']) await send('Input.dispatchDragEvent', { type, x, y, data });
}
// Press a key with `modifiers` (CDP's bit field) held, as a person would.
const CTRL = 2, SHIFT = 8;
async function key(key, code, keyCode, modifiers = 0) {
  for (const type of ['keyDown', 'keyUp']) await send('Input.dispatchKeyEvent', { type, key, code, windowsVirtualKeyCode: keyCode, modifiers });
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

// Ask check_browser.sh to restart the host runner, so the server forgets every user program it held.
async function restartServer() {
  const requestFile = process.env.IREXPLORER_RESTART_REQUEST;
  if (!requestFile) throw Error('Restarting the host runner needs IREXPLORER_RESTART_REQUEST; run this through check_browser.sh');
  await writeFile(requestFile, '');
  for (let attempt = 0; existsSync(requestFile); attempt += 1) {
    if (attempt === 600) throw Error('The host runner was not restarted');
    await pause(100);
  }
}
// Open Explore in a tab of its own (not opened from this one, so its session storage starts empty), wait
// until `ready` holds there, and return the value of `expression` in it.
async function inFreshTab(ready, expression) {
  const tab = await (await fetch(`${cdp}/json/new?${base}/#/explore`, { method: 'PUT' })).json();
  const socket = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise(resolve => socket.addEventListener('open', resolve, { once: true }));
  let id = 0;
  const evaluate = text => new Promise(resolve => {
    const sent = ++id;
    socket.addEventListener('message', function reply({ data }) {
      const message = JSON.parse(data);
      if (message.id !== sent) return;
      socket.removeEventListener('message', reply);
      resolve(message.result?.result?.value);
    });
    socket.send(JSON.stringify({ id: sent, method: 'Runtime.evaluate', params: { expression: text, returnByValue: true } }));
  });
  try {
    for (let attempt = 0; !(await evaluate(ready)); attempt += 1) {
      if (attempt === 200) throw Error(`Timed out in a fresh tab: ${ready}`);
      await pause(75);
    }
    return await evaluate(expression);
  } finally {
    socket.close();
    await fetch(`${cdp}/json/close/${tab.id}`);
  }
}
const uploadOptions = `[...document.querySelector('#your-file-select').options].filter(option => option.value).map(option => option.textContent)`;
// Upload `name` from the curated sources through Your files and wait until it is open.
async function upload(name) {
  await click('#source-mode input[value="yours"]');
  await chooseFile('#program-drop button', join(curatedSources, name));
  await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
}
async function reload() {
  await send('Page.reload');
  await until(`document.readyState === 'complete' && document.querySelectorAll('#example-select option').length === 4`);
  await until(`document.querySelector('#source-mode') !== null`);
}

// Open the curated example `exampleId` in the File select and wait until it is open.
async function openCurated(exampleId) {
  await select('#example-select', exampleId);
  await until(`window.StudyWorkspace.ready && appState.exampleId === ${JSON.stringify(exampleId)}`);
}
// Choose `option` in a workspace select and wait until the workspace shows it.
async function choose(selector, option) {
  await select(selector, option);
  await until(`window.StudyWorkspace.ready && document.querySelector(${JSON.stringify(selector)}).value === ${JSON.stringify(option)}`);
}
// Replace everything in the editor with `text`, as pasting over a selection does.
async function editorText(text) {
  await value(`document.querySelector('#program-editor textarea').select()`);
  await send('Input.insertText', { text });
}
// What the source panel says beside the editor about the source it shows.
const SOURCE_NOTE = 'This is the source that was compiled, as the panels show it.';
// The C source and both panels start their code areas at the same height below their headings.
const alignedCode = `(() => { const panels = ['#source-panel', '#left-panel', '#right-panel'].map(selector => document.querySelector(selector).getBoundingClientRect()), views = ['#source-lines', '#left-viewer', '#right-viewer'].map(selector => document.querySelector(selector).getBoundingClientRect()); return views.every((view, index) => Math.abs((view.top - panels[index].top) - (views[0].top - panels[0].top)) < 1); })()`;

// Study (#/study…) is unchanged by user programs: none of their controls exist there, and the source
// panel is the curated one. `studySurface` reads what a participant's source panel is made of.
const programControls = ['#source-mode', '#your-file-control', '#your-file-select', '#program-upload', '#program-new', '#program-edit', '#program-origin', '#program-source-note', '#program-file-input', '#program-drop', '#program-editor', '#program-chip', '#program-card', '#program-warnings', '.source-title'];
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
  await reload();
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
  async 'A compile error marks its lines in the source and replaces the comparison'() {
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', join(curatedSources, 'score.c'));
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('An earlier comparison is open before the failing upload', `${visible('#left-panel')} && ${visible('.comparison-status')}`);
    // The fake clang fails as clang does on each call to an undeclared abss, with a note in stdlib.h.
    const filler = Array.from({ length: 36 }, (_, index) => `int filler_${index}(int value) { return value + ${index}; }`);
    const broken = ['// irx-fake: error', '#include <stdlib.h>', '', ...filler, '', 'int distance(int from, int to) {',
      '  return abss(to - from);', '}', '', ...filler.map(line => line.replace('filler_', 'more_')), '',
      'int gap(int from, int to) {', '  int difference = to - from;', '  return abss(difference);', '}', ''].join('\n');
    const brokenFile = join(writtenSources, 'broken.c');
    await writeFile(brokenFile, broken);
    const lineOf = text => broken.split('\n').indexOf(text) + 1;
    const [first, second] = [lineOf('  return abss(to - from);'), lineOf('  return abss(difference);')];
    await chooseFile('#program-upload', brokenFile);
    await until(`document.querySelector('#program-card')?.innerText.includes('broken.c could not be opened')`);

    await check('The failure card replaces the earlier comparison: no panels, no comparison, no program open',
      `${visible('#program-card')} && !${visible('#left-panel')} && !${visible('#right-panel')} && !${visible('.comparison-status')} && !appState.programId && !appState.exampleId`);
    await check('The failed upload is not added to Your file',
      `[...document.querySelectorAll('#your-file-select option')].filter(option => option.value).map(option => option.textContent).join('|') === 'score.c'`);
    await check('The failed source is shown with its failing lines marked',
      `document.querySelector('#source-summary').textContent === 'C source · broken.c' && [...document.querySelectorAll('#source-lines .source-line.is-error')].map(line => Number(line.dataset.line)).join(',') === '${first},${second}'`);
    await check('Each diagnostic in the file is a button reading "Line L, column C: message"',
      `(() => { const buttons = [...document.querySelectorAll('#program-card .program-diagnostics button')].map(button => button.textContent); return buttons.length === 4 && buttons[0] === "Line ${first}, column 10: call to undeclared function 'abss'; ISO C99 and later do not support implicit function declarations [-Wimplicit-function-declaration]" && buttons[1] === "Line ${first}, column 10: did you mean 'abs'?" && buttons[2].startsWith('Line ${second}, column 10: '); })()`);
    await check('A diagnostic in a system header is listed with its path, not as a button',
      `[...document.querySelectorAll('#program-card .program-diagnostics li:not(:has(button))')].some(item => item.textContent.includes("/usr/include/stdlib.h, line 980, column 12: 'abs' declared here"))`);
    const secondLine = `document.querySelector('#source-lines .source-line[data-line="${second}"]')`;
    const inView = `(() => { const viewer = document.querySelector('#source-lines').getBoundingClientRect(), line = ${secondLine}.getBoundingClientRect(); return line.top >= viewer.top && line.bottom <= viewer.bottom; })()`;
    await check('The second failing line starts out of view', `!${inView}`);
    await value(`[...document.querySelectorAll('#program-card .program-diagnostics button')].find(button => button.textContent.startsWith('Line ${second},')).click()`);
    await check('A diagnostic button scrolls to its line and outlines it, and only it',
      `${inView} && ${secondLine}.classList.contains('is-outlined') && document.querySelectorAll('#source-lines .is-outlined').length === 1 && getComputedStyle(${secondLine}).outlineStyle !== 'none'`);
    await check("clang's full output is in a closed Full compiler output disclosure",
      `(() => { const details = document.querySelector('#program-card details.program-output'); return Boolean(details) && !details.open && details.querySelector('summary').textContent === 'Full compiler output' && details.querySelector('pre').textContent.startsWith('broken.c:${first}:10: error: ') && details.querySelector('pre').textContent.includes('2 errors generated.'); })()`);
    await check('Choose another file… is offered', `[...document.querySelectorAll('#program-card button')].some(button => button.textContent === 'Choose another file…')`);
    await snap('user-programs-compile-error.png');

    const crashFile = join(writtenSources, 'crash.c');
    await writeFile(crashFile, '// irx-fake: crash\nint answer(void) { return 42; }\n');
    await chooseFile('#program-card .program-actions button', crashFile);
    await until(`document.querySelector('#program-card')?.innerText.includes('crash.c could not be opened')`);
    await check('An opt failure lists no diagnostics and marks no lines, only its output',
      `!document.querySelector('#program-card .program-diagnostics') && !document.querySelector('#source-lines .is-error, #source-lines .is-outlined') && document.querySelector('#program-card details.program-output pre').textContent.includes('Stack dump:')`);
  },

  async "Clang's warnings on an uploaded program are listed, collapsed, above the source, and marked on their lines"() {
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', join(userProgramSources, 'clang_warnings.c'));
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    // The recorded clang 22 printed 22 warnings for clang_warnings.c, some with notes; the server answers the first 20.
    const warned = [7, 17, 24, 28, 33, 39, 47, 52, 58, 62, 69, 73, 74, 80, 81, 88, 89, 102, 103];
    await check('The warnings are listed in a closed disclosure at the top of the source panel, above the source lines',
      `(() => { const warnings = document.querySelector('#program-warnings'); return ${visible('#program-warnings')} && warnings.matches('#source-panel > details') && !warnings.open && warnings.compareDocumentPosition(document.querySelector('#source-lines')) & Node.DOCUMENT_POSITION_FOLLOWING && document.querySelector('.source-heading').compareDocumentPosition(warnings) & Node.DOCUMENT_POSITION_FOLLOWING; })()`);
    await check('Its summary counts the warnings and says at most 20 are listed',
      `document.querySelector('#program-warnings summary').textContent === '20 clang warnings · at most 20 are listed'`);
    await check('The comparison stays open beside the warnings', `${visible('#left-panel')} && ${visible('.comparison-status')}`);
    await check('Each line with a warning is marked in the source, and no other',
      `[...document.querySelectorAll('#source-lines .source-line.is-warning')].map(line => Number(line.dataset.line)).join(',') === '${warned.join(',')}'`);
    await check('The opened program is announced with its warnings', `/^clang_warnings\\.c is ready\\..* Clang reported 20 warnings, listed above the source\\.$/.test(document.querySelector('#notice').textContent)`);
    await click('#program-warnings summary');
    await check('The warnings are a labelled list of 20, one button each reading "Line L, column C: message", with no notes',
      `(() => { const list = document.querySelector('#program-warnings ul'), buttons = [...list.querySelectorAll('li[data-severity="warning"] button')].map(button => button.textContent); return ${visible('#program-warnings ul')} && list.getAttribute('aria-label') === 'Clang warnings' && list.children.length === 20 && buttons.length === 20 && buttons[0] === 'Line 7, column 16: using the result of an assignment as a condition without parentheses [-Wparentheses]' && buttons[19] === 'Line 103, column 18: equality comparison result unused [-Wunused-comparison]' && !list.textContent.includes('place parentheses'); })()`);
    const lastLine = `document.querySelector('#source-lines .source-line[data-line="103"]')`;
    const inView = `(() => { const viewer = document.querySelector('#source-lines').getBoundingClientRect(), line = ${lastLine}.getBoundingClientRect(); return line.top >= viewer.top && line.bottom <= viewer.bottom; })()`;
    await check('The last warned line starts out of view', `!${inView}`);
    await value(`[...document.querySelectorAll('#program-warnings button')].at(-1).click()`);
    await check('A warning button scrolls to its line and outlines it, and only it',
      `${inView} && ${lastLine}.classList.contains('is-outlined') && document.querySelectorAll('#source-lines .is-outlined').length === 1`);
    await snap('user-programs-warnings.png');
    const warningsId = await value('appState.programId');

    await chooseFile('#program-upload', join(curatedSources, 'score.c'));
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(warningsId)}`);
    await check('A program that compiles cleanly shows no warnings and marks no lines',
      `!${visible('#program-warnings')} && !document.querySelector('#source-lines .is-warning') && !document.querySelector('#notice').textContent.includes('warning')`);
    await select('#your-file-select', warningsId);
    await until(`window.StudyWorkspace.ready && appState.programId === ${JSON.stringify(warningsId)}`);
    await check('Reopening the warned upload lists its warnings again, collapsed, and marks their lines',
      `${visible('#program-warnings')} && !document.querySelector('#program-warnings').open && document.querySelectorAll('#source-lines .source-line.is-warning').length === ${warned.length}`);
    await click('#program-new');
    await until(visible('#program-editor'));
    await check('Writing a new program shows no warnings beside it, as nothing of it is compiled yet', `!${visible('#program-warnings')}`);
    await click('#program-editor-discard');
    await until(`!document.querySelector('#program-editor')`);
    await check('Closing the editor lists the open upload\'s warnings again', visible('#program-warnings'));
    await click('#source-mode input[value="curated"]');
    await check('Curated examples shows no warnings', `!${visible('#program-warnings')} && !document.querySelector('#source-lines .is-warning')`);
  },

  async 'A program irexplorer cannot show says why, with the parser message for a parser failure'() {
    await upload('score.c');
    await check('An earlier comparison is open before the unsupported upload', `${visible('#left-panel')} && ${visible('.comparison-status')}`);
    // Recorded from the real toolchain (tests/data/user-programs): a computed goto compiles to indirectbr.
    await chooseFile('#program-upload', join(userProgramSources, 'computed_goto.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('computed_goto.c could not be opened')`);
    await check('The unsupported card replaces the comparison and opens no program',
      `${visible('#program-card')} && !${visible('#left-panel')} && !${visible('.comparison-status')} && !appState.programId && !appState.exampleId`);
    await check("The card says what irexplorer can't display, with no compiler output, diagnostics or parser message",
      `document.querySelector('#program-card .program-failure-message').textContent === "This program uses a computed goto (goto *pointer), which compiles to LLVM's indirectbr. irexplorer can't display indirectbr control flow." && !document.querySelector('#program-card details') && !document.querySelector('#program-card .program-diagnostics') && !document.querySelector('#source-lines .is-error')`);
    await check('It offers Choose another file… and no Try again',
      `[...document.querySelectorAll('#program-card button')].map(button => button.textContent).join('|') === 'Choose another file…'`);
    await check('The unsupported upload is not added to Your file', `${uploadOptions}.join('|') === 'score.c'`);
    await snap('user-programs-unsupported.png');

    // A function LLVM names in quotes, which the parser cannot read: a generic failure with the parser's message.
    await chooseFile('#program-card .program-actions button', join(userProgramSources, 'non_ascii_name.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('non_ascii_name.c could not be opened')`);
    await check("A parser failure says irexplorer can't display the program",
      `document.querySelector('#program-card .program-failure-message').textContent === "irexplorer can't display this program."`);
    await check("The parser's message is in a closed Parser message disclosure",
      `(() => { const details = document.querySelectorAll('#program-card details'); return details.length === 1 && details[0].matches('.program-parser-message') && !details[0].open && details[0].querySelector('summary').textContent === 'Parser message' && details[0].querySelector('pre').textContent.startsWith('unrecognised function definition at line 7: define dso_local i32 @"caf\\\\C3\\\\A9_total"('); })()`);
    await check('Choose another file… is offered, and the failed upload is not added to Your file',
      `[...document.querySelectorAll('#program-card button')].map(button => button.textContent).join('|') === 'Choose another file…' && ${uploadOptions}.join('|') === 'score.c'`);
    await value(`document.querySelector('#program-card details.program-parser-message').open = true`);
    await snap('user-programs-parser-message.png');
  },

  async 'Uploads survive a reload in this tab, and a fresh tab starts on Curated examples'() {
    await upload('score.c');
    await upload('binary_search.c');
    await reload();
    await check('After a reload the uploads are listed, oldest first', `JSON.stringify(${uploadOptions}) === '["score.c","binary_search.c"]'`);
    await check('After a reload with uploads the page opens in Your files', `document.querySelector('#source-mode input[value="yours"]').checked && ${visible('#your-file-select')} && !${visible('#example-select')}`);
    await check('After a reload nothing reopens by itself',
      `!appState.programId && !appState.exampleId && document.querySelector('#your-file-select').value === '' && ${visible('#program-drop')} && !${visible('#program-card')} && !${visible('#left-panel')}`);
    await snap('user-programs-reloaded.png');
    const fresh = await inFreshTab(`document.querySelector('#source-mode') !== null`,
      `({ curated: document.querySelector('#source-mode input[value="curated"]').checked, uploads: ${uploadOptions} })`);
    if (!fresh.curated || fresh.uploads.length) throw Error(`Failed: a fresh tab starts in Curated examples with an empty list; observed=${JSON.stringify(fresh)}`);
    checks.push('A fresh tab starts in Curated examples with an empty list');
  },

  async 'A program the server forgot is recompiled from the source this tab kept'() {
    await upload('score.c');
    const programId = await value('appState.programId');
    await reload();
    await restartServer();
    await holdCompiles(true);
    const from = responses.length, before = posts();
    await select('#your-file-select', programId);
    await until(`document.querySelector('#program-card')?.innerText.includes('Recompiling score.c')`);
    await check('The card says the server no longer had the program and replaces the panels',
      `${visible('#program-card')} && /no longer had/.test(document.querySelector('#program-card').innerText) && !${visible('#left-panel')} && document.querySelector('#workspace-shell').getAttribute('aria-busy') === 'true'`);
    await snap('user-programs-recompiling.png');
    await releaseCompile();
    await holdCompiles(false);
    await until(`window.StudyWorkspace.ready && appState.programId === ${JSON.stringify(programId)} && !${visible('#program-card')}`);
    await check('The program opens again with its panels and comparison', `${visible('#left-panel')} && ${visible('.comparison-status')} && document.querySelectorAll('#left-viewer .ir-line').length > 0 && ${visible('#program-chip')}`);
    const forgotten = responses.slice(from).filter(response => response.status === 404 && response.path.startsWith(`/api/programs/${programId}/`));
    await check('Parallel requests found the program gone and shared one recompile: one POST /api/programs',
      `${forgotten.length >= 2 && posts() - before === 1}`);

    await restartServer();
    const postsBeforeChange = posts();
    await select('#right-state', '3');
    await until(`window.StudyWorkspace.ready && document.querySelector('#right-state').value === '3' && !${visible('#program-card')}`);
    await check('A program forgotten while it is open is recompiled when a panel changes, and the panels come back',
      `${posts() - postsBeforeChange === 1} && ${visible('#left-panel')} && ${visible('#right-panel')} && ${visible('.comparison-status')} && !${visible('#empty-state')} && document.querySelectorAll('#right-viewer .ir-line').length > 0`);
  },
  async 'Cancel stops a recompile, keeps the upload and offers Try again'() {
    // The fake clang spends a couple of seconds on a slow-marked source, which leaves time to cancel its recompile.
    const slowFile = join(writtenSources, 'slow_score.c');
    await writeFile(slowFile, await readFile(join(curatedSources, 'score.c'), 'utf8') + '// irx-fake: slow\n');
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', slowFile);
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    const programId = await value('appState.programId');
    await reload();
    await restartServer();
    await select('#your-file-select', programId);
    await until(`document.querySelector('#program-card')?.innerText.includes('Recompiling slow_score.c')`);
    await check('The recompile card offers Cancel', `${cardButtons} === 'Cancel'`);
    await cardButton('Cancel');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling cancelled')`);
    await check('A cancelled recompile closes the program, shows its kept source and offers Try again and Choose another file…',
      `${cardButtons} === 'Try again|Choose another file…' && !appState.programId && document.querySelector('#source-summary').textContent === 'C source · slow_score.c' && document.querySelector('#workspace-shell').getAttribute('aria-busy') !== 'true' && !document.querySelector('#your-file-select').disabled`);
    await check('The upload stays in Your file, and no error replaces the card', `${uploadOptions}.join('|') === 'slow_score.c' && !document.querySelector('.error-state')`);

    const before = posts();
    await cardButton('Try again');
    await until(`window.StudyWorkspace.ready && appState.programId === ${JSON.stringify(programId)} && !${visible('#program-card')}`);
    await check('Try again compiles the kept source and opens the program', `${posts() - before === 1} && ${visible('#left-panel')} && ${visible('#program-chip')}`);
  },

  async 'Drop a C file onto the C source panel in Your files and explore it as a user program'() {
    const before = posts();
    await dropFile('#source-panel', join(curatedSources, 'score.c'));
    await pause(300);
    await check('Dropping a file in Curated examples does nothing: no compile and the page stays',
      `${posts() === before} && location.hash === '#/explore' && !${visible('#program-card')} && document.querySelector('#source-mode input[value="curated"]').checked`);

    await click('#source-mode input[value="yours"]');
    await check('With no user program open the source lines area reads "Drop a .c file here" and offers Write or paste a program',
      `(() => { const drop = document.querySelector('#program-drop'), buttons = [...drop.querySelectorAll('button')].map(b => b.textContent); return ${visible('#program-drop')} && drop.querySelector('.program-drop-title').textContent === 'Drop a .c file here' && buttons.join('|') === 'Choose a file…|Write or paste a program'; })()`);
    await holdCompiles(true);
    await dropFile('#source-panel', join(curatedSources, 'binary_search.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling binary_search.c')`);
    await check('The dropped source is shown at once while it compiles', `document.querySelector('#source-summary').textContent === 'C source · binary_search.c' && document.querySelector('#source-lines').inert`);
    await check('New… is unavailable during a compile',
      `[...document.querySelectorAll('#program-new, #program-drop button')].every(control => control.disabled)`);
    await dropFile('#source-panel', join(curatedSources, 'quick_sort.c'));
    await pause(300);
    await check('Dropping another file during a compile is refused: the compile carries on',
      `document.querySelector('#program-card').innerText.includes('Compiling binary_search.c') && document.querySelector('#source-summary').textContent === 'C source · binary_search.c' && location.hash === '#/explore'`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent for the drops', `${posts() - before === 1}`);
    await check('The dropped file opens as a user program',
      `document.querySelector('#source-summary').textContent === 'C source · binary_search.c' && ${visible('#program-chip')} && /^[0-9a-f]{64}$/.test(appState.programId) && appState.exampleId === null && document.querySelectorAll('#left-viewer .ir-line').length > 0`);

    const programId = await value('appState.programId');
    await dropFile('#source-panel', join(curatedSources, 'quick_sort.c'));
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(programId)}`);
    await check('Dropping onto the panel with a user program open opens the new file, and both are listed',
      `document.querySelector('#source-summary').textContent === 'C source · quick_sort.c' && [...document.querySelector('#your-file-select').options].filter(option => option.value).map(option => option.textContent).join('|') === 'binary_search.c|quick_sort.c'`);
  },

  async 'New… opens the editor on a starter function, and Compile opens it as a new program'() {
    const starter = await readFile(join(userProgramSources, 'program.c'), 'utf8');
    await click('#source-mode input[value="yours"]');
    await check('Your files offers New… after Upload…, and no paste box',
      `${visible('#program-new')} && document.querySelector('#program-new').textContent === 'New…' && Boolean(document.querySelector('#program-upload').compareDocumentPosition(document.querySelector('#program-new')) & Node.DOCUMENT_POSITION_FOLLOWING) && !document.querySelector('#program-paste-open, #program-paste')`);
    await check('The drop zone offers Write or paste a program beside Choose a file…',
      `[...document.querySelectorAll('#program-drop button')].map(button => button.textContent).join('|') === 'Choose a file…|Write or paste a program'`);
    await click('#program-new');
    await check('The editor stands in for the panels and the comparison, two columns wide',
      `(() => { const editor = document.querySelector('#program-editor').getBoundingClientRect(), source = document.querySelector('#source-panel').getBoundingClientRect(); return ${visible('#program-editor')} && !${visible('#left-panel')} && !${visible('#right-panel')} && !${visible('.comparison-status')} && !${visible('#empty-state')} && editor.left > source.right && editor.width > 1.8 * source.width && Math.abs(editor.top - source.top) < 1; })()`);
    await check('The source panel beside it is empty: no source lines and no drop zone',
      `!${visible('#source-lines')} && !${visible('#program-drop')} && !${visible('#source-prompt')} && document.querySelector('#source-summary').textContent === 'C source' && !${visible('#program-chip')}`);
    await check('Its heading reads New program and labels the editor, with a File name field of program.c',
      `(() => { const editor = document.querySelector('#program-editor'), heading = document.getElementById(editor.getAttribute('aria-labelledby')), name = document.querySelector('#program-editor-name'); return editor.tagName === 'SECTION' && heading.tagName === 'H2' && heading.textContent === 'New program' && name.value === 'program.c' && name.labels[0]?.textContent.trim().startsWith('File name'); })()`);
    await check('The editor holds the starter function, focused, and is labelled for screen readers',
      `(() => { const text = document.querySelector('#program-editor textarea'); return text.value === ${JSON.stringify(starter)} && document.activeElement === text && text.getAttribute('aria-label') === 'C source'; })()`);
    await check('The editor numbers its lines', `[...document.querySelectorAll('#program-editor .editor-gutter span')].map(span => span.textContent).join() === ${JSON.stringify(starter.split('\n').map((_, index) => index + 1).join())}`);
    await check('The editor highlights C as the source panel does, behind the text and aligned with the numbers',
      `(() => { const lines = [...document.querySelectorAll('#program-editor .editor-highlight > span')], numbers = [...document.querySelectorAll('#program-editor .editor-gutter span')]; return lines[0].querySelector('.c-token-comment')?.textContent.startsWith('// A new program') && lines[1].querySelector('.c-token-type')?.textContent === 'int' && lines[1].querySelector('.c-token-function')?.textContent === 'square' && lines[2].querySelector('.c-token-keyword')?.textContent === 'return' && document.querySelector('#program-editor .editor-highlight').getAttribute('aria-hidden') === 'true' && lines.every((line, index) => Math.abs(line.getBoundingClientRect().top - numbers[index].getBoundingClientRect().top) < 1); })()`);
    await check('The switch, both file selects, Upload… and New… are disabled while editing',
      `[...document.querySelectorAll('#source-mode input, #example-select, #your-file-select, #program-upload, #program-new')].every(control => control.disabled)`);
    await snap('user-programs-editor.png');
    await check('With no edits the editor offers Close editor', `document.querySelector('#program-editor-discard').textContent === 'Close editor'`);
    await click('#program-editor-discard');
    await check('Close editor closes at once, back to the drop zone with the controls enabled and New… focused',
      `!document.querySelector('#program-editor') && ${visible('#program-drop')} && !document.querySelector('#program-new').disabled && !document.querySelector('#program-upload').disabled && !document.querySelector('#source-mode input[value="curated"]').disabled && document.activeElement === document.querySelector('#program-new')`);

    await value(`[...document.querySelectorAll('#program-drop button')].find(button => button.textContent === 'Write or paste a program').click()`);
    await check('Write or paste a program opens the editor too, on the starter function', `${visible('#program-editor')} && document.querySelector('#program-editor textarea').value === ${JSON.stringify(starter)}`);
    await holdCompiles(true);
    const before = posts();
    await click('#program-editor-compile');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling program.c')`);
    await check('Compile closes the editor and shows the compiling card with Cancel, the source shown at once',
      `!document.querySelector('#program-editor') && ${visible('#program-card')} && ${cardButtons} === 'Cancel' && document.querySelector('#source-summary').textContent === 'C source · program.c' && document.querySelectorAll('#source-lines .source-line').length === ${starter.replace(/\n$/, '').split('\n').length}`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent', `${posts() - before === 1}`);
    await check('The new program opens in the panels and is listed as "program.c · new"',
      `document.querySelector('#source-summary').textContent === 'C source · program.c' && ${visible('#left-panel')} && document.querySelectorAll('#left-viewer .ir-line').length > 0 && ${uploadOptions}.join('|') === 'program.c · new' && document.querySelector('#your-file-select').selectedOptions[0].textContent === 'program.c · new'`);
  },

  async 'Ctrl+Enter compiles the editor under the name typed in File name'() {
    const starter = await readFile(join(userProgramSources, 'program.c'), 'utf8');
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await value(`(() => { const name = document.querySelector('#program-editor-name'); name.focus(); name.select(); })()`);
    await send('Input.insertText', { text: 'my_square.c' });
    await value(`document.querySelector('#program-editor textarea').focus()`);
    await holdCompiles(true);
    const before = posts();
    await key('Enter', 'Enter', 13, CTRL);
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling my_square.c')`);
    await check('Ctrl+Enter compiles with the compiling card and Cancel', `!document.querySelector('#program-editor') && ${cardButtons} === 'Cancel'`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent, for the starter unchanged', `${posts() - before === 1}`);
    await check('The program is compiled and listed under the name typed',
      `document.querySelector('#source-summary').textContent === 'C source · my_square.c' && ${uploadOptions}.join('|') === 'my_square.c · new'`);
    await check('The server holds the starter under that name',
      `fetch('/api/programs/' + appState.programId + '/source').then(r => r.json()).then(body => body.file === 'my_square.c' && body.text === ${JSON.stringify(starter)})`);
  },

  async 'Discard edits asks first, and brings back the program that was open'() {
    const quickSort = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    await upload('score.c');
    const programId = await value('appState.programId');
    await click('#program-new');
    await check('Over an open program, the editor hides the panels and leaves the source panel empty',
      `${visible('#program-editor')} && !${visible('#left-panel')} && !${visible('.comparison-status')} && !${visible('#source-lines')} && document.querySelector('#source-summary').textContent === 'C source' && !${visible('#program-chip')}`);
    await value(`document.querySelector('#program-editor textarea').select()`);
    await send('Input.insertText', { text: quickSort });
    await check('Source pasted into the editor replaces the starter, numbered and highlighted',
      `(() => { const lines = document.querySelectorAll('#program-editor .editor-highlight > span'); return document.querySelector('#program-editor textarea').value === ${JSON.stringify(quickSort)} && document.querySelectorAll('#program-editor .editor-gutter span').length === ${quickSort.split('\n').length} && lines.length === ${quickSort.split('\n').length}; })()`);
    await check('With edits the button reads Discard edits', `document.querySelector('#program-editor-discard').textContent === 'Discard edits'`);
    const posted = posts();
    await dropFile('#source-panel', join(curatedSources, 'binary_search.c'));
    await pause(300);
    await check('A file dropped while editing is refused: nothing is sent and the editor stays', `${posts() === posted} && ${visible('#program-editor')}`);

    await click('#program-editor-discard');
    await check('Discard edits asks for confirmation in the page, with Keep editing focused',
      `(() => { const confirmation = document.querySelector('#program-editor .program-editor-confirmation'); return ${visible('#program-editor .program-editor-confirmation')} && confirmation.getAttribute('role') === 'alert' && confirmation.textContent.includes('Discard your edits to program.c?') && [...confirmation.querySelectorAll('button')].map(button => button.textContent).join('|') === 'Keep editing|Discard edits' && document.activeElement?.textContent === 'Keep editing'; })()`);
    await snap('user-programs-editor-discard.png');
    await value(`[...document.querySelectorAll('#program-editor .program-editor-confirmation button')].find(button => button.textContent === 'Keep editing').click()`);
    await check('Keep editing keeps the edit and returns to the editor',
      `!${visible('#program-editor .program-editor-confirmation')} && document.querySelector('#program-editor textarea').value === ${JSON.stringify(quickSort)} && document.activeElement === document.querySelector('#program-editor textarea')`);
    await click('#program-editor-discard');
    await value(`[...document.querySelectorAll('#program-editor .program-editor-confirmation button')].find(button => button.textContent === 'Discard edits').click()`);
    await check('Discarding brings back the program that was open, its panels and its source',
      `!document.querySelector('#program-editor') && appState.programId === ${JSON.stringify(programId)} && window.StudyWorkspace.ready && ${visible('#left-panel')} && ${visible('.comparison-status')} && ${visible('#source-lines')} && document.querySelector('#source-summary').textContent === 'C source · score.c' && ${visible('#program-chip')}`);
    await check('The controls are enabled again, nothing was compiled and Your files is unchanged',
      `${posts() === posted} && ${uploadOptions}.join('|') === 'score.c' && [...document.querySelectorAll('#source-mode input, #your-file-select, #program-upload, #program-new')].every(control => !control.disabled)`);
  },

  async 'Edit a copy opens the editor on a copy of the curated example, beside the source that was compiled'() {
    const quickSort = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    await check('With no curated example open there is no Edit a copy', `!${visible('#program-edit')}`);
    await openCurated('quick_sort');
    await check('Edit a copy appears under the source controls once a curated example is open',
      `${visible('#program-edit')} && document.querySelector('#program-edit').textContent === 'Edit a copy' && document.querySelector('#program-edit').getBoundingClientRect().top >= document.querySelector('#function-select').getBoundingClientRect().bottom`);
    await check('The C source and both panels still start their code at the same height', alignedCode);
    await click('#program-edit');
    await check('Its heading names the curated example, with a File name field of the example\'s file',
      `document.querySelector('#program-editor-heading').textContent === 'Editing a copy of curated quick sort' && document.querySelector('#program-editor-name').value === 'quick_sort.c'`);
    await check('The editor holds the curated source, focused', `(() => { const text = document.querySelector('#program-editor textarea'); return text.value === ${JSON.stringify(quickSort)} && document.activeElement === text; })()`);
    await check('The editor stands in for the panels and the comparison', `${visible('#program-editor')} && !${visible('#left-panel')} && !${visible('#right-panel')} && !${visible('.comparison-status')}`);
    await check('The source panel beside it shows the compiled source, with a note saying it is what was compiled',
      `${visible('#source-lines')} && document.querySelector('#source-summary').textContent === 'C source · quick_sort.c' && document.querySelectorAll('#source-lines .source-line').length === ${quickSort.replace(/\n$/, '').split('\n').length} && ${visible('#program-source-note')} && document.querySelector('#program-source-note').textContent === ${JSON.stringify(SOURCE_NOTE)}`);
    await click('.source-line[data-line="4"]');
    await check('The compiled source is read-only beside the editor: a line clicked selects nothing', `!document.querySelector('#source-lines .is-source') && document.querySelector('#source-lines .source-line').disabled`);
    await check('Edit a copy is disabled with the file controls while editing',
      `[...document.querySelectorAll('#source-mode input, #example-select, #program-edit')].every(control => control.disabled)`);
    await snap('user-programs-edit-a-copy.png');
    await click('#program-editor-discard');
    await check('Close editor brings back the curated example, with Edit a copy focused',
      `!document.querySelector('#program-editor') && !${visible('#program-source-note')} && appState.exampleId === 'quick_sort' && window.StudyWorkspace.ready && ${visible('#left-panel')} && document.activeElement === document.querySelector('#program-edit') && !document.querySelector('#program-edit').disabled && !document.querySelector('#source-lines .source-line').disabled`);
  },

  async 'Edit opens the editor on one of your files, beside the source that was compiled'() {
    const quickSort = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    await upload('quick_sort.c');
    await check('Edit appears under the source controls when one of your files is open', `${visible('#program-edit')} && document.querySelector('#program-edit').textContent === 'Edit'`);
    await click('#program-edit');
    await check('Its heading names the file, with a File name field of the file',
      `document.querySelector('#program-editor-heading').textContent === 'Editing quick_sort.c' && document.querySelector('#program-editor-name').value === 'quick_sort.c' && document.querySelector('#program-editor textarea').value === ${JSON.stringify(quickSort)}`);
    await check('The source panel beside it shows the compiled source, with a note saying it is what was compiled',
      `${visible('#source-lines')} && document.querySelector('#source-summary').textContent === 'C source · quick_sort.c' && document.querySelectorAll('#source-lines .source-line').length === ${quickSort.replace(/\n$/, '').split('\n').length} && ${visible('#program-source-note')} && !${visible('#left-panel')}`);
    await check('Edit is disabled with the file controls while editing',
      `[...document.querySelectorAll('#source-mode input, #your-file-select, #program-upload, #program-new, #program-edit')].every(control => control.disabled)`);
  },

  async 'A compiled edit opens with both panels and the function as they were, the selection and trace cleared'() {
    const edited = await readFile(join(userProgramSources, 'quick_sort.c'), 'utf8');
    await openCurated('quick_sort');
    await choose('#function-select', 'partition');
    await choose('#left-state', '2');
    await choose('#left-view', 'cfg');
    await choose('#right-state', '9');
    await click('.source-line[data-line="4"]');
    await until(`Boolean(document.querySelector('#source-lines .is-source'))`);
    await check('Before the edit a C line is selected and traced into the panels', `document.querySelectorAll('#right-viewer .ir-line.is-source, #right-viewer .ir-line.is-linked').length > 0`);
    await click('#program-edit');
    await editorText(edited);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    await check('The compiled edit opens as quick_sort.c in Your files',
      `document.querySelector('#source-summary').textContent === 'C source · quick_sort.c' && document.querySelector('#source-mode input[value="yours"]').checked && ${visible('#program-chip')} && document.querySelector('#source-lines').textContent.includes('void sort(')`);
    await check('Both panels keep their states and views',
      `document.querySelector('#left-state').value === '2' && document.querySelector('#left-view').value === 'cfg' && document.querySelector('#right-state').value === '9' && document.querySelector('#right-view').value === 'ir' && ${visible('#left-viewer .cfg-svg')} && document.querySelectorAll('#right-viewer .ir-line').length > 0`);
    await check('The function that still exists stays chosen',
      `document.querySelector('#function-select').value === 'partition' && [...document.querySelector('#function-select').options].map(option => option.value).join('|') === 'sort|partition'`);
    await check('The source selection and trace are cleared',
      `!document.querySelector('#source-lines .is-source') && !document.querySelector('#left-viewer .is-source, #left-viewer .is-linked, #left-viewer .is-selected, #right-viewer .is-source, #right-viewer .is-linked, #right-viewer .is-selected')`);
    await click('.source-line[data-line="4"]');
    await until(`Boolean(document.querySelector('#source-lines .is-source'))`);
    await check('A C line of the edit links into its instructions', `document.querySelectorAll('#right-viewer .ir-line.is-source, #right-viewer .ir-line.is-linked').length > 0`);
  },

  async 'A compiled edit opens the default function when the chosen one is gone'() {
    const edited = await readFile(join(userProgramSources, 'quick_sort.c'), 'utf8');
    await upload('quick_sort.c');
    const uploaded = await value('appState.programId');
    await choose('#function-select', 'quick_sort');
    await choose('#right-state', '5');
    await click('#program-edit');
    await editorText(edited);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(uploaded)} && !${visible('#program-card')}`);
    await check('quick_sort is gone, so the edit opens on its first function, sort, with the states kept',
      `document.querySelector('#function-select').value === 'sort' && document.querySelector('#right-state').value === '5' && document.querySelector('#left-state').value === '0'`);
  },

  async 'A compile from Edit replaces the Your files entry it started from, and Open the original opens the first upload'() {
    const quickSort = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    const edited = await readFile(join(userProgramSources, 'quick_sort.c'), 'utf8');
    await upload('quick_sort.c');
    const uploaded = await value('appState.programId');
    await check('An upload is listed under its own name, with no line saying it was edited',
      `${uploadOptions}.join('|') === 'quick_sort.c' && !${visible('#program-origin')}`);
    await click('#program-edit');
    await editorText(edited);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(uploaded)} && !${visible('#program-card')}`);
    await check('The compiled edit replaces the upload in Your files, labelled "· edited" and selected',
      `${uploadOptions}.join('|') === 'quick_sort.c · edited' && document.querySelector('#your-file-select').value === appState.programId`);
    await check('A line under the controls says where the edit came from, with a way back to it',
      `(() => { const line = document.querySelector('#program-origin'); return ${visible('#program-origin')} && line.textContent === 'Edited from your upload quick_sort.c. Open the original' && line.querySelector('button')?.textContent === 'Open the original' && Boolean(document.querySelector('#source-panel > .source-heading').compareDocumentPosition(line) & Node.DOCUMENT_POSITION_FOLLOWING); })()`);
    await check('The C source and both panels still start their code at the same height', alignedCode);
    await snap('user-programs-edited.png');
    // A second compiled edit: the edited copy again, with a marker the fake toolchain strips before replaying it.
    const once = await value('appState.programId');
    await click('#program-edit');
    await check('Editing a compiled edit names the file it is listed as', `document.querySelector('#program-editor-heading').textContent === 'Editing quick_sort.c'`);
    await editorText(`${edited}// irx-fake: slow\n`);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(once)} && !${visible('#program-card')}`);
    await check('Another compiled edit replaces that entry again under the same name, with no suffix',
      `${uploadOptions}.join('|') === 'quick_sort.c · edited' && document.querySelector('#source-summary').textContent === 'C source · quick_sort.c' && !${visible('#program-renamed')}`);
    await check('It still came from the first upload', `document.querySelector('#program-origin').textContent === 'Edited from your upload quick_sort.c. Open the original'`);
    await value(`document.querySelector('#program-origin button').click()`);
    await until(`window.StudyWorkspace.ready && appState.programId === ${JSON.stringify(uploaded)} && !${visible('#program-card')}`);
    await check('Open the original opens the first upload, listed again as an upload', `document.querySelector('#source-lines').textContent.includes('void quick_sort(') && ${uploadOptions}.join('|') === 'quick_sort.c · edited|quick_sort.c' && !${visible('#program-origin')} && document.querySelector('#your-file-select').value === appState.programId`);
    await check('The original is the text first uploaded', `fetch('/api/programs/' + appState.programId + '/source').then(r => r.json()).then(body => body.text === ${JSON.stringify(quickSort)})`);
  },

  async 'Edit a copy and New… add to Your files, a name already listed getting a numbered suffix'() {
    const edited = await readFile(join(userProgramSources, 'quick_sort.c'), 'utf8');
    await openCurated('quick_sort');
    await click('#program-edit');
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    await check('A compiled copy of a curated example is added to Your files, labelled "· edited"', `${uploadOptions}.join('|') === 'quick_sort.c · edited'`);
    await check('A line under the controls says it came from the curated example', `document.querySelector('#program-origin').textContent === 'Edited from curated quick sort. Open the original'`);
    await value(`document.querySelector('#program-origin button').click()`);
    await until(`window.StudyWorkspace.ready && appState.exampleId === 'quick_sort'`);
    await check('Open the original opens the curated example under Curated examples',
      `document.querySelector('#source-mode input[value="curated"]').checked && document.querySelector('#example-select').value === 'quick_sort' && !appState.programId && !${visible('#program-origin')} && document.activeElement === document.querySelector('#example-select')`);

    await click('#program-edit');
    await check('A second copy starts under the example\'s file name too', `document.querySelector('#program-editor-name').value === 'quick_sort.c'`);
    await editorText(edited);
    await click('#program-editor-compile');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling quick_sort_2_.c')`);
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    await check('It is added beside the first copy, never replacing it, under a numbered name',
      `${uploadOptions}.join('|') === 'quick_sort.c · edited|quick_sort_2_.c · edited' && document.querySelector('#source-summary').textContent === 'C source · quick_sort_2_.c'`);
    await check('The numbered name, made safe, is the one the compiler saw', `fetch('/api/programs/' + appState.programId + '/source').then(r => r.json()).then(body => body.file === 'quick_sort_2_.c' && body.text === ${JSON.stringify(edited)})`);
    await check('The source panel says the name was renamed from the numbered one', `document.querySelector('#program-renamed').textContent === 'Renamed from “quick_sort (2).c”.'`);

    await click('#program-new');
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && document.querySelector('#source-summary').textContent === 'C source · program.c' && !${visible('#program-card')}`);
    await check('A new program is added, labelled "· new", with no line about an original',
      `${uploadOptions}.join('|') === 'quick_sort.c · edited|quick_sort_2_.c · edited|program.c · new' && !${visible('#program-origin')}`);
    await click('#program-new');
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && document.querySelector('#source-summary').textContent === 'C source · program_2_.c' && !${visible('#program-card')}`);
    await check('Another new program under a name already listed is added with a numbered suffix',
      `${uploadOptions}.join('|') === 'quick_sort.c · edited|quick_sort_2_.c · edited|program.c · new|program_2_.c · new'`);
  },

  async 'Restore original puts back the curated text after several compiled edits, and undo reverses it'() {
    const quickSort = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    const edited = await readFile(join(userProgramSources, 'quick_sort.c'), 'utf8');
    const twice = `${edited}// irx-fake: slow\n`;
    await openCurated('quick_sort');
    await click('#program-edit');
    await check('Restore original is offered, and disabled while the text is the original',
      `${visible('#program-editor-restore')} && document.querySelector('#program-editor-restore').textContent === 'Restore original' && document.querySelector('#program-editor-restore').disabled`);
    await editorText(edited);
    await check('Restore original is enabled once the text differs from the original', `!document.querySelector('#program-editor-restore').disabled`);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && !${visible('#program-card')}`);
    const once = await value('appState.programId');
    await click('#program-edit');
    await editorText(twice);
    await click('#program-editor-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(once)} && !${visible('#program-card')}`);
    await check('Two compiled edits later, one entry is listed', `${uploadOptions}.join('|') === 'quick_sort.c · edited'`);
    await click('#program-edit');
    await check('The editor opens on the last compiled edit', `document.querySelector('#program-editor textarea').value === ${JSON.stringify(twice)}`);
    await click('#program-editor-restore');
    await check('Restore original puts back the curated example\'s text, with the editor focused',
      `document.querySelector('#program-editor textarea').value === ${JSON.stringify(quickSort)} && document.activeElement === document.querySelector('#program-editor textarea') && document.querySelector('#program-editor-restore').disabled`);
    await check('The restored text counts as an edit of the compiled source', `document.querySelector('#program-editor .editor-status').textContent.startsWith('Edited · not compiled · ') && document.querySelector('#program-editor-discard').textContent === 'Discard edits'`);
    await check('Restoring is announced, with the way to undo it', `document.querySelector('#notice').textContent.includes('Restored the original') && document.querySelector('#notice').textContent.includes('undo')`);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undo reverses Restore original', `document.querySelector('#program-editor textarea').value === ${JSON.stringify(twice)} && !document.querySelector('#program-editor-restore').disabled`);
  },

  async 'A new program has no original to restore'() {
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await check('Restore original is not offered for a new program', `!${visible('#program-editor-restore')}`);
  },

  async 'In the editor Tab indents, Shift+Tab outdents, Enter keeps the indent, and undo steps back through them'() {
    const starter = await readFile(join(userProgramSources, 'program.c'), 'utf8');
    const lines = starter.split('\n');
    const editor = `document.querySelector('#program-editor textarea')`;
    // The editor's text, and its selection as [start, end].
    const text = () => value(`${editor}.value`);
    const selection = () => value(`[${editor}.selectionStart, ${editor}.selectionEnd]`);
    const at = (line, column) => lines.slice(0, line - 1).join('\n').length + (line > 1 ? 1 : 0) + column;
    const caret = (start, end = start) => value(`${editor}.setSelectionRange(${start}, ${end})`);
    const edited = (...changed) => lines.map((line, index) => changed[index] ?? line).join('\n');
    await click('#source-mode input[value="yours"]');
    await click('#program-new');

    await caret(at(3, 6));
    await key('Tab', 'Tab', 9);
    await check('Tab indents the line the caret is on by four spaces, and the caret moves with its text',
      `${editor}.value === ${JSON.stringify(edited(undefined, undefined, '        return x * x;'))} && ${editor}.selectionStart === ${at(3, 10)} && document.activeElement === ${editor}`);
    await key('Tab', 'Tab', 9, SHIFT);
    await check('Shift+Tab outdents it again', `${editor}.value === ${JSON.stringify(starter)} && ${editor}.selectionStart === ${at(3, 6)}`);
    await key('Tab', 'Tab', 9, SHIFT);
    await check('Shift+Tab again takes off the indent the line had', `${editor}.value === ${JSON.stringify(edited(undefined, undefined, 'return x * x;'))} && ${editor}.selectionStart === ${at(3, 2)}`);
    await key('Tab', 'Tab', 9, SHIFT);
    await check('Shift+Tab on a line with no indent changes nothing', `${editor}.value === ${JSON.stringify(edited(undefined, undefined, 'return x * x;'))}`);
    await key('Tab', 'Tab', 9);
    await check('Tab puts that indent back', `${editor}.value === ${JSON.stringify(starter)}`);

    await caret(at(2, 4), at(4, 1));
    await key('Tab', 'Tab', 9);
    await check('Tab indents every line of a selection, which still covers them',
      `${editor}.value === ${JSON.stringify(edited(undefined, '    int square(int x) {', '        return x * x;', '    }'))} && ${editor}.selectionStart === ${at(2, 0)} && ${editor}.selectionEnd === ${at(4, 1) + 12}`);
    await key('Tab', 'Tab', 9, SHIFT);
    await key('Tab', 'Tab', 9, SHIFT);
    await check('Shift+Tab outdents every line of a selection, each by what indent it has',
      `${editor}.value === ${JSON.stringify(edited(undefined, undefined, 'return x * x;'))}`);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undo reverses the last outdent', `${editor}.value === ${JSON.stringify(starter)}`);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undo again reverses the outdent before it, back to the indented selection',
      `${editor}.value === ${JSON.stringify(edited(undefined, '    int square(int x) {', '        return x * x;', '    }'))}`);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undo reverses the indent made with Tab', `${editor}.value === ${JSON.stringify(starter)}`);

    await caret(at(3, lines[2].length));
    await key('Enter', 'Enter', 13);
    await send('Input.insertText', { text: 'x = 1;' });
    await check('Enter starts a new line with the same indent as the line it splits',
      `${editor}.value === ${JSON.stringify(starter.replace('x * x;\n', 'x * x;\n    x = 1;\n'))} && ${editor}.selectionStart === ${at(4, 10)}`);
    await key('z', 'KeyZ', 90, CTRL);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undo steps back through the typing and the new line', `${editor}.value === ${JSON.stringify(starter)}`);
  },

  async 'Esc releases Tab, so the next Tab leaves the editor'() {
    const starter = await readFile(join(userProgramSources, 'program.c'), 'utf8');
    const editor = `document.querySelector('#program-editor textarea')`;
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await value(`${editor}.setSelectionRange(0, 0)`);
    await key('Escape', 'Escape', 27);
    await key('ArrowRight', 'ArrowRight', 39);
    await key('Tab', 'Tab', 9);
    await check('A key between Esc and Tab takes the release back: Tab still indents', `${editor}.value === '    ' + ${JSON.stringify(starter)} && document.activeElement === ${editor}`);
    await key('z', 'KeyZ', 90, CTRL);
    await key('Escape', 'Escape', 27);
    await check('Esc changes nothing in the editor and keeps it open', `${editor}.value === ${JSON.stringify(starter)} && ${visible('#program-editor')} && document.activeElement === ${editor}`);
    await key('Tab', 'Tab', 9);
    await check('Tab after Esc leaves the editor, and the text is unchanged', `document.activeElement !== ${editor} && ${editor}.value === ${JSON.stringify(starter)}`);
    await value(`${editor}.focus()`);
    await key('Escape', 'Escape', 27);
    await key('Tab', 'Tab', 9, SHIFT);
    await check('Shift+Tab after Esc leaves it backwards, to File name and the buttons', `document.activeElement !== ${editor} && document.querySelector('#program-editor').contains(document.activeElement) && ${editor}.value === ${JSON.stringify(starter)}`);
    await value(`${editor}.focus()`);
    await key('Tab', 'Tab', 9);
    await check('Back in the editor, Tab indents again', `${editor}.value.startsWith('    ') && document.activeElement === ${editor}`);
  },

  async 'The hint under the editor gives the keys and counts lines against the 200-line limit'() {
    const editor = `document.querySelector('#program-editor textarea')`;
    const hint = `document.querySelector('#program-editor .editor-hint')`;
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await check('A hint under the editor gives the keys, and the editor is described by it',
      `(() => { const text = ${hint}.textContent; return ${visible('#program-editor .editor-hint')} && Boolean(${editor}.compareDocumentPosition(${hint}) & Node.DOCUMENT_POSITION_FOLLOWING) && ${editor}.getAttribute('aria-describedby').split(' ').includes(${hint}.id) && ['Tab indents', 'Shift+Tab outdents', 'Enter keeps the indent', 'Esc, then Tab, leaves the editor', 'Ctrl/⌘+Enter compiles'].every(part => text.includes(part)); })()`);
    await check('It counts the starter function as 4 / 200 lines', `${hint}.textContent.endsWith('4 / 200 lines') && !${hint}.classList.contains('is-over')`);
    await value(`${editor}.setSelectionRange(${editor}.value.length, ${editor}.value.length)`);
    await send('Input.insertText', { text: 'int cube(int x) {\n    return x * x * x;\n}\n' });
    await check('The count follows the lines added', `${hint}.textContent.endsWith('7 / 200 lines')`);
    await value(`${editor}.select()`);
    await send('Input.insertText', { text: 'int x;\n'.repeat(201) });
    await check('Over the limit the count says so, apart from colour', `${hint}.textContent.endsWith('201 / 200 lines: too many to compile') && ${hint}.classList.contains('is-over')`);
  },

  async 'The margin marks new or changed lines, and the status line counts them'() {
    const starter = await readFile(join(userProgramSources, 'program.c'), 'utf8');
    const editor = `document.querySelector('#program-editor textarea')`;
    const status = `document.querySelector('#program-editor .editor-status')`;
    // The line numbers the margin marks as new or changed.
    const marked = `[...document.querySelectorAll('#program-editor .editor-gutter span.is-changed')].map(span => span.textContent).join()`;
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await check('For a new program every line is new: the margin marks the four lines of the starter', `${marked} === '1,2,3,4'`);
    await check('With no edits there is no status line', `!${visible('#program-editor .editor-status')} && ${status}.textContent === ''`);
    await value(`${editor}.setSelectionRange(${editor}.value.length, ${editor}.value.length)`);
    await send('Input.insertText', { text: 'int cube(int x) {\n    return x * x * x;\n}\n' });
    await check('After an edit the status line reads Edited · not compiled, counting the lines the margin marks',
      `${visible('#program-editor .editor-status')} && ${status}.textContent === 'Edited · not compiled · 7 lines new or changed' && ${marked} === '1,2,3,4,5,6,7'`);
    await snap('user-programs-editor-edited.png');
    await check('The status line is announced to screen readers, and sits above the editor',
      `${status}.getAttribute('role') === 'status' && Boolean(${status}.compareDocumentPosition(${editor}) & Node.DOCUMENT_POSITION_FOLLOWING)`);
    await key('z', 'KeyZ', 90, CTRL);
    await check('Undoing back to the starter clears the status line', `${editor}.value === ${JSON.stringify(starter)} && ${status}.textContent === '' && ${marked} === '1,2,3,4'`);

    // An edit that starts from compiled source, as Edit a copy does, is marked against that source.
    const compiled = await readFile(join(curatedSources, 'quick_sort.c'), 'utf8');
    await click('#program-editor-discard');
    await click('#source-mode input[value="curated"]');
    await openCurated('quick_sort');
    await click('#program-edit');
    await check('Unedited compiled source has no lines marked and no status line', `${marked} === '' && ${status}.textContent === ''`);
    await value(`(() => { const at = ${editor}.value.indexOf('a[high];'); ${editor}.focus(); ${editor}.setSelectionRange(at + 2, at + 6); })()`);
    await send('Input.insertText', { text: 'low' });
    await value(`${editor}.setSelectionRange(${compiled.indexOf('\n\n') + 1}, ${compiled.indexOf('\n\n') + 1})`);
    await send('Input.insertText', { text: '// a comment\n' });
    await check('A changed line and an inserted line are marked, and only they are counted',
      `${editor}.value === ${JSON.stringify(compiled.replace('\n\n', '\n// a comment\n\n').replace('a[high];', 'a[low];'))} && ${marked} === '2,5' && ${status}.textContent === 'Edited · not compiled · 2 lines new or changed'`);
    await value(`(() => { const at = ${editor}.value.indexOf('// a comment'); ${editor}.setSelectionRange(at, at + 13); })()`);
    await key('Delete', 'Delete', 46);
    await check('A deleted line is not counted: one line is changed', `${marked} === '4' && ${status}.textContent === 'Edited · not compiled · 1 line new or changed'`);
  },

  async 'Leaving Explore closes the editor, and Study never shows it'() {
    await click('#source-mode input[value="yours"]');
    await click('#program-new');
    await send('Input.insertText', { text: '// an edit\n' });
    await value(`location.hash = '/study'`);
    await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
    await check('Study shows no editor and no New…, and the curated source panel', `${noProgramControls} && ${curatedSourcePanel}`);
    await value(`location.hash = '/explore'`);
    await until(`document.querySelector('#source-mode') !== null`);
    await check('Back in Explore the editor is closed, on Curated examples', `!document.querySelector('#program-editor') && document.querySelector('#source-mode input[value="curated"]').checked && ${visible('#example-select')}`);
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
    await check('The tab keeps the upload in session storage', `JSON.parse(sessionStorage.getItem('irexplorer.programs.uploads')).length === 1`);
    await value(`history.replaceState(null, '', '/#/study')`); await send('Page.reload');
    await until(`document.readyState === 'complete' && document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
    await until(`document.querySelectorAll('#example-select option').length === ${curatedExamples.length + 1}`);
    await pause(500);
    await check('A page loaded on #/study with uploads in the tab never builds them', `${noProgramControls} && ${curatedSourcePanel}`);
    await value(`location.hash = '/explore'`);
    await until(`document.querySelector('#source-mode') !== null`);
    await check('Explore then opens on Your files, as a tab with uploads does', `document.querySelector('#source-mode input[value="yours"]').checked && !${visible('#example-select')}`);
    await value(`location.hash = '/study'`);
    await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
    await check('Leaving Your files with uploads for #/study still leaves the curated source panel', `${noProgramControls} && ${curatedSourcePanel}`);
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
    await check('A file dragged over the task\'s source panel is left to the browser, as before',
      `(() => { const files = new DataTransfer(); files.items.add(new File(['int main(void) { return 0; }'], 'program.c')); return ['dragover', 'drop'].every(type => { const event = new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer: files }); document.querySelector('#source-lines').dispatchEvent(event); return !event.defaultPrevented; }) && !document.querySelector('#source-panel').classList.contains('is-drop-target') && !appState.programId; })()`);
    const entered = await value(studySurface);
    await send('Page.reload');
    await onTask('T6');
    await check('A page loaded on the task never builds the controls', noProgramControls);
    await check('The task looks exactly as on a page that never built them', `${JSON.stringify(entered)} === ${studySurface}`);
  },

  async 'A busy compiler is reported with Try again, which compiles the file once the other compile is over'() {
    const slow = postElsewhere('slow.c', await readFile(join(curatedSources, 'score.c'), 'utf8') + '// irx-fake: slow\n');
    await pause(300);
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', await renamedCopy('score', 'busy_score.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('could not be opened')`);
    await check('The busy card shows the server\'s message, with Try again and Choose another file…',
      `(() => { const text = document.querySelector('#program-card').innerText; return text.includes('busy_score.c could not be opened') && text.includes('The compiler is busy with another program. Try again in a moment.') && ${cardButtons} === 'Try again|Choose another file…'; })()`);
    await check('The busy file is not added to Your file and the workbench is not busy',
      `${uploadOptions}.join('|') === '' && document.querySelector('#workspace-shell').getAttribute('aria-busy') !== 'true' && !appState.programId`);
    await snap('user-programs-busy.png');
    if ((await slow).status !== 201) throw Error(`Failed: the other compile finished; observed=${(await slow).status}`);

    const before = posts();
    await cardButton('Try again');
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Try again posts the same file once and opens it', `${posts() - before === 1} && !${visible('#program-card')} && document.querySelector('#source-summary').textContent === 'C source · busy_score.c'`);
    await check('Only the file that compiled is listed in Your file', `${uploadOptions}.join('|') === 'busy_score.c'`);
  },

  async 'An unavailable compiler is reported with Try again, which compiles the file once the compiler answers'() {
    const compiler = Number(process.env.IREXPLORER_COMPILER_PID);
    if (!compiler) throw Error('IREXPLORER_COMPILER_PID is not set');
    await click('#source-mode input[value="yours"]');
    // A paused compiler service accepts the connection and never answers, until the app gives up on it.
    process.kill(compiler, 'SIGSTOP');
    try {
      await chooseFile('#program-drop button', await renamedCopy('binary_search', 'unavailable_search.c'));
      await until(`document.querySelector('#program-card')?.innerText.includes('could not be opened')`);
    } finally {
      process.kill(compiler, 'SIGCONT');
    }
    await check('The unavailable card shows the server\'s message, with Try again and Choose another file…',
      `(() => { const text = document.querySelector('#program-card').innerText; return text.includes('unavailable_search.c could not be opened') && text.includes('The compiler service is unavailable.') && ${cardButtons} === 'Try again|Choose another file…'; })()`);
    await check('The unavailable file is not added to Your file', `${uploadOptions}.join('|') === '' && !appState.programId`);
    await snap('user-programs-unavailable.png');

    // The compiler finishes the request the app gave up on before it takes another.
    await compilerFree();
    await cardButton('Try again');
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Try again opens the file once the compiler answers', `!${visible('#program-card')} && document.querySelector('#source-summary').textContent === 'C source · unavailable_search.c' && ${uploadOptions}.join('|') === 'unavailable_search.c'`);
  },

  async 'Cancel stops the compile, and another file uploaded at once compiles rather than finding the compiler busy'() {
    // The fake clang never finishes a source carrying the hang marker; only stopping the compile frees the compiler.
    const hangFile = join(writtenSources, 'hang.c');
    await writeFile(hangFile, 'int main(void) { return 0; }\n// irx-fake: hang\n');
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', hangFile);
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling hang.c')`);
    await check('The compile card offers Cancel', `${cardButtons} === 'Cancel'`);
    await cardButton('Cancel');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling cancelled')`);
    await check('The cancelled card offers Try again and Choose another file…, with the cancelled source still shown',
      `${cardButtons} === 'Try again|Choose another file…' && document.querySelector('#source-summary').textContent === 'C source · hang.c' && document.querySelector('#workspace-shell').getAttribute('aria-busy') !== 'true'`);
    await check('The cancelled file is not added to Your file', `${uploadOptions}.join('|') === '' && !appState.programId`);
    await snap('user-programs-cancelled.png');

    const before = posts();
    await cardButton('Try again');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling hang.c')`);
    await check('Try again posts the cancelled file again', `${posts() - before === 1}`);
    await cardButton('Cancel');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling cancelled')`);

    const answered = responses.length;
    await chooseFile('#program-card .program-actions button:last-child', await renamedCopy('quick_sort', 'after_cancel.c'));
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) || document.querySelector('#program-card')?.innerText.includes('could not be opened')`);
    await check('The next file, uploaded at once, compiles: the compiler was not left busy',
      `${JSON.stringify(responses.slice(answered).filter(response => response.path === '/api/programs').map(response => response.status))}.join() === '201' && !${visible('#program-card')} && document.querySelector('#source-summary').textContent === 'C source · after_cancel.c' && ${uploadOptions}.join('|') === 'after_cancel.c'`);
  },

  async 'The browser accepts and refuses exactly the shared acceptance cases'() {
    const cases = acceptance.cases.map(({ name, fileName, source, accepted, refused }) => ({
      name, fileName: expand(fileName), source: expand(source),
      expected: accepted ? { ok: true, fileName: expand(accepted.fileName), source: expand(accepted.source) } : { ok: false, ...refused },
    }));
    const mismatches = await value(`${JSON.stringify(cases)}.map(c => ({ name: c.name, expected: c.expected, observed: AcceptedProgram.accept(c.fileName, c.source) }))
      .filter(c => JSON.stringify(c.observed) !== JSON.stringify(c.expected))`);
    if (mismatches.length) throw Error(`Failed: the shared acceptance cases; mismatches=${JSON.stringify(mismatches)}`);
    checks.push(`All ${cases.length} shared acceptance cases match the server's`);
  },

  async 'A file that fails the checks is refused in the browser and nothing is sent'() {
    await click('#source-mode input[value="yours"]');
    const refusals = [
      ['not_c_file', 'notes.txt', 'int main(void) { return 0; }\n', 'Only C files can be compiled: the file name must end in .c.'],
      ['empty', 'empty.c', ' \r\n\t\n', 'The file is empty or contains only whitespace.'],
      // Latin-1 é: a byte that is not UTF-8, which only a file (never pasted text) can contain.
      ['invalid_utf8', 'latin1.c', Buffer.from([0x2f, 0x2f, 0x20, 0xe9, 0x0a, ...Buffer.from('int main(void) { return 0; }\n')]), 'The file is not UTF-8 text.'],
      ['nul_character', 'nul.c', 'int main(void) { return 0; }\n\0', 'The file contains a NUL character.'],
      ['too_many_lines', 'long.c', 'int x;\r\n'.repeat(201), 'The file has 201 lines; up to 200 are allowed.'],
      ['too_large', 'large.c', `${'/'.repeat(99)}\n`.repeat(164) + '\n', 'The file is 16401 bytes of UTF-8 text; up to 16 KiB (16384 bytes) is allowed.'],
    ];
    const before = posts();
    for (const [reason, name, contents, message] of refusals) {
      // Choose another file… on the previous card, then Upload…, so each way to choose a file is used.
      await chooseFile(reason === 'not_c_file' ? '#program-drop button' : reason === 'empty' ? '#program-card button' : '#program-upload', await file(name, contents));
      await until(`document.querySelector('#program-card')?.innerText.includes(${JSON.stringify(message)})`);
      await check(`${reason}: a card in place of the panels gives the reason and says nothing was sent`,
        `(() => { const text = document.querySelector('#program-card').innerText; return ${visible('#program-card')} && !${visible('#left-panel')} && !${visible('.comparison-status')} && !${visible('#empty-state')} && text.includes(${JSON.stringify(`${name} could not be opened`)}) && text.includes('Nothing was sent to the compiler.') && ${visible('#program-card button')}; })()`);
      await check(`${reason}: the refusal is announced`, `document.querySelector('#notice').textContent === ${JSON.stringify(`Error: ${message} Nothing was sent to the compiler.`)}`);
      await check(`${reason}: no POST /api/programs was sent`, `${posts() === before}`);
      await check(`${reason}: no user program is open, listed or renamed`,
        `!appState.programId && ![...document.querySelector('#your-file-select').options].some(option => option.value) && !${visible('#program-renamed')} && !document.querySelector('#source-mode input[value="yours"]').disabled`);
      if (reason === 'too_many_lines') await snap('user-programs-refused.png');
    }
  },

  async 'An unsafe file name is renamed and CRLF and a BOM are normalised before compiling'() {
    const score = await readFile(join(curatedSources, 'score.c'), 'utf8');
    await click('#source-mode input[value="yours"]');
    await holdCompiles(true);
    const before = posts();
    await chooseFile('#program-drop button', await file('My Program (2).c', `\ufeff${score.replaceAll('\n', '\r\n')}`));
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling My_Program_2_.c')`);
    await check('The renamed file says so under the controls while it compiles',
      `${visible('#program-renamed')} && document.querySelector('#program-renamed').textContent === 'Renamed from “My Program (2).c”.' && Boolean(document.querySelector('.source-controls').compareDocumentPosition(document.querySelector('#program-renamed')) & Node.DOCUMENT_POSITION_FOLLOWING)`);
    await check('The source is shown normalised under its safe name',
      `document.querySelector('#source-summary').textContent === 'C source · My_Program_2_.c' && sourceState.data.text === ${JSON.stringify(score)}`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent', `${posts() - before === 1}`);
    await check('It opens as My_Program_2_.c, still saying it was renamed',
      `document.querySelector('#source-summary').textContent === 'C source · My_Program_2_.c' && ${visible('#program-chip')} && document.querySelector('#program-renamed').textContent === 'Renamed from “My Program (2).c”.' && [...document.querySelector('#your-file-select').options].filter(option => option.value).map(option => option.textContent).join() === 'My_Program_2_.c'`);
    await check('The source the server holds is the normalised source',
      `fetch('/api/programs/' + appState.programId + '/source').then(r => r.json()).then(body => body.file === 'My_Program_2_.c' && body.text === ${JSON.stringify(score)})`);
    await snap('user-programs-renamed.png');
    await chooseFile('#program-upload', join(curatedSources, 'score.c'));
    await until(`window.StudyWorkspace.ready && document.querySelector('#source-summary').textContent === 'C source · score.c'`);
    await check('A file that keeps its name shows no rename notice', `!${visible('#program-renamed')}`);
    await select('#your-file-select', await value(`[...document.querySelector('#your-file-select').options].find(option => option.textContent === 'My_Program_2_.c').value`));
    await until(`window.StudyWorkspace.ready && document.querySelector('#source-summary').textContent === 'C source · My_Program_2_.c'`);
    await check('Reopening the renamed upload shows the notice again', `${visible('#program-renamed')}`);
    await click('#source-mode input[value="curated"]');
    await check('Curated examples shows no rename notice', `!${visible('#program-renamed')}`);
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
  await rm(writtenSources, { recursive: true, force: true });
}
