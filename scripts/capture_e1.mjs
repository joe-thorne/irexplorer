// E1 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9223.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9223/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9223.');
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
  await send('Page.navigate', {url: `http://127.0.0.1:8000/#${path}`});
  await until(`document.querySelector('#preview-controls')?.hidden === false`);
}
async function consent() {
  await click('#preview-ack'); await click('[data-action="start"]'); await screen('Pre-survey');
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  const version = await send('Browser.getVersion');
  await viewport(1440, 1000);
  await navigate('/study/tasks/T2'); await screen('Information and consent');
  await check('Task deep link gates before consent', `location.hash === '#/study'`);
  await route('/study/post'); await until(`location.hash === '#/study'`);
  await check('Post deep link gates before consent', `document.querySelector('[data-action="start"]').disabled && !document.querySelector('#preview-ack').checked`);
  await capture('e1-information-desktop.png');
  await click('[data-action="decline"]'); await screen('Preview declined');
  await route('/study/post'); await screen('Information and consent');
  await consent(); await capture('e1-pre-desktop.png');
  await evaluate('history.back()'); await screen('Information and consent');
  await evaluate('history.forward()'); await screen('Pre-survey');
  await click('[data-action="next"]'); await screen('Preview task');
  await until(`document.querySelector('#example-select').disabled === false`);
  await select('#example-select', 'score'); await until(`document.querySelector('#notice').textContent.startsWith('score is ready')`);
  await check('All 14 states remain reachable in both panes', `document.querySelector('#left-state').options.length === 14 && document.querySelector('#right-state').options.length === 14`);
  await select('#right-view', 'cfg'); await until(`!!document.querySelector('#right-viewer .cfg-node')`);
  await click('#left-viewer .ir-line');
  await until(`document.querySelector('#selection-status').textContent !== 'Select an IR line or CFG block to follow its recorded link.'`);
  await check('Workspace has selected an instruction', `!!document.querySelector('#left-viewer .ir-line.is-selected')`);
  await capture('e1-task-desktop.png');
  const desktop = await evaluate(`({left: document.querySelector('#left-viewer').getBoundingClientRect().toJSON(), right: document.querySelector('#right-viewer').getBoundingClientRect().toJSON(), task: document.querySelector('#study-screen').getBoundingClientRect().toJSON()})`);
  await click('a[href="#workspace"]');
  await check('Comparison focus link retains task route', `location.hash === '#/study/tasks/preview' && document.activeElement.id === 'workspace'`);
  // Exercise real keyboard events against native controls.
  await evaluate(`document.querySelector('.skip-link').focus()`);
  await send('Input.dispatchKeyEvent', {type:'keyDown', key:'Enter', code:'Enter', windowsVirtualKeyCode:13});
  await send('Input.dispatchKeyEvent', {type:'keyUp', key:'Enter', code:'Enter', windowsVirtualKeyCode:13});
  await check('Keyboard Enter skip link focuses page heading', `document.activeElement.id === 'route-heading' && location.hash === '#/study/tasks/preview'`);
  await send('Input.dispatchKeyEvent', {type:'keyDown', key:'Tab', code:'Tab', windowsVirtualKeyCode:9});
  await send('Input.dispatchKeyEvent', {type:'keyUp', key:'Tab', code:'Tab', windowsVirtualKeyCode:9});
  await check('Tab from task heading reaches disclosure', `document.activeElement.tagName === 'SUMMARY'`);
  await viewport(390, 844); await route('/study/pre'); await screen('Pre-survey');
  await route('/study/tasks/preview'); await screen('Preview task');
  await check('Narrow task details initially compact', `!document.querySelector('.task-details').open`);
  await capture('e1-task-narrow.png', true);
  const narrow = await evaluate(`({width: innerWidth, documentWidth: document.documentElement.scrollWidth, left: document.querySelector('#left-viewer').getBoundingClientRect().toJSON(), right: document.querySelector('#right-viewer').getBoundingClientRect().toJSON()})`);
  await check('No page-wide overflow at 390px', `document.documentElement.scrollWidth === innerWidth`);
  await check('Both narrow panes bounded to 320px', `['left','right'].every(s => document.querySelector('#'+s+'-viewer').getBoundingClientRect().height <= 320)`);
  await click('.task-details summary'); await check('Narrow instructions expand', `document.querySelector('.task-details').open`);
  await click('[data-action="next"]'); await screen('Post-survey'); await capture('e1-post-narrow.png', true);
  await click('[data-action="receipt"]'); await screen('Simulated receipt'); await capture('e1-receipt-narrow.png', true);
  await check('Receipt explicitly disclaims saving', `document.querySelector('#study-screen').textContent.includes('Nothing was submitted or saved.')`);
  await send('Page.reload'); await until(`document.querySelector('#route-heading')?.textContent === 'Information and consent'`);
  await check('Refresh resets consent and progress', `location.hash === '#/study' && !document.querySelector('#preview-ack').checked`);
  await consent(); await click('[data-action="stop"]'); await screen('Preview stopped');
  await route('/study/post'); await screen('Information and consent');
  await consent(); await click('#preview-reset'); await screen('Information and consent');
  await route('/explore');
  await until(`document.activeElement.id === 'explore-heading'`);
  await check('Direct explore hides study and progress', `!document.querySelector('#workspace-shell').hidden && document.querySelector('#study-screen').hidden && document.querySelector('#study-progress').hidden`);
  await select('#example-select', 'quick_sort'); await until(`document.querySelector('#notice').textContent.startsWith('quick_sort is ready')`);
  await viewport(1440, 1000); await capture('e1-explore-desktop.png');
  await check('Preview creates no browser storage', `sessionStorage.length === 0 && localStorage.length === 0 && document.cookie === ''`);
  // Simulate a non-preview build before its scripts run, never via URL mode switches.
  const injected = await send('Page.addScriptToEvaluateOnNewDocument', {source: `document.addEventListener('readystatechange', () => { if (document.readyState === 'interactive') document.body.dataset.studyMode = 'live'; });`});
  await send('Page.navigate', {url:'http://127.0.0.1:8000/?e1-check#/study/post?mode=preview'});
  await until(`document.querySelector('#explore-heading') && !document.querySelector('#workspace-shell').hidden`);
  await check('Non-preview build hides controls and disables study routes', `location.hash === '#/explore' && document.querySelector('#preview-controls').hidden && document.querySelector('#study-screen').hidden && document.querySelector('#source-placeholder').hidden`);
  await send('Page.removeScriptToEvaluateOnNewDocument', {identifier: injected.identifier});
  if(requests.some(r => !['GET','HEAD'].includes(r.method))) throw new Error('Unexpected write request');
  checks.push('No write requests during full journey, receipt, reset, or exit');
  if (errors.length) throw new Error('Browser exceptions recorded');
  await writeFile(new URL('e1-browser-checks.json', root), JSON.stringify({capturedAt:new Date().toISOString(), baselineRevision:revision, frontendSha256:sourceHashes, version, checks, desktop, narrow, requests, errors, limitations:['Isolated headless Chrome CDP fallback; in-app runtime reported no browsers.', 'Keyboard events automated; physical keyboard and assistive technology checks remain E7.', 'E1 is a preview-only build; E6 must supply server-controlled modes and durable submission.']}, null, 2)+'\n');
  await navigate('/study');
  console.log(`E1: ${checks.length} behavioural checks passed; seven screenshots saved.`);
} finally { ws.close(); }
