// User programs acceptance. Node 22+ and an isolated headless Chrome CDP, against a host runner with the
// user programs setting on and a compiler service on loopback over the fake toolchain (check_browser.sh
// phase 3). Uploads are the unedited curated sources, which the fake toolchain has recordings for.
// Each scenario starts from a freshly loaded Explore page with empty session storage; add a scenario
// to `scenarios` for each new behaviour. Optional IREXPLORER_CHECK_OUTPUT directory for screenshots.
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const curatedSources = join(import.meta.dirname, '..', 'examples', 'curated');
// The acceptance cases the server is tested against too (tests/test_accepted_programs.py).
const acceptance = JSON.parse(await readFile(join(import.meta.dirname, '..', 'tests', 'data', 'user-program-acceptance.json'), 'utf8'));
const expand = text => typeof text === 'string' ? text : text.map(part => typeof part === 'string' ? part : part[0].repeat(part[1])).join('');
// Sources written for a scenario, such as ones carrying a fake toolchain marker (tests/fake_toolchain).
const writtenSources = await mkdtemp(join(tmpdir(), 'irexplorer-user-programs-'));
async function file(name, contents) {
  await writeFile(join(writtenSources, name), contents);
  return join(writtenSources, name);
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

// Study (#/study…) is unchanged by user programs: none of their controls exist there, and the source
// panel is the curated one. `studySurface` reads what a participant's source panel is made of.
const programControls = ['#source-mode', '#your-file-control', '#your-file-select', '#program-upload', '#program-paste-open', '#program-file-input', '#program-drop', '#program-paste', '#program-chip', '#program-card', '.source-title'];
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

  async 'Drop a C file onto the C source panel in Your files and explore it as a user program'() {
    const before = posts();
    await dropFile('#source-panel', join(curatedSources, 'score.c'));
    await pause(300);
    await check('Dropping a file in Curated examples does nothing: no compile and the page stays',
      `${posts() === before} && location.hash === '#/explore' && !${visible('#program-card')} && document.querySelector('#source-mode input[value="curated"]').checked`);

    await click('#source-mode input[value="yours"]');
    await check('With no user program open the source lines area reads "Drop a .c file here" and offers Paste source instead',
      `(() => { const drop = document.querySelector('#program-drop'), buttons = [...drop.querySelectorAll('button')].map(b => b.textContent); return ${visible('#program-drop')} && drop.querySelector('.program-drop-title').textContent === 'Drop a .c file here' && buttons.join('|') === 'Choose a file…|Paste source instead'; })()`);
    await holdCompiles(true);
    await dropFile('#source-panel', join(curatedSources, 'binary_search.c'));
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling binary_search.c')`);
    await check('The dropped source is shown at once while it compiles', `document.querySelector('#source-summary').textContent === 'C source · binary_search.c' && document.querySelector('#source-lines').inert`);
    await check('Pasting is unavailable during a compile',
      `[...document.querySelectorAll('#program-paste-open, #program-drop button')].every(control => control.disabled) && !${visible('#program-paste')}`);
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

  async 'Paste source in Your files and explore it as a user program'() {
    const source = await readFile(join(curatedSources, 'score.c'), 'utf8');
    await click('#source-mode input[value="yours"]');
    await check('Your files offers Paste… beside Upload…', `${visible('#program-paste-open')} && document.querySelector('#program-paste-open').textContent === 'Paste…' && !${visible('#program-paste')}`);
    await value(`[...document.querySelectorAll('#program-drop button')].find(b => b.textContent === 'Paste source instead').click()`);
    await check('Paste source instead opens a plain textarea with a File name field defaulting to program.c',
      `${visible('#program-paste')} && !${visible('#program-drop')} && document.querySelector('#program-paste-name').value === 'program.c' && document.querySelector('label[for="program-paste-name"]').textContent.startsWith('File name') && document.querySelector('#program-paste-source').tagName === 'TEXTAREA' && document.activeElement === document.querySelector('#program-paste-source')`);
    await snap('user-programs-paste.png');
    await click('#program-paste-cancel');
    await check('Cancel closes the paste box and offers the drop zone again', `!${visible('#program-paste')} && ${visible('#program-drop')}`);

    await click('#program-paste-open');
    await check('Paste… opens the paste box too', `${visible('#program-paste')} && document.activeElement === document.querySelector('#program-paste-source')`);
    await send('Input.insertText', { text: source });
    await holdCompiles(true);
    const before = posts();
    await click('#program-paste-compile');
    await until(`document.querySelector('#program-card')?.innerText.includes('Compiling program.c')`);
    await check('The pasted source compiles as program.c, shown at once, and the paste box closes',
      `document.querySelector('#source-summary').textContent === 'C source · program.c' && ${visible('#source-lines')} && !${visible('#program-paste')} && document.querySelectorAll('#source-lines .source-line').length === ${source.replace(/\n$/, '').split('\n').length}`);
    await check('Paste… and the paste box are disabled during a compile',
      `[...document.querySelectorAll('#program-paste-open, #program-drop button, #program-paste-compile')].every(control => control.disabled)`);
    await releaseCompile();
    await holdCompiles(false);
    await until('window.StudyWorkspace.ready && Boolean(appState.programId)');
    await check('Exactly one POST /api/programs was sent for the paste', `${posts() - before === 1}`);
    await check('The pasted source opens as a user program named program.c',
      `document.querySelector('#source-summary').textContent === 'C source · program.c' && ${visible('#program-chip')} && /^[0-9a-f]{64}$/.test(appState.programId) && appState.exampleId === null && document.querySelectorAll('#left-viewer .ir-line').length > 0`);
    const programId = await value('appState.programId');

    await click('#program-paste-open');
    await check('Paste… over an open user program hides its source until cancelled or compiled', `${visible('#program-paste')} && !${visible('#source-lines')}`);
    await value(`(() => { const name = document.querySelector('#program-paste-name'); name.value = 'my_score.c'; name.dispatchEvent(new Event('input', { bubbles: true })); })()`);
    await click('#program-paste-compile');
    await until(`window.StudyWorkspace.ready && Boolean(appState.programId) && appState.programId !== ${JSON.stringify(programId)}`);
    await check('A custom file name is honoured',
      `document.querySelector('#source-summary').textContent === 'C source · my_score.c' && [...document.querySelector('#your-file-select').options].filter(option => option.value).map(option => option.textContent).join('|') === 'program.c|my_score.c'`);
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
