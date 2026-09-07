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
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable'); await send('Network.setCacheDisabled', {cacheDisabled:true});
  const version = await send('Browser.getVersion');
  await viewport(1440, 1100); await navigate('/explore');
  await until(`!document.querySelector('#example-select').disabled`);
  for (const example of ['score', 'binary_search', 'quick_sort']) {
    await select('#example-select',example); await ready();
    await check(example + ': all 14 labelled states reachable', `['left','right'].every(s => document.querySelector('#'+s+'-state').options.length === 14 && document.querySelector('#'+s+'-state').options[12].text.includes('End of teaching chain') && document.querySelector('#'+s+'-state').options[13].text.includes('Separately compiled -O3'))`);
    const noOp = await evaluate(`appState.states.find(s => s.transition?.noOp).ordinal`);
    for (const [mode,l,r] of [['adjacent',1,2],['non-adjacent',0,9],['same-state',3,3],['reversed',9,0],['no-op',noOp-1,noOp],['recompiled',12,13],['wide-recompiled',0,13]]) {
      await pair(l,r);
      await check(example + ': '+mode+' summary agrees with backend and scope', `appState.summary.fromOrdinal === ${Math.min(l,r)} && appState.summary.toOrdinal === ${Math.max(l,r)} && document.querySelector('#comparison-outcomes').textContent.includes('whole example') && appState.summary.items.slice(0,3).every(i => document.querySelector('#comparison-outcomes').textContent.includes(i.text))`);
      if (mode==='reversed') await check(example+': reversed direction explicit', `document.querySelector('#comparison-action').textContent.includes('Earlier state is on the right')`);
      if (mode.includes('recompiled')) await check(example+': O3 boundary explicit in '+mode, `document.querySelector('#comparison-action').textContent.includes('separately compiled -O3') && !document.querySelector('#pass-purpose').textContent`);
      if (mode==='no-op') await check(example+': no-op evidence inspectable', `appState.summary.items[0].linkIndices.length > 0 && document.querySelector('#comparison-evidence-body').textContent.includes('retained as a no-op')`);
    }
    await pair(0,1);
    const line = await evaluate(`appState.panels.left.mappings[0].location.line`);
    await click('.source-line[data-line="'+line+'"]');
    await evaluate(`document.querySelector('#right-next').focus()`); await key('Enter','Enter',13,'\r'); await ready();
    await check(example+': native Enter steps right only and preserves source', `appState.panels.left.ordinal===0 && appState.panels.right.ordinal===2 && sourceState.anchors[0].line===${line} && document.activeElement.id==='right-next'`);
    await evaluate(`document.querySelector('#right-previous').focus()`); await key(' ','Space',32,' '); await ready();
    await check(example+': native Space steps back', `appState.panels.right.ordinal===1`);
    await pair(0,13);
    await check(example+': boundary step buttons disabled', `document.querySelector('#left-previous').disabled && document.querySelector('#right-next').disabled`);
    await pair(3,3,'cfg','cfg');
    await check(example+': rendered CFG exactly preserves nodes/edges and visible paths', `['left','right'].every(s => { const cfg=appState.panels[s].cfg; const svg=document.querySelector('#'+s+'-viewer svg'); const edges=[...svg.querySelectorAll('.cfg-edge')]; return svg.querySelectorAll('.cfg-node').length===cfg.blocks.length && edges.length===cfg.edges.length && edges.every((p,i)=>p.dataset.fromId===cfg.edges[i].fromId && p.dataset.toId===cfg.edges[i].toId && p.getTotalLength()>20) && [...svg.querySelectorAll('.cfg-node')].every(g=>g.querySelector('text').getBBox().width < +g.querySelector('rect').getAttribute('width')); })`);
    await check(example+': directed endpoints outside node interiors', `['left','right'].every(s => [...document.querySelectorAll('#'+s+'-viewer .cfg-edge')].every(p => { const end=p.getPointAtLength(p.getTotalLength()); const g=document.querySelector('#'+s+'-viewer .cfg-node[data-node-id="'+CSS.escape(p.dataset.toId)+'"]'); const m=g.transform.baseVal.getItem(0).matrix; const w=+g.querySelector('rect').getAttribute('width'); return (end.x < m.e || end.x > m.e+w) && p.getAttribute('marker-end'); }))`);
  }
  await select('#example-select','score'); await ready();
  await pair(0,12); await check('T1: actual baseline and final teaching IR remain inspectable', `document.querySelectorAll('#left-viewer .ir-line').length===41 && document.querySelectorAll('#right-viewer .ir-line').length===5 && document.querySelector('#right-state-label').textContent.includes('End of teaching chain')`);
  await capture('e3-score-ir-ir.png',true);
  await pair(0,1); await click('.source-line[data-line="3"]');
  await check('T2: computation visible before the pass', `document.querySelector('#right-viewer').textContent.includes('mul nsw')`);
  await click('#right-next'); await ready();
  await check('T2: actual IR changes and source absence is honest', `!document.querySelector('#right-viewer').textContent.includes('%mul1 =') && !document.querySelector('#right-viewer').textContent.includes('%mul2 =') && !document.querySelector('#right-viewer').textContent.includes('%sub =') && sourceState.anchors[0].line===3 && document.querySelector('#source-status').textContent.includes('No recorded source mapping')`);
  await select('#example-select','binary_search'); await ready(); await pair(3,3,'ir','cfg');
  await click('#left-viewer [data-node-id="fn0/bb1/i2"]');
  await check('T3: loop condition selects the CFG block and true/false destinations', `document.querySelector('#right-viewer .cfg-node[data-node-id="fn0/bb1"]').classList.contains('is-linked') && appState.panels.right.cfg.edges.filter(e=>e.fromId==='fn0/bb1').map(e=>e.label).join(',')==='true,false' && document.querySelector('#right-viewer details').textContent.includes('while.cond → while.body: true')`);
  await capture('e3-binary-search-ir-cfg.png',true);
  await pair(6,7,'cfg','cfg');
  await check('T4: 7/9 to 8/11 topology and non-zero self-loop', `appState.panels.left.cfg.blocks.length===7 && appState.panels.left.cfg.edges.length===9 && appState.panels.right.cfg.blocks.length===8 && appState.panels.right.cfg.edges.length===11 && [...document.querySelectorAll('#right-viewer .cfg-edge')].some(p=>p.dataset.fromId===p.dataset.toId && p.getTotalLength()>80)`);
  await evaluate(`for (const side of ['left','right']) document.querySelector('#'+side+'-viewer').scrollTop=150`);
  await capture('e3-binary-search-cfg-cfg.png',true);
  await evaluate(`document.querySelector('#right-viewer .cfg-node[data-node-id="fn0/bb2"]').focus()`); await key(' ','Space',32,' ');
  await until(`!!appState.selection`);
  await check('Native Space selects CFG and reveals source evidence', `appState.panels.right.selectedNodeIds.has('fn0/bb2') && sourceState.anchors.length > 0 && document.querySelector('#selection-evidence').hidden===false`);
  await select('#example-select','quick_sort'); await ready(); await pair(0,9);
  await evaluate(`document.querySelector('#left-viewer [data-node-id="fn0/bb0/i9"]').focus()`); await key('Enter','Enter',13,'\r');
  await until(`appState.selection?.text.includes('approximate')`);
  await check('T5: approximate match and composed comparison visible without task hints', `document.querySelector('#selection-status').textContent.includes('approximate confidence') && document.querySelector('#comparison-action').textContent.includes('no single pass') && document.querySelector('#selection-evidence pre').textContent.includes('approximate')`);
  await click('#comparison-evidence > summary');
  await check('Full summary evidence opens independently of selection confidence', `document.querySelector('#comparison-evidence').open && document.querySelector('#comparison-evidence-body').textContent.includes('fromNodeIds') && document.querySelector('#selection-status').textContent.includes('approximate')`);
  await capture('e3-quick-sort-evidence.png',true);
  await select('#function-select','partition'); await ready();
  await check('Function change updates panes and clears selection while summary scope stays explicit', `appState.panels.left.function.name==='partition' && !appState.selection && !sourceState.anchors.length && document.querySelector('#comparison-outcomes').textContent.includes('whole example')`);
  await viewport(390,844); await capture('e3-quick-sort-narrow.png',true);
  await check('390px page and evidence have no horizontal overflow; panes bounded', `document.documentElement.scrollWidth<=innerWidth && [...document.querySelectorAll('.viewer-content')].every(e=>e.clientHeight<=320) && document.querySelector('#right-state-label').scrollWidth<=document.querySelector('#right-state-label').clientWidth`);
  await evaluate(`document.querySelector('#left-next').focus()`); await key('Tab','Tab',9);
  await check('Native Tab reaches view selector after step controls', `document.activeElement.id==='left-view'`);
  await send('Emulation.setEmulatedMedia',{features:[{name:'forced-colors',value:'active'},{name:'prefers-reduced-motion',value:'reduce'}]});
  await pair(6,7,'cfg','cfg');
  await check('Forced colours keep paths visible and source distinct', `getComputedStyle(document.querySelector('.cfg-edge')).stroke !== 'none' && getComputedStyle(document.querySelector('.cfg-edge')).fill === 'none' && matchMedia('(prefers-reduced-motion: reduce)').matches`);
  await send('Emulation.setEmulatedMedia',{features:[]});
  // Delayed summary responses must not replace newer state data or expose old evidence.
  await evaluate(`window.originalFetch=window.fetch; window.fetch=async(...args)=>{const r=await originalFetch(...args); if(String(args[0]).includes('/summary') && String(args[0]).includes('toOrdinal=2')) await new Promise(r=>setTimeout(r,350)); return r;}`);
  await select('#right-state','2'); await select('#right-state','13'); await ready();
  await evaluate(`new Promise(r=>setTimeout(r,500))`);
  await check('Delayed summary cannot overwrite latest panes or O3 explanation', `appState.summary.toOrdinal===13 && document.querySelector('#comparison-action').textContent.includes('separately compiled -O3')`);
  await evaluate(`window.fetch=async(...args)=>String(args[0]).includes('/summary') ? new Response(JSON.stringify({error:{message:'Synthetic summary failure'}}),{status:503}) : originalFetch(...args)`);
  await select('#right-state','1'); await until(`document.querySelector('.error-message')?.textContent.includes('Synthetic summary failure')`);
  await check('Summary failure hides stale workspace and evidence', `!appState.ready && document.querySelector('#workspace').hidden && !appState.summary && !document.querySelector('#comparison-evidence-body').textContent`);
  await evaluate(`window.fetch=originalFetch`); await select('#example-select','score'); await ready();
  await check('Reload recovers from summary failure', `appState.summary.exampleId==='score'`);
  await route('/study'); await screen('Information and consent'); await consent(); await click('[data-action="next"]'); await screen('Preview task');
  await check('Task context remains reachable at 390px', `!document.querySelector('#workspace-shell').hidden && document.documentElement.scrollWidth<=innerWidth`);
  await viewport(1440,1100); await capture('e3-task-desktop.png',true);
  await check('No runtime exceptions or write traffic', `${errors.length===0 && requests.every(r=>r.method==='GET')}`);
  await writeFile(new URL('e3-browser-checks.json',root),JSON.stringify({revision,sourceHashes,date:new Date().toISOString(),version,checks,errors,requests},null,2)+'\n');
  console.log(JSON.stringify({checks:checks.length,errors:errors.length}));
} finally { ws.close(); }
