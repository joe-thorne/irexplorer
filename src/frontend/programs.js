// User programs in Explore (ADR 0005): the Curated examples | Your files switch, uploading a C file, the
// editor for writing a new program (editor.js), and the card that stands in for the panels and the
// comparison while a user program compiles or after it fails. Nothing here is built unless /api/release
// reports the user programs setting on, and nothing here exists in Study (#/study…), which shares the
// workspace: the controls are added on entering Explore and removed on leaving it.
(() => {
  const LIMITS = "One C file, up to 200 lines. Standard headers are allowed.";
  const WAIT = "irexplorer compiles the unoptimised -O0 state, applies the curated pass sequence one pass at a time, "
    + "and compiles the recompiled O3 state separately. This usually takes about 5 s.";
  const FORGOTTEN = "The server no longer had this program, so irexplorer is compiling it again from the source this tab kept.";
  // Failures where the compiler, not the program, was the problem: the same file may well work next time.
  const RETRYABLE = new Set(["compiler_busy", "compile_timeout", "compiler_unavailable"]);
  // What a new program starts as in the editor. tests/data/user-programs/program.c is the same text, recorded
  // from the real toolchain so that the browser regression can compile it over the fake one.
  const STARTER = "// A new program: change this function, or replace it with your own C.\nint square(int x) {\n    return x * x;\n}\n";
  const EMPTY_PROMPTS = {
    curated: "Choose a curated file to start comparing.",
    yours: "Upload a C file, or choose one of your files, to start comparing.",
  };

  // The server lists at most this many of clang's warnings on a program that compiled.
  const MAX_WARNINGS = 20;

  // This tab's uploads, oldest first: { programId, fileName, source, renamedFrom, origin, warnings }, with the
  // safe name and the normalised source that were sent, the name as chosen if it was not safe (else null),
  // where the program came from: { kind: "new" } for one written in the editor, else null for an uploaded
  // file, and clang's warnings as the server listed them. A failed upload is never kept. They survive a
  // reload in this tab (session storage), not across tabs.
  const UPLOADS_KEY = "irexplorer.programs.uploads";
  const uploads = readUploads();
  // After a reload nothing reopens by itself, but a tab with uploads opens in Your files.
  let mode = uploads.length ? "yours" : "curated";
  // The user program on screen or being opened, if any.
  let current = null;
  // What the card shows in place of the panels: null (no card), { kind: "compiling", fileName, renamedFrom,
  // origin, started, cancel, forgotten } (cancel: the POST's AbortController, which Cancel aborts; forgotten:
  // recompiling a program the server no longer had), { kind: "cancelled", fileName, renamedFrom, origin,
  // source } or { kind: "failed", fileName, renamedFrom, origin, source, error }, where error is the server's
  // { code, message, … }. A file the browser refuses before sending fails with the server's invalid_program error.
  let card = null;
  let ticking = null;
  // The program open in the editor, if any: { title, origin, start, opener, exampleSelectDisabled, confirming }.
  // start is the text it opened with, so an edit is any change from it; opener is the button that opened it,
  // which gets focus back when it closes. While it is open the editor stands in for the panels and the
  // comparison (which stay as they were behind it), and the file controls are disabled.
  let editing = null;
  // The warnings the list was last built for, so it is rebuilt, and closed, only for another program.
  let listedWarnings = null;

  function readUploads() {
    try {
      const stored = JSON.parse(sessionStorage.getItem(UPLOADS_KEY) || "[]");
      if (!Array.isArray(stored)) return [];
      return stored.filter(upload => ["programId", "fileName", "source"].every(key => typeof upload?.[key] === "string"));
    } catch {
      return [];
    }
  }

  function keepUploads() {
    try { sessionStorage.setItem(UPLOADS_KEY, JSON.stringify(uploads)); } catch { /* kept for this page only */ }
  }

  function h(tag, attributes = {}, ...children) {
    const element = document.createElement(tag);
    for (const [name, value] of Object.entries(attributes)) {
      if (name.startsWith("on")) element.addEventListener(name.slice(2), value);
      else if (value === true) element.setAttribute(name, "");
      else if (value !== false && value != null) element.setAttribute(name, value);
    }
    element.append(...children);
    return element;
  }

  const view = {};
  const DRAG_EVENTS = ["dragenter", "dragover", "dragleave", "drop"];

  // Make the controls once; attach() and detach() put them in the page and take them out again.
  function build() {
    const sourcePanel = document.querySelector("#source-panel");
    view.sourcePanel = sourcePanel;
    view.controls = sourcePanel.querySelector(".source-controls");
    view.shell = document.querySelector("#workspace-shell");
    view.sourceLines = document.querySelector("#source-lines");
    view.summary = document.querySelector("#source-summary");
    view.fileControl = view.controls.querySelector('label[for="example-select"]');
    view.modes = ["curated", "yours"].map(value => h("input", {
      type: "radio", name: "source-mode", value, onchange: () => setMode(value),
    }));
    view.mode = h("fieldset", { id: "source-mode", class: "source-mode" }, h("legend", { class: "sr-only" }, "Source"),
      h("label", {}, view.modes[0], "Curated examples"), h("label", {}, view.modes[1], "Your files"));
    view.yourSelect = h("select", { id: "your-file-select", onchange: () => openUpload(view.yourSelect.value) });
    view.yourControl = h("label", { id: "your-file-control", for: "your-file-select" }, "Your file", view.yourSelect);
    view.upload = h("button", { id: "program-upload", type: "button", onclick: () => view.fileInput.click() }, "Upload…");
    view.newProgram = h("button", { id: "program-new", type: "button", onclick: openEditor }, "New…");
    view.renamed = h("p", { id: "program-renamed", class: "program-renamed" });
    view.fileInput = h("input", { id: "program-file-input", type: "file", accept: ".c", hidden: true, onchange: () => {
      const [file] = view.fileInput.files;
      view.fileInput.value = "";
      if (file) uploadFile(file);
    } });
    view.choose = h("button", { type: "button", class: "primary", onclick: () => view.fileInput.click() }, "Choose a file…");
    view.write = h("button", { type: "button", onclick: openEditor }, "Write or paste a program");
    // Stands in for the source prompt while Your files is selected (see style.css).
    view.drop = h("div", { id: "program-drop", class: "program-drop" },
      h("p", { class: "program-drop-title" }, "Drop a .c file here"),
      h("p", {}, LIMITS), h("div", { class: "program-actions" }, view.choose, view.write));
    // In the page only while a program is open in it (see renderEditor and style.css).
    view.editor = ProgramEditor.create({ label: "C source", onInput: renderEditor, onSubmit: compileEditor });
    view.editorHeading = h("h2", { id: "program-editor-heading" });
    view.editorName = h("input", { id: "program-editor-name", type: "text", spellcheck: "false", autocomplete: "off" });
    view.editorDiscard = h("button", { id: "program-editor-discard", type: "button", onclick: discardEditor });
    view.editorConfirmation = h("div", { class: "program-editor-confirmation", role: "alert" });
    view.editorSection = h("section", { id: "program-editor", class: "panel program-editor", "aria-labelledby": "program-editor-heading" },
      h("header", { class: "program-editor-heading" }, view.editorHeading,
        h("div", { class: "program-editor-controls" },
          h("label", { for: "program-editor-name" }, "File name", view.editorName),
          h("div", { class: "program-actions" },
            h("button", { id: "program-editor-compile", type: "button", class: "primary", onclick: compileEditor }, "Compile"),
            view.editorDiscard))),
      view.editorConfirmation, view.editor.element);
    view.chip = h("span", { id: "program-chip", class: "program-chip" }, "Your file");
    view.title = h("div", { class: "source-title" });
    view.card = h("section", { id: "program-card", class: "panel program-card", "aria-labelledby": "program-card-heading" });
    // clang's warnings on the open upload, collapsed, between the source heading and the source lines.
    view.warnings = h("details", { id: "program-warnings", class: "program-warnings" });
    recompileForgottenProgram = recompileForgotten;
    // The workspace draws the source lines again once a program has loaded, so their marks are put back.
    document.addEventListener("workspace-ready", markWarnings);
  }

  function attach() {
    view.controls.prepend(view.mode);
    view.fileControl.after(view.yourControl, view.upload, view.newProgram);
    view.controls.after(view.renamed);
    view.controls.closest(".source-heading").after(view.warnings);
    view.sourceLines.after(view.drop, view.fileInput);
    view.summary.replaceWith(view.title);
    view.title.append(view.summary, view.chip);
    view.shell.append(view.card);
    for (const type of DRAG_EVENTS) view.sourcePanel.addEventListener(type, dragFile);
    render();
  }

  // Leave the source panel and the workspace exactly as the page has them without user programs. A user
  // program that is open, opening or compiling is closed, so Study never shows one; a compile that
  // finishes later is kept in Your file but not opened. Explore comes back on Curated examples.
  function detach() {
    // An edit in the editor is not kept on leaving Explore.
    if (editing) closeEditor();
    if (current || card) closeWorkspace();
    mode = "curated";
    current = null;
    card = null;
    clearInterval(ticking);
    ticking = null;
    view.title.replaceWith(view.summary);
    for (const element of [view.mode, view.yourControl, view.upload, view.newProgram, view.renamed, view.warnings, view.drop, view.fileInput, view.card]) {
      element.remove();
    }
    for (const line of view.sourceLines.querySelectorAll(".is-warning")) line.classList.remove("is-warning");
    for (const type of DRAG_EVENTS) view.sourcePanel.removeEventListener(type, dragFile);
    view.sourcePanel.classList.remove("is-drop-target");
    delete view.sourcePanel.dataset.mode;
    view.fileControl.hidden = false;
    view.shell.removeAttribute("aria-busy");
    view.sourceLines.inert = false;
    view.sourceLines.classList.remove("is-pending");
    setEmptyPrompt(EMPTY_PROMPTS.curated);
  }

  // The route as study.js reads it: Explore is "#/explore" or no hash.
  function followRoute() {
    const explore = (location.hash.slice(1) || "/explore") === "/explore";
    if (explore && !view.mode.isConnected) attach();
    else if (!explore && view.mode.isConnected) detach();
  }

  function render() {
    const yours = mode === "yours";
    const compiling = card?.kind === "compiling";
    // Nothing else can be opened while a program compiles, or while one is open in the editor.
    const locked = compiling || Boolean(editing);
    view.sourcePanel.dataset.mode = mode;
    for (const input of view.modes) {
      input.checked = input.value === mode;
      input.disabled = locked;
    }
    view.fileControl.hidden = yours;
    view.yourControl.hidden = view.upload.hidden = view.newProgram.hidden = !yours;
    const placeholder = new Option(uploads.length ? "Choose one of your files…" : "No files yet", "");
    placeholder.disabled = true;
    view.yourSelect.replaceChildren(placeholder, ...uploads.map(upload => new Option(listed(upload), upload.programId)));
    view.yourSelect.value = current?.programId || "";
    view.yourSelect.disabled = locked || !uploads.length;
    view.upload.disabled = view.choose.disabled = view.newProgram.disabled = view.write.disabled = locked;
    // Re-enabled by the workspace once a curated example or user program can be chosen again, or by
    // closeEditor.
    if (locked) elements.exampleSelect.disabled = true;
    view.shell.setAttribute("aria-busy", String(compiling));
    view.chip.hidden = !(yours && sourceState.data);
    const renamedFrom = card?.renamedFrom ?? current?.renamedFrom;
    view.renamed.hidden = !renamedFrom;
    view.renamed.textContent = renamedFrom ? `Renamed from “${renamedFrom}”.` : "";
    // The source of a program that is compiling, or that failed, is read-only. It is dimmed unless it
    // carries the compile errors to read.
    const errorLines = new Set(sourceDiagnostics().filter(diagnostic => diagnostic.severity.includes("error"))
      .map(diagnostic => diagnostic.line));
    view.sourceLines.inert = Boolean(card);
    view.sourceLines.classList.toggle("is-pending", Boolean(card) && !errorLines.size);
    for (const line of view.sourceLines.querySelectorAll(".source-line")) {
      line.classList.toggle("is-error", errorLines.has(Number(line.dataset.line)));
      line.classList.remove("is-outlined");
    }
    setEmptyPrompt(EMPTY_PROMPTS[mode]);
    renderWarnings();
    renderCard();
    renderEditor();
  }

  // The open upload's warnings, listed closed above the source lines and marked on them; none under a card.
  function renderWarnings() {
    const warnings = !card && current?.warnings || [];
    view.warnings.hidden = !warnings.length;
    if (warnings !== listedWarnings) {
      listedWarnings = warnings;
      const count = `${warnings.length} clang warning${warnings.length === 1 ? "" : "s"}`;
      view.warnings.open = false;
      view.warnings.replaceChildren(
        h("summary", {}, warnings.length >= MAX_WARNINGS ? `${count} · at most ${MAX_WARNINGS} are listed` : count),
        h("ul", { class: "program-diagnostics", "aria-label": "Clang warnings" }, ...warnings.map(diagnosticItem)));
    }
    markWarnings();
  }

  function markWarnings() {
    const lines = new Set(view.warnings.isConnected && !view.warnings.hidden
      ? listedWarnings.filter(inUpload).map(warning => warning.line) : []);
    for (const line of view.sourceLines.querySelectorAll(".source-line")) {
      line.classList.toggle("is-warning", lines.has(Number(line.dataset.line)));
    }
  }

  // Once `program` is open, add its warnings to the announcement that it is ready.
  function announceWarnings(program) {
    const count = program.warnings?.length;
    if (!count || appState.programId !== program.programId || !appState.ready) return;
    announce(`${elements.notice.textContent} Clang reported ${count} warning${count === 1 ? "" : "s"}, listed above the source.`);
  }

  // How Your files lists a program: a new one written in the editor says so.
  const listed = upload => upload.origin?.kind === "new" ? `${upload.fileName} · new` : upload.fileName;

  // The upload is the only file in the server's user-programs directory, whose path the server trims, so a
  // diagnostic against the upload names a bare file; one in a header keeps its path.
  const inUpload = diagnostic => !diagnostic.file.includes("/");

  // The failed compile's diagnostics against the upload, if any.
  function sourceDiagnostics() {
    return (card?.kind === "failed" && card.error.diagnostics || []).filter(inUpload);
  }

  function showSourceLine(number) {
    const line = view.sourceLines.querySelector(`.source-line[data-line="${number}"]`);
    for (const outlined of view.sourceLines.querySelectorAll(".is-outlined")) outlined.classList.remove("is-outlined");
    if (!line) return;
    line.classList.add("is-outlined");
    scrollWithin(view.sourceLines, line);
  }

  // The card for each state; failure kinds add their own content in failureContent.
  function renderCard() {
    clearInterval(ticking);
    ticking = null;
    view.card.hidden = !card;
    if (!card) {
      view.card.replaceChildren();
      return;
    }
    elements.workspace.hidden = true;
    elements.emptyState.hidden = true;
    if (card.kind === "compiling") {
      const { started, cancel } = card;
      // Whole seconds for sighted users only; the status was announced once when the compile started.
      const elapsed = h("span", { class: "program-elapsed", "aria-hidden": "true" });
      const tick = () => { elapsed.textContent = `${Math.floor((performance.now() - started) / 1000)} s`; };
      tick();
      ticking = setInterval(tick, 250);
      view.card.replaceChildren(
        h("h2", { id: "program-card-heading" }, `${card.forgotten ? "Recompiling" : "Compiling"} ${card.fileName} · `, elapsed),
        ...(card.forgotten ? [h("p", {}, FORGOTTEN)] : []),
        h("p", {}, WAIT),
        ...(cancel ? [h("div", { class: "program-actions" },
          h("button", { type: "button", onclick: () => cancel.abort() }, "Cancel"))] : []));
    } else if (card.kind === "cancelled") {
      const { fileName, renamedFrom, origin, source } = card;
      view.card.replaceChildren(
        h("h2", { id: "program-card-heading" }, "Compiling cancelled"),
        h("p", {}, `${fileName} was not compiled.`),
        // Compiled again under the name it was chosen as, so a renamed file still says so.
        programActions(() => compile(renamedFrom ?? fileName, source, origin)));
    } else {
      view.card.replaceChildren(...failureContent(card));
    }
  }

  function failureContent({ fileName, renamedFrom, origin, source, error }) {
    const refused = error.code === "invalid_program";
    return [
      h("h2", { id: "program-card-heading" }, `${fileName} could not be opened`),
      h("p", { class: "program-failure-message" }, error.message),
      ...(refused ? [h("p", {}, "Nothing was sent to the compiler.")] : []),
      ...(error.code === "compile_failed" ? compileFailure(error) : []),
      // A program irexplorer cannot show says why in its message; a parser failure adds the parser's own words.
      ...(error.parserMessage ? [h("details", { class: "program-parser-message" },
        h("summary", {}, "Parser message"), h("pre", {}, error.parserMessage))] : []),
      // Compiled again under the name it was chosen as, so a renamed file still says so.
      programActions(RETRYABLE.has(error.code) && (() => compile(renamedFrom ?? fileName, source, origin))),
    ];
  }

  // Try again, when `retry` is given, and Choose another file…: every way on from a card that opened nothing.
  function programActions(retry) {
    return h("div", { class: "program-actions" },
      ...(retry ? [h("button", { type: "button", class: "primary", onclick: retry }, "Try again")] : []),
      h("button", { type: "button", onclick: () => view.fileInput.click() }, "Choose another file…"));
  }

  // One diagnostic; one against the upload is a button that shows its line in the source.
  function diagnosticItem(diagnostic) {
    const { file, line, column, severity, message } = diagnostic;
    const text = inUpload(diagnostic) ? `Line ${line}, column ${column}: ${message}` : `${file}, line ${line}, column ${column}: ${message}`;
    return h("li", { "data-severity": severity }, h("span", { class: "program-diagnostic-severity" }, severity),
      inUpload(diagnostic) ? h("button", { type: "button", onclick: () => showSourceLine(line) }, text) : h("span", {}, text));
  }

  // Each diagnostic in order, then clang's full output.
  function compileFailure({ diagnostics, output }) {
    const items = diagnostics.map(diagnosticItem);
    return [
      ...(items.length ? [h("ul", { class: "program-diagnostics", "aria-label": "Compiler diagnostics" }, ...items)] : []),
      h("details", { class: "program-output" }, h("summary", {}, "Full compiler output"), h("pre", {}, output)),
    ];
  }

  function setMode(next) {
    mode = next;
    current = null;
    card = null;
    closeWorkspace();
    render();
    announce(mode === "yours" ? "Upload a C file, or choose one of your files." : "Choose a curated file to compare its recorded optimisation states.");
  }

  // Dropping a file onto the C source panel uploads it, in Your files and while nothing compiles. A file
  // dragged over the panel is never left to the browser, which would open it in place of the page.
  function dragFile(event) {
    if (!event.dataTransfer.types.includes("Files")) return;
    event.preventDefault();
    const accepted = mode === "yours" && card?.kind !== "compiling" && !editing;
    if (event.type === "dragleave" && view.sourcePanel.contains(event.relatedTarget)) return;
    view.sourcePanel.classList.toggle("is-drop-target", accepted && (event.type === "dragenter" || event.type === "dragover"));
    if (event.type !== "drop") {
      event.dataTransfer.dropEffect = accepted ? "copy" : "none";
      return;
    }
    const [file] = event.dataTransfer.files;
    if (accepted && file) uploadFile(file);
  }

  // The one way in for a file, however it arrives: read it, then compile it.
  async function uploadFile(file) {
    await compile(file.name, await AcceptedProgram.read(file));
  }

  // Check a file name and its text as the server will, then send the safe name and normalised source,
  // which the server accepts unchanged. `text` is null if the file is not UTF-8. `origin` is where the
  // program came from, as Your files keeps it.
  async function compile(fileName, text, origin = null) {
    if (card?.kind === "compiling") return;
    mode = "yours";
    current = null;
    closeWorkspace();
    const accepted = AcceptedProgram.accept(fileName, text);
    if (!accepted.ok) {
      const { reason, message } = accepted;
      showFailure({ fileName, renamedFrom: null, error: { code: "invalid_program", reason, message } },
        `Error: ${message} Nothing was sent to the compiler.`);
      return;
    }
    const renamedFrom = accepted.fileName === fileName ? null : fileName;
    sourceState.data = { file: accepted.fileName, text: accepted.source };
    renderSource();
    const compiling = { kind: "compiling", fileName: accepted.fileName, renamedFrom, origin, started: performance.now(),
      cancel: new AbortController() };
    card = compiling;
    render();
    announce(`Compiling ${accepted.fileName}.`);
    const result = await postProgram(accepted.fileName, accepted.source, compiling.cancel.signal);
    // Explore was left while it compiled (see detach): keep a compiled upload, but open nothing.
    if (card !== compiling) {
      if (result.ok) keep({ ...result.program, renamedFrom, origin });
      return;
    }
    // Cancel dropped the request, so the server stopped the compile; whatever the request came to is ignored.
    if (compiling.cancel.signal.aborted) {
      showCancelled({ fileName: accepted.fileName, renamedFrom, origin, source: accepted.source });
      return;
    }
    if (!result.ok) {
      showFailure({ fileName: accepted.fileName, renamedFrom, origin, source: accepted.source, error: result.error });
      return;
    }
    const program = { ...result.program, renamedFrom, origin };
    keep(program);
    current = program;
    await loadProgram(program);
    if (card !== compiling) return;
    card = null;
    render();
    announceWarnings(program);
  }

  // An upload of a program already held replaces it, so the name it was renamed from is the latest.
  function keep(program) {
    const held = uploads.findIndex(upload => upload.programId === program.programId);
    if (held < 0) uploads.push(program);
    else uploads[held] = program;
    keepUploads();
  }

  // POST /api/programs and wait for the compile: { ok: true, program } or { ok: false, error }. Aborting
  // `signal` closes the request, which the server takes as the end of the compile.
  async function postProgram(fileName, source, signal) {
    let response;
    try {
      response = await fetch("/api/programs", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ fileName, source }), signal,
      });
    } catch {
      return { ok: false, error: { code: "unreachable", message: "irexplorer could not be reached. Check that it is running." } };
    }
    const body = await response.json().catch(() => ({}));
    if (response.ok) {
      const warnings = Array.isArray(body.warnings) ? body.warnings : [];
      return { ok: true, program: { programId: body.programId, fileName: body.fileName, source, warnings } };
    }
    return { ok: false, error: { message: `The compile failed with status ${response.status}.`, ...body.error } };
  }

  // New… (or Write or paste a program): a new program, named program.c, starting from STARTER.
  function openEditor(event) {
    if (editing || card?.kind === "compiling") return;
    editing = { title: "New program", origin: { kind: "new" }, start: STARTER, opener: event.currentTarget,
      exampleSelectDisabled: elements.exampleSelect.disabled, confirming: false };
    view.editorName.value = "program.c";
    view.editor.load(STARTER);
    render();
    view.editor.focus();
    announce("New program. Write or paste C, then compile it.");
  }

  // The editor's part of the page: the section that stands in for the panels, and the source panel beside it,
  // which shows nothing for a new program, as nothing is compiled yet (see style.css).
  function renderEditor() {
    if (!editing) {
      view.editorSection.remove();
      delete view.sourcePanel.dataset.editing;
      return;
    }
    view.sourcePanel.dataset.editing = editing.origin.kind;
    if (editing.origin.kind === "new") view.summary.textContent = "C source";
    if (!view.editorSection.isConnected) view.shell.append(view.editorSection);
    view.editorHeading.textContent = editing.title;
    view.editorDiscard.textContent = edited() ? "Discard edits" : "Close editor";
    view.editorConfirmation.hidden = !editing.confirming;
  }

  const edited = () => view.editor.text !== editing.start;

  // Back to whatever the editor stood in for, unchanged.
  function closeEditor() {
    elements.exampleSelect.disabled = editing.exampleSelectDisabled;
    editing = null;
    view.summary.textContent = sourceSummary();
    render();
  }

  // Closing an edit asks first, in the page, as the edit would be lost.
  function discardEditor() {
    if (!edited()) {
      leaveEditor();
      return;
    }
    const keep = h("button", { type: "button", onclick: () => {
      editing.confirming = false;
      renderEditor();
      view.editor.focus();
    } }, "Keep editing");
    view.editorConfirmation.replaceChildren(
      h("p", {}, h("strong", {}, `Discard your edits to ${view.editorName.value.trim() || "this program"}?`), " They have not been compiled."),
      h("div", { class: "program-actions" }, keep, h("button", { type: "button", class: "destructive", onclick: leaveEditor }, "Discard edits")));
    editing.confirming = true;
    renderEditor();
    keep.focus();
  }

  function leaveEditor() {
    const { opener } = editing;
    closeEditor();
    // The button that opened the editor, or New… if that one has gone with the drop zone.
    (opener?.checkVisibility() ? opener : view.newProgram).focus();
    announce("Editor closed.");
  }

  // Compile and Ctrl/⌘+Enter: the editor closes and the program compiles as an upload does.
  function compileEditor() {
    if (!editing) return;
    const { origin } = editing;
    const fileName = view.editorName.value.trim(), text = view.editor.text;
    const focused = view.editorSection.contains(document.activeElement);
    closeEditor();
    compile(fileName, text, origin);
    // The card is up at once; keep the keyboard in it (on Cancel, or the first way on from a refusal).
    if (focused) view.card.querySelector("button")?.focus();
  }

  // A held upload opens at once: its kept source shows while the views load, and nothing is compiled.
  async function openUpload(programId) {
    const upload = uploads.find(item => item.programId === programId);
    if (!upload) return;
    current = upload;
    card = null;
    const opened = loadProgram(upload);
    render();
    await opened;
    if (current === upload) announceWarnings(upload);
  }

  // A program the server has forgotten (it restarted, or dropped the program from its store) is compiled
  // again from the source this tab kept. Parallel requests that find it gone share one recompile.
  const recompiles = new Map();
  function recompileForgotten(programId) {
    const upload = uploads.find(item => item.programId === programId);
    if (!upload) return Promise.resolve(false);
    if (!recompiles.has(programId)) recompiles.set(programId, recompile(upload).finally(() => recompiles.delete(programId)));
    return recompiles.get(programId);
  }

  // Resolves true once the server holds the program again. The card stands in for whatever was on
  // screen until then; on a failure the program is closed and the card says why.
  async function recompile(upload) {
    const { fileName, renamedFrom = null, origin = null, source } = upload;
    const workspaceHidden = elements.workspace.hidden, emptyStateHidden = elements.emptyState.hidden;
    const recompiling = { kind: "compiling", fileName, started: performance.now(), forgotten: true,
      cancel: new AbortController() };
    card = recompiling;
    render();
    announce(`Recompiling ${fileName}. The server no longer had it.`);
    const result = await postProgram(fileName, source, recompiling.cancel.signal);
    // Explore was left while it compiled (see detach), which closed the program: show nothing again.
    if (card !== recompiling) return false;
    if (result.ok && !recompiling.cancel.signal.aborted) {
      card = null;
      render();
      elements.workspace.hidden = workspaceHidden;
      elements.emptyState.hidden = emptyStateHidden;
      return true;
    }
    // Cancelled or failed: the program closes, its kept source stays, and the upload stays in Your file.
    current = null;
    closeWorkspace();
    sourceState.data = { file: fileName, text: source };
    renderSource();
    if (recompiling.cancel.signal.aborted) showCancelled({ fileName, renamedFrom, origin, source });
    else showFailure({ fileName, origin, source, error: result.error });
    return false;
  }

  // The failed card for a program that was refused or did not compile, and its error announced.
  function showFailure(failed, announcement = `Error: ${failed.error.message}`) {
    card = { kind: "failed", ...failed };
    render();
    announce(announcement, "error");
  }

  // The cancelled card, after Cancel on a compile or a recompile.
  function showCancelled(cancelled) {
    const cancelling = view.card.contains(document.activeElement);
    card = { kind: "cancelled", ...cancelled };
    render();
    announce(`Compiling ${cancelled.fileName} cancelled.`);
    // Cancel has gone with the compile card; Try again stands where it was.
    if (cancelling) view.card.querySelector("button").focus();
  }

  fetch("/api/release", { cache: "no-store" }).then(response => response.ok ? response.json() : null).then(release => {
    if (release?.config?.userPrograms !== true) return;
    build();
    followRoute();
  }).catch(() => {});
  // Added now, before study.js adds its own (scripts run in order), so on leaving Explore a user program
  // is closed before a Study task prepares its workspace.
  window.addEventListener("hashchange", () => { if (view.mode) followRoute(); });
})();
