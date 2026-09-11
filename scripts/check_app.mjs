// Application regression. Node 22+ and an isolated headless Chrome CDP on :9239.
// Optional IREXPLORER_CHECK_OUTPUT directory for screenshots and JSON; otherwise stdout only.
import { writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
if (captures) await mkdir(captures, { recursive: true });
const release = await (await fetch(base + '/api/release')).json();

// A new tab has no opener and no inherited session draft, making reruns independent.
const page = await (await fetch('http://127.0.0.1:9239/json/new?about:blank', { method: 'PUT' })).json();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let sequence = 0;
const waiting = new Map(), exceptions = [], checks = [];
ws.addEventListener('message', ({ data }) => {
  const message = JSON.parse(data);
  if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails);
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
async function until(expression) {
  for (let attempt = 0; attempt < 100; attempt += 1) { if (await value(expression)) return; await new Promise(resolve => setTimeout(resolve, 75)); }
  throw Error(`Timed out: ${expression}`);
}
async function check(name, expression) { if (!await value(expression)) throw Error(`Failed: ${name}`); checks.push(name); }
async function click(selector) { await value(`document.querySelector(${JSON.stringify(selector)}).click()`); }
async function key(key, code, codePoint) {
  await send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: codePoint, ...(key.length === 1 ? { text: key } : {}) });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: codePoint });
}
async function choose(name, option) { await click(`input[name="${name}"][value="${option}"]`); }
async function fill(name, text) { await value(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(text)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`); }
async function route(path) { await value(`location.hash = ${JSON.stringify(path)}`); }
async function screen(name) { await until(`document.querySelector('#route-heading')?.textContent === ${JSON.stringify(name)}`); await check(`Route focus: ${name}`, `document.activeElement.id === 'route-heading'`); }
async function snap(name) {
  if (!captures) return;
  await value('document.activeElement.blur(); window.scrollTo(0, 0)');
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(join(captures, name), Buffer.from(data, 'base64'));
}
async function select(selector, selected) {
  await value(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e.value = ${JSON.stringify(selected)}; e.dispatchEvent(new Event('change', { bubbles: true })); })()`);
}
async function task(id) {
  await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}'`);
  await check(`${id} requires a fresh source choice`, `document.querySelector('#example-select').value === '' && !window.StudyWorkspace.ready`);
  const setup = {
    T0: ['score', '0', '1', 'ir', 'ir'], T1: ['score', '0', '12', 'ir', 'ir'],
    T2: ['score', '0', '0', 'ir', 'ir'], T3: ['binary_search', '3', '3', 'ir', 'cfg'],
    T4: ['binary_search', '6', '7', 'cfg', 'cfg'], T5: ['quick_sort', '8', '9', 'ir', 'ir'],
    T6: ['score', '0', '1', 'ir', 'ir'],
  }[id];
  await select('#example-select', setup[0]);
  await until(`!document.querySelector('#workspace').hidden && !document.querySelector('#example-select').disabled`);
  await check(`${id} requires explicit states and views`, `['left', 'right'].every(side => document.querySelector('#' + side + '-state').value === '' && document.querySelector('#' + side + '-view').value === '')`);
  for (const [selector, selected] of [['#left-state', setup[1]], ['#right-state', setup[2]], ['#left-view', setup[3]], ['#right-view', setup[4]]]) await select(selector, selected);
  await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}' && !document.querySelector('.task-inputs').disabled`);
  if (id === 'T5') await select('#function-select', 'partition');
  await check(`${id} keeps task goal focused`, `location.hash === '#/study/tasks/${id}' && document.activeElement.id === 'route-heading'`);
}

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `${base}/` });
  await until(`document.readyState === 'complete'`);
  await until(`document.querySelectorAll('#example-select option').length === 4`);
  await until(`document.title === 'Explore · irexplorer'`);
  await check('Default page opens Explore without entering Study', `!location.hash && document.querySelector('#study-screen').hidden && !document.querySelector('#explore-heading').hidden`);
  await select('#example-select', 'score');
  await until('window.StudyWorkspace?.ready');
  await check('All three curated examples are available', `document.querySelectorAll('#example-select option').length === 4`);
  await check('Source box contains only source and heading', `document.querySelector('#source-prompt').hidden && !/Compiler debug|debugLoc/.test(document.querySelector('#source-panel').innerText)`);
  await check('Comparison has no expandable evidence', `document.querySelectorAll('.comparison-status details').length === 0`);
  await check('IR symbols offer novice hover help', `[...document.querySelectorAll('#left-viewer .token-value[data-help]')].some(token => token.dataset.help.includes('%')) && document.querySelector('#left-viewer .token-opcode[data-help]') !== null`);

  await check('Help tokens have visible dotted underlines and a help cursor', `(() => { const s = getComputedStyle(document.querySelector('.ir-help')); return s.textDecorationStyle === 'dotted' && s.cursor === 'help'; })()`);
  await value(`window.helpToken = document.querySelector('#left-viewer .ir-help'); window.helpStarted = performance.now(); helpToken.dispatchEvent(new PointerEvent('pointerover', { bubbles: true }));`);
  await check('Hover help uses a short intentional delay', `document.querySelector('#ir-help-tooltip').hidden`);
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('Help appears promptly and describes the hovered token', `performance.now() - helpStarted < 600 && document.querySelector('#ir-help-tooltip').textContent === helpToken.dataset.help && !helpToken.hasAttribute('title')`);
  await key('Escape', 'Escape', 27);
  await check('Escape dismisses help', `document.querySelector('#ir-help-tooltip').hidden`);
  await value('helpToken.focus()');
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('Keyboard focus exposes accessible help', `document.activeElement.getAttribute('aria-describedby') === 'ir-help-tooltip'`);
  await value('helpToken.blur()');
  await click('.source-line[data-line="3"]');
  await check('Source line highlights mapped IR in both panes', `document.querySelectorAll('.source-line.is-source').length === 1 && document.querySelectorAll('#left-viewer .is-source, #right-viewer .is-source').length > 0`);

  await check('C selection follows recorded cross-state links', `appState.selection?.trace.links.length > 0 && document.querySelector('#selection-status').textContent.includes('recorded link')`);
  await value(`document.querySelector('.source-line[data-line="5"]').dispatchEvent(new MouseEvent('click', { bubbles: true, shiftKey: true }))`);
  await check('Shift-click selects the complete C range', `JSON.stringify(sourceState.anchors.map(a => a.line)) === '[3,4,5]' && document.querySelectorAll('.source-line.is-source').length === 3`);
  await value(`document.querySelector('.source-line[data-line="6"]').dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', shiftKey: true, bubbles: true }))`);
  await check('Keyboard range selection retains its starting line', `JSON.stringify(sourceState.anchors.map(a => a.line)) === '[3,4,5,6]'`);
  await value(`window.traceBeforeView = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await check('IR to CFG preserves instruction membership', `window.traceBeforeView === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort())) && document.querySelector('#right-viewer .cfg-node.is-linked title').textContent.includes('instructions belong to the current trace')`);
  await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready');
  await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await click('#left-viewer .ir-block-heading');
  await check('IR block selection includes every member instruction', `appState.selectionInput.kind === 'node' && appState.panels.left.selectedInstructionIds.size === appState.panels.left.function.blocks[0].instructions.length && document.activeElement.classList.contains('ir-block-heading')`);
  await value(`window.blockTrace = document.querySelector('#selection-status').textContent; window.blockMembers = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .cfg-node').dispatchEvent(new MouseEvent('click', { bubbles: true }))`);
  await check('Equivalent IR and CFG block selections have identical results', `window.blockTrace === document.querySelector('#selection-status').textContent && window.blockMembers === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'ir'); await until('window.StudyWorkspace.ready');
  await click('#left-viewer .ir-line');
  await value(`window.instructionTrace = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await select('#left-view', 'ir'); await until('window.StudyWorkspace.ready');
  await check('An instruction remains precise across an IR-CFG-IR round trip', `window.instructionTrace === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort())) && appState.panels.left.selectedInstructionIds.size === 1`);
  await click('.source-line[data-line="3"]');
  await select('#right-state', '1'); await until('window.StudyWorkspace.ready');
  await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await check('Source absence in Right is reflected by the trace count', `document.querySelector('#right-trace-count').textContent === '0'`);


  await check('Cancellation explanation labels the interpretation as likely', `document.querySelector('#optimisation-explanations').textContent.includes('Algebraic simplification · likely')`);
  await click('.source-line[data-line="2"]');
  await check('Selection shows optimisation name, purpose and concrete change', `(() => { const text = document.querySelector('#optimisation-explanations').textContent; return text.includes('Strength reduction') && text.includes('Purpose:') && text.includes('What changed: Multiplication by 32 becomes a left shift by 5.'); })()`);
  await check('Multiple intermediate transformations can explain one source selection', `document.querySelector('#optimisation-explanations').textContent.includes('Local-variable promotion')`);
  await value(`window.explanationText = document.querySelector('#optimisation-explanations').textContent`);
  await select('#left-state', '2'); await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await check('Reversing panes preserves chronological optimisation explanations', `document.querySelector('#optimisation-explanations').textContent === window.explanationText`);
  await select('#left-state', '0'); await select('#right-state', '12'); await until('window.StudyWorkspace.ready');
  await check('Long comparisons identify the intermediate transition', `(() => { const event = appState.summary.optimisations.find(e => e.name === 'Strength reduction'); return event.fromOrdinal === 1 && event.toOrdinal === 2 && document.querySelector('#optimisation-explanations').textContent.includes(event.fromStateId + ' → ' + event.toStateId); })()`);
  await click('.source-line[data-line="4"]');
  await check('Changing selection removes unrelated explanations', `!document.querySelector('#optimisation-explanations').textContent.includes('Strength reduction') && document.querySelector('#optimisation-explanations').textContent.includes('Arithmetic canonicalisation')`);
  await select('#left-state', '12'); await until('window.StudyWorkspace.ready');
  await check('Same-state selection has an explicit no-change explanation', `document.querySelector('#optimisation-explanations').textContent.includes('Same state: no optimisation change')`);
  await select('#left-state', '0'); await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await click('.source-line[data-line="3"]');
  await check('C selection recomputes against a newly selected state', `appState.selectionInput.kind === 'source' && appState.selection.trace.links.every(link => appState.summary.links.includes(link))`);
  await select('#left-state', '2'); await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await click('#right-viewer .ir-line');
  await check('Right-origin tracing works with reversed state order', `appState.selectionInput.side === 'right' && appState.selection.trace.links.length > 0`);
  await select('#right-state', '1'); await until('window.StudyWorkspace.ready');
  await check('Changing the origin state clears stale instruction IDs', `!appState.selectionInput || appState.selectionInput.kind === 'source' || appState.selectionInput.ordinal === appState.panels.right.ordinal`);
  await select('#left-state', '0'); await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .ir-line').focus()`); await key('Enter', 'Enter', 13);
  await until(`Boolean(appState.selection?.trace)`);
  await check('Keyboard Enter follows an IR correspondence', `Boolean(appState.selection?.trace)`);
  await select('#left-view', 'cfg'); await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .cfg-edge').focus()`); await check('Keyboard-focusable CFG route is visibly isolated', `document.querySelector('#left-viewer svg').classList.contains('is-tracing')`);
  await value('document.activeElement.blur()');
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
  await check('Reduced motion preference is honoured', `matchMedia('(prefers-reduced-motion: reduce)').matches && getComputedStyle(document.documentElement).scrollBehavior === 'auto'`);
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'forced-colors', value: 'active' }] });
  await check('Forced colours retains a visible CFG node border', `getComputedStyle(document.querySelector('.cfg-node rect')).stroke !== 'none'`);
  await send('Emulation.setEmulatedMedia', { features: [] });
  await value(`window.testFetch = window.fetch; window.fetch = async (...args) => { if (String(args[0]).includes('/source')) throw Error('Synthetic source outage'); return window.testFetch(...args); };`);
  await select('#example-select', 'binary_search'); await until(`document.querySelector('#source-status').textContent.includes('Source unavailable')`);
  await value('window.fetch = window.testFetch'); await select('#example-select', 'binary_search'); await until('window.StudyWorkspace.ready');
  await check('Source loading failure can be recovered', `document.querySelector('#source-status').textContent.includes('Select a C line')`);


  await select('#example-select', 'quick_sort'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '8'); await select('#right-state', '9'); await until('window.StudyWorkspace.ready');
  await value(`window.mergeGroup = appState.summary.links.find(link => link.relation === 'merged');`);
  await check('Curated comparison includes a two-to-one group', `mergeGroup.fromNodeIds.length === 2 && mergeGroup.toNodeIds.length === 1`);
  const groupFunction = await value(`appState.panels.left.ir.functions.find(fn => fn.blocks.some(block => block.instructions.some(i => i.id === mergeGroup.fromNodeIds[0]))).name`);
  await select('#function-select', groupFunction); await until('window.StudyWorkspace.ready');
  await value(`selectNode('left', mergeGroup.fromNodeIds[0])`);
  await check('Selecting either merged input highlights the complete group', `appState.panels.left.selectedInstructionIds.size === 2 && appState.panels.right.selectedInstructionIds.size === 1 && document.querySelector('#selection-status').textContent.includes('merged')`);
  await value(`selectNode('right', mergeGroup.toNodeIds[0])`);
  await check('Selecting the merged result traces both inputs', `appState.panels.left.selectedInstructionIds.size === 2 && appState.panels.right.selectedInstructionIds.size === 1`);
  await check('Grouped rewrite has a succinct explanation', `document.querySelector('#optimisation-explanations').textContent.includes('Induction-variable widening · likely') && document.querySelector('#optimisation-explanations').textContent.includes('64-bit loop index')`);
  await check('Comparison separates states, selection and transitions', `document.querySelectorAll('.comparison-state').length === 2 && document.querySelector('#selection-context').textContent.includes('Right panel') && document.querySelector('#ir-transition-heading').closest('section').contains(document.querySelector('#optimisation-explanations')) && document.querySelector('#source-transition-heading').closest('section').contains(document.querySelector('#source-status'))`);
  await check('Source mapping text only describes Left', `!document.querySelector('#source-status').textContent.includes('Right:')`);
  await snap('workspace.png');
  await route('/study'); await screen('Information and consent');
  await check('Clean study interface and release label', `document.querySelector('#app-version').textContent === 'v${release.version}' && !/synthetic|preview|not.live|E7/i.test(document.body.innerText) && !location.search`);
  await value(`document.querySelector('#C1').focus()`); await key(' ', 'Space', 32);
  await check('Keyboard Space operates consent checkbox', `document.querySelector('#C1').checked`);
  for (let i = 2; i <= 6; i += 1) await click('#C' + i);
  await click('[data-action="start"]'); await screen('Pre-survey');
  await choose('P1', '1'); await fill('P13', 'Container test background response');
  await send('Page.reload'); await screen('Pre-survey');
  await check('Ordinary refresh restores answers without a special URL', `document.querySelector('input[name="P1"][value="1"]').checked && document.querySelector('textarea[name="P13"]').value === 'Container test background response' && !location.search`);
  await click('#survey-form button[type="submit"]');
  await task('T0');
  await click('[data-action="pause-task"]');
  await check('Pause disables task completion', `document.querySelector('.task-inputs').disabled`);
  await click('[data-action="pause-task"]');
  await click('#survey-form button[type="submit"]');
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5', 'T6']) {
    if (id === 'T1' || id === 'T2') {
      await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}'`);
      await check(`${id} permits an outcome before setup`, `!document.querySelector('[data-action="skip-task"]').disabled && document.querySelector('.task-complete').disabled && !window.StudyWorkspace.ready`);
      await click(id === 'T1' ? '[data-action="skip-task"]' : '[data-action="unable-task"]');
      continue;
    }
    await task(id);
    if (id === 'T4') await snap('task-cfg.png');
    await click('[data-action="skip-task"]');
  }
  await screen('Post-survey'); await choose('Q1', 'na'); await fill('Q14', 'Container test post response'); await click('#survey-form button[type="submit"]'); await screen('Review responses');
  await check('Review provides an explicit final submission action', `!!document.querySelector('[data-action="submit-responses"]')`);
  await snap('study-review.png');
  await value(`window.testFetch = window.fetch; window.fetch = async (...args) => { const response = await window.testFetch(...args); if (args[0] === '/api/study/submissions') throw Error('Synthetic lost acknowledgement'); return response; };`);
  await click('[data-action="submit-responses"]'); await screen('Receipt not yet confirmed');
  await check('Uncertain submit prevents further answer edits', `!document.querySelector('#survey-form') && document.querySelector('#study-screen').textContent.includes('may already exist')`);
  if (captures) await writeFile(join(captures, 'pending.json'), await value(`sessionStorage.getItem('irexplorer.study.submission.e6')`));
  await send('Page.reload'); await screen('Receipt not yet confirmed');
  await click('[data-action="retry-submit"]'); await screen('Responses received');
  await check('Retry produces a durable receipt and removes answer draft', `sessionStorage.getItem('irexplorer.study.e4') === null && JSON.parse(sessionStorage.getItem('irexplorer.study.submission.e6')).kind === 'receipt'`);

  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 2 });
  await check('200% emulated zoom has no page-width overflow', `document.documentElement.scrollWidth <= innerWidth`);
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 1 }); await snap('receipt-narrow.png');

  const newTarget = await send('Target.createTarget', { url: 'about:blank' });
  const second = (await (await fetch('http://127.0.0.1:9239/json/list')).json()).find(item => item.id === newTarget.targetId);
  const other = new WebSocket(second.webSocketDebuggerUrl); await new Promise(resolve => other.addEventListener('open', resolve, { once: true }));
  let otherId = 0; const otherPending = new Map();
  other.addEventListener('message', ({ data }) => { const message = JSON.parse(data); if (otherPending.has(message.id)) { const resolve = otherPending.get(message.id); otherPending.delete(message.id); resolve(message.result); } });
  const otherSend = (method, params = {}) => new Promise(resolve => { const id = ++otherId; otherPending.set(id, resolve); other.send(JSON.stringify({ id, method, params })); });
  await otherSend('Runtime.enable'); await otherSend('Page.enable'); await otherSend('Page.navigate', { url: `${base}/#/study` });
  for (let attempt = 0; attempt < 100; attempt += 1) { const result = await otherSend('Runtime.evaluate', { expression: `document.querySelector('#route-heading')?.textContent`, returnByValue: true }); if (result.result.value === 'Information and consent') break; await new Promise(resolve => setTimeout(resolve, 75)); }
  const isolated = await otherSend('Runtime.evaluate', { expression: `!sessionStorage.getItem('irexplorer.study.e4') && !document.querySelector('[data-action="new-study"]')`, returnByValue: true });
  if (!isolated.result.value) throw Error('Failed: Independent browser tab does not start without the first tab’s draft.');
  checks.push('Independent browser tab has no first-session draft or receipt'); other.close(); await send('Target.closeTarget', { targetId: newTarget.targetId });
  if (exceptions.length) throw Error(JSON.stringify(exceptions));
  const result = { release, assertions: checks.length, checks, runtimeExceptions: exceptions.length };
  if (captures) await writeFile(join(captures, 'browser-checks.json'), JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result));
} finally {
  ws.close();
  await fetch(`http://127.0.0.1:9239/json/close/${page.id}`);
}
