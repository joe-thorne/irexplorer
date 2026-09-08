// Final-only transport. Freeze the envelope before any network attempt.
window.StudySubmit = (() => {
  const KEY = 'irexplorer.study.submission.e6';
  function envelope(draft) {
    return { submissionId: crypto.randomUUID(), ...Object.fromEntries(['participantCode', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consent', 'pre', 'post'].map(k => [k, structuredClone(draft[k])])),
      tasks: Object.entries(draft.tasks).map(([id, t]) => ({ id, status: t.status, durationMs: Math.round(t.durationMs), interrupted: t.interrupted, answers: structuredClone(t.answers) })) };
  }
  function controller(getStorage = () => sessionStorage, send = (...args) => fetch(...args)) {
    let state = null, busy = false, issue = '', recoveryBlocked = false;
    function persist(next) { getStorage().setItem(KEY, JSON.stringify(next)); state = next; }
    return {
      get state() { return state; }, get busy() { return busy; }, get issue() { return issue; }, get recoveryBlocked() { return recoveryBlocked; },
      read() {
        issue = ''; recoveryBlocked = false;
        try {
          const raw = getStorage().getItem(KEY);
          if (!raw) return;
          const parsed = JSON.parse(raw);
          if (!['pending', 'receipt'].includes(parsed?.kind) || (parsed.kind === 'pending' ? !parsed.payload?.submissionId : !parsed.receipt?.receiptId)) throw Error();
          state = parsed;
        } catch { recoveryBlocked = true; issue = 'Submission recovery could not be read. Restore browser storage before starting or retrying.'; }
      },
      async submit(draft, memory = false) {
        if (recoveryBlocked || busy || state?.kind === 'receipt') return;
        issue = '';
        if (!state) {
          const next = { kind: 'pending', payload: envelope(draft) };
          if (next.payload.tasks.some(t => t.durationMs > 86400000) || new TextEncoder().encode(JSON.stringify(next.payload)).length > 128 * 1024) { issue = 'Submission exceeds the 24-hour per-task or 128 KiB request limit. Nothing was sent. Shorten free text or contact the researcher about the task duration.'; return; }
          try { persist(next); }
          catch {
            if (!memory) { issue = 'The retry copy could not be saved. Restore browser storage and try again. Nothing was sent.'; return; }
            state = next;
          }
        }
        busy = true;
        try {
          const response = await send('/api/study/submissions', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(state.payload), signal: AbortSignal.timeout(15000) });
          const body = await response.json();
          if (!response.ok) throw Error(body.error?.message || 'No receipt available.');
          if (![200, 201].includes(response.status) || body.submissionId !== state.payload.submissionId || body.participantCode !== state.payload.participantCode || body.studyVersion !== state.payload.studyVersion || typeof body.receiptId !== 'string') throw Error('Unrecognised receipt.');
          const next = { kind: 'receipt', receipt: body };
          state = next; // Never resume editing acknowledged responses.
          try { persist(next); } catch { issue = 'Receipt confirmed, but local cleanup needs retry. Keep this receipt code.'; }
        } catch (error) {
          issue = `${error.message} A response record may already exist. Keep this tab and retry; the same ID and answers will be sent.`;
        } finally { busy = false; }
      },
      cleanup(removeDraft) {
        if (state?.kind !== 'receipt') return false;
        try { persist(state); } catch { issue = 'Receipt confirmed. Allow browser storage and retry cleanup; a saved answer copy may remain.'; return false; }
        if (!removeDraft()) { issue = 'Receipt confirmed. Retry cleanup to remove the local answer draft.'; return false; }
        issue = ''; return true;
      },
      memory() { if (!state) { issue = ''; recoveryBlocked = false; } },
      clearReceipt() {
        if (state?.kind === 'pending' || busy) return false;
        try { getStorage().removeItem(KEY); state = null; issue = ''; return true; } catch { issue = 'Allow browser storage and retry.'; return false; }
      },
    };
  }
  return { KEY, envelope, controller };
})();
