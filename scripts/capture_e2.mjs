// E2 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9224.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'source.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9224/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8002/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9224.');
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
  await evaluate('document.activeElement.blur(); window.scrollTo(0, 0)');
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
async function click(selector) { await evaluate(`document.querySelector(${JSON.stringify(selector)}).dispatchEvent(new MouseEvent('click', { bubbles: true }))`); }
async function route(path) {
  await evaluate(`location.hash = ${JSON.stringify(path)}`);
}
async function screen(title) {
  await until(`document.querySelector('#route-heading')?.textContent === ${JSON.stringify(title)}`);
  await check(`Focus: ${title}`, `document.activeElement.id === 'route-heading'`);
}
async function navigate(path) {
  await send('Page.navigate', {url: `http://127.0.0.1:8002/?e2=${Date.now()}#${path}`});
  await until(`document.querySelector('#preview-controls')?.hidden === false`);
}
async function consent() {
  await click('#preview-ack'); await click('[data-action="start"]'); await screen('Pre-survey');
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable'); await send('Network.setCacheDisabled', {cacheDisabled:true});
  const version = await send('Browser.getVersion');
  await viewport(1440, 1000);
  await navigate('/explore');
  await until(`!document.querySelector('#example-select').disabled`);
  await select('#example-select', 'score');
  await until(`appState.ready && appState.exampleId === 'score'`);
  await check('Verified numbered source is visible', `document.querySelectorAll('.source-line').length === 11 && sourceState.data.inputVerified`);
  await click('.source-line[data-line="3"]');
  await check('One source line highlights all instructions in both early states', `['left','right'].every(s => appState.panels[s].mappings.filter(m => m.location.line === 3).every(m => appState.panels[s].sourceNodeIds.has(m.instructionId))) && document.querySelectorAll('#left-viewer .ir-line.is-source').length > 1`);
  await capture('e2-score-desktop.png',true);
  for (const ordinal of [2,8,12,13,1,0]) {
    await select('#right-state', String(ordinal)); await until(`appState.ready && appState.panels.right.ir.ordinal === ${ordinal}`);
    await check('Anchor preserved in state '+ordinal, `sourceState.anchors[0].line === 3 && document.querySelector('.source-line[data-line="3"]').getAttribute('aria-pressed') === 'true'`);
    if (ordinal >= 2) await check('Missing mapping is honest in state '+ordinal, `!appState.panels.right.sourceNodeIds.size && document.querySelector('#source-status').textContent.includes('No recorded source mapping')`);
  }
  await select('#right-view','cfg'); await until(`appState.ready && !!document.querySelector('#right-viewer .cfg-node')`);
  await check('Same-state source to CFG containment', `document.querySelectorAll('#right-viewer .cfg-node.is-source').length > 0`);
  await evaluate(`document.querySelector('#source-panel').open = false`);
  await check('Collapsed source retains file and selected line', `document.querySelector('#source-summary').textContent.includes('score.c:3')`);
  await click('#right-viewer .cfg-node.is-source');
  await check('CFG reveals every recorded source location', `document.querySelector('#source-panel').open && sourceState.anchors.length > 1 && document.querySelectorAll('.source-line.is-source').length > 1`);
  await click('#left-viewer .ir-line');
  await check('Instruction without debug location clears source highlights', `sourceState.anchors.length === 0 && document.querySelector('#source-status').textContent.startsWith('No recorded source mapping')`);
  await select('#left-state','13'); await until(`appState.ready && appState.panels.left.ir.ordinal === 13`);
  await click('.source-line[data-line="3"]');
  await check('Reversed state order resolves source independently', `!appState.panels.left.sourceNodeIds.size && appState.panels.right.sourceNodeIds.size > 0`);
  await select('#example-select','binary_search'); await until(`appState.ready && appState.exampleId === 'binary_search'`);
  const loopLine = await evaluate(`sourceState.data.text.split(String.fromCharCode(10)).findIndex(l => l.includes('while')) + 1`);
  await select('#right-view','cfg'); await until(`appState.ready && !!document.querySelector('#right-viewer .cfg-node')`);
  await click(`.source-line[data-line="${loopLine}"]`);
  await check('Loop test maps to IR and CFG', `document.querySelectorAll('#left-viewer .ir-line.is-source').length > 0 && document.querySelectorAll('#right-viewer .cfg-node.is-source').length > 0`);
  await capture('e2-binary-search-desktop.png',true);
  await select('#example-select','quick_sort'); await until(`appState.ready && appState.exampleId === 'quick_sort'`);
  for (const fn of ['quick_sort','partition']) {
    await select('#function-select',fn); await until(`appState.ready && appState.panels.left.function.name === '${fn}'`);
    const line = await evaluate(`appState.panels.left.mappings[0].location.line`);
    await click(`.source-line[data-line="${line}"]`);
    await check('Source scoped to '+fn, `appState.panels.left.sourceNodeIds.size > 0 && appState.panels.left.mappings.every(m => m.instructionId.startsWith(appState.panels.left.function.id + '/'))`);
  }
  await viewport(390,844);
  await capture('e2-quick-sort-narrow.png',true);
  await check('Narrow source and page remain bounded', `document.documentElement.scrollWidth <= innerWidth && document.querySelector('#source-lines').clientHeight <= 180`);
  await evaluate(`document.querySelector('.source-line[data-line="3"]').focus()`);
  await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13,text:'\r'});
  await send('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});
  await check('Native Enter selects source line', `sourceState.anchors[0].line === 3`);
  // Delay real responses to verify old requests cannot replace newer state/example data.
  await evaluate(`window.originalFetch = window.fetch; window.fetch = async (...args) => { const r = await originalFetch(...args); if (String(args[0]).includes('/states/2/')) await new Promise(resolve => setTimeout(resolve, 350)); return r; }`);
  await select('#right-state','2'); await select('#right-state','13');
  await until(`appState.ready && appState.panels.right.ir.ordinal === 13`);
  await evaluate(`new Promise(resolve => setTimeout(resolve, 500))`);
  await check('Delayed state response cannot overwrite latest state', `appState.panels.right.ir.ordinal === 13 && sourceState.anchors[0].line === 3`);
  await evaluate(`window.fetch = async (...args) => { const r = await originalFetch(...args); if (String(args[0]).includes('/score/')) await new Promise(resolve => setTimeout(resolve, 350)); return r; }; document.querySelector('#example-select').value = 'score'; loadExample(); document.querySelector('#example-select').value = 'binary_search'; loadExample();`);
  await until(`appState.ready && appState.exampleId === 'binary_search'`);
  await evaluate(`new Promise(resolve => setTimeout(resolve, 600))`);
  await check('Delayed example response cannot overwrite latest source', `appState.exampleId === 'binary_search' && sourceState.data.file === 'binary_search.c' && !sourceState.anchors.length`);
  await evaluate(`window.fetch = originalFetch`);
  await evaluate(`window.fetch = async (...args) => { if (String(args[0]).includes('/source-mappings')) return new Response(JSON.stringify({error:{message:'Synthetic mapping failure'}}), {status:503}); return originalFetch(...args); }`);
  await select('#right-state','2');
  await until(`document.querySelector('#source-status').textContent.includes('Mappings unavailable')`);
  await check('Mapping failure is visible and selection is disabled', `!appState.ready && document.querySelector('#workspace').hidden`);
  await evaluate(`window.fetch = originalFetch`);
  await select('#example-select','score'); await until(`appState.ready && appState.exampleId === 'score'`);
  await check('Choosing the file again recovers', `!document.querySelector('#workspace').hidden && sourceState.data.file === 'score.c'`);
  await route('/study'); await screen('Information and consent'); await consent();
  await click('[data-action="next"]'); await screen('Preview task');
  await check('Verified source works inside synthetic task layout', `!document.querySelector('#workspace-shell').hidden && document.querySelectorAll('.source-line').length === 11`);
  await viewport(1440,1000); await capture('e2-task-desktop.png',true);
  await check('No runtime errors or write requests', `${errors.length === 0 && requests.every(r => r.method === 'GET')}`);
  await writeFile(new URL('e2-browser-checks.json',root), JSON.stringify({revision, sourceHashes, date:new Date().toISOString(),version,checks,errors,requests},null,2)+'\n');
  console.log(JSON.stringify({checks:checks.length,errors:errors.length}));
} finally { ws.close(); }
