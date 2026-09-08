// E6 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9239.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'study-draft.js', 'source.js', 'comparison.js', 'task-clock.js', 'study-submit.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9239/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8006/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9239.');
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
async function click(selector) { await evaluate(`document.querySelector(${JSON.stringify(selector)}).click()`); }
async function route(path) {
  await evaluate(`location.hash = ${JSON.stringify(path)}`);
}
async function screen(title) {
  await until(`document.querySelector('#route-heading')?.textContent === ${JSON.stringify(title)}`);
  await check(`Focus: ${title}`, `document.activeElement.id === 'route-heading'`);
}
async function navigate(path) {
  const stamp = Date.now();
  await send('Page.navigate', {url: `http://127.0.0.1:8006/?e6=${stamp}#${path}`});
  await until(`location.search === '?e6=${stamp}' && document.readyState === 'complete' && document.querySelector('#preview-controls')?.hidden === false`);
}
async function key(key, code, n, text) {
  await send('Input.dispatchKeyEvent', {type:'keyDown',key,code,windowsVirtualKeyCode:n,...(text ? {text} : {})});
  await send('Input.dispatchKeyEvent', {type:'keyUp',key,code,windowsVirtualKeyCode:n});
}
async function choose(name, value) { await click(`input[name="${name}"][value="${value}"]`); }
async function fill(name, value) { await evaluate(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(value)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`); }
async function submit() { await evaluate(`document.querySelector('#survey-form').requestSubmit()`); }
async function consent() { for (let i = 1; i <= 6; i++) await click('#C' + i); await click('[data-action="start"]'); await screen('Pre-survey'); }
const stored = `JSON.parse(sessionStorage.getItem('irexplorer.study.e4'))`;
const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
async function task(id) {
  await until(`document.querySelector('#survey-form')?.dataset.stage === '${id}' && !document.querySelector('.task-inputs').disabled`);
  await check(`${id} prompt ready with route focus`, `document.activeElement.id === 'route-heading' && location.hash === '#/study/tasks/${id}'`);
}
async function setup(left, right, lview='ir', rview='ir', example) {
  await check(`Setup ${example}: ${left}/${right} ${lview}/${rview}`, `document.querySelector('#example-select').value === '${example}' && document.querySelector('#left-state').value === '${left}' && document.querySelector('#right-state').value === '${right}' && document.querySelector('#left-view').value === '${lview}' && document.querySelector('#right-view').value === '${rview}' && window.StudyWorkspace.ready`);
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Emulation.setFocusEmulationEnabled', {enabled:true});
  await viewport(1440,1000); await navigate('/study');
  if (await evaluate("!!document.querySelector('[data-action=\"new-study\"]')")) await click('[data-action="new-study"]');
  for (let session = 1; session <= 2; session++) {
    await screen('Information and consent');
    await consent(); await choose('P1', session); await fill('P13','Synthetic pre '+session); await submit();
    for (let i=0; i<=6; i++) {
      await task('T'+i);
      if(i===1) { await fill('T1a','Synthetic task response '+session); await choose('T1b',3); }
      if(i===3) { await fill('T3a','Synthetic block'); await click('[data-action="skip-task"]'); }
      else if(i===2) await click('[data-action="unable-task"]');
      else await submit();
    }
    await screen('Post-survey'); await choose('Q1','na'); await fill('Q14','Synthetic post '+session); await fill('Q18',' =SUM(1,2)\nSynthetic café '+session); await submit();
    await screen('Review responses');
    await check('Final submit is explicit '+session, `!!document.querySelector('[data-action="submit-responses"]')`);
    if(session===1) {
      await capture('e6-review-desktop.png');
      // Server commits normally; only its acknowledgement is lost at the transport seam.
      await evaluate(`window.realFetch=window.fetch; window.fetch=async (...args)=>{const r=await window.realFetch(...args); if(args[0]==='/api/study/submissions') throw Error('Synthetic lost acknowledgement');return r;}`);
      // Controller's default transport must resolve the current fetch at invocation.
    } else {
      await send('Network.emulateNetworkConditions',{offline:true,latency:0,downloadThroughput:-1,uploadThroughput:-1});
    }
    await click('[data-action="submit-responses"]'); await screen('Receipt not yet confirmed');
    await check('No false success or discard after uncertain attempt '+session, `!document.querySelector('[data-action="stop"]') && document.querySelector('#study-screen').textContent.includes('may already exist')`);
    await route('/study/pre'); await screen('Receipt not yet confirmed');
    await check('Back cannot edit frozen submission '+session, `location.hash==='#/study/complete' && !document.querySelector('#survey-form')`);
    if(session===1) { await viewport(390,844); await capture('e6-retry-narrow.png'); await evaluate('window.fetch=window.realFetch'); }
    else await send('Network.emulateNetworkConditions',{offline:false,latency:0,downloadThroughput:-1,uploadThroughput:-1});
    await send('Page.reload'); await screen('Receipt not yet confirmed');
    await click('[data-action="retry-submit"]'); await screen('Responses received');
    await check('Acknowledgement clears both answer copies '+session, `sessionStorage.getItem('irexplorer.study.e4')===null && JSON.parse(sessionStorage.getItem('irexplorer.study.submission.e6')).kind==='receipt' && !sessionStorage.getItem('irexplorer.study.submission.e6').includes('Synthetic task response')`);
    await check('Receipt fits narrow page '+session, 'document.documentElement.scrollWidth <= innerWidth');
    await capture('e6-receipt-'+session+'.png');
    await send('Page.reload'); await screen('Responses received');
    if(session===1) { await click('[data-action="new-study"]'); await viewport(1440,1000); }
  }
  await check('No browser runtime exceptions', String(errors.length === 0));
  await writeFile(new URL('e6-browser-checks.json',root),JSON.stringify({checks,errors,sourceHashes,revision,requests:requests.map(r=>({method:r.method,path:new URL(r.url).pathname}))},null,2));
  console.log(JSON.stringify({assertions:checks.length,errors:errors.length}));
} finally { ws.close(); }
