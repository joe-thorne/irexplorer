// Study journey with local drafts and final-only submission.
(async () => {
  const D = window.StudyDraft;
  const submission = window.StudySubmit.controller();
  const screen = document.querySelector('#study-screen');
  const workspace = document.querySelector('#workspace-shell');
  const progress = document.querySelector('#study-progress');
  const layout = document.querySelector('#journey-layout');
  const routes = ['/study', '/study/pre', '/study/tasks/T0', '/study/post', '/study/complete'];
  const names = ['Information', 'Pre-survey', 'Tasks', 'Post-survey', 'Review'];
  const esc = text => String(text).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const button = (action, text, primary = false) => `<button type="button" data-action="${action}"${primary ? ' class="primary"' : ''}>${text}</button>`;
  const heading = text => `<h2 id="route-heading" tabindex="-1">${text}</h2>`;
  let content, store, draft = null, editingPre = false, errors = {}, loaded = false, loadError = false;
  let activeTask = null, clock = null, setupToken = 0, setupLoading = false, setupReady = false;
  const answersFor = stage => stage.startsWith('T') ? draft.tasks[stage].answers : draft[stage];
  const outcomeLabel = status => ({ completed: 'Completed', skipped: 'Skipped', could_not_work_out: 'Could not work this out', pending: 'In progress' })[status];
  const taskRoute = () => '/study/tasks/' + D.currentTask(draft);
  function leaveTask(route) {
    if (!activeTask || route === '/study/tasks/' + activeTask) return;
    clock?.stop(true); save(); clock = null; activeTask = null; ++setupToken;
  }
  function taskHtml(id) {
    const task = content.tasks.find(t => t.id === id), record = draft.tasks[id];
    const locked = record.status !== 'pending';
    return heading(`${id} — ${task.title}`) + `<p class="eyebrow">${id === 'T0' ? 'Orientation · no scored response' : `Task ${id.slice(1)} of 6`}</p><p><strong>Goal:</strong> ${esc(task.goal)}</p>
      <nav class="task-jumps" aria-label="Task sections"><a href="#task-instructions">Instructions</a><a href="#workspace-shell">Go to workspace</a><a href="#task-responses">Go to responses</a></nav>
      <details id="task-instructions" class="task-details"${matchMedia('(max-width: 1100px)').matches ? '' : ' open'}><summary>Setup and instructions</summary>
      ${id === 'T0' ? content.taskIntroduction.map(p => `<p>${esc(p)}</p>`).join('') : ''}<p class="task-prose">${esc(task.instructions)}</p>
      ${id === 'T1' ? '<p>End of teaching chain: ordinal 12, final_cleanup. Separately compiled -O3 is the next state.</p>' : ''}
      ${Object.keys(task.setup).length ? button('task-setup', 'Open task setup') : '<p>Choose any example, states, function, and views. Five minutes is guidance; continue whenever you are ready.</p>'}</details>
      <p id="task-timing" class="form-note" role="status"></p>${!locked ? button('pause-task', record.paused ? 'Resume task' : 'Pause task') : ''}
      <details class="task-details task-responses"${matchMedia('(max-width: 1100px)').matches ? '' : ' open'}><summary id="task-responses">${locked ? 'Saved responses (read-only)' : 'Responses and continue'}</summary>
      <a href="#route-heading">Back to goal</a><p>${locked ? `Recorded outcome: ${esc(outcomeLabel(record.status))}. Responses are locked.` : 'You may leave fields unanswered. Choosing inability or skipping is a valid outcome. Continuing locks this task’s responses.'}</p>
      <form id="survey-form" data-stage="${id}" novalidate><p id="form-errors" role="alert" tabindex="-1"></p><fieldset class="task-inputs"${locked ? ' disabled' : ''}>
      ${task.fields.map(fid => fieldHtml(content.fields.find(f => f.id === fid), id)).join('')}
      ${!locked ? `<div class="screen-actions"><button type="submit" class="primary">${id === 'T0' ? 'Finish orientation and start T1' : id === 'T6' ? 'Continue to post-survey' : 'Save and continue'}</button>${id !== 'T0' ? button('unable-task', 'I could not work this out — continue') + button('skip-task', 'Skip task') : ''}</div>` : ''}</fieldset></form></details>
      <nav class="task-history" aria-label="Task progress">${content.tasks.map(t => draft.tasks[t.id].status !== 'pending' ? `<a href="#/study/tasks/${t.id}">${t.id} saved</a>` : t.id === D.currentTask(draft) ? `<a href="#${taskRoute()}">${t.id} current</a>` : `<span>${t.id}</span>`).join(' ')}</nav>
      ${locked ? `<a href="#${D.tasksComplete(draft) ? '/study/post' : taskRoute()}">Return to current stage</a>` : ''}`;
  }
  function updateTaskStatus() {
    if (!activeTask || !draft) return;
    const t = draft.tasks[activeTask], status = screen.querySelector('#task-timing');
    if (!status) return;
    status.textContent = t.status !== 'pending' ? `Saved active duration: ${(t.durationMs / 1000).toFixed(1)} seconds${t.interrupted ? ' · interrupted' : ''}.` : setupLoading ? (clock?.running ? 'Preparing workspace. Active timing continues during exploration.' : 'Preparing workspace; timing has not resumed.') : !setupReady ? 'Timing is waiting for a usable workspace. Open task setup to retry, or choose a file for open exploration.' : t.paused ? 'Paused. Resume when ready; paused time is excluded.' : 'Timing active · hidden tabs and pauses excluded · no time limit.';
    const pause = screen.querySelector('[data-action="pause-task"]');
    if (pause) { pause.textContent = t.paused ? 'Resume task' : 'Pause task'; pause.disabled = !t.started || !setupReady; }
    const inputs = screen.querySelector('.task-inputs');
    if (inputs) inputs.disabled = t.status !== 'pending' || !setupReady || t.paused;
  }
  function startClock() {
    if (!activeTask || !draft || !setupReady) return;
    const t = draft.tasks[activeTask];
    if (t.status !== 'pending') return;
    t.started = true;
    if (!document.hidden && !t.paused) clock?.resume();
    save(); updateTaskStatus();
  }
  async function openTaskSetup(id) {
    if (!id) return;
    const token = ++setupToken;
    setupLoading = true; setupReady = false;
    updateTaskStatus();
    try {
      const ready = await window.StudyWorkspace.open(content.tasks.find(t => t.id === id).setup);
      if (token !== setupToken || activeTask !== id) return;
      setupReady = ready;
    } catch { if (token !== setupToken) return; setupReady = false; }
    setupLoading = false; startClock(); updateTaskStatus();
  }
  function enterTask(id) {
    if (activeTask === id) { updateTaskStatus(); return; }
    activeTask = id; draft.p13Locked = true; save();
    const t = draft.tasks[id]; clock = window.TaskClock(t);
    setupReady = false; setupLoading = false;
    if (t.status === 'pending') openTaskSetup(id); else updateTaskStatus();
  }
  function finishTask(id, status) {
    if (!id || !draft || !available()) return;
    const t = draft.tasks[id];
    if (t.status !== 'pending' || !setupReady || !t.started || t.paused || (id === 'T0' && status !== 'completed')) return;
    errors = D.validate(content, id, t.answers, true);
    if (Object.keys(errors).length) { showErrors(); screen.querySelector('[aria-invalid="true"]')?.focus(); return; }
    clock?.stop(); t.status = status; t.paused = false; save();
    if (available()) go(D.tasksComplete(draft) ? '/study/post' : taskRoute()); else updateTaskStatus();
  }
  function taskReview() {
    return `<details class="response-review"><summary>Task outcomes and active durations</summary><ul>${content.tasks.map(task => { const t = draft.tasks[task.id]; return `<li><a href="#/study/tasks/${task.id}">${task.id}: ${esc(outcomeLabel(t.status))}</a> · ${(t.durationMs / 1000).toFixed(1)} seconds${t.interrupted ? ' · interrupted' : ''}</li>`; }).join('')}</ul><p>Durations include visible reading, exploration, and answering. They exclude hidden tabs, explicit pauses, and refresh downtime; they are not pure comprehension times.</p></details>`;
  }
  document.addEventListener('workspace-ready', () => {
    if (activeTask === 'T6' && !setupLoading && window.StudyWorkspace.ready) { setupReady = true; startClock(); }
  });
  document.addEventListener('visibilitychange', () => {
    if (!clock) return;
    if (document.hidden) { clock.stop(true); save(); } else if (setupReady) startClock();
  });
  window.addEventListener('pagehide', () => { if (clock) { clock.stop(true); save(); } });
  window.addEventListener('pageshow', () => { if (clock && setupReady) startClock(); });
  setInterval(() => { if (clock?.running) { clock.checkpoint(); save(); } }, 1000);
  function go(route, replace = false) {
    if (replace || location.hash === `#${route}`) { history.replaceState(null, '', `#${route}`); render(); }
    else location.hash = route;
  }
  function maximum() { if (submission.state) return 4; return !draft ? 0 : !draft.preComplete ? 1 : !D.tasksComplete(draft) ? 2 : !draft.reviewReady ? 3 : 4; }
  function save() { if (draft) store.save(draft); updateStorage(); }
  function updateStorage() {
    const area = screen.querySelector('#draft-status');
    if (submission.state) { if (area) area.hidden = true; return; }
    if (!area || !store) return;
    const signature = [store.mode, store.issue, store.stale, store.unreadable, !!draft].join('|');
    if (area.dataset.signature === signature) return;
    area.dataset.signature = signature;
    area.classList.toggle('storage-ok', store.mode === 'local');
    if (store.mode === 'blocked' || store.mode === 'invalid') {
      area.innerHTML = `<p role="alert">${esc(store.issue)}${store.stale ? ' A previous saved copy may remain.' : ''}</p>${draft ? button('retry-storage', 'Retry local save') : ''}${!store.stale && store.mode !== 'invalid' ? button('memory', 'Continue in memory only') : ''}${store.stale ? button('stop', 'Retry discard saved draft') : ''}`;
    } else area.innerHTML = `<p role="status">${store.mode === 'memory' ? 'Memory only: keep this tab open. Refreshing loses your answers.' + (store.unreadable ? ' Any older saved copy could not be checked or removed.' : '') : draft ? 'Saved in this tab. You can refresh; keep the tab open until you submit.' : 'After consent, your answers are saved in this tab until submission. Keep the tab open.'}</p>`;
  }
  function available() { if (store.mode === 'local' || store.mode === 'memory') return true; screen.querySelector('#draft-status')?.focus(); return false; }
  function fieldHtml(field, stage) {
    const answer = answersFor(stage)[field.id], id = field.id.replaceAll('.', '-');
    const locked = stage.startsWith('T') ? draft.tasks[stage].status !== 'pending' : stage === 'pre' && ((draft.preComplete && !editingPre) || (field.id === 'P13' && draft.p13Locked));
    const label = `${field.id}. ${field.prompt}`;
    let control;
    if (['text', 'short_text'].includes(field.type)) control = `<label class="sr-only" for="answer-${id}">${esc(label)}</label><textarea id="answer-${id}" name="${field.id}" rows="3" aria-describedby="note-${id} error-${id}"${locked ? ' readonly' : ''}>${esc(answer.status === 'answered' ? answer.value : '')}</textarea>`;
    else {
      const options = (field.options || content.scales[field.scale]).map(o => ({ ...o, status: field.optionStatuses?.[o.value] || 'answered' }));
      if (field.notApplicableLabel) options.push({ value: 'na', status: 'not_applicable', label: field.notApplicableLabel });
      control = `<div class="answer-options${field.type === 'rating' ? ' rating-options' : ''}">${options.map((o, n) => {
        const selected = o.status !== 'answered' ? answer.status === o.status : answer.status === 'answered' && (Array.isArray(answer.value) ? answer.value.includes(o.value) : answer.value === o.value);
        return `<label class="answer-option${o.status === 'not_applicable' ? ' not-applicable' : ''}" for="answer-${id}-${n}"><input id="answer-${id}-${n}" type="${field.type === 'multiple' ? 'checkbox' : 'radio'}" name="${field.id}" value="${o.value}" data-status="${o.status}"${selected ? ' checked' : ''}${locked ? ' disabled' : ''}${field.required ? ' required' : ''} aria-describedby="note-${id} error-${id}"><span>${field.type === 'rating' && o.status === 'answered' ? `<span class="rating-number">${o.value}</span>` : ''}${esc(o.label)}</span></label>`;
      }).join('')}</div>`;
    }
    const note = locked ? (field.id === 'P13' ? 'Locked when the T0 orientation started; kept as your pre-exposure answer.' : stage.startsWith('T') ? 'Saved task answer; read-only.' : 'Saved answer. Use Edit background answers to correct it.') : ['text', 'short_text'].includes(field.type) ? `${field.required ? 'Required' : 'Optional'} · up to ${field.maxLength.toLocaleString()} characters.` : field.required ? 'Required.' : field.type === 'multiple' ? 'Optional · select all that apply.' : 'Optional.';
    return `<fieldset class="survey-item" data-field="${field.id}"${D.visible(field, answersFor(stage)) ? '' : ' hidden'}><legend>${esc(label)}</legend><p id="note-${id}" class="form-note">${note}</p>${control}${field.inabilityLabel && !locked ? `<label class="answer-option"><input type="checkbox" name="${field.id}" data-inability="true"${answer.status === 'could_not_work_out' ? ' checked' : ''}>${esc(field.inabilityLabel)}</label>` : ''}${field.inabilityLabel && locked && answer.status === 'could_not_work_out' ? `<p>${esc(field.inabilityLabel)}</p>` : ''}<p id="error-${id}" class="field-error" role="alert"></p>${!locked && !['text', 'short_text'].includes(field.type) ? `<button type="button" class="clear-answer" data-clear="${field.id}" aria-label="Clear answer for ${field.id}">Clear answer</button>` : ''}</fieldset>`;
  }
  function survey(stage) {
    const sections = content[stage === 'pre' ? 'preSections' : 'postSections'];
    return `<form id="survey-form" novalidate data-stage="${stage}"><p id="form-errors" role="alert" tabindex="-1"></p>${sections.map(s => `<section class="survey-section"><h3>${esc(s.title)}</h3>${s.intro ? `<p>${esc(s.intro)}</p>` : ''}${s.groups ? s.groups.map(g => `<h4>${esc(g.title)}</h4>${g.fields.map(id => fieldHtml(content.fields.find(f => f.id === id), stage)).join('')}`).join('') : s.fields.map(id => fieldHtml(content.fields.find(f => f.id === id), stage)).join('')}</section>`).join('')}<div class="screen-actions"><button type="submit" class="primary">${stage === 'post' ? 'Review responses' : editingPre ? 'Save background corrections' : draft.preComplete ? 'Return to tasks' : 'Save pre-survey and start T0'}</button>${stage === 'pre' && draft.preComplete && !editingPre ? button('edit-pre', 'Edit background answers') : ''}</div></form>`;
  }
  function informationSections(sections) {
    return sections.map(s => `<section><h3>${esc(s.title)}</h3>${s.blocks.map(b => b.kind === 'paragraph' ? `<p>${esc(b.text)}</p>` : `<${b.kind === 'ordered' ? 'ol' : 'ul'}>${b.items.map(i => `<li>${esc(i)}</li>`).join('')}</${b.kind === 'ordered' ? 'ol' : 'ul'}>`).join('')}</section>`).join('');
  }
  function info() {
    return `<div class="participant-information">${informationSections(content.information.slice(0, -1))}</div><h3>Consent</h3><p>Please confirm each of the following before starting.</p><p>Your answers stay in this tab until you submit. You can stop and discard them before submission.</p>${content.fields.filter(f => f.id.startsWith('C')).map(f => `<label class="acknowledgement" for="${f.id}"><input id="${f.id}" type="checkbox"${draft ? ' checked disabled' : ''}>${esc(f.prompt)}</label>`).join('')}<p id="consent-error" role="alert"></p><div class="screen-actions">${button('start', draft ? 'Return to study' : 'Continue to pre-survey', true)}${!draft ? button('decline', 'Decline and exit') : ''}</div><div class="participant-information">${informationSections(content.information.slice(-1))}</div>`;
  }
  function review() {
    return heading('Review responses') + (submission.issue ? `<p role="alert">${esc(submission.issue)}</p>` : '') + `<p><strong>Nothing has been submitted.</strong> Select Submit responses to save your consent, survey and task answers, outcomes, and active task durations. Your session is identified by a random participant code.</p><p>Once submission begins, answers are locked. If the connection fails, keep this tab open and retry. A receipt confirms that your responses were saved.</p><p>You can correct background answers and post-survey answers below. P13 stays locked.</p><div class="screen-actions">${button('edit-pre', 'Edit background answers')}<a href="#/study/post">Edit post-survey answers</a>${content.submissionEnabled ? button('submit-responses', 'Submit responses', true) : '<button disabled>Participant collection disabled</button>'}</div>${taskReview()}${['pre', 'post'].map(stage => `<details class="response-review"><summary>${stage === 'pre' ? 'Pre-survey' : 'Post-survey'} answers</summary><dl>${D.fieldsFor(content, stage).filter(f => D.visible(f, draft[stage])).map(f => { const a = draft[stage][f.id]; let value = 'Unanswered'; if (a.status === 'not_applicable') value = f.notApplicableLabel || 'Not applicable'; if (a.status === 'answered') value = f.type === 'text' ? a.value : (Array.isArray(a.value) ? a.value : [a.value]).map(v => (f.options || content.scales[f.scale]).find(o => o.value === v).label).join('; '); return `<dt>${esc(f.id + '. ' + f.prompt)}</dt><dd>${esc(value)}</dd>`; }).join('')}</dl></details>`).join('')}`;
  }
  function submissionHtml() {
    const state = submission.state;
    if (state.kind === 'receipt') return heading('Responses received') + `<p>Your responses have been saved.</p><p>Receipt: <code>${esc(state.receipt.receiptId)}</code></p><p>Participant code: <code>${esc(state.receipt.participantCode)}</code></p><p>Keep your participant code and receipt for reference.</p>${submission.issue ? `<p role="alert">${esc(submission.issue)}</p>${button('cleanup-receipt', 'Retry local cleanup')}` : `<p>Local answer drafts have been cleared. Only this receipt remains in the tab.</p>${button('new-study', 'Start another session')}`}`;
    return heading(submission.busy ? 'Submitting responses…' : 'Receipt not yet confirmed') + `<p role="status">${submission.busy ? 'Wait for the server receipt. Answers are frozen for this attempt.' : 'A response record may already exist. Retry with the same submission ID and answers.'}</p><p>Participant code: <code>${esc(state.payload.participantCode)}</code></p>${submission.issue ? `<p role="alert">${esc(submission.issue)}</p>` : ''}${submission.busy ? '' : button('retry-submit', 'Retry submission', true)}<p>Keep this tab open. Stop/discard is unavailable after an attempt because it cannot erase a server record.</p>`;
  }
  function render() {
    const route = location.hash.slice(1) || '/explore', explore = route === '/explore';
    if (loaded && submission.state && !explore && route !== '/study/complete') return go('/study/complete', true);
    leaveTask(route);
    const exited = ['/study/declined', '/study/stopped'].includes(route);
    const requestedTask = /^\/study\/tasks\/(T[0-6])$/.exec(route)?.[1];
    const index = requestedTask ? 2 : routes.indexOf(route);
    if (loaded && draft?.preComplete && requestedTask && Number(requestedTask.slice(1)) > Number(D.currentTask(draft).slice(1))) return go(taskRoute(), true);
    if (loaded && !explore && !exited && (index < 0 || index > maximum())) return go(maximum() === 2 ? taskRoute() : routes[maximum()], true);
    screen.hidden = explore; workspace.hidden = !explore && (!loaded || index !== 2);
    progress.hidden = explore || exited || !loaded;
    document.querySelector('#explore-heading').hidden = !explore;
    document.querySelector('.skip-link').href = explore ? '#explore-heading' : '#route-heading';
    layout.classList.toggle('with-task', !explore && loaded && index === 2);
    if (explore) { document.title = 'Explore · irexplorer'; document.querySelector('#explore-heading').focus(); return; }
    if (!loaded) {
      screen.innerHTML = heading(loadError ? 'Study content unavailable' : 'Loading study content…') + (loadError ? `<p>No study answers have been sent. Retry to load the forms and recover any compatible local draft.</p>${button('retry-content', 'Retry loading forms', true)}` : '');
    } else {
      progress.innerHTML = `<ol>${names.map((name, n) => `<li${n === index ? ' aria-current="step"' : ''}>${n + 1}. ${n <= maximum() ? `<a href="#${n === 2 && draft ? taskRoute() : routes[n]}">${name}</a>` : name}</li>`).join('')}</ol>`;
      let html;
      if (submission.state) html = submissionHtml();
      else if (submission.recoveryBlocked) html = heading('Submission recovery unavailable') + `<p role="alert">${esc(submission.issue)}</p>${button('retry-content', 'Retry recovery')}<p>Memory-only continuation starts a new session; an older submission may already exist. Refresh cannot recover this new session.</p>${button('memory', 'Continue in memory only')}`;
      else if (exited) html = heading(route.endsWith('declined') ? 'Study declined' : 'Study stopped') + `<p>No response record was created. The local draft has been discarded.</p>${button('restart', 'Start a new session', true)} <a href="#/explore">Explore curated artefacts</a>`;
      else if (index === 0) html = heading('Information and consent') + info();
      else if (index === 1) html = heading('Pre-survey') + `<p>Approximately 4 minutes. Every item is optional except P1.</p>${draft.p13Locked ? '<p>P13 was locked when the T0 orientation started. Background corrections do not change it.</p>' : '<p>P13 will be locked when you start the T0 orientation.</p>'}` + survey('pre');
      else if (index === 2) html = taskHtml(requestedTask);
      else if (index === 3) html = heading('Post-survey') + `<p>Approximately 8 minutes. All items may be left unanswered. Answers stay local until you select Submit responses.</p>` + survey('post');
      else html = review();
      screen.innerHTML = (!exited ? html.replace('</h2>', '</h2><div id="draft-status" class="draft-status" tabindex="-1"></div>') : html) + (draft && !exited && !submission.state ? `<p class="participant-code">Participant code: ${esc(draft.participantCode)}</p><div class="study-utilities"><a href="#/study">Information</a>${button('stop', 'Stop and discard answers')}</div>` : '');
      updateStorage(); showErrors();
      if (index === 2) enterTask(requestedTask);
    }
    document.title = `${screen.querySelector('h2').textContent} · irexplorer`;
    screen.querySelector('h2').focus({ preventScroll: true });
    // The desktop task sidebar scrolls independently of the page. Reset both
    // explicitly rather than relying on a browser's focus-scroll behaviour.
    screen.scrollTop = 0;
    screen.scrollLeft = 0;
    window.scrollTo(0, 0);
  }
  function showErrors() {
    for (const fieldset of screen.querySelectorAll('[data-field]')) {
      const message = errors[fieldset.dataset.field] || '';
      fieldset.querySelector('.field-error').textContent = message;
      fieldset.querySelectorAll('input, textarea').forEach(e => e.setAttribute('aria-invalid', message ? 'true' : 'false'));
    }
    const summary = screen.querySelector('#form-errors');
    if (summary) summary.textContent = Object.keys(errors).length ? 'Please correct the marked answers before continuing.' : '';
  }
  function updateAnswer(event) {
    const input = event.target, form = input.closest('#survey-form');
    if (!form || !draft || !input.name) return;
    const stage = form.dataset.stage, field = content.fields.find(f => f.id === input.name);
    if (!field || (stage.startsWith('T') && (draft.tasks[stage].status !== 'pending' || !draft.tasks[stage].started || draft.tasks[stage].paused)) || (stage === 'pre' && ((draft.preComplete && !editingPre) || (field.id === 'P13' && draft.p13Locked)))) return;
    if (input.dataset.inability) { answersFor(stage)[field.id] = input.checked ? { status: 'could_not_work_out', value: null } : D.blank(); input.closest('fieldset').querySelector('textarea').value = ''; }
    else if (['text', 'short_text'].includes(field.type)) answersFor(stage)[field.id] = input.value.trim() ? { status: 'answered', value: input.value } : D.blank();
    else if (event.type === 'change') {
      if (field.type === 'multiple') {
        const inputs = [...input.closest('fieldset').querySelectorAll('input')];
        if (input.checked) for (const other of inputs) if (other !== input && (Number(input.value) === field.exclusiveValue || Number(other.value) === field.exclusiveValue)) other.checked = false;
        const values = inputs.filter(e => e.checked).map(e => Number(e.value));
        answersFor(stage)[field.id] = values.length ? { status: 'answered', value: values } : D.blank();
      } else answersFor(stage)[field.id] = { status: input.dataset.status, value: input.dataset.status === 'answered' ? Number(input.value) : null };
    } else return;
    if (field.inabilityLabel && !input.dataset.inability) input.closest('fieldset').querySelector('[data-inability]').checked = false;
    for (const dependent of D.fieldsFor(content, stage).filter(f => f.condition)) {
      const shown = D.visible(dependent, draft[stage]);
      const group = screen.querySelector(`[data-field="${dependent.id}"]`);
      group.hidden = !shown;
      if (!shown) { draft[stage][dependent.id] = D.blank(); group.querySelector('textarea').value = ''; }
    }
    if (stage === 'pre' && editingPre) draft.preComplete = !Object.keys(D.validate(content, stage, draft.pre, true)).length;
    if (stage === 'post') draft.reviewReady = false;
    const current = D.validate(content, stage, answersFor(stage));
    errors = Object.fromEntries(Object.entries(current).filter(([id]) => id === field.id || errors[id]));
    showErrors(); save();
  }
  screen.addEventListener('input', updateAnswer); screen.addEventListener('change', updateAnswer);
  screen.addEventListener('submit', event => {
    event.preventDefault();
    if (!draft || !available()) return;
    const stage = event.target.dataset.stage;
    if (stage.startsWith('T')) { finishTask(stage, 'completed'); return; }
    errors = D.validate(content, stage, draft[stage], true);
    if (Object.keys(errors).length) { showErrors(); screen.querySelector('[aria-invalid="true"]')?.focus(); return; }
    if (stage === 'pre') { draft.preComplete = true; editingPre = false; }
    else draft.reviewReady = true;
    save(); if (available()) go(stage === 'pre' ? D.tasksComplete(draft) ? '/study/post' : taskRoute() : '/study/complete');
  });
  async function load() {
    loaded = false; loadError = false; render();
    try {
      const response = await fetch('/api/study/content', { cache: 'no-store' });
      if (!response.ok) throw new Error('Content unavailable');
      content = await response.json();
      if (!['local', 'preview', 'pilot', 'live'].includes(content.mode) || content.contentVersion !== 'e5-preview-1') throw new Error('Unsupported content');
      store = D.storage(content); submission.read(); draft = store.read();
      if (submission.state?.kind === 'receipt' && submission.cleanup(() => store.discard())) draft = null;
      if (draft) { const t = draft.tasks[D.currentTask(draft)]; if (t.started && t.status === 'pending') { t.interrupted = true; store.save(draft); } }
      loaded = true;
    } catch { loadError = true; }
    render();
  }
  function discard(route) {
    if (submission.state || submission.recoveryBlocked) { render(); return; }
    clock?.stop(true); save();
    if (store && !store.discard()) {
      if (setupReady && !document.hidden) clock?.resume();
      updateStorage(); screen.querySelector('#draft-status')?.focus(); return;
    }
    clock = null; activeTask = null; ++setupToken;
    draft = null; errors = {}; editingPre = false; go(route, true);
  }
  screen.addEventListener('click', event => {
    const clear = event.target.closest('[data-clear]')?.dataset.clear;
    if (clear && draft) {
      const group = event.target.closest('fieldset');
      group.querySelectorAll('input').forEach(e => { e.checked = false; });
      const stage = event.target.closest('form').dataset.stage;
      if (stage.startsWith('T') && (draft.tasks[stage].status !== 'pending' || draft.tasks[stage].paused || !draft.tasks[stage].started)) return;
      answersFor(stage)[clear] = D.blank();
      // Reuse dependency clearing and validation without manufacturing a choice.
      const field = content.fields.find(f => f.id === clear);
      for (const dependent of content.fields.filter(f => f.condition?.field === field.id)) {
        draft[stage][dependent.id] = D.blank();
        const g = screen.querySelector(`[data-field="${dependent.id}"]`); g.hidden = true; g.querySelector('textarea').value = '';
      }
      if (stage === 'pre' && editingPre) draft.preComplete = !Object.keys(D.validate(content, stage, draft.pre, true)).length;
      if (stage === 'post') draft.reviewReady = false;
      delete errors[clear]; showErrors(); save(); return;
    }
    const action = event.target.closest('[data-action]')?.dataset.action;
    if (!action) return;
    if (action === 'retry-content') { load(); return; }
    if (!loaded) return;
    if (action === 'submit-responses' && content.submissionEnabled && draft) {
      const promise = submission.submit(draft, store.mode === 'memory'); render();
      promise.then(() => { if (submission.state?.kind === 'receipt' && submission.cleanup(() => store.discard())) draft = null; render(); }); return;
    }
    if (action === 'retry-submit' && submission.state?.kind === 'pending') {
      const promise = submission.submit(null); render(); promise.then(() => { if (submission.state?.kind === 'receipt' && submission.cleanup(() => store.discard())) draft = null; render(); }); return;
    }
    if (action === 'cleanup-receipt') { if (submission.cleanup(() => store.discard())) draft = null; render(); return; }
    if (action === 'new-study' && !submission.issue && submission.clearReceipt()) { draft = null; go('/study', true); return; }
    if (action === 'memory' && !submission.state && store.memory()) { submission.memory(); render(); return; }
    if (submission.state || submission.recoveryBlocked) return;
    if (action === 'start') {
      if (!available()) return;
      if (!draft) {
        const acknowledgements = Object.fromEntries(content.fields.filter(f => f.id.startsWith('C')).map(f => [f.id, screen.querySelector('#' + f.id).checked]));
        if (!Object.values(acknowledgements).every(Boolean)) { screen.querySelector('#consent-error').textContent = 'Please confirm all six acknowledgements before starting.'; screen.querySelector('.acknowledgement input:not(:checked)').focus(); return; }
        try { draft = D.create(content, acknowledgements); } catch { screen.querySelector('#consent-error').textContent = 'A secure random participant code could not be created. Use a secure browser connection and retry.'; return; }
        save();
      }
      if (available()) go(maximum() === 2 ? taskRoute() : routes[maximum()]);
    } else if (action === 'task-setup') { openTaskSetup(activeTask); }
    else if (action === 'pause-task' && activeTask) {
      const t = draft.tasks[activeTask];
      if (t.status !== 'pending' || !t.started) return;
      if (t.paused) { t.paused = false; if (!document.hidden) clock?.resume(); }
      else { clock?.stop(true); t.paused = true; }
      save(); updateTaskStatus();
    } else if (action === 'skip-task' || action === 'unable-task') finishTask(activeTask, action === 'skip-task' ? 'skipped' : 'could_not_work_out');
    else if (action === 'edit-pre' && draft) { editingPre = true; errors = {}; go('/study/pre'); }
    else if (action === 'stop' || action === 'decline' || action === 'restart') discard(action === 'restart' ? '/study' : `/study/${action === 'decline' ? 'declined' : 'stopped'}`);
    else if (action === 'memory' && store.memory()) { updateStorage(); }
    else if (action === 'retry-storage' && draft) { store.retry(draft); render(); }
  });
  document.addEventListener('click', event => {
    const target = event.target.closest('a[href^="#"]')?.getAttribute('href');
    if (!target || target.startsWith('#/')) return;
    const element = document.getElementById(target.slice(1)); if (!element) return;
    event.preventDefault(); const disclosure = element.closest('details'); if (disclosure) disclosure.open = true; element.tabIndex = -1; element.focus(); element.scrollIntoView({ block: 'start' });
  });
  window.addEventListener('hashchange', () => { errors = {}; render(); });
  fetch('/api/release', { cache: 'no-store' }).then(r => r.ok ? r.json() : null).then(release => {
    if (release) {
      const label = document.querySelector('#app-version');
      label.textContent = release.version === 'development' ? 'Development' : `v${release.version}`;
      label.title = release.revision;
    }
  }).catch(() => {});
  await load();
})();
