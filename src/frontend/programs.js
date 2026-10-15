// User programs in Explore (ADR 0005): the Curated examples | Your files switch, uploading a C file, the
// editor for writing a new program or editing the one open (editor.js), and the card that stands in for the
// panels and the comparison while a user program compiles or after it fails. Nothing here is built unless
// /api/release reports the user programs setting on, and nothing here exists in Study (#/study…), which
// shares the workspace: the controls are added on entering Explore and removed on leaving it.
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
  // What the source panel says, beside the editor, of the compiled source it shows.
  const SOURCE_NOTE = "This is the source that was compiled, as the panels show it.";
  const EMPTY_PROMPTS = {
    curated: "Choose a curated file to start comparing.",
    yours: "Upload a C file, or choose one of your files, to start comparing.",
  };

  // The server lists at most this many of clang's warnings on a program that compiled, and does not say
  // whether there were more, so a full list is described as at least this many.
  const MAX_WARNINGS = 20;

  // This tab's uploads, oldest first: { programId, fileName, source, renamedFrom, origin, warnings }, with the
  // safe name and the normalised source that were sent, the name as chosen if it was not safe (else null),
  // where the program came from, and clang's warnings as the server listed them. origin is null for an
  // uploaded file; a compiled edit keeps where its first edit started, however many compiled edits ago:
  // { kind: "curated", exampleId, source } (Edit a copy), { kind: "upload", fileName, source } (Edit on an
  // uploaded file; source is the text first uploaded) or { kind: "new" } (New…). A failed upload is never
  // kept. They survive a reload in this tab (session storage), not across tabs.
  const UPLOADS_KEY = "irexplorer.programs.uploads";
  const uploads = readUploads();
  // After a reload nothing reopens by itself, but a tab with uploads opens in Your files.
  let mode = uploads.length ? "yours" : "curated";
  // The user program on screen or being opened, if any.
  let current = null;
  // What the card shows in place of the panels: null (no card), { kind: "compiling", fileName, renamedFrom,
  // request, started, cancel, forgotten } (cancel: the POST's AbortController, which Cancel aborts;
  // forgotten: recompiling a program the server no longer had), { kind: "cancelled", fileName, renamedFrom,
  // request } or { kind: "failed", fileName, renamedFrom, request, error }, where fileName is the safe name,
  // renamedFrom the name as chosen if that was not safe, request the compile request (see compile), which Try
  // again sends again, and error the server's { code, message, … }. A file the browser refuses before sending
  // fails with the server's invalid_program error.
  let card = null;
  let ticking = null;
  // The program open in the editor, if any: { title, origin, replaces, compiled, workspace, opened, opener,
  // exampleSelectDisabled, confirming, reopened, behind }. replaces is the programId of the Your files entry
  // a compile replaces (Edit), or null when it adds one (Edit a copy, New…). compiled is true when it opened
  // on the program on screen (Edit a copy or Edit), whose compiled source the source panel keeps showing
  // beside it, and the margin marks changes against, and false for a new program; workspace is the panels
  // and function on screen, for the compiled edit to open with (app.js currentWorkspace), or null; opened is
  // what was open behind the editor ({ exampleId } or { programId }), or null. opener is the button that
  // opened it, which gets focus back when it closes. While it is open the editor stands in for the panels
  // and the comparison (which stay as they were behind it), and the file controls are disabled. reopened is
  // true for an Uncompiled edit picked up again after a reload, when nothing is open behind it (reopenEdit).
  // While the edit compiles, and when it fails for another reason than a compile error, the card stands in
  // for the editor in turn, and `behind` is what the source panel and the workspace showed beside the
  // editor, for the editor to come back to (see uncover).
  let editing = null;
  // The Uncompiled edit, kept in session storage beside the uploads while the editor is open, so that a
  // reload in this tab picks it up again (another tab, or a later visit, starts clean): { mode, title, origin,
  // replaces, opened, workspace, fileName, text, start, compiled }, where text is the editor's text, start
  // what the edit started as and compiled the compiled source the source panel shows beside it ({ file,
  // text }, null for a new program). Compiling or discarding removes it. Leaving Explore keeps it, for the
  // editor to reopen on coming back.
  const EDIT_KEY = "irexplorer.programs.uncompiled-edit";
  // The one kept when this page loaded, or when Explore was left, which the editor reopens on entering Explore.
  let keptEdit = readEdit();
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

  function readEdit() {
    try {
      const edit = JSON.parse(sessionStorage.getItem(EDIT_KEY) || "null");
      const complete = ["title", "fileName", "text", "start"].every(key => typeof edit?.[key] === "string")
        && ["curated", "yours"].includes(edit.mode) && typeof edit.origin?.kind === "string";
      return complete ? edit : null;
    } catch {
      return null;
    }
  }

  function keepEdit() {
    const { title, origin, replaces, opened, workspace, compiled } = editing;
    const source = compiled && sourceState.data ? { file: sourceState.data.file, text: sourceState.data.text } : null;
    const edit = { mode, title, origin, replaces, opened, workspace, fileName: view.editorName.value, text: view.editor.text,
      start: view.editor.start, compiled: source };
    try { sessionStorage.setItem(EDIT_KEY, JSON.stringify(edit)); } catch { /* kept until this page closes */ }
  }

  function forgetEdit() {
    try { sessionStorage.removeItem(EDIT_KEY); } catch { /* nothing was kept */ }
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
    view.newProgram = h("button", { id: "program-new", type: "button", onclick: openNew }, "New…");
    // Edit a copy of the curated example open, or Edit the user program open: under the source controls.
    view.edit = h("button", { id: "program-edit", type: "button", onclick: openEdit });
    view.sourceNote = h("p", { id: "program-source-note", class: "program-source-note" }, SOURCE_NOTE);
    view.renamed = h("p", { id: "program-renamed", class: "program-renamed" });
    // Where the compiled edit open came from, with a way back to it: under Edit, in the source controls.
    view.originName = h("span");
    view.openOriginal = h("button", { type: "button", class: "program-link", onclick: openOriginal }, "Open the original");
    view.origin = h("p", { id: "program-origin", class: "program-origin" }, "Edited from ", view.originName, ". ", view.openOriginal);
    view.fileInput = h("input", { id: "program-file-input", type: "file", accept: ".c", hidden: true, onchange: () => {
      const [file] = view.fileInput.files;
      view.fileInput.value = "";
      if (file) uploadFile(file);
    } });
    view.choose = h("button", { type: "button", class: "primary", onclick: () => view.fileInput.click() }, "Choose a file…");
    view.write = h("button", { type: "button", onclick: openNew }, "Write or paste a program");
    // Stands in for the source prompt while Your files is selected (see style.css).
    view.drop = h("div", { id: "program-drop", class: "program-drop" },
      h("p", { class: "program-drop-title" }, "Drop a .c file here"),
      h("p", {}, LIMITS), h("div", { class: "program-actions" }, view.choose, view.write));
    // In the page only while a program is open in it (see renderEditor and style.css).
    view.editor = ProgramEditor.create({ label: "C source", onInput: renderEditor, onSubmit: compileEditor });
    view.editorHeading = h("h2", { id: "program-editor-heading" });
    view.editorName = h("input", { id: "program-editor-name", type: "text", spellcheck: "false", autocomplete: "off", oninput: keepEdit });
    view.editorDiscard = h("button", { id: "program-editor-discard", type: "button", onclick: discardEditor });
    view.editorRestore = h("button", { id: "program-editor-restore", type: "button", onclick: restoreOriginal }, "Restore original");
    view.editorConfirmation = h("div", { class: "program-editor-confirmation", role: "alert" });
    // Why the edit's last compile failed, above the editor (see reopenEditor).
    view.editorDiagnostics = h("div", { id: "program-editor-diagnostics", class: "program-editor-diagnostics" });
    view.editorSection = h("section", { id: "program-editor", class: "panel program-editor", "aria-labelledby": "program-editor-heading" },
      h("header", { class: "program-editor-heading" }, view.editorHeading,
        h("div", { class: "program-editor-controls" },
          h("label", { for: "program-editor-name" }, "File name", view.editorName),
          h("div", { class: "program-actions" },
            h("button", { id: "program-editor-compile", type: "button", class: "primary", onclick: compileEditor }, "Compile"),
            view.editorRestore, view.editorDiscard))),
      view.editorConfirmation, view.editorDiagnostics, view.editor.element);
    view.chip = h("span", { id: "program-chip", class: "program-chip" }, "Your file");
    view.title = h("div", { class: "source-title" });
    view.card = h("section", { id: "program-card", class: "panel program-card", "aria-labelledby": "program-card-heading" });
    // clang's warnings on the open upload, collapsed, between the source heading and the source lines.
    view.warnings = h("details", { id: "program-warnings", class: "program-warnings" });
    recompileForgottenProgram = recompileForgotten;
    // The workspace draws the source lines again once a program has loaded, so their marks are put back.
    document.addEventListener("workspace-ready", markWarnings);
    // Edit a copy and Edit follow what the workspace has open (see renderEdit).
    document.addEventListener("workspace-ready", renderEdit);
    elements.exampleSelect.addEventListener("change", renderEdit);
  }

  function attach() {
    view.controls.prepend(view.mode);
    view.fileControl.after(view.yourControl, view.upload, view.newProgram);
    view.controls.append(view.edit, view.origin);
    view.controls.after(view.renamed);
    view.controls.closest(".source-heading").after(view.warnings);
    view.sourceLines.after(view.drop, view.fileInput);
    view.summary.replaceWith(view.title);
    view.title.append(view.summary, view.chip);
    view.shell.append(view.card);
    for (const type of DRAG_EVENTS) view.sourcePanel.addEventListener(type, dragFile);
    if (keptEdit) reopenEdit(keptEdit);
    keptEdit = null;
    render();
  }

  // Leave the source panel and the workspace exactly as the page has them without user programs. A user
  // program that is open, opening or compiling is closed, so Study never shows one; a compile that
  // finishes later is kept in Your file but not opened. Explore comes back on Curated examples, or on the
  // Uncompiled edit that was in the editor, which is kept as it is through a reload.
  function detach() {
    if (editing) {
      keptEdit = readEdit();
      removeEditor();
    }
    if (current || card) closeWorkspace();
    mode = "curated";
    current = null;
    card = null;
    clearInterval(ticking);
    ticking = null;
    view.title.replaceWith(view.summary);
    for (const element of [view.mode, view.yourControl, view.upload, view.newProgram, view.edit, view.renamed, view.origin, view.warnings, view.drop, view.fileInput, view.card]) {
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
    const origin = !card && current?.origin?.kind !== "new" && current?.origin;
    view.origin.hidden = !origin;
    view.originName.textContent = !origin ? ""
      : origin.kind === "curated" ? `curated ${exampleName(origin.exampleId)}` : `your upload ${origin.fileName}`;
    view.openOriginal.disabled = locked;
    // The source of a program that is compiling, or that failed, is read-only. It is dimmed unless it
    // carries the compile errors to read.
    const errorLines = new Set(sourceDiagnostics().filter(diagnostic => diagnostic.severity.includes("error"))
      .map(diagnostic => diagnostic.line));
    view.sourceLines.inert = Boolean(card);
    view.sourceLines.classList.toggle("is-pending", Boolean(card) && !errorLines.size);
    for (const line of view.sourceLines.querySelectorAll(".source-line")) {
      line.classList.toggle("is-error", errorLines.has(Number(line.dataset.line)));
      line.classList.remove("is-outlined");
      // Beside the editor the compiled source is only to read: a line selects nothing in the hidden panels.
      line.disabled = Boolean(editing);
    }
    setEmptyPrompt(EMPTY_PROMPTS[mode]);
    renderWarnings();
    renderCard();
    renderEditor();
    renderEdit();
  }

  // Edit a copy while a curated example is open, Edit while one of your files is; disabled while the editor
  // is open.
  function renderEdit() {
    const open = appState.ready && !card && (mode === "yours" ? Boolean(current) : Boolean(appState.exampleId));
    view.edit.hidden = !open;
    view.edit.textContent = mode === "yours" ? "Edit" : "Edit a copy";
    view.edit.disabled = Boolean(editing);
  }

  // The open upload's warnings, listed closed above the source lines and marked on them; none under a card.
  function renderWarnings() {
    const warnings = !card && current?.warnings || [];
    view.warnings.hidden = !warnings.length;
    if (warnings !== listedWarnings) {
      listedWarnings = warnings;
      view.warnings.open = false;
      view.warnings.replaceChildren(
        h("summary", {}, warnings.length >= MAX_WARNINGS
          ? `At least ${MAX_WARNINGS} clang warnings · the first ${MAX_WARNINGS} are listed`
          : `${warnings.length} clang warning${warnings.length === 1 ? "" : "s"}`),
        h("ul", { class: "program-diagnostics", "aria-label": "Clang warnings" }, ...warnings.map(warning => diagnosticItem(warning))));
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
    announce(`${elements.notice.textContent} ${count >= MAX_WARNINGS
      ? `Clang reported at least ${MAX_WARNINGS} warnings; the first ${MAX_WARNINGS} are listed above the source.`
      : `Clang reported ${count} warning${count === 1 ? "" : "s"}, listed above the source.`}`);
  }

  // How Your files lists a program: a compiled edit says it is edited, or new if written in the editor.
  const listed = upload => (upload.origin ? `${upload.fileName} · ${upload.origin.kind === "new" ? "new" : "edited"}` : upload.fileName);
  const exampleName = exampleId => exampleId.replaceAll("_", " ");

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
      view.card.replaceChildren(
        h("h2", { id: "program-card-heading" }, "Compiling cancelled"),
        h("p", {}, `${card.fileName} was not compiled.`),
        programActions(card));
    } else {
      view.card.replaceChildren(...failureContent(card));
    }
  }

  function failureContent(failed) {
    const { fileName, error } = failed;
    const refused = error.code === "invalid_program";
    return [
      h("h2", { id: "program-card-heading" }, `${fileName} could not be opened`),
      h("p", { class: "program-failure-message" }, error.message),
      ...(refused ? [h("p", {}, "Nothing was sent to the compiler.")] : []),
      ...(error.code === "compile_failed" ? compileFailure(error) : []),
      // A program irexplorer cannot show says why in its message; a parser failure adds the parser's own words.
      ...(error.parserMessage ? [h("details", { class: "program-parser-message" },
        h("summary", {}, "Parser message"), h("pre", {}, error.parserMessage))] : []),
      programActions(failed),
    ];
  }

  // Every way on from a card that opened nothing: Try again after Cancel or a failure the compiler caused
  // (sending the same request, so a renamed file still says so), and Choose another file…. A card for an
  // edit leads with Back to editing.
  function programActions({ kind, request, error }) {
    const { edit } = request;
    const retry = kind === "cancelled" || RETRYABLE.has(error.code);
    return h("div", { class: "program-actions" },
      ...(edit ? [h("button", { type: "button", class: "primary", onclick: backToEditing }, "Back to editing")] : []),
      ...(retry ? [h("button", { type: "button", class: edit ? null : "primary", onclick: () => compile(request) }, "Try again")] : []),
      h("button", { type: "button", onclick: () => view.fileInput.click() }, "Choose another file…"));
  }

  // One diagnostic; one against the upload is a button that shows its line (in the source, unless `show`
  // shows it elsewhere).
  function diagnosticItem(diagnostic, show = showSourceLine) {
    const { line, column, severity } = diagnostic;
    const text = diagnosticText(diagnostic);
    return h("li", { "data-severity": severity }, h("span", { class: "program-diagnostic-severity" }, severity),
      inUpload(diagnostic) ? h("button", { type: "button", onclick: () => show(line, column) }, text) : h("span", {}, text));
  }

  function diagnosticText({ file, line, column, message }) {
    return `${inUpload({ file }) ? "Line" : `${file}, line`} ${line}, column ${column}: ${message}`;
  }

  // Each diagnostic in order, then clang's full output.
  function compileFailure({ diagnostics, output }, show = showSourceLine) {
    const items = diagnostics.map(diagnostic => diagnosticItem(diagnostic, show));
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
    await compile({ fileName: file.name, text: await AcceptedProgram.read(file) });
  }

  // Compile a request { fileName, text, origin, workspace, replaces, edit }, of which only the file name
  // and text, as chosen, are needed: check them as the server will, then send the safe name and normalised
  // source, which the server accepts unchanged. `text` is null if the file is not UTF-8. `origin` is where the
  // program came from, as Your files keeps it. `workspace` (app.js currentWorkspace), if given, is the
  // panels and function the compiled program opens with. `replaces`, if given, is the programId of the Your
  // files entry the compiled program takes the place of. A file replaces whatever was open at once, an edit
  // the editor left open included. `edit` compiles the edit open in the editor instead (see compileEditor):
  // what it started from stays open, behind the card, until it compiles, and a compile error takes it back
  // to the editor.
  async function compile(request) {
    const { fileName, text, origin = null, workspace = null, replaces = null, edit = false } = request;
    if (card?.kind === "compiling") return;
    if (!edit) {
      if (editing) closeEditor();
      mode = "yours";
      current = null;
      closeWorkspace();
    }
    const accepted = AcceptedProgram.accept(fileName, text);
    if (!accepted.ok) {
      const { reason, message } = accepted;
      showFailure({ fileName, renamedFrom: null, request, error: { code: "invalid_program", reason, message } },
        `Error: ${message} Nothing was sent to the compiler.`);
      return;
    }
    const renamedFrom = accepted.fileName === fileName ? null : fileName;
    sourceState.data = { file: accepted.fileName, text: accepted.source };
    renderSource();
    const compiling = { kind: "compiling", fileName: accepted.fileName, renamedFrom, request, started: performance.now(),
      cancel: new AbortController() };
    card = compiling;
    render();
    announce(`Compiling ${accepted.fileName}.`);
    const result = await postProgram(accepted.fileName, accepted.source, compiling.cancel.signal);
    // Explore was left while it compiled (see detach): keep a compiled upload, but open nothing. An edit
    // that compiled is no longer an Uncompiled edit, unless the editor has been opened on it again since.
    if (card !== compiling) {
      if (result.ok) keep({ ...result.program, renamedFrom, origin }, replaces);
      if (result.ok && edit && !editing) {
        keptEdit = null;
        forgetEdit();
      }
      return;
    }
    // Cancel dropped the request, so the server stopped the compile; whatever the request came to is ignored.
    if (compiling.cancel.signal.aborted) {
      showCancelled({ fileName: accepted.fileName, renamedFrom, request });
      return;
    }
    if (!result.ok && edit && result.error.code === "compile_failed") {
      reopenEditor(result.error);
      return;
    }
    if (!result.ok) {
      showFailure({ fileName: accepted.fileName, renamedFrom, request, error: result.error });
      return;
    }
    if (edit) {
      // The edit compiled: what it started from closes, and the edit opens in its place.
      mode = "yours";
      current = null;
      closeWorkspace();
      sourceState.data = { file: accepted.fileName, text: accepted.source };
      renderSource();
      closeEditor();
    }
    const program = { ...result.program, renamedFrom, origin };
    keep(program, replaces);
    current = program;
    await loadProgram(program, workspace);
    if (card !== compiling) return;
    card = null;
    render();
    announceWarnings(program);
  }

  // A compiled edit from Edit takes the place of the entry it started from (`replaces`); anything else is
  // added at the end. An upload of a program already held replaces it, so the name it was renamed from is
  // the latest, and a program is never listed twice.
  function keep(program, replaces = null) {
    const held = uploads.findIndex(upload => upload.programId === program.programId);
    const replaced = replaces === null ? -1 : uploads.findIndex(upload => upload.programId === replaces);
    if (replaced >= 0) {
      uploads[replaced] = program;
      if (held >= 0 && held !== replaced) uploads.splice(held, 1);
    } else if (held < 0) uploads.push(program);
    else uploads[held] = program;
    keepUploads();
  }

  // `fileName`, or, when Your files already lists that name (bar the entry being replaced), the first of
  // "name (2).c", "name (3).c", … that it does not. The list holds safe names, so names are compared as the
  // compiler would see them.
  function unusedName(fileName, replaces) {
    const taken = new Set(uploads.filter(upload => upload.programId !== replaces).map(upload => upload.fileName));
    const [, stem, extension] = /^([\s\S]*)(\.[cC])$/.exec(fileName) ?? [];
    if (!stem || !taken.has(AcceptedProgram.safeFileName(fileName))) return fileName;
    let number = 2;
    while (taken.has(AcceptedProgram.safeFileName(`${stem} (${number})${extension}`))) number += 1;
    return `${stem} (${number})${extension}`;
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
  function openNew(event) {
    openEditor({ title: "New program", origin: { kind: "new" }, replaces: null, fileName: "program.c", text: STARTER, compiled: false },
      event.currentTarget, "New program. Write or paste C, then compile it.");
  }

  // Edit a copy of the curated example open, named after its file, or Edit the user program open.
  function openEdit(event) {
    if (!appState.ready) return;
    const { file, text } = sourceState.data;
    // An edit of one of your files replaces its entry, and keeps the entry's origin, or the file as uploaded
    // if it is not an edit itself; a copy of a curated example is added.
    const program = mode === "yours"
      ? { title: `Editing ${current.fileName}`, replaces: current.programId,
        origin: current.origin ?? { kind: "upload", fileName: current.fileName, source: current.source } }
      : { title: `Editing a copy of curated ${exampleName(appState.exampleId)}`, replaces: null,
        origin: { kind: "curated", exampleId: appState.exampleId, source: text } };
    openEditor({ ...program, fileName: file, text, compiled: true }, event.currentTarget, `${program.title}. Change the C, then compile it.`);
  }

  // Open the editor on `text` under `fileName`. Over a program on screen, the compiled edit opens with its
  // panels and function.
  function openEditor({ title, origin, replaces, fileName, text, compiled }, opener, announcement) {
    if (editing || card?.kind === "compiling") return;
    const { ready, exampleId, programId } = appState;
    editing = { title, origin, replaces, compiled, workspace: ready ? currentWorkspace() : null,
      opened: !ready ? null : exampleId ? { exampleId } : { programId }, opener,
      exampleSelectDisabled: elements.exampleSelect.disabled, confirming: false, reopened: false, behind: null };
    view.editorName.value = fileName;
    view.editor.load(text, { compiled: compiled ? text : null });
    view.editorDiagnostics.replaceChildren();
    render();
    view.editor.focus();
    announce(announcement);
  }

  // The editor's part of the page: the section that stands in for the panels, and the source panel beside it,
  // which shows the compiled source the edit started from, with a note saying so, or nothing for a new
  // program, as nothing is compiled yet (see style.css). While the edit compiles, or its card says why it did
  // not, the card stands in for the editor instead, and the source panel shows the edit as it shows an upload.
  function renderEditor() {
    if (!editing || card) {
      view.editorSection.remove();
      view.sourceNote.remove();
      delete view.sourcePanel.dataset.editing;
      return;
    }
    view.sourcePanel.dataset.editing = editing.compiled ? "compiled" : "new";
    if (editing.compiled) view.sourceLines.before(view.sourceNote);
    else view.summary.textContent = "C source";
    if (!view.editorSection.isConnected) view.shell.append(view.editorSection);
    view.editorHeading.textContent = editing.title;
    view.editorDiscard.textContent = view.editor.edited ? "Discard edits" : "Close editor";
    // A new program has no original to go back to.
    view.editorRestore.hidden = editing.origin.kind === "new";
    view.editorRestore.disabled = view.editor.text === editing.origin.source;
    view.editorConfirmation.hidden = !editing.confirming;
    view.editorDiagnostics.hidden = !view.editorDiagnostics.childElementCount;
    keepEdit();
  }

  // After a reload, or on coming back to Explore, open the Uncompiled edit `kept` in the editor as it was,
  // beside the compiled source kept with it, with the source mode and file it was started from chosen and
  // locked. Nothing is asked of the server, which may have forgotten the program the edit started from; what
  // was open behind the editor opens again only if the editor closes without compiling (see leaveEditor).
  function reopenEdit({ mode: kind, title, origin, replaces = null, opened = null, workspace = null, fileName, text, start, compiled = null }) {
    // Whatever Study left open is not what the edit started from.
    closeWorkspace();
    mode = kind;
    current = uploads.find(upload => upload.programId === opened?.programId) ?? null;
    if (opened?.exampleId) elements.exampleSelect.value = opened.exampleId;
    sourceState.data = compiled;
    renderSource();
    editing = { title, origin, replaces, compiled: Boolean(compiled), workspace, opened, opener: null,
      exampleSelectDisabled: false, confirming: false, reopened: true, behind: null };
    view.editorName.value = fileName;
    view.editor.load(text, { compiled: compiled?.text ?? null, start });
    announce(`${title}: your uncompiled edit was kept.`);
  }

  // Back to whatever the editor stood in for, unchanged, with the Uncompiled edit gone.
  function closeEditor() {
    forgetEdit();
    removeEditor();
  }

  // Take the editor out of the page, keeping the Uncompiled edit (see detach).
  function removeEditor() {
    elements.exampleSelect.disabled = editing.exampleSelectDisabled;
    editing = null;
    view.summary.textContent = sourceSummary();
    render();
  }

  // Closing an edit asks first, in the page, as the edit would be lost.
  function discardEditor() {
    if (!view.editor.edited) {
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

  // Restore original: the curated example's text, or the text first uploaded, as one edit that the
  // browser's undo reverses.
  function restoreOriginal() {
    view.editor.replaceText(editing.origin.source);
    announce(`Restored the original ${editing.origin.kind === "curated" ? "curated example" : "upload"}. Ctrl/⌘+Z (undo) reverses it.`);
  }

  // Open the original: the curated example under Curated examples, or the first upload, opened from Your
  // files if it is still listed there as an upload, else compiled again from the text kept.
  async function openOriginal() {
    const { origin } = current;
    // The button goes with the line, so the keyboard is put on the select the original is chosen in.
    let select = view.yourSelect;
    if (origin.kind === "curated") {
      setMode("curated");
      elements.exampleSelect.value = origin.exampleId;
      const opened = loadExample();
      renderEdit();
      await opened;
      select = elements.exampleSelect;
    } else {
      const uploaded = uploads.find(upload => !upload.origin && upload.source === origin.source);
      if (uploaded) await openUpload(uploaded.programId);
      else await compile({ fileName: origin.fileName, text: origin.source });
    }
    if (select.checkVisibility() && !select.disabled) select.focus();
  }

  async function leaveEditor() {
    const { opener, opened, workspace, reopened } = editing;
    closeEditor();
    announce("Editor closed.");
    // After a reload nothing was open behind the editor: what was open when the edit started opens again.
    if (reopened && opened?.exampleId) {
      elements.exampleSelect.value = opened.exampleId;
      await loadExample(workspace);
    } else if (reopened && opened?.programId) {
      await openUpload(opened.programId, workspace);
    }
    // The button that opened the editor, else Edit (or Edit a copy) on what opened again, else New….
    (opener?.checkVisibility() ? opener : view.edit.checkVisibility() ? view.edit : view.newProgram).focus();
  }

  // Compile and Ctrl/⌘+Enter: the card stands in for the editor and the edit compiles as an upload does,
  // but the program it started from stays open behind them until it has compiled.
  function compileEditor() {
    if (!editing || card) return;
    const { origin, workspace, replaces } = editing;
    const fileName = unusedName(view.editorName.value.trim(), replaces), text = view.editor.text;
    const focused = view.editorSection.contains(document.activeElement);
    editing.behind = { source: sourceState.data, workspaceHidden: elements.workspace.hidden, emptyStateHidden: elements.emptyState.hidden };
    view.editorDiagnostics.replaceChildren();
    view.editor.markErrors([]);
    compile({ fileName, text, origin, workspace, replaces, edit: true });
    // The card is up at once; keep the keyboard in it (on Cancel, or the first way on from a refusal).
    if (focused) view.card.querySelector("button")?.focus();
  }

  // Put back what the card stood in for while the edit compiled: the source panel and the workspace as they
  // were beside the editor, which then comes back.
  function uncover() {
    const { source, workspaceHidden, emptyStateHidden } = editing.behind;
    card = null;
    sourceState.data = source;
    renderSource();
    if (appState.ready) applySourceHighlights();
    elements.workspace.hidden = workspaceHidden;
    elements.emptyState.hidden = emptyStateHidden;
  }

  // A compile error in the edit: the editor comes back with the edit as it was, its failing lines marked and
  // clang's diagnostics listed above it, each going to its line. The announcement reads them all.
  function reopenEditor(error) {
    uncover();
    view.editorDiagnostics.replaceChildren(h("p", { class: "program-failure-message" }, error.message),
      ...compileFailure(error, (line, column) => view.editor.showLine(line, column)));
    render();
    const lines = (error.diagnostics || []).filter(diagnostic => inUpload(diagnostic) && diagnostic.severity.includes("error"))
      .map(diagnostic => diagnostic.line);
    view.editor.markErrors(lines);
    if (lines.length) view.editor.showLine(lines[0]);
    else view.editor.focus();
    const diagnostics = (error.diagnostics || []).map(diagnostic => `${diagnostic.severity}: ${diagnosticText(diagnostic)}`);
    announce(`Error: ${error.message} ${diagnostics.length
      ? `Clang's diagnostics, listed above the editor: ${diagnostics.join(" ")}` : "Clang's output is above the editor."}`);
  }

  // Back to editing, from the card of an edit that did not compile: the edit, unchanged.
  function backToEditing() {
    uncover();
    render();
    view.editor.focus();
    announce(`Back to editing ${view.editorName.value.trim() || "the program"}.`);
  }

  // A held upload opens at once: its kept source shows while the views load, and nothing is compiled.
  // `workspace` (app.js currentWorkspace), if given, is the panels and function it opens with.
  async function openUpload(programId, workspace = null) {
    const upload = uploads.find(item => item.programId === programId);
    if (!upload) return;
    current = upload;
    card = null;
    const opened = loadProgram(upload, workspace);
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
    // What Try again compiles: the upload, under the name it was chosen as.
    const request = { fileName: renamedFrom ?? fileName, text: source, origin };
    const workspaceHidden = elements.workspace.hidden, emptyStateHidden = elements.emptyState.hidden;
    const recompiling = { kind: "compiling", fileName, request, started: performance.now(), forgotten: true,
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
    if (recompiling.cancel.signal.aborted) showCancelled({ fileName, renamedFrom, request });
    else showFailure({ fileName, renamedFrom: null, request, error: result.error });
    return false;
  }

  // The failed card for a program that was refused or did not compile, and its error announced.
  function showFailure(failed, announcement = `Error: ${failed.error.message}`) {
    // For an edit, the keyboard stays in the card: Cancel goes with the compiling card, and Back to editing
    // stands where it was.
    const focused = failed.request.edit && view.card.contains(document.activeElement);
    card = { kind: "failed", ...failed };
    render();
    announce(announcement, "error");
    if (focused) view.card.querySelector("button").focus();
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
    // Once the curated examples are listed, which unlocks their select, so that an Uncompiled edit
    // reopened after a reload keeps it locked.
    return examplesReady.then(followRoute);
  }).catch(() => {});
  // Added now, before study.js adds its own (scripts run in order), so on leaving Explore a user program
  // is closed before a Study task prepares its workspace.
  window.addEventListener("hashchange", () => { if (view.mode) followRoute(); });
})();
