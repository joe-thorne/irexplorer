// Journey-guidance acceptance. Node 22+ and an isolated headless Chrome CDP; synthetic answers only.
// Every expected participant sentence is read from the served compiled message catalogue, glossary
// and introductions, so the same journey runs on the packaged content (desktop and narrow) and on a
// synthetic catalogue variant whose every message is marked. Covers normal guidance, T0 glossary help,
// storage and discard failures, review, uncertain delivery with same-content retries, receipt and
// cleanup failure, then incompatible and corrupt recovery and invalid catalogues.
// Each full journey submits one synthetic record: use a disposable local or preview store.
const base = process.env.IREXPLORER_ORIGIN || 'http://localhost:8000';
const cdp = `http://127.0.0.1:${process.env.IREXPLORER_CDP_PORT || '9239'}`;
const DRAFT = 'irexplorer.study.v0.11', SUBMISSION = 'irexplorer.submission.v3';
const packaged = await (await fetch(base + '/api/study/content')).json();

const page = await (await fetch(`${cdp}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise(resolve => ws.addEventListener('open', resolve, { once: true }));
let sequence = 0, served = packaged, variant = null;
// Scripted outcomes for successive submission attempts: 'offline' fails before the server,
// 'unavailable' answers 503 without reaching it, 'unsupported' answers 422 unsupported_instrument
// (the server stored nothing), 'lost' stores the submission but drops the response.
let attempts = [], posted = [], statuses = [], delayMs = 0;
const waiting = new Map(), exceptions = [], consoleErrors = [], checks = [];
const json = body => Buffer.from(JSON.stringify(body)).toString('base64');
ws.addEventListener('message', async ({ data }) => {
  const message = JSON.parse(data);
  if (message.method === 'Runtime.exceptionThrown') exceptions.push(message.params.exceptionDetails);
  if (message.method === 'Log.entryAdded' && message.params.entry.level === 'error') {
    const { source, text, url } = message.params.entry;
    consoleErrors.push({ source, text, url });
  }
  if (message.method === 'Fetch.requestPaused') {
    const { requestId, request, responseStatusCode } = message.params;
    if (request.url.endsWith('/api/study/content')) {
      send('Fetch.fulfillRequest', { requestId, responseCode: 200, body: json(served),
        responseHeaders: [{ name: 'Content-Type', value: 'application/json' }, { name: 'Cache-Control', value: 'no-store' }] });
    } else if (responseStatusCode !== undefined) {
      statuses.push(responseStatusCode);
      if (attempts.shift() === 'lost') send('Fetch.failRequest', { requestId, errorReason: 'ConnectionReset' });
      else send('Fetch.continueResponse', { requestId });
    } else {
      posted.push(request.postData);
      if (delayMs) await pause(delayMs);
      const next = attempts[0];
      if (next === 'offline') { attempts.shift(); send('Fetch.failRequest', { requestId, errorReason: 'ConnectionFailed' }); }
      else if (next === 'unavailable') {
        attempts.shift();
        send('Fetch.fulfillRequest', { requestId, responseCode: 503, body: json({ error: { code: 'storage_unavailable', message: 'Synthetic storage unavailable.' } }),
          responseHeaders: [{ name: 'Content-Type', value: 'application/json' }] });
      } else if (next === 'unsupported') {
        attempts.shift();
        send('Fetch.fulfillRequest', { requestId, responseCode: 422, body: json({ error: { code: 'unsupported_instrument', message: 'Check consent, P1, versions, task outcomes, and answer limits. No answers were changed.' } }),
          responseHeaders: [{ name: 'Content-Type', value: 'application/json' }] });
      } else send('Fetch.continueRequest', { requestId, interceptResponse: true });
    }
  }
  if (waiting.has(message.id)) {
    const [resolve, reject] = waiting.get(message.id); waiting.delete(message.id);
    message.error ? reject(message.error) : resolve(message.result);
  }
});
function send(method, params = {}) {
  return new Promise((resolve, reject) => { const id = ++sequence; waiting.set(id, [resolve, reject]); ws.send(JSON.stringify({ id, method, params })); });
}
function pause(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }
async function value(expression) {
  const result = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (result.exceptionDetails) throw Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
async function until(expression, attempts = 200) {
  for (let attempt = 0; attempt < attempts; attempt += 1) { if (await value(expression)) return; await pause(75); }
  throw Error(`Timed out: ${expression}; hash=${await value('location.hash')}; screen=${JSON.stringify(await value(`document.querySelector('#study-screen')?.innerText.slice(0, 500)`))}`);
}
let label = '';
async function check(name, expression) {
  // A missing element fails the named check rather than aborting with a script error.
  if (await value(`(() => { try { return Boolean(${expression}); } catch { return false; } })()`)) { checks.push(`${label}: ${name}`); return; }
  // Best-effort diagnosis: report which top-level conjuncts are false (fragments that do not parse are skipped).
  const failing = [];
  for (const part of expression.split(' && ')) {
    try { if (!(await value(`(() => { try { return Boolean(${part}); } catch { return false; } })()`))) failing.push(part.slice(0, 160)); } catch { /* not a complete expression */ }
  }
  const observed = await value(`({ failing: ${JSON.stringify(failing)}, hash: location.hash, active: document.activeElement?.outerHTML.slice(0, 160), screen: document.querySelector('#study-screen')?.innerText.slice(0, 900), responses: document.querySelector('#task-responses')?.innerText.slice(0, 400) })`);
  throw Error(`Failed: ${label}: ${name}; observed=${JSON.stringify(observed)}`);
}
const q = JSON.stringify;
const click = selector => value(`document.querySelector(${q(selector)}).click()`);
const fill = (name, text) => value(`(() => { const e = document.querySelector('textarea[name="${name}"]'); e.value = ${q(text)}; e.dispatchEvent(new Event('input', { bubbles: true })); })()`);
async function key(name, code, keyCode) {
  await send('Input.dispatchKeyEvent', { type: 'keyDown', key: name, code, windowsVirtualKeyCode: keyCode, ...(name === 'Enter' ? { text: '\r' } : {}) });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: name, code, windowsVirtualKeyCode: keyCode });
}
async function tabTo(selector, limit = 400) {
  for (let i = 0; i < limit; i += 1) { if (await value(`document.activeElement.matches(${q(selector)})`)) return; await key('Tab', 'Tab', 9); }
  throw Error(`Tab navigation did not reach ${selector}`);
}
const saved = () => value(`JSON.parse(sessionStorage.getItem('${DRAFT}'))`);

// Expected participant text, interpolated independently of the application from the served catalogue.
const M = (messageKey, params = {}) => {
  const text = served.messages[messageKey];
  if (typeof text !== 'string') throw Error(`Catalogue has no ${messageKey}`);
  return text.replace(/\{(\w+)\}/g, (_, name) => { if (!(name in params)) throw Error(`${messageKey} needs ${name}`); return String(params[name]); });
};
const heading = messageKey => until(`document.querySelector('#route-heading')?.textContent === ${q(M(messageKey))} && document.activeElement.id === 'route-heading'`);
// An element in the journey whose complete text is exactly the expected message.
const shows = (text, selector = '#journey-layout p, #journey-layout li, #journey-layout summary') =>
  `[...document.querySelectorAll(${q(selector)})].some(e => e.textContent === ${q(text)})`;
const fits = `document.documentElement.scrollWidth <= innerWidth`;
// Storage faults a participant's browser can raise, limited to one key.
const fault = (method, storageKey) => value(`(() => { const original = Storage.prototype.${method}; window.__restore${method} = () => { Storage.prototype.${method} = original; }; Storage.prototype.${method} = function (k, ...rest) { if (k === ${q(storageKey)}) throw new DOMException('Synthetic ${method} failure', 'QuotaExceededError'); return original.call(this, k, ...rest); }; })()`);
const restore = method => value(`window.__restore${method}()`);

async function load(route = '/study') {
  await value(`sessionStorage.clear()`);
  await value(`history.replaceState(null, '', '/#${route}')`); await send('Page.reload');
}

async function journey(viewport) {
  const outcome = status => M({ completed: 'outcome.completed', skipped: 'outcome.skipped', could_not_work_out: 'outcome.unable' }[status]);
  const blocks = served.information.flatMap(section => section.blocks);
  await send('Emulation.setDeviceMetricsOverride', { ...viewport, deviceScaleFactor: 1, mobile: viewport.width < 600 });
  await load();

  // Information and consent.
  await heading('information.title');
  await check('Study purpose and submission guidance carry their compiled labels once', `(() => { const purpose = [...document.querySelectorAll('.study-purpose')], guidance = [...document.querySelectorAll('.submission-guidance')]; return purpose.length === 1 && guidance.length === 1 && purpose[0].querySelector('strong').textContent === ${q(M('information.purpose-label'))} && purpose[0].textContent === ${q(M('information.purpose-label') + ' ' + blocks.find(b => b.role === 'study-purpose').text)} && guidance[0].querySelector('strong').textContent === ${q(M('information.submission-label'))} && guidance[0].textContent === ${q(M('information.submission-label') + ' ' + blocks.find(b => b.role === 'submission-guidance').text)} && guidance[0].getAttribute('role') === 'note'; })()`);
  await check('Consent guidance and local-storage status come from the catalogue', `document.querySelector('#study-screen h3:not(.participant-information h3)')?.textContent === ${q(M('consent.title'))} && ${shows(M('consent.introduction'))} && ${shows(M('consent.local'))} && document.querySelector('#draft-status [role="status"]').textContent === ${q(M('storage.before-consent'))} && document.querySelector('[data-action="start"]').textContent === ${q(M('actions.start'))} && document.querySelector('[data-action="decline"]').textContent === ${q(M('actions.decline'))}`);
  await check('Study navigation names its sections from the catalogue', `document.querySelector('#study-progress').getAttribute('aria-label') === ${q(M('progress.sections'))} && [...document.querySelectorAll('#study-progress li')].map(li => li.textContent).join('|') === ${q(['information', 'pre', 'tasks', 'post', 'review'].map((s, n) => `${n + 1}. ${M('progress.' + s)}`).join('|'))} && document.querySelector('#study-progress [aria-current="step"]') !== null`);
  await check('Information page fits the viewport', fits);
  await value(`document.querySelector('#route-heading').focus()`);
  await tabTo('[data-action="start"]');
  await key('Enter', 'Enter', 13);
  await check('Keyboard Continue without consent explains the requirement and focuses the first acknowledgement', `document.querySelector('#consent-error').textContent === ${q(M('consent.confirm'))} && document.querySelector('#consent-error').getAttribute('role') === 'alert' && document.activeElement.id === ${q(served.membership.consent[0])}`);
  for (const id of served.membership.consent) await click('#' + id);
  await click('[data-action="start"]');

  // Pre-survey: introduction, P13 lock expectation, field notes and validation.
  await heading('pre.title');
  await check('Pre-survey shows its compiled introduction and P13 lock expectation', `${shows(served.journey.introductions.pre)} && ${shows(M('pre.lock-pending'))} && document.querySelector('#draft-status [role="status"]').textContent === ${q(M('storage.saved'))}`);
  const p13 = served.fields.find(f => f.id === 'P13'), p3 = served.fields.find(f => f.id === 'P3');
  await check('Field notes and clear controls come from the catalogue', `document.querySelector('#note-P1').textContent === ${q(M('field.required'))} && document.querySelector('#note-P13').textContent === ${q(M('field.text-limit', { required: M(p13.required ? 'field.required-label' : 'field.optional-label'), maxLength: p13.maxLength.toLocaleString('en') }))} && document.querySelector('#note-P3').textContent === ${q(M(p3.required ? 'field.required' : 'field.multiple'))} && document.querySelector('[data-clear="P1"]').textContent === ${q(M('field.clear-label'))} && document.querySelector('[data-clear="P1"]').getAttribute('aria-label') === ${q(M('field.clear-accessible', { fieldId: 'P1' }))} && document.querySelector('#survey-form button[type="submit"]').textContent === ${q(M('actions.pre-start'))}`);
  await click('#survey-form button[type="submit"]');
  await check('Validation summary and field error come from the catalogue and focus the invalid answer', `document.querySelector('#form-errors').textContent === ${q(M('validation.summary'))} && document.querySelector('#error-P1').textContent === ${q(M('validation.required-p1'))} && document.activeElement.name === 'P1' && document.activeElement.getAttribute('aria-invalid') === 'true'`);
  await click('input[name="P1"][value="1"]'); await fill('P13', 'Synthetic initial account');
  await click('#survey-form button[type="submit"]');

  // T0: orientation guidance, glossary help, timing and pause.
  const t0 = served.tasks.find(t => t.id === 'T0');
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T0' && window.StudyWorkspace.ready`);
  await check('T0 heading, orientation label, task links and setup summary come from the catalogue', `document.querySelector('#route-heading').textContent === ${q(M('task.title', { taskId: 'T0', title: t0.title }))} && document.querySelector('#study-screen .eyebrow').textContent === ${q(M('task.orientation'))} && document.querySelector('#study-screen strong').textContent === ${q(M('task.goal-label'))} && document.querySelector('.task-jumps').getAttribute('aria-label') === ${q(M('task.navigation'))} && [...document.querySelectorAll('.task-jumps a')].map(a => a.textContent).join('|') === ${q([M('task.instructions'), M('task.workspace-link'), M('task.responses-link')].join('|'))} && document.querySelector('#task-instructions > summary').textContent === ${q(M('task.setup-title'))}`);
  await check('T0 entry guidance names its declared example', `${shows(M('task.entry', { example: t0.entryWorkspace.example }), '#task-instructions p')}`);
  await check('T0 renders the compiled task introduction', `${q(served.taskIntroduction)}.every(text => [...document.querySelectorAll('#task-instructions p')].some(p => p.textContent === text))`);
  await check('T0 marks each glossary term once with its compiled help', `(() => { const terms = [...document.querySelectorAll('#task-instructions .study-term-help')]; return ${q(served.glossary)}.every(g => terms.filter(t => t.textContent.toLowerCase() === g.match.toLowerCase()).length === 1 && terms.find(t => t.textContent.toLowerCase() === g.match.toLowerCase()).dataset.help === g.text) && terms.length === ${served.glossary.length} && terms.every(t => t.tabIndex === 0 && t.getAttribute('role') === 'term') && !document.querySelector('#task-instructions img, #task-instructions script'); })()`);
  for (const g of [served.glossary[0], served.glossary.at(-1)]) {
    await value(`document.activeElement.blur()`);
    await value(`document.querySelector('#task-instructions').open = true; [...document.querySelectorAll('#task-instructions .study-term-help')].find(t => t.textContent.toLowerCase() === ${q(g.match.toLowerCase())}).focus()`);
    await until(`!document.querySelector('#ir-help-tooltip').hidden`);
    await check(`Keyboard focus on ${g.match} explains it with its compiled help text`, `document.activeElement.getAttribute('aria-describedby') === 'ir-help-tooltip' && document.querySelector('#ir-help-tooltip').textContent === ${q(g.text)} && document.querySelector('#ir-help-tooltip').childElementCount === 0`);
  }
  await value(`document.activeElement.blur()`);
  await check('T0 timing, pause and response guidance come from the catalogue', `document.querySelector('#task-timing').textContent === ${q(M('timing.active'))} && document.querySelector('#task-timing').getAttribute('role') === 'status' && document.querySelector('[data-action="pause-task"]').textContent === ${q(M('actions.pause'))} && document.querySelector('.task-responses-details > summary').textContent === ${q(M('task.responses-open'))} && ${shows(M('task.optional'), '#task-responses p')} && document.querySelector('#task-responses a[href="#route-heading"]').textContent === ${q(M('task.goal-link'))} && document.querySelector('.task-complete').textContent === ${q(M('actions.finish-orientation'))} && document.querySelector('.task-history').getAttribute('aria-label') === ${q(M('task.progress'))} && document.querySelector('.task-history a').textContent === ${q(M('task.current', { taskId: 'T0' }))}`);
  await click('[data-action="pause-task"]');
  await check('Pausing shows the compiled paused guidance and resume label', `document.querySelector('#task-timing').textContent === ${q(M('timing.paused'))} && document.querySelector('[data-action="pause-task"]').textContent === ${q(M('actions.resume'))}`);
  await click('[data-action="pause-task"]');
  await check('T0 fits the viewport', fits);
  // Background corrections show the locking guidance after T0 starts.
  await value(`location.hash = '/study/pre'`); await heading('pre.title');
  await check('Pre-survey explains the P13 lock and saved-answer locking', `${shows(M('pre.locked'))} && document.querySelector('#note-P13').textContent === ${q(M('locking.expectation'))} && document.querySelector('#note-P1').textContent === ${q(M('locking.background'))} && document.querySelector('[data-action="edit-pre"]').textContent === ${q(M('actions.edit-pre'))} && document.querySelector('#survey-form button[type="submit"]').textContent === ${q(M('actions.return-tasks'))}`);
  await value(`location.hash = '/study/tasks/T0'`);
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T0'`);
  await click('#survey-form button[type="submit"]');

  // T1–T6: numbering, outcomes, locking, T2a selection prompt and T6 inheritance guidance.
  for (const id of ['T1', 'T2', 'T3', 'T4', 'T5', 'T6']) {
    await until(`document.querySelector('#survey-form')?.dataset.section === '${id}' && window.StudyWorkspace.ready`);
    const task = served.tasks.find(t => t.id === id);
    if (id === 'T1') await check('T1 numbering, outcome actions and saved-task link come from the catalogue', `document.querySelector('#study-screen .eyebrow').textContent === ${q(M('task.number', { taskNumber: 1 }))} && document.querySelector('.task-complete').textContent === ${q(M('actions.continue'))} && document.querySelector('[data-action="unable-task"]').textContent === ${q(M('actions.unable'))} && document.querySelector('[data-action="skip-task"]').textContent === ${q(M('actions.skip'))} && document.querySelector('.task-history a').textContent === ${q(M('task.saved', { taskId: 'T0' }))} && ${shows(M('task.entry', { example: task.entryWorkspace.example }), '#task-instructions p')}`);
    if (id === 'T2') await check('T2a offers the compiled selection prompt', `document.querySelector('select[name="T2a"] option').textContent === ${q(M('field.choose'))}`);
    if (id === 'T6') await check('T6 describes its inherited workspace and continues to the post-survey', `${shows(M('task.inherit'), '#task-instructions p')} && document.querySelector('.task-complete').textContent === ${q(M('actions.post'))}`);
    if (id === 'T1') await fill('T1a', 'Synthetic brief T1 note');
    await click(id === 'T2' ? '[data-action="unable-task"]' : '[data-action="skip-task"]');
  }
  await heading('post.title');
  const draft = await saved();
  await value(`location.hash = '/study/tasks/T1'`);
  await until(`document.querySelector('#survey-form')?.dataset.section === 'T1'`);
  await check('A saved task explains its recorded outcome, duration and read-only answers', `document.querySelector('.task-responses-details > summary').textContent === ${q(M('task.responses-locked'))} && ${shows(M('task.locked', { outcome: outcome('skipped') }), '#task-responses p')} && document.querySelector('#task-timing').textContent === ${q(M('timing.saved', { seconds: (draft.tasks.T1.durationMs / 1000).toFixed(1), interrupted: draft.tasks.T1.interrupted ? M('timing.interrupted') : '' }))} && document.querySelector('#note-T1a').textContent === ${q(M('locking.task'))} && [...document.querySelectorAll('#task-responses a')].some(a => a.textContent === ${q(M('actions.current'))})`);
  await value(`location.hash = '/study/post'`); await heading('post.title');
  await check('Post-survey shows its compiled introduction', `${shows(served.journey.introductions.post)} && document.querySelector('#survey-form button[type="submit"]').textContent === ${q(M('actions.review'))}`);

  // Storage failure while answering, then explicit retry.
  await fault('setItem', DRAFT);
  await fill('Q14', 'Synthetic post answer');
  await check('A failed local save is announced with retry and memory-only choices', `document.querySelector('#draft-status [role="alert"]').textContent === ${q(M('storage.save-failed'))} && document.querySelector('[data-action="retry-storage"]').textContent === ${q(M('actions.retry-save'))} && document.querySelector('[data-action="memory"]').textContent === ${q(M('actions.memory'))}`);
  await restore('setItem');
  await click('[data-action="retry-storage"]');
  await check('Retrying the local save restores the saved status', `document.querySelector('#draft-status [role="status"]').textContent === ${q(M('storage.saved'))} && JSON.parse(sessionStorage.getItem('${DRAFT}')).post.Q14.value === 'Synthetic post answer'`);
  await click('#survey-form button[type="submit"]');

  // Review.
  await heading('review.title');
  const reviewed = await saved();
  await check('Review explains that nothing is submitted, the frozen attempt and permitted corrections', `(() => { const notice = [...document.querySelectorAll('#study-screen p')].find(p => p.querySelector('strong')?.textContent === ${q(M('review.not-submitted'))}); return notice?.textContent === ${q(M('review.not-submitted') + ' ' + M('review.submit-detail'))} && ${shows(M('review.frozen'))} && ${shows(M('review.editable'))} && document.querySelector('[data-action="submit-responses"]').textContent === ${q(M('actions.submit'))} && document.querySelector('#study-screen a[href="#/study/post"]').textContent === ${q(M('actions.edit-post'))}; })()`);
  await check('Review summarises task outcomes and durations from the catalogue', `document.querySelector('.response-review > summary').textContent === ${q(M('review.tasks'))} && [...document.querySelectorAll('.response-review li')].map(li => li.textContent).join('|') === ${q(served.tasks.map(t => { const r = reviewed.tasks[t.id]; return M('review.task-summary', { taskId: t.id, outcome: outcome(r.status), seconds: (r.durationMs / 1000).toFixed(1), interrupted: r.interrupted ? M('timing.interrupted') : '' }); }).join('|'))} && ${shows(M('review.duration'), '.response-review p')}`);
  await check('Review names each answer section and unanswered items from the catalogue', `[...document.querySelectorAll('.response-review > summary')].slice(1).map(s => s.textContent).join('|') === ${q([M('review.section-answers', { section: M('progress.pre') }), M('review.section-answers', { section: M('progress.post') })].join('|'))} && [...document.querySelectorAll('.response-review dd')].some(dd => dd.textContent === ${q(M('answer.unanswered'))})`);
  await check('Review fits the viewport', fits);

  // Discard confirmation, keyboard cancel, and a discard that cannot remove the saved copy.
  await click('[data-action="stop"]');
  await check('Discard asks for confirmation with compiled wording and its question emphasised', `document.querySelector('.stop-confirmation').getAttribute('role') === 'alert' && document.querySelector('.stop-confirmation p').textContent === ${q(M('discard.confirm'))} && document.querySelector('.stop-confirmation strong').textContent === ${q(/^(.*?[?.!])(\s|$)/s.exec(M('discard.confirm'))[1])} && document.querySelector('[data-action="cancel-stop"]').textContent === ${q(M('actions.keep'))} && document.querySelector('[data-action="confirm-stop"]').textContent === ${q(M('actions.discard'))} && document.activeElement.dataset.action === 'confirm-stop'`);
  await key('Escape', 'Escape', 27);
  await check('Escape keeps the answers and returns focus to Stop', `!document.querySelector('.stop-confirmation') && document.activeElement.dataset.action === 'stop' && document.activeElement.textContent === ${q(M('actions.stop'))}`);
  await fault('removeItem', DRAFT);
  await click('[data-action="stop"]'); await click('[data-action="confirm-stop"]');
  await check('A failed discard says the saved copy may remain and offers retry', `document.querySelector('#draft-status [role="alert"]').textContent === ${q(M('storage.discard-failed') + M('storage.stale'))} && document.activeElement.id === 'draft-status' && [...document.querySelectorAll('#draft-status [data-action="stop"]')].some(b => b.textContent === ${q(M('actions.retry-discard'))}) && !document.querySelector('#draft-status [data-action="memory"]') && sessionStorage.getItem('${DRAFT}') !== null`);
  await restore('removeItem');
  await click('[data-action="retry-storage"]');
  await check('The retained draft can be saved again after the failed discard', `document.querySelector('#draft-status [role="status"]').textContent === ${q(M('storage.saved'))} && document.querySelector('#route-heading').textContent === ${q(M('review.title'))}`);

  // Uncertain delivery: an offline attempt, then a 503 that is not a receipt.
  posted = []; statuses = []; attempts = ['offline'];
  await click('[data-action="submit-responses"]');
  await heading('submission.unconfirmed');
  const frozen = await value(`JSON.parse(sessionStorage.getItem('${SUBMISSION}')).submission`);
  const pending = `document.querySelector('#study-screen [role="status"]').textContent === ${q(M('submission.retry'))} && ${shows(M('submission.participant-code', { participantCode: frozen.participantCode }), '#study-screen p')} && document.querySelector('#study-screen code').textContent === ${q(frozen.participantCode)} && ${shows(M('submission.keep-tab'), '#study-screen p')} && document.querySelector('[data-action="retry-submit"]').textContent === ${q(M('actions.retry-submit'))} && !document.querySelector('[data-action="stop"]') && !document.querySelector('#survey-form') && !document.querySelector('[data-action="new-study"]')`;
  await check('An offline attempt keeps the frozen submission and asks for a same-ID retry', `${pending} && document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('submission.uncertain', { error: 'Failed to fetch' }))}`);
  await check('Uncertain delivery fits the viewport', fits);
  await send('Page.reload');
  await heading('submission.unconfirmed');
  await check('Compatible recovery after reload keeps the same frozen submission and ID', `${pending} && JSON.stringify(JSON.parse(sessionStorage.getItem('${SUBMISSION}')).submission) === ${q(JSON.stringify(frozen))}`);
  attempts = ['unavailable']; delayMs = 900;
  await value(`document.querySelector('#route-heading').focus()`);
  await tabTo('[data-action="retry-submit"]');
  await key('Enter', 'Enter', 13);
  await heading('submission.submitting');
  await check('An attempt in progress says answers are frozen and offers no second attempt', `document.querySelector('#study-screen [role="status"]').textContent === ${q(M('submission.wait'))} && !document.querySelector('[data-action="retry-submit"]')`);
  await heading('submission.unconfirmed'); delayMs = 0;
  await check('A server failure is not a receipt and keeps the frozen submission', `${pending} && document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('submission.uncertain', { error: 'Synthetic storage unavailable.' }))} && JSON.parse(sessionStorage.getItem('${SUBMISSION}')).kind === 'pending'`);
  // The server stores the next attempt but its response is lost; the same-content retry then
  // returns the original receipt while the browser cannot persist it (cleanup failure).
  attempts = ['lost'];
  await click('[data-action="retry-submit"]');
  await until(`document.querySelector('#route-heading')?.textContent === ${q(M('submission.unconfirmed'))} && document.querySelector('[data-action="retry-submit"]') !== null`);
  await check('A lost acknowledgement still shows no receipt', `${pending} && JSON.parse(sessionStorage.getItem('${SUBMISSION}')).kind === 'pending'`);
  await fault('setItem', SUBMISSION);
  await click('[data-action="retry-submit"]');
  await heading('receipt.title');
  const receipt = await value(`document.querySelector('#study-screen code').textContent`);
  await check('Receipt appears only after the server confirmed storage, from the catalogue', `document.querySelector('#study-screen').innerText.includes(${q(M('receipt.saved'))}) && ${shows(M('receipt.code', { receiptId: receipt }), '#study-screen p')} && ${shows(M('receipt.keep'), '#study-screen p')}`);
  await check('A receipt that cannot replace the local answer copy says a copy may remain', `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('cleanup.retry-save'))} && document.querySelector('[data-action="cleanup-receipt"]').textContent === ${q(M('actions.cleanup'))} && !document.querySelector('[data-action="new-study"]') && JSON.parse(sessionStorage.getItem('${SUBMISSION}')).kind === 'pending'`);
  await restore('setItem');
  await fault('removeItem', DRAFT);
  await click('[data-action="cleanup-receipt"]');
  await check('A receipt whose draft cannot be removed asks for cleanup retry', `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('cleanup.retry-draft'))} && sessionStorage.getItem('${DRAFT}') !== null && JSON.parse(sessionStorage.getItem('${SUBMISSION}')).kind === 'receipt'`);
  await restore('removeItem');
  await click('[data-action="cleanup-receipt"]');
  await check('Successful cleanup says only the receipt remains', `${shows(M('cleanup.done'), '#study-screen p')} && document.querySelector('[data-action="new-study"]').textContent === ${q(M('actions.new-session'))} && sessionStorage.getItem('${DRAFT}') === null && JSON.parse(sessionStorage.getItem('${SUBMISSION}')).receipt.receiptId === ${q(receipt)}`);
  await check('Receipt fits the viewport', fits);
  if (posted.length !== 4 || posted.some(body => body !== posted[0]) || JSON.parse(posted[0]).submissionId !== frozen.submissionId)
    throw Error(`Failed: ${label}: retries changed the submission ${JSON.stringify(posted.map(b => b?.length))}`);
  checks.push(`${label}: Offline, 503, lost-response and final attempts sent identical content and submission ID`);
  if (statuses.join() !== '201,200') throw Error(`Failed: ${label}: server statuses ${statuses}`);
  checks.push(`${label}: The lost first insert (201) is recovered by an identical retry receipt (200)`);
  await click('[data-action="new-study"]');
  await heading('information.title');

  // Declining discards the local draft with compiled confirmation.
  await click('[data-action="decline"]');
  await heading('discard.declined');
  await check('Declining confirms nothing was submitted and offers restart', `${shows(M('discard.done'), '#study-screen p')} && document.querySelector('[data-action="restart"]').textContent === ${q(M('actions.restart'))} && document.querySelector('#study-screen a[href="#/explore"]').textContent === ${q(M('actions.explore'))}`);
}

