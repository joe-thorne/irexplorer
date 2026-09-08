// E5 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9229.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'study-draft.js', 'source.js', 'comparison.js', 'task-clock.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9229/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9229.');
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
  await send('Page.navigate', {url: `http://127.0.0.1:8000/?e5=${stamp}#${path}`});
  await until(`location.search === '?e5=${stamp}' && document.readyState === 'complete' && document.querySelector('#preview-controls')?.hidden === false`);
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
const baseline=process.argv.includes('--baseline');
const prefix=baseline?'e5-zoom-before':'e5-zoom-after';
const graphWidth=()=>evaluate(`document.querySelector('#left-viewer svg').getBoundingClientRect().width`);
try {
  await send('Runtime.enable');await send('Page.enable');await send('Emulation.setFocusEmulationEnabled',{enabled:true});
  await viewport(1440,1000);await navigate('/explore');await select('#example-select','score');await until('window.StudyWorkspace.ready');
  await select('#left-view','cfg');await until('window.StudyWorkspace.ready');
  const fit=await graphWidth();await select('#left-cfg-size','actual');const actual=await graphWidth();
  if(baseline) await check('Fit and Actual size are identical for a graph smaller than its pane', `${fit}===${actual}`);
  else {
    await check('Fit width expands a small graph to available width', `${fit}>${actual}+30`);
    for(const percent of [50,75,125,150]) {
      await select('#left-cfg-size',String(percent));
      await check(`${percent}% produces its stated scale`, `Math.abs(document.querySelector('#left-viewer svg').getBoundingClientRect().width - ${actual*percent/100})<1`);
    }
    await select('#left-cfg-size','75');await select('#left-state','3');await until('window.StudyWorkspace.ready');
    await check('Zoom preference survives state changes', `document.querySelector('#left-cfg-size').value==='75' && Math.abs(document.querySelector('#left-viewer svg').getBoundingClientRect().width-document.querySelector('#left-viewer svg').viewBox.baseVal.width*.75)<1`);
    await select('#left-cfg-size','fit');await viewport(1200,900);
    await check('Fit tracks pane resizing', `Math.abs(document.querySelector('#left-viewer svg').getBoundingClientRect().width - (document.querySelector('#left-viewer').clientWidth-2*parseFloat(getComputedStyle(document.querySelector('#left-viewer')).paddingLeft)))<1`);
    await viewport(1440,1000);await navigate('/study');await evaluate('sessionStorage.clear()');await navigate('/study');
    await consent();await choose('P1',1);await submit();await task('T0');await submit();await task('T1');
    for(const id of ['T2','T3','T4']){await click('[data-action="skip-task"]');await task(id);}
    await fill('T4b','Synthetic sizing response');await click('#source-summary');
    const widths=[];
    for(const value of ['fit','75','actual','125','150']) {
      await select('#right-cfg-size',value);widths.push(await evaluate(`document.querySelector('#right-viewer svg').getBoundingClientRect().width`));
    }
    await check('Every size choice visibly changes the narrower study CFG', `${JSON.stringify(widths)}.every((w,i,a)=>i===0||Math.abs(w-a[i-1])>10)`);
    await check('Right graph resizing preserves left choice and task response', `document.querySelector('#left-cfg-size').value==='fit' && ${stored}.tasks.T4.answers.T4b.value==='Synthetic sizing response'`);
    await evaluate(`document.querySelector('#right-viewer .cfg-node').focus()`);await key('Enter','Enter',13,'\r');await until(`document.querySelector('#right-viewer .cfg-node.is-selected')`);
    await check('Selection keeps zoom and graph topology', `document.querySelector('#right-cfg-size').value==='150' && document.querySelectorAll('#right-viewer .cfg-node').length===8 && document.querySelectorAll('#right-viewer .cfg-edge').length===11`);
    await select('#right-cfg-size','75');await evaluate(`document.querySelector('#workspace').scrollIntoView({block:'start'})`);
    await writeFile(new URL(prefix+'-75.png',root),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
    await select('#right-cfg-size','150');
    await writeFile(new URL(prefix+'-150.png',root),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
    await select('#right-cfg-size','fit');await viewport(390,844);
    await check('Fit avoids page and viewer overflow at 390px', `document.documentElement.scrollWidth<=innerWidth && ['left','right'].every(side=>{const v=document.querySelector('#'+side+'-viewer');return v.scrollWidth<=v.clientWidth;})`);
  }
  if(errors.length)throw Error(JSON.stringify(errors));
  await writeFile(new URL(prefix+'.json',root),JSON.stringify({date:new Date().toISOString(),sourceHashes,fit,actual,count:checks.length,checks,runtimeExceptions:errors.length},null,2)+'\n');
  console.log(JSON.stringify({baseline,fit,actual,checks:checks.length}));
}finally{ws.close();}
