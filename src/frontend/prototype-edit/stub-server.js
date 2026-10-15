// PROTOTYPE ONLY (irexplorer#71, throwaway branch prototype/editing-flow). Not production code.
// Stands in for the compiler-backed /api/programs routes inside the browser, so the M1 flow runs with no
// compiler service: /api/release reports the user programs setting on, POST /api/programs "compiles"
// after a delay, and /api/programs/{programId}/… answers from the curated example the program most
// resembles (by function names). The IR, CFG and comparison are therefore that example's, and line links
// drift once lines are added or removed. Compile errors are a few recognised patterns, not clang.
(() => {
  const realFetch = window.fetch.bind(window);
  const SETTINGS_KEY = "prototype.edit.settings";
  const MEMORY_KEY = "prototype.edit.server";
  const read = (key, fallback) => { try { return JSON.parse(sessionStorage.getItem(key)) ?? fallback; } catch { return fallback; } };
  const write = (key, value) => { try { sessionStorage.setItem(key, JSON.stringify(value)); } catch { /* prototype */ } };

  const settings = Object.assign({ compileMs: 4000, nextOutcome: "auto" }, read(SETTINGS_KEY, {}));
  let programs = read(MEMORY_KEY, []); // [{ programId, fileName, source, backing }]
  let compiling = false;
  const curated = {};

  async function curatedSources() {
    if (Object.keys(curated).length) return curated;
    const { examples } = await (await realFetch("/api/examples")).json();
    for (const id of examples) curated[id] = (await (await realFetch(`/api/examples/${id}/source`)).json()).text;
    return curated;
  }

  const json = (status, body) => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
  const failure = (status, code, message, extra = {}) => json(status, { error: { code, message, ...extra } });
  const sleep = (ms, signal) => new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, ms);
    signal?.addEventListener("abort", () => { clearTimeout(timer); reject(new DOMException("Aborted", "AbortError")); });
  });

  async function sha256(text) {
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
    return [...new Uint8Array(digest)].map(byte => byte.toString(16).padStart(2, "0")).join("");
  }

  // Fake clang: a few recognisable errors, so the failure path can be walked from the editor.
  function diagnose(fileName, source) {
    const diagnostics = [];
    const lines = source.split("\n");
    lines.forEach((text, index) => {
      const line = index + 1;
      const error = /#error\s*(.*)/.exec(text);
      if (error) diagnostics.push({ line, column: text.indexOf("#error") + 2, message: error[1] || "#error" });
      const undeclared = /\b(undeclared_\w+|totl|reslt|vlaue)\b/.exec(text);
      if (undeclared) diagnostics.push({ line, column: undeclared.index + 1, message: `use of undeclared identifier '${undeclared[1]}'` });
      if (/^\s*(int|long|unsigned|double|float|char|size_t|return)\b[^;{}]*[^;{}\s,(]\s*$/.test(text) && !/\)\s*$/.test(text)) {
        diagnostics.push({ line, column: text.length + 1, message: "expected ';' at end of declaration" });
      }
    });
    const open = (source.match(/{/g) || []).length, close = (source.match(/}/g) || []).length;
    if (open > close) diagnostics.push({ line: lines.length - (source.endsWith("\n") ? 1 : 0), column: 1, message: "expected '}'" });
    const found = diagnostics.map(d => ({ file: fileName, severity: "error", ...d }));
    const output = found.map(d => `${fileName}:${d.line}:${d.column}: error: ${d.message}\n${lines[d.line - 1] ?? ""}\n${" ".repeat(Math.max(0, d.column - 1))}^`).join("\n")
      + (found.length ? `\n${found.length} error${found.length === 1 ? "" : "s"} generated.` : "");
    return { diagnostics: found.slice(0, 20), output };
  }

  const definitions = text => new Set([...text.matchAll(/^[A-Za-z_][\w\s*]*?\b([A-Za-z_]\w*)\s*\([^;]*\)\s*\{/gm)].map(match => match[1]));

  // The curated example to borrow views from: the one sharing most function names, else score.
  async function backingFor(source) {
    const sources = await curatedSources();
    const mine = definitions(source);
    let best = ["score", 0];
    for (const [id, text] of Object.entries(sources)) {
      const shared = [...definitions(text)].filter(name => mine.has(name)).length;
      if (shared > best[1]) best = [id, shared];
    }
    return best[0];
  }

  async function compile(init) {
    const { fileName, source } = JSON.parse(init.body || "{}");
    const forced = settings.nextOutcome;
    if (forced !== "auto") { settings.nextOutcome = "auto"; save(); }
    if (forced === "compiler_unavailable") { await sleep(300); return failure(503, "compiler_unavailable", "The compiler service is not running. Start the user-programs stack, then try again."); }
    if (compiling) return failure(409, "compiler_busy", "The compiler is already compiling another program. Try again when it finishes.");
    const programId = await sha256(`${fileName}\n${source}`);
    if (programs.some(program => program.programId === programId)) return json(200, { programId, fileName });
    compiling = true;
    try {
      await sleep(settings.compileMs, init.signal);
      const { diagnostics, output } = diagnose(fileName, source);
      if (diagnostics.length) return failure(422, "compile_failed", `clang could not compile ${fileName}.`, { reason: "clang", diagnostics, output });
      if (!/\)\s*\{/.test(source)) return failure(422, "unsupported_program", "The compiler kept no function from this program. Add at least one function definition.", { reason: "no_function" });
      programs = programs.filter(program => program.programId !== programId);
      programs.push({ programId, fileName, source, backing: await backingFor(source) });
      if (programs.length > 16) programs.shift();
      write(MEMORY_KEY, programs);
      document.dispatchEvent(new Event("prototype:server"));
      return json(201, { programId, fileName });
    } finally { compiling = false; }
  }

  async function serve(url, programId, rest) {
    const program = programs.find(item => item.programId === programId);
    if (!program) return failure(404, "unknown_program", "The server does not hold this user program.");
    if (rest === "manifest") return json(200, { programId, fileName: program.fileName });
    if (rest === "source") return json(200, { programId, file: program.fileName, text: program.source });
    const response = await realFetch(`/api/examples/${program.backing}/${rest}${url.search}`);
    const text = (await response.text())
      .replaceAll(`/workspace/examples/curated/${program.backing}.c`, `/workspace/user-programs/${program.fileName}`)
      .replaceAll(`"${program.backing}.c"`, JSON.stringify(program.fileName))
      .replaceAll(`"exampleId":"${program.backing}"`, `"programId":"${programId}"`);
    return new Response(text, { status: response.status, headers: { "Content-Type": "application/json" } });
  }

  window.fetch = async (input, init = {}) => {
    const url = new URL(typeof input === "string" ? input : input.url, location.href);
    if (url.pathname === "/api/release") {
      const response = await realFetch(input, init);
      const body = await response.json();
      return json(response.status, { ...body, config: { ...(body.config || {}), userPrograms: true } });
    }
    if (url.pathname === "/api/programs" && (init.method || "GET").toUpperCase() === "POST") {
      try { return await compile(init); } catch (error) { compiling = false; throw error; }
    }
    const match = /^\/api\/programs\/([^/]+)\/(.+)$/.exec(url.pathname);
    if (match) return serve(url, decodeURIComponent(match[1]), match[2]);
    return realFetch(input, init);
  };

  function save() { write(SETTINGS_KEY, settings); document.dispatchEvent(new Event("prototype:settings")); }

  window.PrototypeServer = {
    settings, save, curatedSources,
    restart() { programs = []; write(MEMORY_KEY, programs); document.dispatchEvent(new Event("prototype:server")); },
    get programs() { return programs.map(({ programId, fileName, backing }) => ({ programId, fileName, backing })); },
  };
})();