async function recovery() {
  // Corrupt submission recovery blocks progression explicitly.
  await value(`sessionStorage.clear(); sessionStorage.setItem('${SUBMISSION}', '{broken')`);
  await value(`history.replaceState(null, '', '/#/study')`); await send('Page.reload');
  await heading('recovery.title');
  await check('Corrupt submission recovery is explicit and offers retry or memory-only continuation', `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('recovery.unreadable'))} && document.querySelector('[data-action="retry-content"]').textContent === ${q(M('actions.retry-recovery'))} && ${shows(M('recovery.memory'), '#study-screen p')} && document.querySelector('[data-action="memory"]').textContent === ${q(M('actions.memory'))}`);
  // An incompatible older pending submission is never resent; discarding it can fail and be retried.
  await value(`sessionStorage.clear(); sessionStorage.setItem('irexplorer.submission.v2', JSON.stringify({ kind: 'pending', submission: { submissionId: 'synthetic-old', participantCode: 'synthetic-old-participant' } }))`);
  await send('Page.reload');
  await heading('recovery.title');
  await check('Incompatible recovery names the possible server copy and its participant code', `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('recovery.incompatible'))} && ${shows(M('recovery.server-copy'), '#study-screen p')} && ${shows(M('submission.participant-code', { participantCode: 'synthetic-old-participant' }), '#study-screen p')} && document.querySelector('[data-action="discard-incompatible-submission"]').textContent === ${q(M('actions.discard-incompatible'))}`);
  await fault('removeItem', 'irexplorer.submission.v2');
  await click('[data-action="discard-incompatible-submission"]');
  await check('A failed incompatible discard is reported', `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('recovery.discard-failed'))}`);
  await restore('removeItem');
  await click('[data-action="discard-incompatible-submission"]');
  await heading('information.title');
  // A frozen submission whose release the server no longer accepts: the server confirmed nothing was
  // stored, so the view says so instead of the uncertain server-copy wording.
  const unsupported = { submissionId: 'synthetic-unsupported', participantCode: 'synthetic-unsupported-participant' };
  await value(`sessionStorage.clear(); sessionStorage.setItem('${SUBMISSION}', ${q(JSON.stringify({ kind: 'pending', submission: unsupported }))})`);
  await send('Page.reload');
  await heading('submission.unconfirmed');
  attempts = ['unsupported'];
  await click('[data-action="retry-submit"]');
  await heading('recovery.title');
  const notStored = `document.querySelector('#study-screen [role="alert"]').textContent === ${q(M('recovery.incompatible'))} && ${shows(M('recovery.not-stored'), '#study-screen p')} && !${shows(M('recovery.server-copy'), '#study-screen p')} && ${shows(M('submission.participant-code', { participantCode: unsupported.participantCode }), '#study-screen p')} && document.querySelector('[data-action="discard-incompatible-submission"]').textContent === ${q(M('actions.discard-incompatible'))} && !document.querySelector('[data-action="retry-submit"]') && JSON.stringify(JSON.parse(sessionStorage.getItem('${SUBMISSION}')).submission) === ${q(JSON.stringify(unsupported))}`;
  await check('An unsupported release says the answers were not saved, keeps the frozen submission, and makes no server-copy claim', notStored);
  await check('The not-saved recovery fits the viewport', fits);
  await send('Page.reload');
  await heading('submission.unconfirmed');
  attempts = ['unsupported'];
  await click('[data-action="retry-submit"]');
  await heading('recovery.title');
  await check('After a refresh the server decides again and the not-saved message returns', notStored);
  await click('[data-action="discard-incompatible-submission"]');
  await heading('information.title');
  await check('The unsupported frozen submission is removed only by the explicit discard', `sessionStorage.getItem('${SUBMISSION}') === null`);
  // A damaged answer draft must be discarded explicitly.
  await value(`sessionStorage.clear(); sessionStorage.setItem('${DRAFT}', '{broken')`);
  await send('Page.reload');
  await heading('information.title');
  await check('A damaged draft is reported with an explicit discard', `document.querySelector('#draft-status [role="alert"]').textContent === ${q(M('storage.incompatible') + M('storage.stale'))} && [...document.querySelectorAll('#draft-status [data-action="stop"]')].some(b => b.textContent === ${q(M('actions.retry-discard'))})`);
  await value(`sessionStorage.clear()`);
}

