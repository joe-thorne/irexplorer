// E3 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9225.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'source.js', 'comparison.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9225/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9225.');
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
  const stamp = Date.now();
  await send('Page.navigate', {url: `http://127.0.0.1:8000/?e3=${stamp}#${path}`});
  await until(`location.search === '?e3=${stamp}' && document.readyState === 'complete' && document.querySelector('#preview-controls')?.hidden === false`);
}
async function consent() {
  await click('#preview-ack'); await click('[data-action="start"]'); await screen('Pre-survey');
}
async function ready() { await until(`appState.ready && !document.querySelector('#workspace').hidden`); }
async function pair(left, right, leftView = 'ir', rightView = 'ir') {
  await select('#left-state', String(left)); await select('#right-state', String(right));
  await select('#left-view', leftView); await select('#right-view', rightView); await ready();
}
async function key(key, code, n, text) {
  await send('Input.dispatchKeyEvent', {type:'keyDown',key,code,windowsVirtualKeyCode:n,...(text ? {text} : {})});
  await send('Input.dispatchKeyEvent', {type:'keyUp',key,code,windowsVirtualKeyCode:n});
}
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Network.setCacheDisabled', {cacheDisabled:false});
  const version=await send('Browser.getVersion');
  // Simulate a browser reusing the E1 app under its original, unversioned URL.
  const fixed=process.env.EXPECT_FIXED==='1';
  const legacy=execFileSync('git',['show','421a219:src/frontend/app.js'],{encoding:'utf8'});
  ws.addEventListener('message', async ({data})=>{
    const m=JSON.parse(data);
    if(m.method==='Fetch.requestPaused') {
      if(!fixed && m.params.resourceType==='Document') {
        const html=(await readFile(new URL('../src/frontend/index.html',import.meta.url),'utf8')).replaceAll('?v=e3-source-fix-1','');
        await send('Fetch.fulfillRequest',{requestId:m.params.requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:'text/html'}],body:Buffer.from(html).toString('base64')});
      } else if(new URL(m.params.request.url).pathname==='/app.js' && !new URL(m.params.request.url).search) {
        await send('Fetch.fulfillRequest',{requestId:m.params.requestId,responseCode:200,responseHeaders:[{name:'Content-Type',value:'text/javascript'}],body:Buffer.from(legacy).toString('base64')});
      } else await send('Fetch.continueRequest',{requestId:m.params.requestId});
    }
  });
  await send('Fetch.enable',{patterns:[{urlPattern:'*/app.js*',requestStage:'Request'}, ...(!fixed?[{resourceType:'Document',requestStage:'Request'}]:[])]});
  await viewport(1440,1000); await navigate('/explore');
  await until(`!document.querySelector('#example-select').disabled`);
  await select('#example-select','score'); await until(`document.querySelector('#notice').textContent.startsWith('score is ready')`);
  if(!fixed) {
    await check('Legacy app reproduces ready notice with untouched C placeholder', `document.querySelector('#notice').textContent.startsWith('score is ready') && document.querySelector('#source-summary').textContent==='C source · choose a curated file' && !document.querySelectorAll('.source-line').length`);
    await capture('e3-cache-reproduction.png',true);
  } else {
    await check('Versioned scripts bypass legacy app and render verified C', `sourceState.data.file==='score.c' && document.querySelectorAll('.source-line').length===11 && document.querySelector('#source-summary').textContent.includes('verified input')`);
    await send('Fetch.disable');
    await send('Page.reload',{ignoreCache:false});
    await until(`document.readyState==='complete' && !document.querySelector('#example-select').disabled && !appState.exampleId`);
    for(const example of ['score','binary_search','quick_sort']) {
      await select('#example-select',example); await ready();
      await check(example+': source loads after normal cached reload', `sourceState.data.file==='${example}.c' && document.querySelectorAll('.source-line').length>0 && appState.summary.exampleId==='${example}'`);
    }
    await click('.source-line[data-line="25"]');
    await click('#right-next'); await ready();
    await check('Source coordination and E3 stepping survive reload', `sourceState.anchors[0].line===25 && appState.panels.right.ordinal===2`);
    await capture('e3-cache-fixed.png',true);
  }
  await check('No browser runtime exceptions', `${errors.length===0}`);
  await writeFile(new URL(fixed?'e3-cache-fixed.json':'e3-cache-reproduction.json',root),JSON.stringify({revision,sourceHashes,version,checks,errors,requests,date:new Date().toISOString()},null,2)+'\n');
  console.log(JSON.stringify({fixed,checks:checks.length,errors:errors.length}));
} finally { ws.close(); }
