// User programs acceptance. Node 22+ and an isolated headless Chrome CDP, against a host runner with the
// user programs setting on and a compiler service on loopback over the fake toolchain (check_browser.sh
// phase 3). Uploads are the unedited curated sources, which the fake toolchain has recordings for.
// Each scenario starts from a freshly loaded Explore page with empty session storage; add a scenario
// to `scenarios` for each new behaviour. Optional IREXPLORER_CHECK_OUTPUT directory for screenshots.
// IREXPLORER_COMPILER_PID is the compiler service's process, which a scenario pauses to make it unavailable.
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const curatedSources = join(import.meta.dirname, '..', 'examples', 'curated');
const copies = await mkdtemp(join(tmpdir(), 'irexplorer-user-programs-'));
// A curated source under another name: the same recording, but a programId the server does not hold yet.
async function renamedCopy(example, fileName) {
  const path = join(copies, fileName);
  await writeFile(path, await readFile(join(curatedSources, `${example}.c`)));
  return path;
}
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
// Clicks the failure card's button with exactly this text.
const cardButton = text => value(`[...document.querySelectorAll('#program-card button')].find(button => button.textContent === ${JSON.stringify(text)}).click()`);
const cardButtons = `[...document.querySelectorAll('#program-card button')].map(button => button.textContent).join('|')`;
const yourFiles = `[...document.querySelector('#your-file-select').options].filter(option => option.value).map(option => option.textContent).join('|')`;
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

  async 'A busy compiler is reported with Try again, which compiles the file once the other compile is over'() {
    const slow = postElsewhere('slow.c', await readFile(join(curatedSources, 'score.c'), 'utf8') + '// irx-fake: slow\n');
    await pause(300);
    await click('#source-mode input[value="yours"]');
    await chooseFile('#program-drop button', await renamedCopy('score', 'busy_score.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('could not be opened')`);
    await check('The busy card shows the server\'s message, with Try again and Choose another file…',
      `(() => { const text = document.querySelector('#program-card').innerText; return text.includes('busy_score.c could not be opened') && text.includes('The compiler is busy with another program. Try again in a moment.') && ${cardButtons} === 'Try again|Choose another file…'; })()`);
    await check('The busy file is not added to Your file and the workbench is not busy',
      `${yourFiles} === '' && document.querySelector('#workspace-shell').getAttribute('aria-busy') !== 'true' && !appState.programId`);
    await snap('user-programs-busy.png');
    if ((await slow).status !== 201) throw Error(`Failed: the other compile finished; observed=${(await slow).status}`);

    const before = posts();
    await cardButton('Try again');
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Try again posts the same file once and opens it', `${posts() - before === 1} && !${visible('#program-card')} && document.querySelector('#source-summary').textContent === 'C source · busy_score.c'`);
    await check('Only the file that compiled is listed in Your file', `${yourFiles} === 'busy_score.c'`);
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
    await check('The unavailable file is not added to Your file', `${yourFiles} === '' && !appState.programId`);
    await snap('user-programs-unavailable.png');

    // The compiler finishes the request the app gave up on before it takes another.
    await compilerFree();
    await cardButton('Try again');
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Try again opens the file once the compiler answers', `!${visible('#program-card')} && document.querySelector('#source-summary').textContent === 'C source · unavailable_search.c' && ${yourFiles} === 'unavailable_search.c'`);
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
  await rm(copies, { recursive: true, force: true });
  ws.close();
  await fetch(`${cdp}/json/close/${page.id}`);
}