try {
  await send('Runtime.enable'); await send('Page.enable'); await send('Log.enable');
  await send('Fetch.enable', { patterns: [
    { urlPattern: '*/api/study/content', requestStage: 'Request' },
    { urlPattern: '*/api/study/submissions', requestStage: 'Request' },
  ] });
  await send('Emulation.setFocusEmulationEnabled', { enabled: true });
  await send('Page.navigate', { url: `${base}/` });
  await until(`document.readyState === 'complete'`);

  label = 'Packaged desktop'; await journey({ width: 1440, height: 1000 }); await recovery();
  label = 'Packaged narrow'; await journey({ width: 390, height: 844 }); await recovery();

  // Synthetic catalogue variant: every message, glossary help and introduction is marked, so each
  // participant sentence checked above must come from the served catalogue rather than the code.
  const marked = JSON.parse(JSON.stringify(packaged));
  for (const messageKey of Object.keys(marked.messages)) marked.messages[messageKey] = `‹${messageKey}› ${marked.messages[messageKey]}`;
  for (const item of marked.glossary) item.text = `‹glossary ${item.id}› ${item.text}`;
  for (const section of ['pre', 'post']) marked.journey.introductions[section] = `‹intro ${section}› ${marked.journey.introductions[section]}`;
  served = marked;
  label = 'Marked catalogue desktop'; await journey({ width: 1440, height: 1000 }); await recovery();

  // Catalogue prose is displayed as text, never markup.
  label = 'Unsafe prose variant';
  served = JSON.parse(JSON.stringify(packaged));
  served.messages['information.title'] = '<img src=x onerror="window.__guidanceMarkup=1">Information & consent';
  served.messages['consent.introduction'] = 'Confirm <b>each</b> item & {{literal}} braces are {{kept}}.';
  served.glossary[0].text = '<script>window.__guidanceMarkup=1</script>Help';
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 1000, deviceScaleFactor: 1, mobile: false });
  await load();
  await until(`document.querySelector('#route-heading')?.textContent === ${q('<img src=x onerror="window.__guidanceMarkup=1">Information & consent')}`);
  await check('Message markup is shown literally and escaped braces are kept', `!document.querySelector('#study-screen img, #study-screen b') && !window.__guidanceMarkup && document.title.startsWith('<img') && ${shows('Confirm <b>each</b> item & {literal} braces are {kept}.')}`);

  // A catalogue that breaks the key or placeholder contract is not used; no journey starts.
  for (const [name, change] of [
    ['a missing required key', m => { delete m['receipt.title']; }],
    ['a missing placeholder', m => { m['task.entry'] = 'The workspace opens at State 0.'; }],
    ['an unknown placeholder', m => { m['receipt.saved'] = 'Saved {receiptId}.'; }],
    ['a malformed placeholder', m => { m['timing.paused'] = 'Paused {'; }],
  ]) {
    label = `Invalid catalogue (${name})`;
    served = JSON.parse(JSON.stringify(packaged)); change(served.messages);
    await load();
    await until(`document.querySelector('#route-heading')?.textContent === 'Study content unavailable'`);
    await check('Content is rejected before any journey guidance or draft', `!document.querySelector('#survey-form, .acknowledgement') && document.querySelector('[data-action="retry-content"]').textContent === 'Retry loading forms' && sessionStorage.getItem('${DRAFT}') === null`);
  }
  served = packaged;
  await load();
  await until(`document.querySelector('#route-heading')?.textContent === ${q(M('information.title'))}`);
  const cspViolations = consoleErrors.filter(entry => entry.source === 'security' || /Content Security Policy/i.test(entry.text));
  if (exceptions.length) throw Error(`Browser runtime exceptions: ${JSON.stringify(exceptions)}`);
  if (cspViolations.length) throw Error(`Browser Content Security Policy violations: ${JSON.stringify(cspViolations)}`);
  console.log(JSON.stringify({ assertions: checks.length, checks, runtimeExceptions: exceptions.length, consoleErrors, cspViolations }, null, 1));
} finally {
  ws.close();
  await fetch(`${cdp}/json/close/${page.id}`);
}
