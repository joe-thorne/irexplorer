// PROTOTYPE ONLY (irexplorer#47). Browser-side behaviour every variant shares: the checks made
// before posting, the synchronous compile with an elapsed-time tick, the sources the browser
// keeps, and re-posting a kept source when the server answers unknown_program.
(() => {
  const server = window.PrototypeServer;
  const CLIENT_KEY = 'prototype.upload.client';
  const read = () => { try { return JSON.parse(sessionStorage.getItem(CLIENT_KEY)) || []; } catch { return []; } };
  const save = () => { try { sessionStorage.setItem(CLIENT_KEY, JSON.stringify(server.settings.keepAcrossReload ? kept : [])); } catch { /* prototype */ } };
  let kept = server.settings.keepAcrossReload ? read() : []; // [{programId, fileName, originalName, source}]
  let busy = false;

  // Decode and check a picked file (ArrayBuffer) or pasted text (string) before anything is sent.
  function prepare(originalName, content) {
    let source = typeof content === 'string' ? content : null, utf8 = true;
    if (source === null) {
      try { source = new TextDecoder('utf-8', { fatal: true }).decode(content); } catch { utf8 = false; source = ''; }
    }
    source = source.replace(/\r\n?/g, '\n');
    const isC = /\.c$/i.test(originalName);
    const fileName = isC ? server.safeName(originalName) : originalName;
    const lines = source.split('\n').length - (source.endsWith('\n') ? 1 : 0);
    const bytes = typeof content === 'string' ? new TextEncoder().encode(source).length : content.byteLength;
    const checks = [
      { label: 'A .c file', ok: isC, refusal: `“${originalName}” is not a .c file. irexplorer compiles one C file.` },
      { label: 'Not empty', ok: Boolean(source.trim()) || !utf8, refusal: `“${originalName}” is empty.` },
      { label: 'UTF-8 text without NUL characters', ok: utf8 && !source.includes('\u0000'), refusal: utf8 ? `“${originalName}” contains NUL characters.` : `“${originalName}” is not UTF-8 text.` },
      { label: `At most 200 lines (${lines})`, ok: lines <= 200, refusal: `“${originalName}” has ${lines} lines; the limit is 200.` },
      { label: `At most 16 KiB (${(bytes / 1024).toFixed(1)} KiB)`, ok: bytes <= 16384, refusal: `“${originalName}” is ${(bytes / 1024).toFixed(1)} KiB; the limit is 16 KiB.` },
    ];
    const failed = checks.find(check => !check.ok);
    return { originalName, fileName, renamed: isC && fileName !== originalName, source, lines, checks, refusal: failed?.refusal || null };
  }

  const announce = detail => document.dispatchEvent(new CustomEvent('prototype:compile', { detail }));

  // POST /api/programs and wait (about 5 s). The server reports no stages, so the only
  // progress is elapsed time. onTick receives whole seconds.
  async function compile(prepared, { onTick = () => {}, reason = 'upload', signal } = {}) {
    busy = true;
    const started = performance.now();
    announce({ phase: 'start', reason, fileName: prepared.fileName, originalName: prepared.originalName });
    const timer = setInterval(() => onTick(Math.floor((performance.now() - started) / 1000)), 250);
    onTick(0);
    let result;
    try {
      const response = await fetch('/api/programs', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, signal,
        body: JSON.stringify({ fileName: prepared.originalName, source: prepared.source }),
      });
      const body = await response.json();
      if (response.ok) {
        kept = kept.filter(program => program.programId !== body.programId);
        kept.push({ programId: body.programId, fileName: body.fileName, originalName: prepared.originalName, source: prepared.source });
        save();
        result = { ok: true, programId: body.programId, fileName: body.fileName };
      } else result = { ok: false, error: body.error };
    } catch (error) {
      result = { ok: false, error: { code: error.name === 'AbortError' ? 'cancelled' : 'network', message: error.name === 'AbortError' ? 'Compiling was cancelled in this tab. The compiler may still be finishing it.' : error.message } };
    } finally {
      clearInterval(timer);
      busy = false;
    }
    result.seconds = Math.round((performance.now() - started) / 100) / 10;
    announce({ phase: 'end', reason, fileName: prepared.fileName, result });
    return result;
  }

  // unknown_program: the server restarted or evicted the program. Re-post the kept source once,
  // then retry the original request; parallel requests share one recompile.
  const stubFetch = window.fetch;
  let recovering = null;
  window.fetch = async (input, init) => {
    const response = await stubFetch(input, init);
    if (response.status !== 404) return response;
    const match = /^\/api\/programs\/([^/]+)\//.exec(new URL(typeof input === 'string' ? input : input.url, location.href).pathname);
    const program = match && kept.find(item => item.programId === decodeURIComponent(match[1]));
    if (!program || (await response.clone().json().catch(() => ({}))).error?.code !== 'unknown_program') return response;
    recovering ??= compile({ originalName: program.originalName, fileName: program.fileName, source: program.source }, {
      reason: 'recover', onTick: seconds => document.dispatchEvent(new CustomEvent('prototype:tick', { detail: seconds })),
    }).finally(() => { recovering = null; });
    return (await recovering).ok ? stubFetch(input, init) : response;
  };

  // Load a compiled program into the real workspace through the File selector.
  function open(programId) {
    const select = document.querySelector('#example-select');
    select.value = `program:${programId}`;
    return loadExample();
  }

  window.ProgramClient = {
    prepare, compile, open,
    get busy() { return busy; },
    get programs() { return kept.slice(); },
    program: programId => kept.find(program => program.programId === programId),
    current() { return appState.exampleId?.startsWith('program:') ? kept.find(program => `program:${program.programId}` === appState.exampleId) : null; },
    persist: save,
  };
})();
