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
  await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}' && !document.querySelector('.task-inputs').disabled`);
  await check(`${id} keeps task goal focused`, `location.hash === '#/study/tasks/${id}' && document.activeElement.id === 'route-heading'`);
}

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `${base}/#/explore` });
  await until(`document.readyState === 'complete'`);
  await until(`document.querySelectorAll('#example-select option').length === 4`);
  await select('#example-select', 'score');
  await until('window.StudyWorkspace?.ready');
  await check('All three curated examples are available', `document.querySelectorAll('#example-select option').length === 4`);
  await click('.source-line[data-line="3"]');
  await check('Source line highlights mapped IR in both panes', `document.querySelectorAll('.source-line.is-source').length === 1 && document.querySelectorAll('#left-viewer .is-source, #right-viewer .is-source').length > 0`);
  await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await check('Source absence is explicit after instcombine', `document.querySelector('#source-status').textContent.includes('No recorded source mapping')`);
  await value(`document.querySelector('#left-viewer .ir-line').focus()`); await key('Enter', 'Enter', 13);
  await until(`document.querySelector('#selection-status').textContent.includes('Selection:')`);
  await check('Keyboard Enter follows an IR correspondence', `document.querySelector('#selection-status').textContent.includes('Selection:')`);
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
  await check('Source loading failure can be recovered', `document.querySelector('#source-status').textContent.includes('Verified canonical input')`);

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
