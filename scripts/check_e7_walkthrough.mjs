// E7 behavioural rehearsal. Node 22+ and an isolated headless Chrome CDP on :9239.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFile, writeFile } from 'node:fs/promises';

const base = process.env.IREXPLORER_E7_ORIGIN || 'http://127.0.0.1:8007';
const captures = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const file of ['index.html', 'style.css', 'app.js', 'preview.js', 'source.js', 'comparison.js', 'task-clock.js', 'study-draft.js', 'study-submit.js', 'vendor/dagre-1.1.5.min.js']) {
  sourceHashes[file] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + file, import.meta.url))).digest('hex');
}

const pages = await (await fetch('http://127.0.0.1:9239/json/list')).json();
const page = pages.find(item => item.type === 'page' && (item.url === 'about:blank' || item.url.startsWith(base)));
if (!page) throw Error('Start an isolated headless Chrome at about:blank on :9239.');
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
  await value('document.activeElement.blur(); window.scrollTo(0, 0)');
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(new URL(name, captures), Buffer.from(data, 'base64'));
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
  await send('Page.navigate', { url: `${base}/?e7=${Date.now()}#/explore` });
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
  await value(`window.e7Fetch = window.fetch; window.fetch = async (...args) => { if (String(args[0]).includes('/source')) throw Error('Synthetic source outage'); return window.e7Fetch(...args); };`);
  await select('#example-select', 'binary_search'); await until(`document.querySelector('#source-status').textContent.includes('Source unavailable')`);
  await value('window.fetch = window.e7Fetch'); await select('#example-select', 'binary_search'); await until('window.StudyWorkspace.ready');
  await check('Source loading failure can be recovered', `document.querySelector('#source-status').textContent.includes('Verified canonical input')`);

  await route('/study'); await screen('Information and consent');
  await check('Visible preview label identifies the E7 revision', `document.querySelector('#preview-controls strong').textContent === 'E7 · Synthetic study preview'`);
  await value(`document.querySelector('#C1').focus()`); await key(' ', 'Space', 32);
  await check('Keyboard Space operates consent checkbox', `document.querySelector('#C1').checked`);
  for (let i = 2; i <= 6; i += 1) await click('#C' + i);
  await click('[data-action="start"]'); await screen('Pre-survey');
  await choose('P1', '1'); await fill('P13', 'E7 synthetic background response'); await click('#survey-form button[type="submit"]');
  await task('T0'); await click('#survey-form button[type="submit"]');
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5', 'T6']) { await task(id); await click('[data-action="skip-task"]'); }
  await screen('Post-survey'); await choose('Q1', 'na'); await fill('Q14', 'E7 synthetic post response'); await click('#survey-form button[type="submit"]'); await screen('Review responses');
  await check('Review provides an explicit final submission action', `!!document.querySelector('[data-action="submit-responses"]')`);
  await snap('e7-review-desktop.png');
  await value(`window.e7Fetch = window.fetch; window.fetch = async (...args) => { const response = await window.e7Fetch(...args); if (args[0] === '/api/study/submissions') throw Error('Synthetic lost acknowledgement'); return response; };`);
  await click('[data-action="submit-responses"]'); await screen('Receipt not yet confirmed');
  await check('Uncertain submit prevents further answer edits', `!document.querySelector('#survey-form') && document.querySelector('#study-screen').textContent.includes('may already exist')`);
  await value('window.fetch = window.e7Fetch'); await click('[data-action="retry-submit"]'); await screen('Responses received');
  await check('Retry produces a durable receipt and removes answer draft', `sessionStorage.getItem('irexplorer.study.e4') === null && JSON.parse(sessionStorage.getItem('irexplorer.study.submission.e6')).kind === 'receipt'`);

  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 2 });
  await check('200% emulated zoom has no page-width overflow', `document.documentElement.scrollWidth <= innerWidth`);
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 1 }); await snap('e7-receipt-narrow-zoom.png');

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
  checks.push('Independent browser tab has no first-session draft or receipt'); other.close();
  if (exceptions.length) throw Error(JSON.stringify(exceptions));
  await writeFile(new URL('e7-browser-checks.json', captures), JSON.stringify({ date: new Date().toISOString(), base, revision, sourceHashes, assertions: checks.length, checks, runtimeExceptions: exceptions.length }, null, 2) + '\n');
  console.log(JSON.stringify({ assertions: checks.length, runtimeExceptions: exceptions.length }));
} finally { ws.close(); }
