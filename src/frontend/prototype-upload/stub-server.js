// PROTOTYPE ONLY (irexplorer#47, throwaway branch prototype/upload-flow). Not production code.
// Simulates the compiler-backed routes decided in irexplorer#44 and #46 inside the browser:
// POST /api/programs, GET /api/programs/{programId}/states|source|ir|cfg|source-mappings|comparison-report.
// A "compiled" program is backed by the curated example whose source it matches (else by a
// guess from its function names), so the real source, panel and comparison views render.
// "Server memory" survives page reloads (sessionStorage) until "Restart server" is pressed.
(() => {
  const realFetch = window.fetch.bind(window);
  const MEMORY_KEY = 'prototype.upload.server';
  const SETTINGS_KEY = 'prototype.upload.settings';
  const CAPACITY = 16;
  const read = (key, fallback) => { try { return JSON.parse(sessionStorage.getItem(key)) ?? fallback; } catch { return fallback; } };
  const write = (key, value) => { try { sessionStorage.setItem(key, JSON.stringify(value)); } catch { /* prototype */ } };

  const settings = Object.assign({ compileMs: 5000, nextOutcome: 'auto', keepAcrossReload: true }, read(SETTINGS_KEY, {}));
  let programs = read(MEMORY_KEY, []); // [{programId, fileName, source, backing}], oldest first
  let compiling = false;
  const curated = {};

  async function curatedSources() {
    if (Object.keys(curated).length) return curated;
    const { examples } = await (await realFetch('/api/examples')).json();
    for (const id of examples) curated[id] = (await (await realFetch(`/api/examples/${id}/source`)).json()).text;
    return curated;
  }

  const json = (status, body) => new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
  const failure = (status, code, message, extra = {}) => json(status, { error: { code, message, ...extra } });
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

  function safeName(name) {
    const base = String(name).replace(/\.c$/i, '');
    return base.replace(/[^A-Za-z0-9._-]+/g, '_').replace(/^[._-]+/, '') + '.c';
  }

  async function sha256(text) {
    const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
    return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, '0')).join('');
  }

  // The same refusals the browser makes before posting (irexplorer#46).
  function invalid(fileName, source) {
    const lines = source.split('\n').length - (source.endsWith('\n') ? 1 : 0);
    const bytes = new TextEncoder().encode(source).length;
    if (!/\.c$/i.test(fileName)) return ['not_c_file', `“${fileName}” is not a .c file.`];
    if (!source.trim()) return ['empty', `“${fileName}” is empty.`];
    if (source.includes('\u0000')) return ['nul_character', `“${fileName}” contains NUL characters.`];
    if (lines > 200) return ['too_many_lines', `“${fileName}” has ${lines} lines; the limit is 200.`];
    if (bytes > 16384) return ['too_large', `“${fileName}” is ${(bytes / 1024).toFixed(1)} KiB; the limit is 16 KiB.`];
    return null;
  }

  // Fake clang: a few recognisable errors so the failure states can be judged.
  function diagnose(fileName, source) {
    const diagnostics = [];
    source.split('\n').forEach((text, index) => {
      const line = index + 1;
      const error = /#error\s*(.*)/.exec(text);
      if (error) diagnostics.push({ line, column: text.indexOf('#error') + 2, message: `error: ${error[1] || '#error'}` });
      const undeclared = /\b(undeclared_\w+|totl|reslt)\b/.exec(text);
      if (undeclared) diagnostics.push({ line, column: undeclared.index + 1, message: `error: use of undeclared identifier '${undeclared[1]}'` });
      if (/^\s*(int|return)\b[^;{}]*[^;{}\s]\s*$/.test(text) && !/\)\s*$/.test(text))
        diagnostics.push({ line, column: text.length + 1, message: "error: expected ';' at end of declaration" });
    });
    const open = (source.match(/{/g) || []).length, close = (source.match(/}/g) || []).length;
    if (open > close) diagnostics.push({ line: source.split('\n').length, column: 1, message: "error: expected '}'" });
    const output = diagnostics.map(d => `${fileName}:${d.line}:${d.column}: ${d.message}\n${source.split('\n')[d.line - 1] ?? ''}\n${' '.repeat(Math.max(0, d.column - 1))}^`).join('\n')
      + (diagnostics.length ? `\n${diagnostics.length} error${diagnostics.length === 1 ? '' : 's'} generated.` : '');
    return { diagnostics: diagnostics.slice(0, 20), output };
  }

  function unsupported(source) {
    if (/goto\s*\*|[=,{(]\s*&&\s*[A-Za-z_]/.test(source)) return { reason: 'computed_goto', message: 'This program uses a computed goto (goto *), and irexplorer cannot show the indirect branch it compiles to.' };
    if (/asm\s+goto/.test(source)) return { reason: 'asm_goto', message: 'This program uses asm goto, and irexplorer cannot show the branch it compiles to.' };
    if (!/\)\s*\{/.test(source)) return { reason: 'no_function', message: 'The compiler kept no function from this program. Add at least one function definition.' };
    return null;
  }

  async function backingFor(source) {
    const sources = await curatedSources();
    const normalised = source.replace(/\r\n?/g, '\n').trim();
    const exact = Object.entries(sources).find(([, text]) => text.trim() === normalised);
    if (exact) return exact[0];
    if (/partition|quick_?sort/.test(source)) return 'quick_sort';
    if (/binary_?search|\blo\b.*\bhi\b/.test(source)) return 'binary_search';
    return 'score';
  }

  async function compile(init) {
    const { fileName: suppliedName, source: suppliedSource } = JSON.parse(init.body || '{}');
    const source = String(suppliedSource ?? '').replace(/\r\n?/g, '\n');
    const fileName = /\.c$/i.test(suppliedName || '') ? safeName(suppliedName) : String(suppliedName || '');
    const refusal = invalid(fileName, source);
    if (refusal) return failure(400, 'invalid_program', refusal[1], { reason: refusal[0] });
    const forced = settings.nextOutcome;
    if (forced !== 'auto') { settings.nextOutcome = 'auto'; write(SETTINGS_KEY, settings); document.dispatchEvent(new Event('prototype:settings')); }
    if (forced === 'compiler_unavailable') { await sleep(300); return failure(503, 'compiler_unavailable', 'The compiler service is not running. Start the user-programs stack, then try again.'); }
    if (compiling || forced === 'compiler_busy') { await sleep(200); return failure(409, 'compiler_busy', 'The compiler is already compiling another program. Try again when it finishes.'); }
    const programId = await sha256(`${fileName}\n${source}`);
    const known = programs.find(program => program.programId === programId);
    if (known && forced === 'auto') return json(200, { programId, fileName });
    compiling = true;
    try {
      if (forced === 'compile_timeout') { await sleep(30000); return failure(504, 'compile_timeout', 'Compiling took longer than 30 s, so it was stopped.'); }
      await sleep(settings.compileMs);
      const { diagnostics, output } = forced === 'compile_failed'
        ? { diagnostics: [{ line: 3, column: 5, message: "error: use of undeclared identifier 'total'" }], output: `${fileName}:3:5: error: use of undeclared identifier 'total'\n1 error generated.` }
        : diagnose(fileName, source);
      if (diagnostics.length) return failure(422, 'compile_failed', `clang could not compile ${fileName}.`, { diagnostics, output });
      if (forced === 'parser_failure') return failure(422, 'unsupported_program', `${fileName} compiled, but irexplorer could not read the IR the compiler produced.`, { reason: 'parser_failure', detail: `ParseError: ${fileName}, State 7 (licm), line 41: unexpected token 'callbr' in block %for.body` });
      const notShown = unsupported(source);
      if (notShown) return failure(422, 'unsupported_program', `${fileName} compiled, but irexplorer cannot show it. ${notShown.message}`, { reason: notShown.reason });
      programs = programs.filter(program => program.programId !== programId);
      programs.push({ programId, fileName, source, backing: await backingFor(source) });
      if (programs.length > CAPACITY) programs.shift();
      write(MEMORY_KEY, programs);
      document.dispatchEvent(new Event('prototype:server'));
      return json(201, { programId, fileName });
    } finally { compiling = false; }
  }

  // Serve a program's routes from its backing curated example, renamed to the program.
  async function serve(url, programId, rest) {
    const program = programs.find(item => item.programId === programId);
    if (!program) return failure(404, 'unknown_program', 'The server no longer has this program. Upload it again.');
    if (rest === 'manifest') return json(200, { programId, fileName: program.fileName });
    if (rest === 'source') return json(200, { programId, file: program.fileName, text: program.source });
    const response = await realFetch(`/api/examples/${program.backing}/${rest}${url.search}`);
    const text = (await response.text())
      .replaceAll(`/workspace/examples/curated/${program.backing}.c`, `/workspace/user-programs/${program.fileName}`)
      .replaceAll(`"${program.backing}.c"`, JSON.stringify(program.fileName))
      .replaceAll(`"exampleId":"${program.backing}"`, `"programId":"${programId}"`);
    return new Response(text, { status: response.status, headers: { 'Content-Type': 'application/json' } });
  }

  window.fetch = async (input, init = {}) => {
    const url = new URL(typeof input === 'string' ? input : input.url, location.href);
    if (url.pathname === '/api/programs' && (init.method || 'GET').toUpperCase() === 'POST') return compile(init);
    const match = /^\/api\/programs\/([^/]+)\/(.+)$/.exec(url.pathname);
    if (match) return serve(url, decodeURIComponent(match[1]), match[2]);
    return realFetch(input, init);
  };

  window.PrototypeServer = {
    settings,
    saveSettings() { write(SETTINGS_KEY, settings); document.dispatchEvent(new Event('prototype:settings')); },
    restart() { programs = []; write(MEMORY_KEY, programs); document.dispatchEvent(new Event('prototype:server')); },
    get programs() { return programs.map(({ programId, fileName, backing }) => ({ programId, fileName, backing })); },
    safeName,
    curatedSources,
  };
})();
