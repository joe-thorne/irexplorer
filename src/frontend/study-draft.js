// Local study state only. No network or workspace dependencies.
window.StudyDraft = (() => {
  const KEY = 'irexplorer.study.e4'; // Stable key detects incompatible earlier previews for explicit discard.
  const blank = () => ({ status: 'unanswered', value: null });
  const fieldsFor = (content, stage) => content.fields.filter(f => f.id.startsWith(stage === 'pre' ? 'P' : stage === 'post' ? 'Q' : stage));
  function visible(field, answers) {
    if (!field.condition) return true;
    const parent = answers[field.condition.field];
    const values = Array.isArray(parent?.value) ? parent.value : [parent?.value];
    return parent?.status === 'answered' && values.some(v => field.condition.values.includes(v));
  }
  function validate(content, stage, answers, complete = false, recovering = false) {
    const fields = fieldsFor(content, stage), errors = {};
    if (!answers || typeof answers !== 'object' || Array.isArray(answers)) return { stage: 'Invalid survey.' };
    for (const id of Object.keys(answers)) if (!fields.some(f => f.id === id)) errors[id] = 'Unknown item.';
    for (const field of fields) {
      const answer = answers[field.id] ?? blank();
      if (!answer || Object.keys(answer).sort().join(',') !== 'status,value') { errors[field.id] = 'Invalid answer.'; continue; }
      const { status, value } = answer;
      if (status === 'unanswered' && value === null) {
        if (complete && field.required) errors[field.id] = 'Choose an answer for P1.';
        continue;
      }
      if (value === null && ((status === 'not_applicable' && (field.notApplicableLabel || Object.values(field.optionStatuses || {}).includes(status))) || (status === 'could_not_work_out' && (field.inabilityLabel || Object.values(field.optionStatuses || {}).includes(status))))) continue;
      let valid = status === 'answered';
      if (['text', 'short_text'].includes(field.type)) {
        valid &&= typeof value === 'string' && !!value.trim() && (recovering || [...value].length <= field.maxLength);
      } else {
        const allowed = (field.options || content.scales[field.scale]).filter(o => !field.optionStatuses?.[o.value]).map(o => o.value);
        const values = field.type === 'multiple' ? value : [value];
        valid &&= Array.isArray(values) && values.length > 0 && values.every(v => Number.isInteger(v) && allowed.includes(v)) && new Set(values).size === values.length && !(values.includes(field.exclusiveValue) && values.length > 1);
      }
      valid &&= visible(field, answers);
      if (!valid) errors[field.id] = ['text', 'short_text'].includes(field.type) ? `Use no more than ${field.maxLength.toLocaleString()} characters. Your text has not been shortened.` : 'Choose one of this item’s options.';
    }
    return errors;
  }
  function create(content, acknowledgements) {
    if (!content.fields.filter(f => f.id.startsWith('C')).every(f => acknowledgements[f.id] === true)) throw new Error('Consent is required.');
    return { schemaVersion: 2, studyVersion: content.studyVersion, contentVersion: content.contentVersion,
      instrumentVersion: content.instrumentVersion, participantCode: crypto.randomUUID(),
      consent: { version: content.contentVersion, acknowledgements }, pre: Object.fromEntries(fieldsFor(content, 'pre').map(f => [f.id, blank()])),
      post: Object.fromEntries(fieldsFor(content, 'post').map(f => [f.id, blank()])),
      preComplete: false, p13Locked: false, reviewReady: false,
      tasks: Object.fromEntries(content.tasks.map(t => [t.id, { status: 'pending', started: false, paused: false, durationMs: 0, interrupted: false, answers: Object.fromEntries(fieldsFor(content, t.id).map(f => [f.id, blank()])) }])) };
  }
  function decode(raw, content) {
    if (raw.length > 256 * 1024) throw new Error('Draft is too large.');
    const d = JSON.parse(raw);
    const keys = ['schemaVersion', 'studyVersion', 'contentVersion', 'instrumentVersion', 'participantCode', 'consent', 'pre', 'post', 'preComplete', 'p13Locked', 'tasks', 'reviewReady'];
    if (!d || Object.keys(d).sort().join() !== keys.sort().join() || d.schemaVersion !== 2 || d.studyVersion !== content.studyVersion || d.contentVersion !== content.contentVersion || d.instrumentVersion !== content.instrumentVersion || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(d.participantCode)) throw new Error('Unsupported draft.');
    const consent = content.fields.filter(f => f.id.startsWith('C'));
    if (!d.consent || Object.keys(d.consent).sort().join() !== 'acknowledgements,version' || d.consent.version !== content.contentVersion || Object.keys(d.consent.acknowledgements || {}).length !== consent.length || !consent.every(f => d.consent.acknowledgements[f.id] === true)) throw new Error('Invalid consent.');
    if (!['preComplete', 'p13Locked', 'reviewReady'].every(k => typeof d[k] === 'boolean') || (d.reviewReady && !tasksComplete(d))) throw new Error('Invalid progress.');
    if (!d.tasks || Object.keys(d.tasks).join() !== content.tasks.map(t => t.id).join()) throw new Error('Invalid task order.');
    let pending = false;
    for (const task of content.tasks) {
      const t = d.tasks[task.id];
      if (!t || Object.keys(t).sort().join() !== 'answers,durationMs,interrupted,paused,started,status' ||
          !['pending', 'completed', ...(task.id === 'T0' ? [] : ['skipped', 'could_not_work_out'])].includes(t.status) ||
          !['started', 'paused', 'interrupted'].every(k => typeof t[k] === 'boolean') ||
          !Number.isFinite(t.durationMs) || t.durationMs < 0 || t.durationMs > Number.MAX_SAFE_INTEGER ||
          (pending && (t.started || t.status !== 'pending')) ||
          (!t.started && (t.durationMs !== 0 || t.paused || t.interrupted || t.status !== 'pending')) ||
          (t.started && !d.p13Locked) || (t.status !== 'pending' && t.paused) ||
          Object.keys(validate(content, task.id, t.answers, false, true)).length ||
          Object.keys(t.answers).join() !== fieldsFor(content, task.id).map(f => f.id).join() ||
          (!t.started && Object.values(t.answers).some(a => a.status !== 'unanswered'))) throw new Error('Invalid task progress or responses.');
      if (t.status === 'pending') pending = true;
    }
    for (const stage of ['pre', 'post']) {
      if (Object.keys(validate(content, stage, d[stage], stage === 'pre' && d.preComplete, true)).length) throw new Error('Invalid answers.');
      if (fieldsFor(content, stage).some(f => !Object.hasOwn(d[stage], f.id))) throw new Error('Incomplete draft structure.');
    }
    return d;
  }
  function tasksComplete(d) { return !!d?.tasks && Object.values(d.tasks).every(t => t.status !== 'pending'); }
  function currentTask(d) { return Object.keys(d.tasks).find(id => d.tasks[id].status === 'pending') || 'T6'; }
  function storage(content, getStorage = () => sessionStorage) {
    let mode = 'local', issue = '', stale = false, unreadable = false;
    return {
      get mode() { return mode; }, get issue() { return issue; }, get stale() { return stale; }, get unreadable() { return unreadable; },
      read() {
        let raw;
        try { raw = getStorage().getItem(KEY); } catch { mode = 'blocked'; unreadable = true; issue = 'Browser storage is unavailable. Any older saved copy could not be checked.'; return null; }
        if (!raw) return null;
        try { return decode(raw, content); } catch { mode = 'invalid'; issue = 'A damaged or incompatible draft could not be restored. Discard it to start a new preview.'; stale = true; return null; }
      },
      save(draft) {
        if (mode === 'memory') return true;
        if (mode !== 'local') return false;
        try { getStorage().setItem(KEY, JSON.stringify(draft)); issue = ''; stale = false; unreadable = false; return true; }
        catch {
          mode = 'blocked'; issue = 'The latest answers could not be saved in this tab.';
          try { getStorage().removeItem(KEY); stale = false; } catch { stale = true; }
          return false;
        }
      },
      memory() {
        // Remove any old snapshot before promising a fresh memory-only session.
        if (stale) return false;
        mode = 'memory'; issue = ''; return true;
      },
      retry(draft) { mode = 'local'; return this.save(draft); },
      discard() {
        try { getStorage().removeItem(KEY); stale = false; unreadable = false; issue = ''; mode = 'local'; return true; }
        catch {
          // If reads/writes have always failed and there was no prior snapshot,
          // there is no saved study data to remove.
          if (!stale && !unreadable && mode !== 'local') { mode = 'blocked'; return true; }
          stale = true; mode = 'blocked'; issue = 'The saved draft could not be removed. Allow browser storage and retry discard; it may return on refresh.'; return false;
        }
      },
    };
  }
  return { tasksComplete, currentTask, KEY, blank, fieldsFor, visible, validate, create, decode, storage };
})();
