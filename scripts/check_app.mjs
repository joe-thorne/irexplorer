// Application regression. Node 22+ and an isolated headless Chrome CDP.
// Optional IREXPLORER_CHECK_OUTPUT directory for screenshots and JSON; otherwise stdout only.
import { writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';

const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const captures = process.env.IREXPLORER_CHECK_OUTPUT;
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
if (captures) await mkdir(captures, { recursive: true });
const release = await (await fetch(base + '/api/release')).json();
const publicContent = await (await fetch(base + '/api/study/content')).json();
const purposeText = publicContent.information.flatMap(section => section.blocks).find(block => block.role === 'study-purpose')?.text;
const submissionText = publicContent.information.flatMap(section => section.blocks).find(block => block.role === 'submission-guidance')?.text;

// A new tab has no opener and no inherited session draft, making reruns independent.
const page = await (await fetch(`${cdp}/json/new?about:blank`, { method: 'PUT' })).json();
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
async function check(name, expression) { const result = await value(expression); if (!result) throw Error(`Failed: ${name}; observed=${JSON.stringify(await value(`(() => { const e=document.activeElement,t=document.querySelector('#ir-help-tooltip'),panels=[document.querySelector('#source-panel'),document.querySelector('#left-viewer').closest('.viewer-panel'),document.querySelector('#right-viewer').closest('.viewer-panel')].map(p=>{const c=p.querySelector('.source-lines,.viewer-content'),l=p.querySelector('.source-line,.ir-line'),s=getComputedStyle(p);return {id:p.id,className:p.className,panel:p.getBoundingClientRect().height,computed:s.height,inline:p.style.height,content:c?.clientHeight,line:l?.getBoundingClientRect().height,scrollHeight:c?.scrollHeight};}); return { hash:location.hash, active:{tag:e.tagName,id:e.id,className:e.className,text:e.innerText?.slice(0,80)}, heading:document.querySelector('#route-heading')?.textContent, tooltip:{hidden:t?.hidden,text:t?.textContent,html:t?.innerHTML,children:t?.childElementCount},panels }; })()`))}`); checks.push(name); }
async function click(selector) { await value(`document.querySelector(${JSON.stringify(selector)}).click()`); }
async function hover(selector) {
  const point = await value(`(() => { const r = document.querySelector(${JSON.stringify(selector)}).getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 0, y: 0 });
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', ...point });
}
async function key(key, code, codePoint) {
  await send('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: codePoint, ...(key.length === 1 ? { text: key } : {}) });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: codePoint });
}
async function tabUntil(expression, limit = 400) {
  for (let i = 0; i < limit; i += 1) {
    if (await value(expression)) return;
    await key('Tab', 'Tab', 9);
    if (await value(expression)) return;
  }
  throw Error(`Tab navigation did not reach: ${expression}; active=${JSON.stringify(await value(`(() => { const e = document.activeElement; return { tag: e.tagName, id: e.id, className: e.className, text: e.innerText?.slice(0, 80) }; })()`))}`);
}
async function checkSectionsScrollable(name, selectors) {
  const expression = `(() => { const enough = document.documentElement.scrollHeight > innerHeight; const height = innerHeight; const sections = ${JSON.stringify(selectors)}.map(selector => { const element = document.querySelector(selector); if (!element) return { selector, missing: true }; element.scrollIntoView({ block: 'start', behavior: 'instant' }); const rect = element.getBoundingClientRect(); return { selector, top: rect.top, bottom: rect.bottom }; }); window.scrollTo(0, 0); return { enough, height, sections }; })()`;
  const result = await value(expression);
  if (!result.enough || result.sections.some(section => section.missing || section.bottom <= 0 || section.top >= result.height)) throw Error(`Failed: ${name} ${JSON.stringify(result)}`);
  checks.push(name);
}
async function choose(name, option) { await click(`input[name="${name}"][value="${option}"]`); }
async function fill(name, text) { await value(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${JSON.stringify(text)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`); }
async function route(path) { await value(`location.hash = ${JSON.stringify(path)}`); }
async function screen(name) {
  try { await until(`document.querySelector('#route-heading')?.textContent === ${JSON.stringify(name)}`); }
  catch (error) { throw Error(`${error.message}; hash=${JSON.stringify(await value('location.hash'))}; draft=${JSON.stringify(await value("sessionStorage.getItem('irexplorer.study.v0.11')"))}; visible=${JSON.stringify(await value("document.querySelector('#study-screen')?.innerText.slice(0, 600)"))}; consent=${JSON.stringify(await value("[...document.querySelectorAll('.acknowledgement input')].map(e=>[e.id,e.checked])"))}`); }
  await check(`Route focus: ${name}`, `document.activeElement.id === 'route-heading'`);
}
async function snap(name) {
  if (!captures) return;
  await value('document.activeElement.blur(); window.scrollTo(0, 0)');
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(join(captures, name), Buffer.from(data, 'base64'));
}
async function snapAt(name, selector) {
  if (!captures) return;
  await value(`document.activeElement.blur(); document.querySelector(${JSON.stringify(selector)}).scrollIntoView({ block: 'start', behavior: 'instant' })`);
  await new Promise(resolve => setTimeout(resolve, 250));
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(join(captures, name), Buffer.from(data, 'base64'));
}
async function checkCompactWorkspace(routeName) {
  await check(`${routeName} hides the empty status row`, `(() => { const notice = document.querySelector('#notice'), original = notice.textContent; notice.textContent = ''; const hidden = getComputedStyle(notice).display === 'none' && notice.getBoundingClientRect().height === 0; notice.textContent = original; return hidden; })()`);
  await check(`${routeName} keeps State identity in each selector and help for assistive technology`, `['left','right'].every(side => { const select=document.querySelector('#' + side + '-state'), help=document.querySelector('#' + side + '-description'); return select.selectedOptions[0].textContent.includes('State') && !document.querySelector('#' + side + '-state-label') && help.classList.contains('sr-only') && help.textContent.includes('hover or focus for help'); })`);
  await check(`${routeName} aligns equal-height C and IR code areas`, `(() => { const panels=['#source-panel','#left-panel','#right-panel'].map(selector=>document.querySelector(selector).getBoundingClientRect()), views=['#source-lines','#left-viewer','#right-viewer'].map(selector=>document.querySelector(selector).getBoundingClientRect()); return panels.every(panel=>Math.abs(panel.height-panels[0].height)<1 && panel.height>=innerHeight*.72) && views.every((view,index)=>Math.abs((view.top-panels[index].top)-(views[0].top-panels[0].top))<1 && Math.abs((panels[index].bottom-view.bottom)-(panels[0].bottom-views[0].bottom))<1); })()`);
  await check(`${routeName} places IR code just below its controls`, `['left','right'].every(side => { const panel=document.querySelector('#' + side + '-panel'), controls=panel.querySelector('.viewer-controls').getBoundingClientRect(), code=panel.querySelector('.viewer-content').getBoundingClientRect(); return code.top-controls.bottom<16; })`);
  await check(`${routeName} puts File inside the non-collapsible C panel`, `(() => { const source=document.querySelector('#source-panel'), file=document.querySelector('#example-select'); return source.tagName==='SECTION' && source.contains(file) && !source.querySelector('summary') && !document.querySelector('#workspace-shell > .toolbar'); })()`);
  await check(`${routeName} keeps the comparison close when status is empty`, `(() => { const notice = document.querySelector('#notice'), original = notice.textContent; notice.textContent = ''; const panels = [document.querySelector('#source-panel'), document.querySelector('#left-panel'), document.querySelector('#right-panel')].map(e => e.getBoundingClientRect()); const comparison = document.querySelector('.comparison-status').getBoundingClientRect(); const compact = comparison.top - Math.max(...panels.map(p => p.bottom)) < 16; notice.textContent = original; return compact; })()`);
  await check(`${routeName} tightens code rows and line-number gutters`, `(() => { const source = document.querySelector('.source-line'), ir = document.querySelector('.ir-line'), signature = document.querySelector('.ir-signature'), firstBlock = document.querySelector('.ir-block'); const compact = (line, maxGap) => { const row = getComputedStyle(line), number = getComputedStyle(line.querySelector('.line-number')); return parseFloat(row.lineHeight) / parseFloat(getComputedStyle(line).fontSize) <= 1.35 && parseFloat(number.width) <= 36 && parseFloat(row.columnGap || row.gap) <= maxGap; }; return compact(source, 24) && compact(ir, 8) && signature && firstBlock && firstBlock.getBoundingClientRect().top - signature.getBoundingClientRect().bottom < 20; })()`);
  await check(`${routeName} uses the State selector without a repeated title`, `['left','right'].every(side => { const panel=document.querySelector('#' + side + '-panel'), heading=panel.querySelector('.viewer-heading').getBoundingClientRect(), view=panel.querySelector('.viewer-content').getBoundingClientRect(); return heading.bottom===view.top && !panel.querySelector('.state-label') && panel.querySelector('h2').textContent===(side==='left'?'Left':'Right'); })`);
}
async function select(selector, selected) {
  await value(`(() => { const e = document.querySelector(${JSON.stringify(selector)}); e.value = ${JSON.stringify(selected)}; e.dispatchEvent(new Event('change', { bubbles: true })); })()`);
}
async function task(id) {
  await until(`document.querySelector('#survey-form')?.dataset.section === '${id}'`);
  const examples = { T0: 'score', T1: 'score', T2: 'score', T3: 'binary_search', T4: 'binary_search', T5: 'quick_sort' };
  await until(`window.StudyWorkspace.ready && document.querySelector('#example-select').value === ${JSON.stringify(examples[id] || 'quick_sort')}`);
  if (id !== 'T6') await check(`${id} starts ready at State 0 with IR in both panels and a clear selection`, `(() => { const saved = JSON.parse(sessionStorage.getItem('irexplorer.study.v0.11')); return ['left', 'right'].every(side => document.querySelector('#' + side + '-state').value === '0' && document.querySelector('#' + side + '-view').value === 'ir') && !appState.selection && !appState.selectionInput && saved.tasks.${id}.presented && !document.querySelector('.task-complete').disabled; })()`);
  await check(`${id} timer starts at presentation and has no setup gate`, `document.querySelector('#task-timing').textContent.includes('presentation') && !document.querySelector('[data-action="pause-task"]').disabled && !document.querySelector('[data-action="skip-task"]')?.disabled`);
  if (id === 'T5') {
    await select('#left-state', '8'); await select('#right-state', '9');
    await select('#function-select', 'partition'); await until(`window.StudyWorkspace.ready && appState.functionName === 'partition'`);
    await click('.source-line[data-line="8"]'); await until('Boolean(appState.selection?.trace)');
    await until(`[...document.querySelectorAll('#right-viewer .ir-line')].some(line => line.textContent.includes('getelementptr') && (line.classList.contains('is-source') || line.classList.contains('is-linked')))`);
    const targetSelector = await value(`(() => { const target = [...document.querySelectorAll('#right-viewer .ir-line')].find(line => line.textContent.includes('getelementptr') && (line.classList.contains('is-source') || line.classList.contains('is-linked'))); return target ? '#right-viewer .ir-line[data-node-id="' + target.dataset.nodeId + '"]' : ''; })()`);
    if (!targetSelector) throw Error('T5 highlighted right-panel getelementptr was not found.');
    await click(targetSelector); await until(`appState.selectionInput?.side === 'right'`);
    await check('T5 selection shows approximate correspondence confidence and its separate likely explanation', `document.querySelector('#selection-status').textContent.includes('merged · approximate confidence') && document.querySelector('#optimisation-explanations').textContent.includes('Induction-variable widening · likely')`);
    await check('T5 identifies the relationship, link confidence and qualified explanation separately', `document.querySelector('#task-instructions').innerText.includes('confidence wording appears beside the link') && document.querySelector('#task-instructions').innerText.includes('Keep the link’s confidence separate')`);
    await check('Study uses the selected three-panel workbench before responses', `(() => { const box = selector => document.querySelector(selector).getBoundingClientRect(); const panels = [box('#source-panel'),box('#left-panel'),box('#right-panel')]; const response = box('#task-responses'); const comparison = box('.comparison-status'); return panels.every(panel=>Math.abs(panel.height-panels[0].height)<1) && panels[0].left < panels[1].left && panels[1].left < panels[2].left && comparison.width >= panels[0].width + panels[1].width + panels[2].width - 40 && response.top > panels[1].bottom && response.width >= panels[0].width + panels[1].width + panels[2].width - 40 && document.querySelector('#task-responses').compareDocumentPosition(document.querySelector('#left-state')) & Node.DOCUMENT_POSITION_PRECEDING; })()`);
    await checkCompactWorkspace('Study desktop');
    await check('Study places the C panel close to the instructions', `document.querySelector('#source-panel').getBoundingClientRect().top - document.querySelector('#study-screen').getBoundingClientRect().bottom <= 24`);
    await check('Study desktop IR panels show about thirty code lines', `(() => { const panels=[document.querySelector('#left-panel'),document.querySelector('#right-panel')]; return panels.every(p=>{const view=p.querySelector('.viewer-content'), line=view.querySelector('.ir-line'); return line && view.clientHeight >= line.getBoundingClientRect().height*28;}); })()`);
    await snapAt('study-T5-desktop-workspace.png', '#workspace-shell');
    await checkSectionsScrollable('Study desktop page scrolling reaches instructions, workspace, analysis and responses', ['#task-instructions','#workspace-shell','.comparison-status','#task-responses']);
    await value("document.querySelector('#route-heading').focus()");
    await key('Tab', 'Tab', 9);
    await check('Study Tab begins with the instruction jump', `document.activeElement.matches('.task-jumps a[href="#task-instructions"]')`);
    await key('Tab', 'Tab', 9);
    await check('Study Tab order reaches the workspace jump second', `document.activeElement.matches('.task-jumps a[href="#workspace-shell"]')`);
    await key('Tab', 'Tab', 9);
    await check('Study Tab order reaches the responses jump third', `document.activeElement.matches('.task-jumps a[href="#task-responses"]')`);
    await value("document.querySelector('#left-state').focus()");
    await tabUntil(`document.activeElement.id === 'right-state'`);
    await check('Study Tab advances from left State controls through its IR content to the right State', `document.activeElement.id === 'right-state'`);
    await tabUntil(`document.activeElement.matches('.task-responses-details summary')`);
    await check('Study Tab reaches responses after the comparison evidence', `document.activeElement.matches('.task-responses-details summary')`);
    await snap('study-T5-desktop.png');
    await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "cfg"');
    await check('Study desktop presents the CFG beside C source and LLVM IR', `document.querySelector('#source-lines .source-line') && document.querySelector('#left-viewer .ir-line') && document.querySelector('#right-viewer .cfg-svg')`);
    await snapAt('study-T5-desktop-cfg.png', '#workspace-shell');
    await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "ir"');
    await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
    await check('Study State selectors and T5 instructions remain visible at narrow width', `document.querySelector('#workspace-shell').getBoundingClientRect().width <= innerWidth && document.querySelector('#left-state').getBoundingClientRect().width > 0 && document.querySelector('#task-instructions').getBoundingClientRect().width > 0`);
    await checkCompactWorkspace('Study narrow');
    await check('Study narrow keeps the C panel close to the instructions', `document.querySelector('#source-panel').getBoundingClientRect().top - document.querySelector('#study-screen').getBoundingClientRect().bottom <= 24`);
    await check('Study workbench stacks equal-height panels in reading order', `(() => { const panels = ['#source-panel','#left-panel','#right-panel'].map(selector=>document.querySelector(selector).getBoundingClientRect()); return document.documentElement.scrollWidth <= innerWidth && panels.every(panel=>panel.width>=300 && Math.abs(panel.height-panels[0].height)<1) && panels[0].top<panels[1].top && panels[1].top<panels[2].top && document.querySelector('#task-responses').getBoundingClientRect().top>panels[2].bottom; })()`);
    await check('Study narrow IR panels show at least ten code lines', `['left','right'].every(side=>{const view=document.querySelector('#' + side + '-viewer'), line=view.querySelector('.ir-line'); return line && view.clientHeight>=line.getBoundingClientRect().height*10;})`);
    await snapAt('study-T5-narrow-workspace.png', '#workspace-shell');
    await snapAt('study-T5-narrow-ir.png', '#left-panel');
    await checkSectionsScrollable('Study narrow page scrolling reaches instructions, workspace, analysis and responses', ['#task-instructions','#workspace-shell','.comparison-status','#task-responses']);
    await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "cfg"');
    await check('Study narrow presents a readable CFG beside C source and LLVM IR without page overflow', `document.querySelector('#source-lines .source-line') && document.querySelector('#left-viewer .ir-line') && document.querySelector('#right-viewer .cfg-svg') && document.documentElement.scrollWidth <= innerWidth`);
    await snapAt('study-T5-narrow-cfg.png', '#right-panel');
    await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "ir"');
    await value("document.querySelector('#route-heading').focus()");
    await key('Tab', 'Tab', 9);
    await key('Tab', 'Tab', 9);
    await key('Tab', 'Tab', 9);
    await check('Study narrow Tab order reaches instructions, workspace and response jumps in order', `document.activeElement.matches('.task-jumps a[href="#task-responses"]')`);
    await value("document.querySelector('#left-state').focus()");
    await tabUntil(`document.activeElement.id === 'right-state'`);
    await tabUntil(`document.activeElement.matches('.task-responses-details summary')`);
    await check('Study narrow Tab advances through the stacked workspace before responses', `document.activeElement.matches('.task-responses-details summary')`);
    await snap('study-T5-narrow.png');
    await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
    await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "cfg"');
    await value("document.querySelector('#route-heading').focus()");
  }
  if (id === 'T3') {
    await check('Study gives short and long task responses the same narrow width', `(() => { const responses=document.querySelector('#task-responses'), short=responses.querySelector('[data-field="T3a"]')?.getBoundingClientRect(), long=responses.querySelector('[data-field="T3b"]')?.getBoundingClientRect(), width=responses.getBoundingClientRect().width; return short && long && short.width<width*.65 && Math.abs(short.width-long.width)<1 && short.top<long.top; })()`);
  }
  if (id === 'T4') {
    await check('Study gives ordinary task questions one width and confidence ratings five columns', `(() => { const responses=document.querySelector('#task-responses'), width=responses.getBoundingClientRect().width, fields=['T4a','T4b','T4c','T4d'].map(id=>responses.querySelector('[data-field="' + id + '"]')), boxes=fields.map(field=>field?.getBoundingClientRect()); if(boxes.some(box=>!box)) return false; const cards=[...fields[3].querySelectorAll('.rating-options .answer-option')], columns=getComputedStyle(fields[3].querySelector('.rating-options')).gridTemplateColumns.split(' '); return boxes.slice(0,3).every(box=>box.width<width*.65 && Math.abs(box.width-boxes[0].width)<1) && boxes.every((box,index)=>index===0 || box.top>boxes[index-1].top) && boxes[3].width>width*.85 && columns.length===5 && cards.length>=5 && cards[0].getBoundingClientRect().top===cards[1].getBoundingClientRect().top; })()`);
  }
  if (id === 'T0') {
    await check('T0 presents the C to IR to CFG and back-link exercise', `document.querySelector('#task-instructions').innerText.includes('follow its highlight into IR') && document.querySelector('#task-instructions').innerText.includes('links back to IR instructions and C lines')`);
    await check('Study selectors identify the baseline as State 0', `['left','right'].every(side => document.querySelector('#' + side + '-state').selectedOptions[0].textContent.includes('State 0 · Unoptimised baseline (-O0)'))`);
    await snap('study-T0-desktop.png');
  }
  if (id === 'T1') await check('T1 reassures participants that a brief or partial answer is fine', `document.querySelector('#task-instructions').innerText.includes('A brief or partial answer is fine')`);
  if (id === 'T2') await check('T2a uses a compact dropdown with its existing State and inability choices', `(() => { const field=document.querySelector('[data-field="T2a"]'), select=field.querySelector('select[name="T2a"]'), options=[...select.options]; return field.querySelector('legend').innerText.includes('Which State is the first in which this arithmetic is absent') && select.value==='' && options.some(option=>option.textContent.includes('State 2 · produced by instcombine')) && options.some(option=>option.textContent.includes('State 0 (the unoptimised version)')) && options.find(option=>option.textContent==='I could not work this out')?.dataset.status==='could_not_work_out'; })()`);
  if (id === 'T6') await check('T6 offers continuing from its inherited workspace once or choosing another State pair', `document.querySelector('#task-instructions').innerText.includes('continues from T5 with its selection cleared') && document.querySelector('#task-instructions').innerText.includes('choose another example, State pair') && (document.querySelector('#task-instructions').innerText.match(/Your workspace continues from T5/g) || []).length === 1`);
  if (id === 'T6') await check('T6 inherits T5 workspace and clears its selection', `document.querySelector('#example-select').value === 'quick_sort' && document.querySelector('#left-state').value === '8' && document.querySelector('#right-state').value === '9' && document.querySelector('#left-view').value === 'ir' && document.querySelector('#right-view').value === 'cfg' && appState.functionName === 'partition' && !appState.selection && !appState.selectionInput`);
  if (id === 'T6') {
    await send('Page.reload');
    await until(`document.querySelector('#survey-form')?.dataset.section === 'T6' && window.StudyWorkspace.ready`);
    await check('T6 restores its inherited workspace after refresh and clears the selection', `document.querySelector('#example-select').value === 'quick_sort' && document.querySelector('#left-state').value === '8' && document.querySelector('#right-state').value === '9' && document.querySelector('#left-view').value === 'ir' && document.querySelector('#right-view').value === 'cfg' && appState.functionName === 'partition' && !appState.selection && !appState.selectionInput`);
  }
  await check(`${id} keeps the task goal programmatically reachable`, `location.hash === '#/study/tasks/${id}' && document.querySelector('#route-heading')?.tabIndex === -1`);
}

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `${base}/` });
  await until(`document.readyState === 'complete'`);
  await until(`document.querySelectorAll('#example-select option').length === 4`);
  await until(`document.title === 'Explore · irexplorer'`);
  await check('Default page opens Explore without entering Study', `!location.hash && document.querySelector('#study-screen').hidden && !document.querySelector('#explore-heading').hidden`);
  await select('#example-select', 'score');
  await until('window.StudyWorkspace?.ready');
  await select('#example-select', 'quick_sort'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '3'); await select('#right-state', '4'); await until('window.StudyWorkspace.ready');
  await select('#function-select', 'quick_sort'); await until(`window.StudyWorkspace.ready && appState.functionName === 'quick_sort'`);
  await click('.source-line[data-line="18"]'); await until('appState.selection?.evidence?.remarks?.length > 0');
  await check('A curated quick_sort compiler remark displays its file name without the repository path',
    `(() => { const remark = appState.selection.evidence.remarks.find(item => item.location?.line === 18); const raw = document.querySelector('#compiler-remarks .compiler-remark pre')?.textContent || ''; return Boolean(remark) && remark.location.file === 'quick_sort.c' && raw.includes("File: 'quick_sort.c'") && !raw.includes('examples/curated/'); })()`);
  await select('#example-select', 'score'); await until('window.StudyWorkspace.ready');
  await check('Explore uses aligned code panels with full-width evidence below', `(() => { const box=selector=>document.querySelector(selector).getBoundingClientRect(), panels=['#source-panel','#left-panel','#right-panel'].map(box), evidence=box('.comparison-status'); return panels.every(panel=>Math.abs(panel.height-panels[0].height)<1) && panels[0].left<panels[1].left && panels[1].left<panels[2].left && evidence.top>panels[1].bottom && evidence.width>=panels[0].width+panels[1].width+panels[2].width-40 && document.documentElement.scrollHeight>innerHeight; })()`);
  await checkCompactWorkspace('Explore desktop');
  await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "cfg"');
  await check('Explore desktop presents the CFG beside C source and LLVM IR', `document.querySelector('#source-lines .source-line') && document.querySelector('#left-viewer .ir-line') && document.querySelector('#right-viewer .cfg-svg')`);
  await snapAt('explore-desktop-cfg.png', '#workspace-shell');
  await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "ir"');
  await checkSectionsScrollable('Explore desktop page scrolling reaches workspace, panels and analysis', ['#workspace-shell','#source-panel','#left-panel','#right-panel','.comparison-status']);
  await value("document.querySelector('#example-select').focus()");
  await key('Tab', 'Tab', 9);
  await check('Explore Tab order moves from File to the first C line', `document.activeElement === document.querySelector('#source-lines .source-line')`);
  await check('Explore names the comparison, trace and trace evidence', `document.body.innerText.includes('State-to-State comparison') && document.querySelector('.current-selection .comparison-label').textContent === 'Trace' && [...document.querySelectorAll('.comparison-section-title')][1].textContent === 'Trace evidence'`);
  await check('Steps label only the State-to-State comparison', `document.querySelector('#ir-step-heading').textContent === 'Steps' && document.querySelector('#source-mapping-heading').parentElement.querySelector('.comparison-caption').textContent === 'Source mapping'`);
  await check('State comparison names the curated pass sequence', `document.querySelector('#comparison-action').textContent.includes('curated pass sequence')`);
  await check('All three curated examples are available', `document.querySelectorAll('#example-select option').length === 4`);
  await check('Explore State labels distinguish baseline, pass-produced and separately compiled States', `document.querySelector('#left-state').options[0].textContent.includes('State 0 · Unoptimised baseline (-O0)') && document.querySelector('#left-state').options[1].textContent.includes('State 1 · produced by mem2reg') && document.querySelector('#left-state').options[13].textContent.includes('State 13 · Separately compiled with -O3')`);
  await check('Explore State identity appears in the selector and comparison summary', `document.querySelector('#left-state').selectedOptions[0].textContent.includes('State 0') && document.querySelector('#left-selected-state').textContent.includes('State 0 · Unoptimised baseline')`);
  await check('Source box contains only source and heading', `document.querySelector('#source-prompt').hidden && !/Compiler debug|debugLoc/.test(document.querySelector('#source-panel').innerText)`);
  await check('Comparison has no expandable evidence', `document.querySelectorAll('.comparison-status details').length === 0`);
  await check('IR symbols offer novice hover help', `[...document.querySelectorAll('#left-viewer .token-value[data-help]')].some(token => token.dataset.help.includes('%')) && document.querySelector('#left-viewer .token-opcode[data-help]') !== null`);

  await check('Help tokens have visible dotted underlines and a help cursor', `(() => { const s = getComputedStyle(document.querySelector('.ir-help')); return s.textDecorationStyle === 'dotted' && s.cursor === 'help'; })()`);
  await value(`window.helpToken = document.querySelector('#left-viewer .ir-help'); helpToken.scrollIntoView({ block: 'center' }); window.helpStarted = performance.now();`);
  await hover('#left-viewer .ir-help');
  await check('Hover help uses a short intentional delay', `document.querySelector('#ir-help-tooltip').hidden`);
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('Help appears promptly and describes the hovered token', `performance.now() - helpStarted < 600 && document.querySelector('#ir-help-tooltip').textContent === helpToken.dataset.help && !helpToken.hasAttribute('title')`);
  await key('Escape', 'Escape', 27);
  await check('Escape dismisses help', `document.querySelector('#ir-help-tooltip').hidden`);
  await value('helpToken.focus()');
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('Keyboard focus exposes accessible help', `document.activeElement.getAttribute('aria-describedby') === 'ir-help-tooltip'`);
  await value('helpToken.blur()');
  await value("document.querySelector('#left-state').focus()");
  await tabUntil(`document.activeElement.id === 'right-state'`);
  await check('Explore Tab advances through the left panel to the right State', `document.activeElement.id === 'right-state'`);
  await snap('explore-desktop.png');
  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
  await check('Explore State controls fit the narrow viewport', `document.querySelector('#workspace-shell').getBoundingClientRect().width <= innerWidth && document.querySelector('#left-state').getBoundingClientRect().width > 0 && document.documentElement.scrollWidth <= innerWidth`);
  await checkCompactWorkspace('Explore narrow');
  await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "cfg"');
  await check('Explore narrow presents a readable CFG beside C source and LLVM IR without page overflow', `document.querySelector('#source-lines .source-line') && document.querySelector('#left-viewer .ir-line') && document.querySelector('#right-viewer .cfg-svg') && document.documentElement.scrollWidth <= innerWidth`);
  await snapAt('explore-narrow-cfg.png', '#right-panel');
  await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready && document.querySelector("#right-view").value === "ir"');
  await check('Explore workbench stacks equal-height panels at narrow width', `(() => { const panels=['#source-panel','#left-panel','#right-panel'].map(selector=>document.querySelector(selector).getBoundingClientRect()); return panels.every(panel=>panel.width>=300 && Math.abs(panel.height-panels[0].height)<1) && panels[0].top<panels[1].top && panels[1].top<panels[2].top && document.querySelector('.comparison-status').getBoundingClientRect().top>panels[2].bottom; })()`);
  await checkSectionsScrollable('Explore narrow page scrolling reaches all stacked panels and analysis', ['#source-panel','#left-panel','#right-panel','.comparison-status']);
  await value("document.querySelector('#example-select').focus()");
  await key('Tab', 'Tab', 9);
  await check('Explore narrow Tab reaches the first C line from File', `document.activeElement === document.querySelector('#source-lines .source-line')`);
  await snap('explore-narrow.png');
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await click('.source-line[data-line="3"]');
  await check('Source line highlights mapped IR in both panels', `document.querySelectorAll('.source-line.is-source').length === 1 && document.querySelectorAll('#left-viewer .is-source, #right-viewer .is-source').length > 0`);

  await check('C selection follows recorded cross-state links', `appState.selection?.trace.links.length > 0 && document.querySelector('#selection-status').textContent.includes('recorded link')`);
  await check('Trace labels its readable relations', `document.querySelector('#selection-status').textContent.includes('relation:')`);
  await value(`document.querySelector('.source-line[data-line="5"]').dispatchEvent(new MouseEvent('click', { bubbles: true, shiftKey: true }))`);
  await check('Shift-click selects the complete C range', `JSON.stringify(sourceState.sourceLocations.map(a => a.line)) === '[3,4,5]' && document.querySelectorAll('.source-line.is-source').length === 3`);
  await value(`document.querySelector('.source-line[data-line="6"]').dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', shiftKey: true, bubbles: true }))`);
  await check('Keyboard range selection retains its starting line', `JSON.stringify(sourceState.sourceLocations.map(a => a.line)) === '[3,4,5,6]'`);
  await value(`window.traceBeforeView = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await check('IR to CFG preserves instruction membership', `window.traceBeforeView === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort())) && document.querySelector('#right-viewer .cfg-node.is-linked title').textContent.includes('instructions belong to the current trace')`);
  await select('#right-view', 'ir'); await until('window.StudyWorkspace.ready');
  await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await click('#left-viewer .ir-block-heading');
  await check('IR block selection includes every member instruction', `appState.selectionInput.kind === 'node' && appState.panels.left.selectedInstructionIds.size === appState.panels.left.function.blocks[0].instructions.length && document.activeElement.classList.contains('ir-block-heading')`);
  await value(`window.blockTrace = document.querySelector('#selection-status').textContent; window.blockMembers = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .cfg-node').dispatchEvent(new MouseEvent('click', { bubbles: true }))`);
  await check('Equivalent IR and CFG block selections have identical results', `window.blockTrace === document.querySelector('#selection-status').textContent && window.blockMembers === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'ir'); await until('window.StudyWorkspace.ready');
  await click('#left-viewer .ir-line');
  await value(`window.instructionTrace = JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort()))`);
  await select('#left-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await select('#left-view', 'ir'); await until('window.StudyWorkspace.ready');
  await check('An instruction remains precise across an IR-CFG-IR round trip', `window.instructionTrace === JSON.stringify(['left', 'right'].map(side => [...appState.panels[side].selectedInstructionIds].sort())) && appState.panels.left.selectedInstructionIds.size === 1`);
  await click('.source-line[data-line="3"]');
  await select('#right-state', '1'); await until('window.StudyWorkspace.ready');
  await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await check('Source absence in Right is reflected by the trace count', `document.querySelector('#right-trace-count').textContent === '0'`);


  await check('Cancellation explanation labels the interpretation as likely', `document.querySelector('#optimisation-explanations').textContent.includes('Algebraic simplification · likely')`);
  await click('.source-line[data-line="2"]');
  await check('Selection presents only its recorded structural claims', `(() => { const text = document.querySelector('#structural-claims').textContent; return text.includes('Recorded structural claims') && text.includes('instructions changed') && !text.includes('CFG unchanged'); })()`);
  await check('Selection shows optimisation name, purpose and concrete change', `(() => { const text = document.querySelector('#optimisation-explanations').textContent; return text.includes('Strength reduction') && text.includes('Purpose:') && text.includes('What changed: Multiplication by 32 becomes a left shift by 5.'); })()`);
  await check('Multiple intermediate transformations can explain one source selection', `document.querySelector('#optimisation-explanations').textContent.includes('Local-variable promotion')`);
  await value(`window.explanationText = document.querySelector('#optimisation-explanations').textContent`);
  await select('#left-state', '2'); await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await check('Reversing panels preserves chronological optimisation explanations', `document.querySelector('#optimisation-explanations').textContent === window.explanationText`);
  await select('#left-state', '0'); await select('#right-state', '12'); await until('window.StudyWorkspace.ready');
  await check('Long comparisons identify the intermediate step', `(() => { const event = appState.comparisonReport.optimisations.find(e => e.name === 'Strength reduction'); return event.fromOrdinal === 1 && event.toOrdinal === 2 && document.querySelector('#optimisation-explanations').textContent.includes(event.fromStateId + ' → ' + event.toStateId); })()`);
  await click('.source-line[data-line="4"]');
  await check('Changing selection removes unrelated explanations', `!document.querySelector('#optimisation-explanations').textContent.includes('Strength reduction') && document.querySelector('#optimisation-explanations').textContent.includes('Arithmetic canonicalisation')`);
  await select('#left-state', '12'); await until('window.StudyWorkspace.ready');
  await check('Same-state selection says no cross-state optimisation is being compared', `document.querySelector('#optimisation-explanations').textContent.includes('no cross-state optimisation change is being compared')`);
  await select('#example-select', 'quick_sort'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '12'); await select('#right-state', '13'); await select('#left-view', 'ir'); await select('#right-view', 'ir'); await until('appState.comparisonReport?.fromOrdinal === 12 && appState.comparisonReport?.toOrdinal === 13');
  await value(`window.exactRemoval = appState.comparisonReport.links.find(link => link.relation === 'removed' && link.confidence === 'exact');`);
  await check('Curated comparison includes an exact removal', `Boolean(exactRemoval)`);
  const removalFunction = await value(`appState.panels.left.ir.functions.find(fn => fn.id === exactRemoval.fromNodeIds[0].split('/')[0]).name`);
  await select('#function-select', removalFunction); await until('window.StudyWorkspace.ready'); await value(`selectNode('left', exactRemoval.fromNodeIds[0])`);
  await check('Exact removal and unresolved coverage remain distinct', `document.querySelector('#selection-status').textContent.includes('removed · exact confidence') && document.querySelector('#selection-status').textContent.includes('unresolved') && document.querySelector('#selection-status').textContent.includes('cannot be traced with the available evidence')`);
  await value(`window.unresolvedRemoval = appState.comparisonReport.links.find(link => link.relation === 'removed' && link.confidence === 'unresolved');`);
  await check('Curated comparison includes unresolved correspondence coverage', `Boolean(unresolvedRemoval)`);
  const unresolvedFunction = await value(`appState.panels.left.ir.functions.find(fn => fn.id === unresolvedRemoval.fromNodeIds[0].split('/')[0]).name`);
  await select('#function-select', unresolvedFunction); await until('window.StudyWorkspace.ready'); await value(`selectNode('left', unresolvedRemoval.fromNodeIds[0])`);
  await check('Unresolved coverage remains participant-visible and qualified', `document.querySelector('#selection-status').textContent.includes('unresolved') && document.querySelector('#selection-status').textContent.includes('cannot be traced with the available evidence')`);
  await select('#example-select', 'score'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '0'); await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await click('.source-line[data-line="3"]');
  await check('C selection recomputes against a newly selected state', `appState.selectionInput.kind === 'source' && appState.selection.trace.links.every(link => appState.comparisonReport.links.includes(link))`);
  await select('#left-state', '2'); await select('#right-state', '0'); await until('window.StudyWorkspace.ready');
  await click('#right-viewer .ir-line');
  await check('Right-origin tracing works with reversed state order', `appState.selectionInput.side === 'right' && appState.selection.trace.links.length > 0`);
  await select('#right-state', '1'); await until('window.StudyWorkspace.ready');
  await check('Changing the origin state clears stale instruction IDs', `!appState.selectionInput || appState.selectionInput.kind === 'source' || appState.selectionInput.ordinal === appState.panels.right.ordinal`);
  await select('#left-state', '0'); await select('#right-state', '2'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .ir-line').focus()`); await key('Enter', 'Enter', 13);
  await until(`Boolean(appState.selection?.trace)`);
  await check('Keyboard Enter exposes the recorded selected-link evidence', `Boolean(appState.selection?.trace) && document.querySelector('#selection-status').textContent.includes('recorded link')`);
  await select('#left-view', 'cfg'); await select('#right-view', 'cfg'); await until('window.StudyWorkspace.ready');
  await value(`document.querySelector('#left-viewer .cfg-edge').focus()`); await check('Keyboard-focusable CFG route is visibly isolated', `document.querySelector('#left-viewer svg').classList.contains('is-tracing')`);
  await value('document.activeElement.blur()');
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
  await check('Reduced motion preference is honoured', `matchMedia('(prefers-reduced-motion: reduce)').matches && getComputedStyle(document.documentElement).scrollBehavior === 'auto'`);
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'forced-colors', value: 'active' }] });
  await check('Forced colours retains a visible CFG node border', `getComputedStyle(document.querySelector('.cfg-node rect')).stroke !== 'none'`);
  await send('Emulation.setEmulatedMedia', { features: [] });
  await value(`window.testFetch = window.fetch; window.fetch = async (...args) => { if (String(args[0]).includes('/source')) throw Error('Synthetic source outage'); return window.testFetch(...args); };`);
  await select('#example-select', 'binary_search'); await until(`document.querySelector('#source-status').textContent.includes('Source unavailable')`);
  await value('window.fetch = window.testFetch'); await select('#example-select', 'binary_search'); await until('window.StudyWorkspace.ready');
  await check('Source loading failure can be recovered', `document.querySelector('#source-status').textContent.includes('Select a C line')`);


  await select('#example-select', 'quick_sort'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '3'); await select('#right-state', '4'); await select('#left-view', 'ir'); await select('#right-view', 'ir'); await until('appState.comparisonReport?.fromOrdinal === 3 && appState.comparisonReport?.toOrdinal === 4');
  await select('#function-select', 'partition'); await until(`appState.functionName === 'partition' && window.StudyWorkspace.ready`); await click('.source-line[data-line="12"]'); await until('Boolean(appState.selection?.evidence)');
  await check('Selection presents relevant captured compiler remarks with their recorded step', `(() => { const text = document.querySelector('#compiler-remarks').textContent; const remarks = appState.selection?.evidence?.remarks || []; return remarks.length > 0 && remarks.every(remark => remark.location && sourceMatches(remark.location, appState.selection.trace.sourceLocations)) && text.includes('Captured compiler remarks') && text.includes('recorded remarks are evidence') && text.includes('not a complete explanation of compiler intent') && text.includes('absence does not establish that no optimisation occurred') && text.includes('Recorded step: State 3 → State 4'); })()`);

  await select('#example-select', 'quick_sort'); await until('window.StudyWorkspace.ready');
  await select('#left-state', '8'); await select('#right-state', '9'); await until('window.StudyWorkspace.ready');
  await value(`window.mergeGroup = appState.comparisonReport.links.find(link => link.relation === 'merged');`);
  await check('Curated comparison includes a two-to-one group', `mergeGroup.fromNodeIds.length === 2 && mergeGroup.toNodeIds.length === 1`);
  const groupFunction = await value(`appState.panels.left.ir.functions.find(fn => fn.blocks.some(block => block.instructions.some(i => i.id === mergeGroup.fromNodeIds[0]))).name`);
  await select('#function-select', groupFunction); await until('window.StudyWorkspace.ready');
  await value(`selectNode('left', mergeGroup.fromNodeIds[0])`);
  await check('Selecting either merged input highlights the complete group', `appState.panels.left.selectedInstructionIds.size === 2 && appState.panels.right.selectedInstructionIds.size === 1 && document.querySelector('#selection-status').textContent.includes('merged')`);
  await value(`selectNode('right', mergeGroup.toNodeIds[0])`);
  await check('Selecting the merged result traces both inputs', `appState.panels.left.selectedInstructionIds.size === 2 && appState.panels.right.selectedInstructionIds.size === 1`);
  await check('Grouped rewrite has a succinct explanation', `document.querySelector('#optimisation-explanations').textContent.includes('Induction-variable widening · likely') && document.querySelector('#optimisation-explanations').textContent.includes('64-bit loop index')`);
  await check('Comparison separates states, trace and steps', `document.querySelectorAll('.comparison-state').length === 2 && document.querySelector('#selection-context').textContent.includes('Right panel') && document.querySelector('#ir-step-heading').closest('section').contains(document.querySelector('#optimisation-explanations')) && document.querySelector('#source-mapping-heading').closest('section').contains(document.querySelector('#source-status'))`);
  await check('Source mapping text only describes Left', `!document.querySelector('#source-status').textContent.includes('Right:')`);
  await snap('workspace.png');
  await route('/study'); await screen('Information and consent');
  await check('Opening information page explains Continue is at the bottom', `document.querySelector('#study-screen').innerText.includes('Continue button is at the bottom of this page')`);
  await check('Participant information shows no unresolved researcher annotations', `!document.querySelector('#study-screen').innerText.includes('[Joe/Joel to confirm')`);
  await check('The final information section appears once and before consent', `(() => { const questions=[...document.querySelectorAll('.participant-information h3')].filter(h=>h.textContent==='Questions'); return questions.length===1 && questions[0].compareDocumentPosition(document.querySelector('#C1')) & Node.DOCUMENT_POSITION_FOLLOWING; })()`);
  await check('Study navigation identifies its current sections', `document.querySelector('#study-progress').getAttribute('aria-label') === 'Study sections' && document.querySelector('#study-progress [aria-current="step"]') !== null`);
  await check('Information role blocks render their compiled label and packaged wording once, before general information', `(() => { const purpose = [...document.querySelectorAll('.study-purpose')]; const information = document.querySelector('.participant-information'); return purpose.length === 1 && purpose[0].textContent === ${JSON.stringify(`${publicContent.messages['information.purpose-label']} ${purposeText}`)} && Boolean(information && (purpose[0].compareDocumentPosition(information) & Node.DOCUMENT_POSITION_FOLLOWING)); })()`);
  await check('Submission guidance renders its compiled label and packaged wording once', `(() => { const guidance = [...document.querySelectorAll('.submission-guidance')]; return guidance.length === 1 && guidance[0].textContent === ${JSON.stringify(`${publicContent.messages['information.submission-label']} ${submissionText}`)}; })()`);
  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
  await check('Opening purpose and final-only submission guidance fit the narrow viewport', `document.documentElement.scrollWidth <= innerWidth && ['.study-purpose','.submission-guidance'].every(selector => { const rect = document.querySelector(selector)?.getBoundingClientRect(); return rect && rect.width > 0 && rect.left >= 0 && rect.right <= innerWidth; })`);
  await value("document.querySelector('#route-heading').focus()");
  await tabUntil(`document.activeElement.matches('[data-action="start"]')`);
  await check('Narrow keyboard journey reaches Continue after the information and consent copy', `document.activeElement.matches('[data-action="start"]') && document.activeElement.getBoundingClientRect().top < innerHeight && document.querySelector('.participant-information').getBoundingClientRect().bottom < document.activeElement.getBoundingClientRect().top`);
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await check('Clean study interface and release label', `document.querySelector('#app-version').textContent === ${JSON.stringify(release.version === 'development' ? 'Development' : `v${release.version}`)} && !/synthetic|preview|not.live|E7/i.test(document.body.innerText) && !location.search`);
  await value(`document.querySelector('#C1').focus()`); await key(' ', 'Space', 32);
  await check('Keyboard Space operates consent checkbox', `document.querySelector('#C1').checked`);
  for (let i = 2; i <= 6; i += 1) await click('#C' + i);
  await click('[data-action="start"]'); await screen('Pre-survey');
  await choose('P1', '1'); await fill('P13', 'Container test background response');
  await choose('P3', '7'); await choose('P3', '9'); await fill('P3_other_name', 'Synthetic course');
  await check('Pre-survey records studied courses and optional named Other', `document.querySelector('[data-field="P3"] input[name="P3"][value="7"]:checked') !== null && document.querySelector('[data-field="P3"] input[name="P3"][value="9"]:checked') !== null && document.querySelector('[data-field="P3_other_name"] textarea').value === 'Synthetic course'`);
  await check('Course exposure distinguishes explicit none from unanswered', `(() => { const field=document.querySelector('[data-field="P3"]'); return field.innerText.includes('None of these') && field.innerText.includes('studying or have you studied') && field.querySelector('input[name="P3"][value="8"]')?.type === 'checkbox'; })()`);
  await send('Page.reload'); await screen('Pre-survey');
  await check('Ordinary refresh restores course selections without a special URL', `document.querySelector('input[name="P1"][value="1"]').checked && document.querySelector('textarea[name="P13"]').value === 'Container test background response' && document.querySelector('input[name="P3"][value="7"]').checked && document.querySelector('input[name="P3"][value="9"]').checked && document.querySelector('textarea[name="P3_other_name"]').value === 'Synthetic course' && !location.search`);
  await value(`window.taskTimingFetch = window.fetch; window.fetch = async (input, ...args) => { if (String(input) === '/api/examples/score/states') await new Promise(resolve => setTimeout(resolve, 1250)); return taskTimingFetch(input, ...args); };`);
  await click('#survey-form button[type="submit"]');
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T0'`);
  await new Promise(resolve => setTimeout(resolve, 1100));
  await check('Task-presentation duration accumulates before the example comparison is ready', `!window.StudyWorkspace.ready && JSON.parse(sessionStorage.getItem('irexplorer.study.v0.11')).tasks.T0.durationMs >= 500`);
  await value('window.fetch = window.taskTimingFetch');
  await task('T0');
  await check('T0 distinguishes its orientation from tasks T1–T6 and renders help terms safely', `document.querySelector('#task-instructions').innerText.includes('T0 is the orientation; the six tasks are T1–T6') && document.querySelector('#task-instructions').querySelector('img,script') === null && [...document.querySelectorAll('#task-instructions .study-term-help')].map(term=>term.textContent).includes('-O0') && [...document.querySelectorAll('#task-instructions .study-term-help')].map(term=>term.textContent).includes('-O3')`);
  await value(`window.studyFlag = [...document.querySelectorAll('#task-instructions .study-term-help')].find(term=>term.textContent==='-O0'); studyFlag.focus()`);
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('T0 keyboard focus explains -O0 accessibly', `studyFlag.getAttribute('aria-describedby')==='ir-help-tooltip' && document.querySelector('#ir-help-tooltip').textContent.includes('disables optimisation')`);
  await value(`studyFlag.blur()`);
  await hover('#task-instructions .study-term-help[data-help*="disables optimisation"]');
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('T0 -O0 also exposes its explanation on hover using text content', `document.querySelector('#ir-help-tooltip').textContent.includes('disables optimisation') && document.querySelector('#ir-help-tooltip').childElementCount===0`);
  await value(`window.studyFlag = [...document.querySelectorAll('#task-instructions .study-term-help')].find(term=>term.textContent==='-O3'); studyFlag.focus()`);
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('T0 keyboard focus explains -O3 as a separate high-optimisation build', `studyFlag.getAttribute('aria-describedby')==='ir-help-tooltip' && document.querySelector('#ir-help-tooltip').textContent.includes('separately compiled state')`);
  await value(`window.studyFlag = [...document.querySelectorAll('#task-instructions .study-term-help')].find(term=>term.textContent==='CFG'); studyFlag.focus()`);
  await until(`!document.querySelector('#ir-help-tooltip').hidden`);
  await check('T0 keyboard focus explains CFG without raw markup', `studyFlag.getAttribute('aria-describedby')==='ir-help-tooltip' && document.querySelector('#ir-help-tooltip').textContent.includes('Control-flow graph') && !document.querySelector('#ir-help-tooltip').querySelector('img,script')`);
  await click('[data-action="pause-task"]');
  await check('Pause disables task completion', `document.querySelector('.task-inputs').disabled`);
  await click('[data-action="pause-task"]');
  await check('T0 opens at its named C example and a ready comparison', `document.querySelector('#example-select').value === 'score' && document.querySelector('#left-state').value === '0' && document.querySelector('#right-state').value === '0' && !document.querySelector('.task-complete').disabled`);
  await click('#survey-form button[type="submit"]');
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5', 'T6']) {
    if (id === 'T1' || id === 'T2') {
      await task(id);
      await check(`${id} can finish or skip without matching the requested comparison`, `!document.querySelector('[data-action="skip-task"]').disabled && !document.querySelector('.task-complete').disabled`);
      await click(id === 'T1' ? '[data-action="skip-task"]' : '[data-action="unable-task"]');
      continue;
    }
    await task(id);
    if (id === 'T4') await snap('task-cfg.png');
    await click('[data-action="skip-task"]');
  }
  await screen('Post-survey'); await choose('Q1', 'na'); await fill('Q14', 'Container test post answer'); await click('#survey-form button[type="submit"]'); await screen('Review answers');
  await check('Review provides an explicit final submission action', `!!document.querySelector('[data-action="submit-responses"]')`);
  await check('Review says nothing has been submitted before the final action', `(() => { const notice = [...document.querySelectorAll('#study-screen p')].find(p => p.innerText.includes('Nothing has been submitted.')); const submit = document.querySelector('[data-action="submit-responses"]'); return Boolean(notice && submit && (notice.compareDocumentPosition(submit) & Node.DOCUMENT_POSITION_FOLLOWING)); })()`);
  await snap('study-review.png');
  await value(`window.testFetch = window.fetch; window.fetch = async (...args) => { const response = await window.testFetch(...args); if (args[0] === '/api/study/submissions') throw Error('Synthetic lost acknowledgement'); return response; };`);
  await click('[data-action="submit-responses"]'); await screen('Receipt not yet confirmed');
  await check('Uncertain attempt says a record may exist and directs the participant to retry the same submission', `!document.querySelector('#survey-form') && document.querySelector('#study-screen').textContent.includes('may already exist') && document.querySelector('#study-screen').textContent.includes('same submission ID and answers')`);
  if (captures) await writeFile(join(captures, 'pending.json'), await value(`sessionStorage.getItem('irexplorer.submission.v3')`));
  await send('Page.reload'); await screen('Receipt not yet confirmed');
  await click('[data-action="retry-submit"]'); await screen('Submission received');
  await check('Retry confirms receipt storage and removes answer draft', `document.querySelector('#study-screen').innerText.includes('Your submission has been saved.') && document.querySelector('#study-screen').innerText.includes('Receipt:') && sessionStorage.getItem('irexplorer.study.v0.11') === null && JSON.parse(sessionStorage.getItem('irexplorer.submission.v3')).kind === 'receipt'`);

  await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: false });
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 2 });
  await check('200% emulated zoom has no page-width overflow', `document.documentElement.scrollWidth <= innerWidth`);
  await send('Emulation.setPageScaleFactor', { pageScaleFactor: 1 }); await snap('receipt-narrow.png');

  const newTarget = await send('Target.createTarget', { url: 'about:blank' });
  const second = (await (await fetch(`${cdp}/json/list`)).json()).find(item => item.id === newTarget.targetId);
  const other = new WebSocket(second.webSocketDebuggerUrl); await new Promise(resolve => other.addEventListener('open', resolve, { once: true }));
  let otherId = 0; const otherPending = new Map();
  other.addEventListener('message', ({ data }) => { const message = JSON.parse(data); if (otherPending.has(message.id)) { const resolve = otherPending.get(message.id); otherPending.delete(message.id); resolve(message.result); } });
  const otherSend = (method, params = {}) => new Promise(resolve => { const id = ++otherId; otherPending.set(id, resolve); other.send(JSON.stringify({ id, method, params })); });
  await otherSend('Runtime.enable'); await otherSend('Page.enable'); await otherSend('Page.navigate', { url: `${base}/#/study` });
  for (let attempt = 0; attempt < 100; attempt += 1) { const result = await otherSend('Runtime.evaluate', { expression: `document.querySelector('#route-heading')?.textContent`, returnByValue: true }); if (result.result.value === 'Information and consent') break; await new Promise(resolve => setTimeout(resolve, 75)); }
  const isolated = await otherSend('Runtime.evaluate', { expression: `!sessionStorage.getItem('irexplorer.study.v0.11') && !document.querySelector('[data-action="new-study"]')`, returnByValue: true });
  if (!isolated.result.value) throw Error('Failed: Independent browser tab does not start without the first tab’s draft.');
  checks.push('Independent browser tab has no first-session draft or receipt'); other.close(); await send('Target.closeTarget', { targetId: newTarget.targetId });
  await route('/explore'); await select('#example-select', 'score');
  await until('!document.querySelector("#workspace").hidden && window.StudyWorkspace?.ready');
  await value(`window.originalFetch = window.fetch; window.fetch = (input, options) => String(input).includes('/comparison-report') ? Promise.resolve(new Response(JSON.stringify({ error: { code: 'data_unavailable', message: 'Model records are temporarily unavailable.' } }), { status: 503, headers: { 'Content-Type': 'application/json' } })) : window.originalFetch(input, options);`);
  await select('#right-state', '10');
  await until(`document.querySelector('.error-state .error-message')?.textContent === 'Model records are temporarily unavailable.'`);
  checks.push('Explore displays the model-record-unavailable message');
  await value('window.fetch = window.originalFetch');
  if (exceptions.length) throw Error(JSON.stringify(exceptions));
  const result = { release, assertions: checks.length, checks, runtimeExceptions: exceptions.length };
  if (captures) await writeFile(join(captures, 'browser-checks.json'), JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result));
} finally {
  ws.close();
  await fetch(`${cdp}/json/close/${page.id}`);
}
