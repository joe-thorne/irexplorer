// User programs acceptance. Node 22+ and an isolated headless Chrome CDP, against a host runner with the
// user programs setting on and a compiler service on loopback over the fake toolchain (check_browser.sh
// phase 3). Uploads are the unedited curated sources, which the fake toolchain has recordings for.
// Each scenario starts from a freshly loaded Explore page with empty session storage; add a scenario
// to `scenarios` for each new behaviour. Optional IREXPLORER_CHECK_OUTPUT directory for screenshots.
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const curatedSources = join(import.meta.dirname, '..', 'examples', 'curated');
// Sources written for a scenario, such as ones carrying a fake toolchain marker (tests/fake_toolchain).
const writtenSources = await mkdtemp(join(tmpdir(), 'irexplorer-user-programs-'));
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
