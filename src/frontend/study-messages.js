// Participant journey wording from the package's compiled message catalogue.
// The journey itself (routes, guards, timing, transport, rendering and accessibility structure)
// stays application code: it chooses a message key and supplies placeholder values; the
// catalogue supplies only prose, which is always displayed as text.
window.StudyMessages = (() => {
  // Every key the journey displays, with the placeholders its compiled contract requires.
  const USED = Object.freeze({
    'information.title': [], 'information.purpose-label': [], 'information.submission-label': [],
    'consent.title': [], 'consent.introduction': [], 'consent.local': [], 'consent.confirm': [], 'consent.code-failure': [],
    'progress.information': [], 'progress.pre': [], 'progress.tasks': [], 'progress.post': [], 'progress.review': [], 'progress.sections': [],
    'pre.title': [], 'post.title': [], 'pre.lock-pending': [], 'pre.locked': [],
    'locking.expectation': [], 'locking.task': [], 'locking.background': [],
    'field.choose': [], 'field.text-limit': ['required', 'maxLength'], 'field.required-label': [], 'field.optional-label': [],
    'field.required': [], 'field.multiple': [], 'field.optional': [], 'field.clear-label': [], 'field.clear-accessible': ['fieldId'],
    'validation.summary': [], 'validation.unknown': [], 'validation.invalid': [], 'validation.required-p1': [],
    'validation.required-followup': [], 'validation.text-limit': ['maxLength'], 'validation.options': [],
    'actions.start': [], 'actions.return': [], 'actions.decline': [], 'actions.pre-start': [], 'actions.edit-pre': [],
    'actions.pre-corrections': [], 'actions.return-tasks': [], 'actions.review': [], 'actions.edit-post': [], 'actions.submit': [],
    'actions.finish-orientation': [], 'actions.post': [], 'actions.continue': [], 'actions.unable': [],
    'actions.skip': [], 'actions.pause': [], 'actions.resume': [], 'actions.current': [], 'actions.retry-save': [],
    'actions.memory': [], 'actions.retry-discard': [], 'actions.stop': [], 'actions.keep': [], 'actions.discard': [],
    'actions.restart': [], 'actions.explore': [], 'actions.retry-submit': [], 'actions.cleanup': [], 'actions.new-session': [],
    'actions.retry-recovery': [], 'actions.discard-incompatible': [], 'actions.discard-closed': [],
    'discard.confirm': [], 'discard.declined': [], 'discard.stopped': [], 'discard.done': [],
    'storage.stale': [], 'storage.memory': [], 'storage.unreadable': [], 'storage.saved': [], 'storage.before-consent': [],
    'storage.unavailable': [], 'storage.incompatible': [], 'storage.save-failed': [], 'storage.discard-failed': [],
    'task.title': ['taskId', 'title'], 'task.orientation': [], 'task.number': ['taskNumber'], 'task.goal-label': [],
    'task.navigation': [], 'task.instructions': [], 'task.workspace-link': [], 'task.responses-link': [], 'task.setup-title': [],
    'task.entry': ['example'], 'task.inherit': [], 'task.responses-locked': [], 'task.responses-open': [], 'task.goal-link': [],
    'task.locked': ['outcome'], 'task.optional': [], 'task.progress': [], 'task.saved': ['taskId'], 'task.current': ['taskId'],
    'outcome.completed': [], 'outcome.skipped': [], 'outcome.unable': [], 'outcome.pending': [],
    'answer.unanswered': [], 'answer.not-applicable': [],
    'timing.saved': ['seconds', 'interrupted'], 'timing.interrupted': [], 'timing.paused': [], 'timing.active': [],
    'review.title': [], 'review.not-submitted': [], 'review.submit-detail': [], 'review.frozen': [], 'review.editable': [],
    'review.tasks': [], 'review.task-summary': ['taskId', 'outcome', 'seconds', 'interrupted'], 'review.section-answers': ['section'],
    'review.duration': [],
    'submission.submitting': [], 'submission.unconfirmed': [], 'submission.wait': [], 'submission.retry': [],
    'submission.keep-tab': [], 'submission.participant-code': ['participantCode'], 'submission.no-receipt': [],
    'submission.invalid-receipt': [], 'submission.uncertain': ['error'], 'submission.limit': [], 'submission.retry-save-failed': [],
    'recovery.title': [], 'recovery.incompatible': [], 'recovery.unreadable': [], 'recovery.discard-failed': [],
    'recovery.server-copy': [], 'recovery.not-stored': [], 'recovery.memory': [],
    'closed.title': [], 'closed.detail': [], 'closed.draft': [], 'closed.not-stored': [],
    'receipt.title': [], 'receipt.saved': [], 'receipt.code': ['receiptId'], 'receipt.keep': [],
    'cleanup.done': [], 'cleanup.persist-failed': [], 'cleanup.retry-save': [], 'cleanup.retry-draft': [], 'cleanup.retry': [],
  });
  // Shown only while no catalogue is available (loading, or content that failed to load or verify).
  // The draft check requires this wording to equal the packaged catalogue's.
  const BOOTSTRAP = Object.freeze({
    'load.loading': 'Loading study content…',
    'load.unavailable': 'Study content unavailable',
    'load.retry': 'No study answers have been sent. Retry to load the forms and recover any compatible local draft.',
    'actions.retry-content': 'Retry loading forms',
  });
  const esc = text => String(text).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  // The compiler's placeholder grammar: {name}, with {{ and }} for literal braces; anything else is malformed.
  function parse(text) {
    const parts = [];
    let literal = '', index = 0;
    for (const match of text.matchAll(/\{\{|\}\}|\{([A-Za-z][A-Za-z0-9]*)\}|[{}]/g)) {
      literal += text.slice(index, match.index); index = match.index + match[0].length;
      if (match[0] === '{{' || match[0] === '}}') literal += match[0][0];
      else if (match[1]) { parts.push({ literal }, { name: match[1] }); literal = ''; }
      else return null;
    }
    parts.push({ literal: literal + text.slice(index) });
    return parts;
  }
  // Validates the catalogue once and returns its text and HTML renderers.
  function catalogue(messages) {
    if (!messages || typeof messages !== 'object' || Array.isArray(messages)) throw Error('Unsupported journey messages');
    const compiled = {};
    for (const [key, required] of Object.entries(USED)) {
      const text = Object.hasOwn(messages, key) ? messages[key] : null;
      const parts = typeof text === 'string' && text ? parse(text) : null;
      const names = new Set(parts?.filter(part => 'name' in part).map(part => part.name));
      if (!parts || names.size !== required.length || !required.every(name => names.has(name))) throw Error(`Unsupported journey message: ${key}`);
      compiled[key] = parts;
    }
    // A placeholder value is text, a number, or a nested message reference { key, params }.
    function render(reference, params, literal, value) {
      const key = typeof reference === 'string' ? reference : reference.key;
      params = typeof reference === 'string' ? params || {} : reference.params || {};
      if (!compiled[key]) throw Error(`Unknown journey message: ${key}`);
      return compiled[key].map(part => {
        if (!('name' in part)) return literal(part.literal);
        if (!Object.hasOwn(params, part.name)) throw Error(`Missing ${part.name} for journey message ${key}`);
        const supplied = params[part.name];
        return value(part.name, supplied !== null && typeof supplied === 'object' ? text(supplied) : String(supplied));
      }).join('');
    }
    const text = (reference, params) => render(reference, params, literal => literal, (_, supplied) => supplied);
    // Escaped HTML; placeholders named in `codes` are wrapped in <code>.
    const html = (reference, params, codes = []) => render(reference, params, esc,
      (name, supplied) => codes.includes(name) ? `<code>${esc(supplied)}</code>` : esc(supplied));
    return { text, html };
  }
  return { USED, BOOTSTRAP, catalogue, escape: esc };
})();
