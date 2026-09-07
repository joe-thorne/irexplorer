// E4 behavioural verification. Node 22+ built-ins; isolated local headless Chrome on :9226.
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
const root = new URL('../docs/evaluation-captures/', import.meta.url);
const revision = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: new URL('../', import.meta.url), encoding: 'utf8' }).trim();
const sourceHashes = {};
for (const name of ['index.html', 'style.css', 'app.js', 'preview.js', 'study-draft.js', 'source.js', 'comparison.js']) sourceHashes[name] = createHash('sha256').update(await readFile(new URL('../src/frontend/' + name, import.meta.url))).digest('hex');
const pages = await (await fetch('http://127.0.0.1:9226/json/list')).json();
const page = pages.find(p => p.type === 'page' && (p.url === 'about:blank' || p.url.startsWith('http://127.0.0.1:8000/')));
if (!page) throw new Error('Start an isolated headless Chrome at about:blank on :9226.');
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
  await send('Page.navigate', {url: `http://127.0.0.1:8000/?e4=${stamp}#${path}`});
  await until(`location.search === '?e4=${stamp}' && document.readyState === 'complete' && document.querySelector('#preview-controls')?.hidden === false`);
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
try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  const version = await send('Browser.getVersion');
  await viewport(1440, 1100); await navigate('/explore');
  await evaluate('sessionStorage.clear(); localStorage.clear()'); await navigate('/study/post'); await screen('Information and consent');
  await check('Deep link cannot bypass consent; no storage or identifier before consent', `sessionStorage.length === 0 && localStorage.length === 0 && !document.querySelector('.participant-code')`);
  await check('All six consent boxes unchecked and labelled', `[...document.querySelectorAll('.acknowledgement input')].length === 6 && [...document.querySelectorAll('.acknowledgement input')].every(e => !e.checked && e.labels.length === 1)`);
  await click('[data-action="start"]');
  await check('Missing acknowledgements focus first unchecked consent without storage', `document.activeElement.id === 'C1' && !!document.querySelector('#consent-error').textContent && sessionStorage.length === 0`);
  await capture('e4-information-desktop.png');
  await click('[data-action="decline"]'); await screen('Preview declined');
  await check('Decline creates no record', 'sessionStorage.length === 0');
  await click('[data-action="restart"]'); await screen('Information and consent'); await consent();
  await check('Only after consent: crypto UUID, six acknowledgements and explicit blanks', `${stored}.participantCode.match(/^[a-f0-9-]{36}$/) && Object.values(${stored}.consent.acknowledgements).every(Boolean) && Object.values(${stored}.pre).every(a => a.status === 'unanswered' && a.value === null)`);
  await check('All pre fields and conditional labels present in order', `[...document.querySelectorAll('[data-field]')].map(e => e.dataset.field).join() === 'P1,P1.other,P2,P3,P3.other,P4,P5,P6,P7,P8,P9,P10,P11,P12,P12.detail,P13'`);
  await submit();
  await check('Missing P1 inline validation focuses labelled radio', `location.hash === '#/study/pre' && document.activeElement.name === 'P1' && document.activeElement.getAttribute('aria-invalid') === 'true' && document.querySelector('#error-P1').textContent.includes('P1')`);
  await capture('e4-pre-validation-desktop.png');
  await choose('P1', 5); await fill('P1.other', 'Synthetic other'); await choose('P1', 1);
  await check('P1 conditional text cleared when choice changes', `${stored}.pre['P1.other'].status === 'unanswered' && document.querySelector('[data-field="P1.other"]').hidden`);
  await choose('P2', 6);
  await choose('P3', 1); await choose('P3', 6);
  await check('P3 None of these excludes other choices', `${stored}.pre.P3.value.join() === '6' && !document.querySelector('input[name="P3"][value="1"]').checked`);
  await choose('P3', 7); await fill('P3.other', 'Synthetic course');
  await check('Selecting a P3 course excludes None and reveals detail', `${stored}.pre.P3.value.join() === '7' && !document.querySelector('[data-field="P3.other"]').hidden`);
  await choose('P3', 6); await check('P3 detail cleared on None', `${stored}.pre['P3.other'].value === null`);
  await choose('P10', 6); await choose('P10', 1); await check('P10 None exclusive both ways', `${stored}.pre.P10.value.join() === '1'`);
  await choose('P10', 6); await check('P10 selecting None clears tool selection', `${stored}.pre.P10.value.join() === '6'`);
  await choose('P12', 2); await fill('P12.detail', 'Synthetic project'); await choose('P12', 1);
  await check('P12 detail cleared after No', `${stored}.pre['P12.detail'].value === null && document.querySelector('[data-field="P12.detail"]').hidden`);
  await fill('P13', 'Synthetic expectation before exposure.');
  const participant = await evaluate(`${stored}.participantCode`);
  await send('Page.reload'); await screen('Pre-survey');
  await check('Refresh retains same-tab ID, P2 not-applicable and P13', `${stored}.participantCode === ${JSON.stringify(participant)} && document.querySelector('textarea[name="P13"]').value === 'Synthetic expectation before exposure.' && ${stored}.pre.P2.status === 'not_applicable'`);
  await route('/study/post'); await screen('Pre-survey');
  await check('Post deep link gated by saved pre stage', `location.hash === '#/study/pre'`);
  await submit(); await screen('Preview task');
  await check('Preview task entry locks P13 without inventing task data', `${stored}.p13Locked === true && !('tasks' in ${stored})`);
  await route('/study/pre'); await screen('Pre-survey');
  await check('Back navigation displays pre answers read-only', `document.querySelector('textarea[name="P13"]').readOnly && [...document.querySelectorAll('input[name="P1"]')].every(e => e.disabled)`);
  await click('[data-action="edit-pre"]'); await screen('Pre-survey');
  await check('Explicit correction unlocks background only', `!document.querySelector('input[name="P1"]').disabled && document.querySelector('textarea[name="P13"]').readOnly`);
  await click('[data-clear="P1"]');
  await send('Page.reload'); await screen('Pre-survey');
  await check('Incomplete background correction recovers without losing the P13 lock', `${stored}.pre.P1.status === 'unanswered' && ${stored}.p13Locked && document.querySelector('textarea[name="P13"]').readOnly && ${stored}.participantCode === ${JSON.stringify(participant)}`);
  await route('/study/post'); await screen('Pre-survey');
  await check('Cleared P1 correction prevents deep-link progression', `location.hash === '#/study/pre'`);
  await fill('P13', 'Attempted late replacement');
  await choose('P1', 4); await submit(); await screen('Preview task');
  await check('Even synthetic input event cannot replace locked P13', `${stored}.pre.P13.value === 'Synthetic expectation before exposure.' && ${stored}.pre.P1.value === 4`);
  await click('[data-action="post"]'); await screen('Post-survey');
  await check('All 20 post items in original order; 13 separate NA options', `[...document.querySelectorAll('[data-field]')].map(e => e.dataset.field).join() === Array.from({length:20}, (_,i) => 'Q'+(i+1)).join() && document.querySelectorAll('.not-applicable').length === 13`);
  await choose('Q1', 'na'); await choose('Q2', 3);
  await check('NA, neutral and unanswered are distinct', `${stored}.post.Q1.status === 'not_applicable' && ${stored}.post.Q1.value === null && ${stored}.post.Q2.value === 3 && ${stored}.post.Q3.status === 'unanswered'`);
  await fill('Q14', 'Synthetic <script>window.syntheticLeak=true</script>\n=SUM(A1) 🙂');
  await fill('Q15', '🙂'.repeat(4001)); await submit();
  await check('Over-limit text retained with inline actionable error', `location.hash === '#/study/post' && [...${stored}.post.Q15.value].length === 4001 && document.querySelector('#error-Q15').textContent.includes('4,000')`);
  await fill('Q15', '🙂'.repeat(4000));
  await check('Unicode limit uses code points not UTF-16 units', `!document.querySelector('#error-Q15').textContent`);
  await fill('Q15', 'Synthetic comment.');
  await send('Page.reload'); await screen('Post-survey');
  await check('Post refresh restores NA and free text verbatim', `document.querySelector('input[name="Q1"][value="na"]').checked && document.querySelector('textarea[name="Q14"]').value.includes('<script>') && !window.syntheticLeak`);
  const ax = await send('Accessibility.getFullAXTree');
  if (!ax.nodes.some(n => n.role?.value === 'group' && n.name?.value.startsWith('Q1.')) || !ax.nodes.some(n => n.role?.value === 'radio' && n.name?.value.includes('Not applicable / did not use this'))) throw new Error('Missing accessible survey group/option names');
  checks.push('Chrome accessibility tree exposes named question groups and not-applicable radio options');
  await capture('e4-post-desktop.png');
  await viewport(390, 844); await capture('e4-post-narrow.png');
  await evaluate(`document.querySelector('[data-field="Q1"]').scrollIntoView({block:'start'})`);
  const narrowChoices = await send('Page.captureScreenshot', {format:'png', captureBeyondViewport:false});
  await writeFile(new URL('e4-post-narrow-choices.png', root), Buffer.from(narrowChoices.data, 'base64'));
  await check('390px survey has no page-wide overflow', 'document.documentElement.scrollWidth <= innerWidth');
  await check('Every visible form input has a native label and fieldset legend', `[...document.querySelectorAll('#survey-form input, #survey-form textarea')].every(e => e.labels.length > 0 && e.closest('fieldset').querySelector('legend').textContent && e.getAttribute('aria-describedby'))`);
  await viewport(1440, 1100); await submit(); await screen('Review responses — submission pending');
  await check('Review has pending disabled submit, escaped text, no fake receipt', `document.querySelector('#study-screen').textContent.includes('Nothing has been submitted.') && document.querySelector('#study-screen button:disabled').textContent.includes('pending E6') && !window.syntheticLeak && document.querySelector('.response-review').textContent.includes('Unanswered')`);
  await capture('e4-review-desktop.png');
  await click('[data-action="edit-pre"]'); await screen('Pre-survey');
  await check('Review corrections keep P13 locked after reload', `document.querySelector('textarea[name="P13"]').readOnly`);
  await route('/study/post'); await screen('Post-survey');
  await evaluate(`document.querySelector('input[name="Q3"][value="1"]').focus()`);
  await key(' ', 'Space', 32, ' ');
  await check('Native Space chooses a rating', `${stored}.post.Q3.value === 1`);
  await key('ArrowRight', 'ArrowRight', 39);
  await check('Native radio arrow key changes rating', `${stored}.post.Q3.value === 2`);
  await evaluate(`document.querySelector('[data-clear="Q3"]').focus()`); await key('Enter', 'Enter', 13, '\r');
  await check('Native Enter clears a rating to unanswered', `${stored}.post.Q3.status === 'unanswered'`);
  await click('[data-action="stop"]'); await screen('Preview stopped');
  await check('Stop removes answers and identifiers', 'sessionStorage.length === 0 && !document.querySelector(".participant-code")');
  await evaluate('history.back()'); await until(`location.hash !== '#/study/stopped'`);
  await screen('Information and consent');
  await check('Browser Back after stop cannot restore answers', 'sessionStorage.length === 0 && !document.querySelector(".participant-code")');
  // Permission denial is injected before app startup in this isolated synthetic tab.
  const denial = await send('Page.addScriptToEvaluateOnNewDocument', { source: `Object.defineProperty(window, 'sessionStorage', {get() { throw new DOMException('Blocked', 'SecurityError'); }});` });
  await navigate('/study'); await screen('Information and consent');
  await check('Storage unavailability disclosed with explicit memory choice', `document.querySelector('#draft-status').textContent.includes('unavailable') && !!document.querySelector('[data-action="memory"]')`);
  for (let i = 1; i <= 6; i++) await click('#C' + i);
  await click('[data-action="start"]'); await check('No continuation until memory option chosen', `location.hash === '#/study' && !document.querySelector('.participant-code')`);
  await click('[data-action="memory"]'); await click('[data-action="start"]'); await screen('Pre-survey');
  await check('Memory-only limitation visible', `document.querySelector('#draft-status').textContent.includes('refreshing')`);
  await capture('e4-memory-only.png');
  await send('Page.reload'); await screen('Information and consent');
  await check('Memory-only refresh returns to consent', `!document.querySelector('.participant-code')`);
  await send('Page.removeScriptToEvaluateOnNewDocument', { identifier: denial.identifier });
  await navigate('/study'); await screen('Information and consent'); await consent();
  await evaluate(`window.originalSet = Storage.prototype.setItem; Storage.prototype.setItem = function() { throw new DOMException('Quota', 'QuotaExceededError'); }`);
  await choose('P1', 1);
  await check('Mid-trial save failure disclosed, stale snapshot removed', `document.querySelector('#draft-status').textContent.includes('could not be saved') && sessionStorage.length === 0`);
  await submit(); await check('Storage failure blocks stage continuation', `location.hash === '#/study/pre'`);
  await evaluate('Storage.prototype.setItem = window.originalSet'); await click('[data-action="retry-storage"]');
  await check('Retry saves current answers', `${stored}.pre.P1.value === 1`);
  await evaluate(`window.originalRemove = Storage.prototype.removeItem; Storage.prototype.removeItem = function() { throw new DOMException('Blocked', 'SecurityError'); }`);
  await click('[data-action="stop"]');
  await check('Failed discard cannot claim deletion', `location.hash === '#/study/pre' && document.querySelector('#draft-status').textContent.includes('could not be removed') && sessionStorage.length === 1`);
  await evaluate('Storage.prototype.removeItem = window.originalRemove'); await click('[data-action="stop"]'); await screen('Preview stopped');
  await evaluate(`sessionStorage.setItem('irexplorer.study.e4', '{broken')`); await navigate('/study/post'); await screen('Information and consent');
  await check('Corrupt drafts fail closed with discard/restart option', `document.querySelector('#draft-status').textContent.includes('incompatible') && !document.querySelector('.participant-code')`);
  await click('[data-action="stop"]'); await screen('Preview stopped');
  await route('/explore');
  await until(`!document.querySelector('#example-select').disabled`);
  await select('#example-select', 'score');
  await until(`document.querySelector('#source-lines').querySelectorAll('button').length > 0 && !document.querySelector('#workspace').hidden`);
  await check('Direct exploration still loads canonical source and all 14 states', `document.querySelector('#study-screen').hidden && document.querySelector('#left-state').options.length === 14 && sessionStorage.length === 0`);
  // Fail only the participant-content GET on the next reload, then retry it.
  await send('Network.setBlockedURLs', {urls:['*api/study/content*']});
  await navigate('/study'); await screen('Study content unavailable');
  await check('Content failure offers retry without creating a study record', `!!document.querySelector('[data-action="retry-content"]') && sessionStorage.length === 0`);
  await send('Network.setBlockedURLs', {urls:[]});
  await click('[data-action="retry-content"]'); await screen('Information and consent');
  await check('All requests remain GET with no synthetic answer or identifier in URLs', `${JSON.stringify(requests)}.every(r => r.method === 'GET' && !r.url.includes('Synthetic') && !r.url.includes(${JSON.stringify(participant)}))`);
  if (errors.length) throw new Error(JSON.stringify(errors));
  const report = { date: new Date().toISOString(), revision, sourceHashes, browser: version.product, count: checks.length, checks, runtimeExceptions: errors.length, requestMethods: [...new Set(requests.map(r => r.method))], screenshots: ['e4-information-desktop.png','e4-pre-validation-desktop.png','e4-post-desktop.png','e4-post-narrow.png','e4-post-narrow-choices.png','e4-review-desktop.png','e4-memory-only.png'] };
  await writeFile(new URL('e4-browser-checks.json', root), JSON.stringify(report, null, 2) + '\n');
  console.log(`${checks.length} E4 browser assertions passed; ${report.screenshots.length} screenshots.`);
} finally { ws.close(); }
