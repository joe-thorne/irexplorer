// E4 synthetic consent/surveys. Tasks remain a preview; E6 supplies submission.
(async () => {
  const D = window.StudyDraft;
  const preview = document.body.dataset.studyMode === 'preview';
  const screen = document.querySelector('#study-screen');
  const workspace = document.querySelector('#workspace-shell');
  const progress = document.querySelector('#study-progress');
  const layout = document.querySelector('#journey-layout');
  const routes = ['/study', '/study/pre', '/study/tasks/preview', '/study/post', '/study/complete'];
  const names = ['Information', 'Pre-survey', 'Tasks', 'Post-survey', 'Review'];
  const esc = text => String(text).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  const button = (action, text, primary = false) => `<button type="button" data-action="${action}"${primary ? ' class="primary"' : ''}>${text}</button>`;
  const heading = text => `<h2 id="route-heading" tabindex="-1">${text}</h2>`;
  let content, store, draft = null, editingPre = false, errors = {}, loaded = false, loadError = false;
  function go(route, replace = false) {
    if (replace || location.hash === `#${route}`) { history.replaceState(null, '', `#${route}`); render(); }
    else location.hash = route;
  }
  function maximum() { return !draft ? 0 : !draft.preComplete ? 1 : !draft.previewTaskComplete ? 2 : !draft.reviewReady ? 3 : 4; }
  function save() { if (draft) store.save(draft); updateStorage(); }
  function updateStorage() {
    const area = screen.querySelector('#draft-status');
    if (!area || !store) return;
    if (store.mode === 'blocked' || store.mode === 'invalid') {
      area.innerHTML = `<p role="alert">${esc(store.issue)}${store.stale ? ' A previous saved copy may remain.' : ''}</p>${draft ? button('retry-storage', 'Retry local save') : ''}${!store.stale && store.mode !== 'invalid' ? button('memory', 'Continue in memory only') : ''}${store.stale ? button('stop', 'Retry discard saved draft') : ''}`;
    } else area.innerHTML = `<p role="status">${store.mode === 'memory' ? 'Memory only: refreshing or leaving this page loses this trial. Nothing is sent.' + (store.unreadable ? ' Any older saved copy could not be checked or removed.' : '') : draft ? 'Draft saved in this tab. Refresh here to recover; closing the tab is not a supported recovery workflow. Nothing is sent.' : 'After consent, this preview saves a draft in this tab. Refresh here to recover; closing the tab is not a supported recovery workflow.'}</p>`;
  }
  function available() { if (store.mode === 'local' || store.mode === 'memory') return true; screen.querySelector('#draft-status')?.focus(); return false; }
  function fieldHtml(field, stage) {
    const answer = draft[stage][field.id], id = field.id.replaceAll('.', '-');
    const locked = stage === 'pre' && ((draft.preComplete && !editingPre) || (field.id === 'P13' && draft.p13Locked));
    const label = `${field.id}. ${field.prompt}`;
    let control;
    if (field.type === 'text') control = `<label class="sr-only" for="answer-${id}">${esc(label)}</label><textarea id="answer-${id}" name="${field.id}" rows="3" aria-describedby="note-${id} error-${id}"${locked ? ' readonly' : ''}>${esc(answer.status === 'answered' ? answer.value : '')}</textarea>`;
    else {
      const options = (field.options || content.scales[field.scale]).map(o => ({ ...o, status: field.optionStatuses?.[o.value] || 'answered' }));
      if (field.notApplicableLabel) options.push({ value: 'na', status: 'not_applicable', label: field.notApplicableLabel });
      control = `<div class="answer-options${field.type === 'rating' ? ' rating-options' : ''}">${options.map((o, n) => {
        const selected = o.status === 'not_applicable' ? answer.status === o.status : answer.status === 'answered' && (Array.isArray(answer.value) ? answer.value.includes(o.value) : answer.value === o.value);
        return `<label class="answer-option${o.status === 'not_applicable' ? ' not-applicable' : ''}" for="answer-${id}-${n}"><input id="answer-${id}-${n}" type="${field.type === 'multiple' ? 'checkbox' : 'radio'}" name="${field.id}" value="${o.value}" data-status="${o.status}"${selected ? ' checked' : ''}${locked ? ' disabled' : ''}${field.required ? ' required' : ''} aria-describedby="note-${id} error-${id}"><span>${field.type === 'rating' && o.status === 'answered' ? `<span class="rating-number">${o.value}</span>` : ''}${esc(o.label)}</span></label>`;
      }).join('')}</div>`;
    }
    const note = locked ? (field.id === 'P13' ? 'Locked when the preview task started; kept as your pre-exposure answer.' : 'Saved answer. Use Edit background answers to correct it.') : field.type === 'text' ? `${field.required ? 'Required' : 'Optional'} · up to ${field.maxLength.toLocaleString()} characters.` : field.required ? 'Required.' : field.type === 'multiple' ? 'Optional · select all that apply.' : 'Optional.';
    return `<fieldset class="survey-item" data-field="${field.id}"${D.visible(field, draft[stage]) ? '' : ' hidden'}><legend>${esc(label)}</legend><p id="note-${id}" class="form-note">${note}</p>${control}<p id="error-${id}" class="field-error" role="alert"></p>${!locked && field.type !== 'text' ? `<button type="button" class="clear-answer" data-clear="${field.id}" aria-label="Clear answer for ${field.id}">Clear answer</button>` : ''}</fieldset>`;
  }
  function survey(stage) {
    const sections = content[stage === 'pre' ? 'preSections' : 'postSections'];
    return `<form id="survey-form" novalidate data-stage="${stage}"><p id="form-errors" role="alert" tabindex="-1"></p>${sections.map(s => `<section class="survey-section"><h3>${esc(s.title)}</h3>${s.intro ? `<p>${esc(s.intro)}</p>` : ''}${s.groups ? s.groups.map(g => `<h4>${esc(g.title)}</h4>${g.fields.map(id => fieldHtml(content.fields.find(f => f.id === id), stage)).join('')}`).join('') : s.fields.map(id => fieldHtml(content.fields.find(f => f.id === id), stage)).join('')}</section>`).join('')}<div class="screen-actions"><button type="submit" class="primary">${stage === 'post' ? 'Review responses' : editingPre ? 'Save background corrections' : draft.preComplete ? 'Return to preview task' : 'Save pre-survey and start preview task'}</button>${stage === 'pre' && draft.preComplete && !editingPre ? button('edit-pre', 'Edit background answers') : ''}</div></form>`;
  }
  function informationSections(sections) {
    return sections.map(s => `<section><h3>${esc(s.title)}</h3>${s.blocks.map(b => b.kind === 'paragraph' ? `<p>${esc(b.text)}</p>` : `<${b.kind === 'ordered' ? 'ol' : 'ul'}>${b.items.map(i => `<li>${esc(i)}</li>`).join('')}</${b.kind === 'ordered' ? 'ol' : 'ul'}>`).join('')}</section>`).join('');
  }
  function info() {
    return `<p class="preview-warning"><strong>Draft v0.1 — synthetic review only.</strong> The inherited withdrawal, eligibility, storage/use and contact wording below is awaiting confirmation. It is not release consent. Use invented answers only.</p><div class="participant-information">${informationSections(content.information.slice(0, -1))}</div><h3>Consent</h3><p>Please confirm each of the following before starting.</p><p>For this synthetic preview, the boxes rehearse consent only. Stop/discard removes the local draft; nothing can be submitted. After submission behaviour remains pending review and E6.</p>${content.fields.filter(f => f.id.startsWith('C')).map(f => `<label class="acknowledgement" for="${f.id}"><input id="${f.id}" type="checkbox"${draft ? ' checked disabled' : ''}>${esc(f.prompt)}</label>`).join('')}<p id="consent-error" role="alert"></p><div class="screen-actions">${button('start', draft ? 'Return to study' : 'Continue to pre-survey', true)}${!draft ? button('decline', 'Decline and exit') : ''}</div><div class="participant-information">${informationSections(content.information.slice(-1))}</div>`;
  }
  function review() {
    return heading('Review responses — submission pending') + `<p><strong>Nothing has been submitted.</strong> Your synthetic responses stay in this browser. Final submission and a durable receipt will be connected in E6.</p><p>The completed study will send consent, survey and task responses, task durations, and the random participant code together only when you select Submit responses. Review the final notice before any real participation.</p><p>You can correct background answers and post-survey answers below. P13 stays locked.</p><div class="screen-actions">${button('edit-pre', 'Edit background answers')}<a href="#/study/post">Edit post-survey answers</a><button type="button" disabled>Submit responses — pending E6</button></div>${['pre', 'post'].map(stage => `<details class="response-review"><summary>${stage === 'pre' ? 'Pre-survey' : 'Post-survey'} answers</summary><dl>${D.fieldsFor(content, stage).filter(f => D.visible(f, draft[stage])).map(f => { const a = draft[stage][f.id]; let value = 'Unanswered'; if (a.status === 'not_applicable') value = f.notApplicableLabel || 'Not applicable'; if (a.status === 'answered') value = f.type === 'text' ? a.value : (Array.isArray(a.value) ? a.value : [a.value]).map(v => (f.options || content.scales[f.scale]).find(o => o.value === v).label).join('; '); return `<dt>${esc(f.id + '. ' + f.prompt)}</dt><dd>${esc(value)}</dd>`; }).join('')}</dl></details>`).join('')}`;
  }
  function render() {
    const route = location.hash.slice(1) || '/explore', explore = route === '/explore';
    const exited = ['/study/declined', '/study/stopped'].includes(route);
    const index = routes.indexOf(route);
    if (!preview && !explore) return go('/explore', true);
    if (loaded && !explore && !exited && (index < 0 || index > maximum())) return go(routes[maximum()], true);
    screen.hidden = explore; workspace.hidden = !explore && (!loaded || index !== 2);
    progress.hidden = explore || exited || !loaded;
    document.querySelector('#explore-heading').hidden = !explore;
    document.querySelector('.skip-link').href = explore ? '#explore-heading' : '#route-heading';
    layout.classList.toggle('with-task', !explore && loaded && index === 2);
    if (explore) { document.title = 'Explore · irexplorer'; document.querySelector('#explore-heading').focus(); return; }
    if (!loaded) {
      screen.innerHTML = heading(loadError ? 'Study content unavailable' : 'Loading study content…') + (loadError ? `<p>No study answers have been sent. Retry to load the forms and recover any compatible local draft.</p>${button('retry-content', 'Retry loading forms', true)}` : '');
    } else {
      progress.innerHTML = `<ol>${names.map((name, n) => `<li${n === index ? ' aria-current="step"' : ''}>${n + 1}. ${n <= maximum() ? `<a href="#${routes[n]}">${name}</a>` : name}</li>`).join('')}</ol>`;
      let html;
      if (exited) html = heading(route.endsWith('declined') ? 'Preview declined' : 'Preview stopped') + `<p>No response record was created. The local trial has been discarded.</p>${button('restart', 'Start a new preview', true)} <a href="#/explore">Explore curated artefacts</a>`;
      else if (index === 0) html = heading('Information and consent') + info();
      else if (index === 1) html = heading('Pre-survey') + `<p>Approximately 4 minutes. Every item is optional except P1.</p>${draft.p13Locked ? '<p>P13 was locked when the preview task started. Background corrections do not change it.</p>' : '<p>P13 will be locked when you start the preview task.</p>'}` + survey('pre');
      else if (index === 2) html = heading('Preview task') + `<p class="eyebrow">Synthetic workspace bridge</p><p><strong>Goal:</strong> Try comparing a curated example using the two panes.</p><details class="task-details" open><summary>Instructions</summary><p>Choose a file, then change the state or IR/CFG view in either pane. Select an IR instruction or CFG block to inspect its recorded link.</p><p>This is not T0–T6. Ordered task prompts, responses and timing arrive in E5. P13 is now locked, as it will be when T0 starts.</p></details><div class="screen-actions">${button('post', 'Continue to post-survey', true)}<a href="#/study/pre">View pre-survey</a><a href="#workspace">Go to comparison</a></div>`;
      else if (index === 3) html = heading('Post-survey') + `<p>Approximately 8 minutes. All items may be left unanswered. Answers stay local until final submission is available.</p>` + survey('post');
      else html = review();
      screen.innerHTML = (!exited ? html.replace('</h2>', '</h2><div id="draft-status" class="draft-status" tabindex="-1"></div>') : html) + (draft && !exited ? `<p class="participant-code">Participant code: ${esc(draft.participantCode)}</p><div class="study-utilities"><a href="#/study">Information</a>${button('stop', 'Stop and discard trial')}</div>` : '');
      updateStorage(); showErrors();
      if (index === 2 && matchMedia('(max-width: 1100px)').matches) screen.querySelector('details').open = false;
    }
    document.title = `${screen.querySelector('h2').textContent} · irexplorer preview`;
    screen.querySelector('h2').focus(); window.scrollTo(0, 0);
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
    if (!field || (stage === 'pre' && ((draft.preComplete && !editingPre) || (field.id === 'P13' && draft.p13Locked)))) return;
    if (field.type === 'text') draft[stage][field.id] = input.value.trim() ? { status: 'answered', value: input.value } : D.blank();
    else if (event.type === 'change') {
      if (field.type === 'multiple') {
        const inputs = [...input.closest('fieldset').querySelectorAll('input')];
        if (input.checked) for (const other of inputs) if (other !== input && (Number(input.value) === field.exclusiveValue || Number(other.value) === field.exclusiveValue)) other.checked = false;
        const values = inputs.filter(e => e.checked).map(e => Number(e.value));
        draft[stage][field.id] = values.length ? { status: 'answered', value: values } : D.blank();
      } else draft[stage][field.id] = { status: input.dataset.status, value: input.dataset.status === 'answered' ? Number(input.value) : null };
    } else return;
    for (const dependent of D.fieldsFor(content, stage).filter(f => f.condition)) {
      const shown = D.visible(dependent, draft[stage]);
      const group = screen.querySelector(`[data-field="${dependent.id}"]`);
      group.hidden = !shown;
      if (!shown) { draft[stage][dependent.id] = D.blank(); group.querySelector('textarea').value = ''; }
    }
    if (stage === 'pre' && editingPre) draft.preComplete = !Object.keys(D.validate(content, stage, draft.pre, true)).length;
    if (stage === 'post') draft.reviewReady = false;
    const current = D.validate(content, stage, draft[stage]);
    errors = Object.fromEntries(Object.entries(current).filter(([id]) => id === field.id || errors[id]));
    showErrors(); save();
  }
  screen.addEventListener('input', updateAnswer); screen.addEventListener('change', updateAnswer);
  screen.addEventListener('submit', event => {
    event.preventDefault();
    if (!draft || !available()) return;
    const stage = event.target.dataset.stage;
    errors = D.validate(content, stage, draft[stage], true);
    if (Object.keys(errors).length) { showErrors(); screen.querySelector('[aria-invalid="true"]')?.focus(); return; }
    if (stage === 'pre') { draft.preComplete = true; draft.p13Locked = true; editingPre = false; }
    else draft.reviewReady = true;
    save(); if (available()) go(stage === 'pre' ? '/study/tasks/preview' : '/study/complete');
  });
  async function load() {
    loaded = false; loadError = false; render();
    try {
      const response = await fetch('/api/study/content', { cache: 'no-store' });
      if (!response.ok) throw new Error('Content unavailable');
      content = await response.json();
      if (content.mode !== 'preview' || content.submissionEnabled !== false || content.contentVersion !== 'e4-preview-1') throw new Error('Unsupported content');
      store = D.storage(content); draft = store.read(); loaded = true;
    } catch { loadError = true; }
    render();
  }
  function discard(route) {
    if (store && !store.discard()) { updateStorage(); screen.querySelector('#draft-status')?.focus(); return; }
    draft = null; errors = {}; editingPre = false; go(route, true);
  }
  screen.addEventListener('click', event => {
    const clear = event.target.closest('[data-clear]')?.dataset.clear;
    if (clear && draft) {
      const group = event.target.closest('fieldset');
      group.querySelectorAll('input').forEach(e => { e.checked = false; });
      const stage = event.target.closest('form').dataset.stage;
      draft[stage][clear] = D.blank();
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
    if (!action || !preview) return;
    if (action === 'retry-content') { load(); return; }
    if (!loaded) return;
    if (action === 'start') {
      if (!available()) return;
      if (!draft) {
        const acknowledgements = Object.fromEntries(content.fields.filter(f => f.id.startsWith('C')).map(f => [f.id, screen.querySelector('#' + f.id).checked]));
        if (!Object.values(acknowledgements).every(Boolean)) { screen.querySelector('#consent-error').textContent = 'Please confirm all six acknowledgements before starting.'; screen.querySelector('.acknowledgement input:not(:checked)').focus(); return; }
        try { draft = D.create(content, acknowledgements); } catch { screen.querySelector('#consent-error').textContent = 'A secure random participant code could not be created. Use a secure browser connection and retry.'; return; }
        save();
      }
      if (available()) go(routes[maximum()]);
    } else if (action === 'post' && draft?.preComplete && available()) { draft.previewTaskComplete = true; save(); if (available()) go('/study/post'); }
    else if (action === 'edit-pre' && draft) { editingPre = true; errors = {}; go('/study/pre'); }
    else if (action === 'stop' || action === 'decline' || action === 'restart') discard(action === 'restart' ? '/study' : `/study/${action === 'decline' ? 'declined' : 'stopped'}`);
    else if (action === 'memory' && store.memory()) { updateStorage(); }
    else if (action === 'retry-storage' && draft) { store.retry(draft); updateStorage(); }
  });
  document.querySelector('#preview-controls').hidden = !preview;
  document.querySelector('#preview-reset').addEventListener('click', () => { if (preview && loaded) discard('/study'); });
  document.addEventListener('click', event => {
    const target = event.target.closest('a[href^="#"]')?.getAttribute('href');
    if (!target || target.startsWith('#/')) return;
    const element = document.getElementById(target.slice(1)); if (!element) return;
    event.preventDefault(); element.tabIndex = -1; element.focus(); element.scrollIntoView({ block: 'start' });
  });
  window.addEventListener('hashchange', () => { errors = {}; render(); });
  if (preview) await load(); else render();
})();
