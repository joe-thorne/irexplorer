// Final-only transport. Freeze the submission before any network attempt.
// Issues are compiled message references ({ key, params }); the view supplies their wording.
window.StudySubmit = (() => {
  const KEY = 'irexplorer.submission.v3';
  const LEGACY_KEYS = ['irexplorer.submission.v2', 'irexplorer.submission.v1', 'irexplorer.study.submission.e6'];
  const message = (key, params) => params ? { key, params } : { key };
  // A failed attempt whose cause is a compiled message rather than a server or network error text.
  const failure = key => Object.assign(Error(key), { reference: message(key) });
  function submissionFromDraft(draft) {
    return { submissionId: crypto.randomUUID(), ...Object.fromEntries(['participantCode', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consent', 'pre', 'post'].map(k => [k, structuredClone(draft[k])])),
      tasks: Object.entries(draft.tasks).map(([id, t]) => ({ id, status: t.status, durationMs: Math.round(t.durationMs), interrupted: t.interrupted, answers: structuredClone(t.answers) })) };
  }
  function controller(getStorage = () => sessionStorage, send = (...args) => fetch(...args)) {
    let state = null, busy = false, issue = null, recoveryBlocked = false, legacyPending = false,
      legacyKey = '', legacyParticipantCode = '';
    function persist(next) { getStorage().setItem(KEY, JSON.stringify(next)); state = next; }
    // A pending submission that this version cannot accept: an older recovery record, or a frozen
    // submission whose instrument the server does not accept. It stays stored until explicitly discarded.
    function blockIncompatible(key, participantCode) {
      legacyPending = true; legacyKey = key; recoveryBlocked = true; legacyParticipantCode = participantCode || ''; issue = message('recovery.incompatible');
    }
    return {
      get state() { return state; }, get busy() { return busy; }, get issue() { return issue; }, get recoveryBlocked() { return recoveryBlocked; },
      read() {
        issue = null; recoveryBlocked = false; legacyPending = false; legacyKey = ''; legacyParticipantCode = '';
        try {
          const storage = getStorage();
          let raw = storage.getItem(KEY);
          if (!raw) {
            const oldKey = LEGACY_KEYS.find(key => storage.getItem(key));
            const old = oldKey ? storage.getItem(oldKey) : null;
            if (!old) return;
            const parsedOld = JSON.parse(old);
            const legacySubmission = parsedOld?.submission || parsedOld?.payload;
            if (parsedOld?.kind === 'pending' && legacySubmission?.submissionId) {
              blockIncompatible(oldKey, legacySubmission.participantCode);
              return;
            }
            if (parsedOld?.kind === 'receipt' && parsedOld.receipt?.receiptId) {
              persist(parsedOld); storage.removeItem(oldKey); return;
            }
            throw Error();
          }
          const parsed = JSON.parse(raw);
          if (!['pending', 'receipt'].includes(parsed?.kind) || (parsed.kind === 'pending' ? !parsed.submission?.submissionId : !parsed.receipt?.receiptId)) throw Error();
          state = parsed;
        } catch { recoveryBlocked = true; issue = message('recovery.unreadable'); }
      },
      get legacyPending() { return legacyPending; },
      get legacyParticipantCode() { return legacyParticipantCode; },
      discardLegacy() {
        if (!legacyPending) return false;
        try {
          getStorage().removeItem(legacyKey);
          if (legacyKey === KEY) state = null;
          legacyPending = false; legacyKey = ''; legacyParticipantCode = ''; recoveryBlocked = false; issue = null;
          return true;
        } catch { issue = message('recovery.discard-failed'); return false; }
      },
      async submit(draft, memory = false) {
        if (recoveryBlocked || busy || state?.kind === 'receipt') return;
        issue = null;
        if (!state) {
          const next = { kind: 'pending', submission: submissionFromDraft(draft) };
          if (next.submission.tasks.some(t => t.durationMs > 86400000) || new TextEncoder().encode(JSON.stringify(next.submission)).length > 128 * 1024) { issue = message('submission.limit'); return; }
          try { persist(next); }
          catch {
            if (!memory) { issue = message('submission.retry-save-failed'); return; }
            state = next;
          }
        }
        busy = true;
        try {
          const response = await send('/api/study/submissions', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(state.submission), signal: AbortSignal.timeout(15000) });
          const body = await response.json();
          // Nothing was stored: keep the frozen submission unchanged and report it as incompatible, not as uncertain.
          if (response.status === 422 && body.error?.code === 'unsupported_instrument') { blockIncompatible(KEY, state.submission.participantCode); return; }
          if (!response.ok) throw body.error?.message ? Error(body.error.message) : failure('submission.no-receipt');
          if (![200, 201].includes(response.status) || body.submissionId !== state.submission.submissionId || body.participantCode !== state.submission.participantCode || body.studyVersion !== state.submission.studyVersion || typeof body.receiptId !== 'string') throw failure('submission.invalid-receipt');
          const next = { kind: 'receipt', receipt: body };
          state = next; // Never resume editing acknowledged responses.
          try { persist(next); } catch { issue = message('cleanup.persist-failed'); }
        } catch (error) {
          issue = message('submission.uncertain', { error: error.reference || error.message });
        } finally { busy = false; }
      },
      cleanup(removeDraft) {
        if (state?.kind !== 'receipt') return false;
        try { persist(state); } catch { issue = message('cleanup.retry-save'); return false; }
        if (!removeDraft()) { issue = message('cleanup.retry-draft'); return false; }
        issue = null; return true;
      },
      memory() { if (!state) { issue = null; recoveryBlocked = false; } },
      clearReceipt() {
        if (state?.kind === 'pending' || busy) return false;
        try { getStorage().removeItem(KEY); state = null; issue = null; return true; } catch { issue = message('cleanup.retry'); return false; }
      },
    };
  }
  return { KEY, submissionFromDraft, controller };
})();
