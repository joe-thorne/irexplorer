// E5 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9230.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'study-draft.js', 'source.js', 'comparison.js', 'task-clock.js', 'vendor/dagre-1.1.5.min.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9230/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9230.');
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
const preventFocusScroll=process.argv.includes('--prevent-focus-scroll');
const prefix=baseline ? preventFocusScroll ? 'e5-routing-before-focus' : 'e5-routing-before' : 'e5-routing-after';
async function shot(name) {
  const {data}=await send('Page.captureScreenshot',{format:'png'});
  await writeFile(new URL(name,root),Buffer.from(data,'base64'));
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Emulation.setFocusEmulationEnabled',{enabled:true});
  await viewport(1440,1000); await navigate('/explore'); await evaluate('sessionStorage.clear()'); await navigate('/study');
  if(preventFocusScroll) await evaluate(`{const nativeFocus=HTMLElement.prototype.focus;HTMLElement.prototype.focus=function(options){return nativeFocus.call(this,this.id==='route-heading'?{...options,preventScroll:true}:options);};}`);
  await consent(); await choose('P1',1); await submit(); await task('T0');
  await evaluate(`document.querySelector('#study-screen').scrollTop=10000`); await submit(); await task('T1');
  await fill('T1a','Synthetic retained response');
  await evaluate(`document.querySelector('#study-screen').scrollTop=10000`);
  await check('Task panel is independently scrolled before continuing', `document.querySelector('#study-screen').scrollTop > 300`);
  await click('#survey-form button[type="submit"]'); await task('T2'); await wait(150);
  const scroll=await evaluate(`({top:document.querySelector('#study-screen').scrollTop,heading:document.querySelector('#route-heading').getBoundingClientRect().top,panel:document.querySelector('#study-screen').getBoundingClientRect().top})`);
  if(!baseline) await check('Next task resets independent panel to its heading', `document.querySelector('#study-screen').scrollTop===0 && document.querySelector('#route-heading').getBoundingClientRect().top >= document.querySelector('#study-screen').getBoundingClientRect().top`);
  await shot(prefix+'-task.png');
  await click('[data-action="skip-task"]'); await task('T3'); await click('[data-action="skip-task"]'); await task('T4');
  await click('#source-summary');
  await evaluate(`document.querySelector('#workspace').scrollIntoView({block:'start'});document.querySelector('#study-screen').scrollTop=0`);
  const dimensions=await evaluate(`['left','right'].map(side=>{const v=document.querySelector('#'+side+'-viewer'),s=v.querySelector('svg');return {side,viewerWidth:v.clientWidth,graphWidth:s.getBoundingClientRect().width,graphHeight:s.getBoundingClientRect().height,viewBox:s.getAttribute('viewBox'),nodes:s.querySelectorAll('.cfg-node').length,edges:s.querySelectorAll('.cfg-edge').length};})`);
  await shot(prefix+'-cfg.png');
  if(!baseline) {
    await check('T4 topology remains seven/nine and eight/eleven', `document.querySelectorAll('#left-viewer .cfg-node').length===7 && document.querySelectorAll('#left-viewer .cfg-edge').length===9 && document.querySelectorAll('#right-viewer .cfg-node').length===8 && document.querySelectorAll('#right-viewer .cfg-edge').length===11`);
    await check('Both graphs fit inside their desktop pane', `['left','right'].every(side=>{const v=document.querySelector('#'+side+'-viewer'),s=v.querySelector('svg');return s.getBoundingClientRect().width<=v.clientWidth-12 && v.scrollWidth<=v.clientWidth;})`);
    await check('Layered graph stays compact', `document.querySelector('#right-viewer svg').viewBox.baseVal.height < 850`);
    await check('All directed edges keep visible paths/arrowheads including self-loop', `[...document.querySelectorAll('.cfg-edge')].every(p=>p.getTotalLength()>5 && p.getAttribute('marker-end')) && [...document.querySelectorAll('#right-viewer .cfg-edge')].some(p=>p.dataset.fromId===p.dataset.toId && p.getTotalLength()>40)`);
    await check('Branches occupy separate columns', `new Set([...document.querySelectorAll('#right-viewer .cfg-node')].map(n=>Math.round(n.transform.baseVal.consolidate().matrix.e))).size>2`);
    await check('Edge labels are horizontal', `[...document.querySelectorAll('.cfg-edge-label')].every(n=>!n.hasAttribute('transform'))`);
    await evaluate(`document.querySelector('#right-viewer .cfg-edge').focus()`);
    await check('Keyboard focus isolates a directed edge', `document.querySelector('#right-viewer svg').classList.contains('is-tracing') && document.querySelectorAll('#right-viewer .is-traced').length===1`);
    await evaluate('document.activeElement.blur()');
    await fill('T4b','Synthetic CFG answer');
    await select('#right-cfg-size','actual');
    await check('Actual-size option enlarges graph while leaving other pane and answers alone', `document.querySelector('#right-viewer svg').getBoundingClientRect().width===Number(document.querySelector('#right-viewer svg').viewBox.baseVal.width) && document.querySelector('#left-cfg-size').value==='fit' && ${stored}.tasks.T4.answers.T4b.value==='Synthetic CFG answer'`);
    await evaluate(`document.querySelector('#right-viewer .cfg-node').focus()`); await key('Enter','Enter',13,'\r');
    await until(`document.querySelector('#right-viewer .cfg-node.is-selected')`);
    await check('Keyboard CFG selection and graph-size preference survive rendering', `document.querySelector('#right-cfg-size').value==='actual' && !!document.querySelector('#right-viewer .cfg-node.is-selected')`);
    await select('#right-cfg-size','fit');
    await viewport(1200,900);
    await check('Fit follows narrower desktop panes without rerendering', `['left','right'].every(side=>{const v=document.querySelector('#'+side+'-viewer');return v.scrollWidth<=v.clientWidth;})`);
    await shot(prefix+'-1200.png');
    await viewport(390,844);
    await check('Narrow graph stays within pane and page', `document.documentElement.scrollWidth<=innerWidth && ['left','right'].every(side=>{const v=document.querySelector('#'+side+'-viewer');return v.scrollWidth<=v.clientWidth;})`);
    await evaluate(`document.querySelector('#right-viewer').scrollIntoView({block:'start'})`); await shot(prefix+'-390.png');
    await viewport(1440,1000); await click('[data-action="skip-task"]'); await task('T5');
    await check('Skip also resets task scroll and retains prior answers', `document.querySelector('#study-screen').scrollTop===0 && ${stored}.tasks.T4.answers.T4b.value==='Synthetic CFG answer'`);
    await route('/study/tasks/T4'); await until(`document.querySelector('#survey-form')?.dataset.stage==='T4'`);
    await check('Read-only revisit starts at top, preserves locks', `document.querySelector('#study-screen').scrollTop===0 && document.querySelector('.task-inputs').disabled`);
    // Compact geometry must keep every curated label, path, and arrow inside its SVG.
    await route('/explore'); await until(`document.querySelector('#study-screen').hidden`);
    for(const example of ['score','binary_search','quick_sort']) {
      await select('#example-select',example); await until('window.StudyWorkspace.ready');
      await select('#left-view','cfg'); await select('#right-view','cfg'); await until('window.StudyWorkspace.ready');
      const functions=await evaluate(`[...document.querySelector('#function-select').options].map(o=>o.value)`);
      for(let ordinal=0;ordinal<14;ordinal++) {
        await select('#left-state',String(ordinal)); await select('#right-state',String(ordinal)); await until('window.StudyWorkspace.ready');
        for(const name of functions) {
          await select('#function-select',name); await until('window.StudyWorkspace.ready');
          await check(`Compact geometry ${example}/${ordinal}/${name}: labels, nodes and edges remain contained`, `['left','right'].every(side=>{
            const s=document.querySelector('#'+side+'-viewer svg'),box=s.viewBox.baseVal;
            return s.querySelectorAll('.cfg-node').length===appState.panels[side].cfg.blocks.length && s.querySelectorAll('.cfg-edge').length===appState.panels[side].cfg.edges.length && [...s.querySelectorAll('.cfg-node')].every(n=>n.querySelector('text').getComputedTextLength()<=Number(n.querySelector('rect').getAttribute('width'))-20) &&
              [...s.querySelectorAll('.cfg-node,.cfg-edge')].every(n=>{const b=n.getBBox();const m=n.transform.baseVal.consolidate()?.matrix;const x=b.x+(m?.e||0),y=b.y+(m?.f||0);return x>=0&&y>=0&&x+b.width<=box.width&&y+b.height<=box.height;});
          })`);
        }
      }
    }

  }
  if(errors.length) throw Error(JSON.stringify(errors));
  await writeFile(new URL(prefix+'.json',root),JSON.stringify({date:new Date().toISOString(),revision,sourceHashes,baseline,preventFocusScroll,scroll,dimensions,count:checks.length,checks,runtimeExceptions:errors.length},null,2)+'\n');
  console.log(JSON.stringify({baseline,scroll,dimensions,checks:checks.length}));
} finally {ws.close();}
