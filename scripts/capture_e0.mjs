// E0 baseline only. Node 22+ built-ins; isolated local headless Chrome on :9223.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9223/json/list')).json();
const page = pages.find(p => p.type === 'page' && ['about:blank', 'http://127.0.0.1:8000/'].includes(p.url));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9223.');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let id = 0;
const pending = new Map(), errors = [];
ws.addEventListener('message', ({ data }) => {
  const m = JSON.parse(data);
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
try {
  await send('Runtime.enable'); await send('Page.enable');
  const version = await send('Browser.getVersion');
  await viewport(1440, 1000); await send('Page.navigate', { url: 'http://127.0.0.1:8000/' });
  await until(`document.querySelector('#example-select')?.disabled === false`);
  await select('#example-select', 'score'); await until(`document.querySelector('#notice').textContent.startsWith('score is ready')`);
  await capture('e0-score-desktop.png');
  await viewport(390, 844); await capture('e0-score-narrow.png', true);
  const narrow = await evaluate(`({width: innerWidth, documentWidth: document.documentElement.scrollWidth, left: document.querySelector('#left-viewer').getBoundingClientRect().toJSON(), right: document.querySelector('#right-viewer').getBoundingClientRect().toJSON()})`);
  await viewport(1440, 1000);
  await select('#example-select', 'binary_search'); await until(`document.querySelector('#notice').textContent.startsWith('binary_search is ready')`);
  await select('#left-state', '3'); await until(`document.querySelector('#left-description').textContent.startsWith('simplifycfg')`);
  await select('#right-state', '3'); await until(`document.querySelector('#right-description').textContent.startsWith('simplifycfg')`);
  await select('#right-view', 'cfg'); await until(`!!document.querySelector('#right-viewer .cfg-node')`);
  await evaluate(`document.querySelector('#left-viewer [data-node-id="fn0/bb1/i2"]').click()`);
  await until(`document.querySelector('#right-viewer [data-node-id="fn0/bb1"]').getAttribute('aria-pressed') === 'true'`);
  const t3 = await evaluate(`document.querySelector('#selection-status').textContent`);
  await capture('e0-binary-search-t3.png');
  await select('#left-state', '6'); await until(`document.querySelector('#left-description').textContent.startsWith('loop_canonical')`);
  await select('#left-view', 'cfg'); await until(`!!document.querySelector('#left-viewer .cfg-node')`);
  await select('#right-state', '7'); await until(`document.querySelector('#right-description').textContent.startsWith('loop_rotate')`);
  await capture('e0-binary-search-t4.png');
  const t4 = await evaluate(`Array.from(document.querySelectorAll('#right-viewer .cfg-edge')).filter(e => e.getAttribute('x1') === e.getAttribute('x2') && e.getAttribute('y1') === e.getAttribute('y2')).length`);
  await select('#example-select', 'quick_sort'); await until(`document.querySelector('#notice').textContent.startsWith('quick_sort is ready')`);
  await select('#right-state', '9'); await until(`document.querySelector('#right-description').textContent.startsWith('indvars')`);
  await evaluate(`document.querySelector('#left-viewer [data-node-id="fn0/bb0/i9"]').click()`);
  await until(`document.querySelector('#selection-status').textContent.includes('approximate')`);
  const t5 = await evaluate(`document.querySelector('#selection-status').textContent`);
  await capture('e0-quick-sort-t5.png');
  await writeFile(new URL('e0-browser-checks.json', root), JSON.stringify({ capturedAt: new Date().toISOString(), baselineRevision: revision, frontendSha256: sourceHashes, version, desktop: [1440, 1000], narrowViewport: [390, 844], narrow, t3, t4ZeroLengthSelfEdges: t4, t5, errors, limitations: ['Headless CDP fallback; Browser runtime had no available browser.', 'Not a physical keyboard, screen-reader, or complete accessibility walkthrough.', 'No study flow or response storage exists in E0.'] }, null, 2) + '\n');
  if (errors.length) throw new Error('Browser exceptions recorded.');
  console.log('E0: five baseline captures and browser observations saved.');
} finally { ws.close(); }
