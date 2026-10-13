// User programs in Explore (ADR 0005): the Curated examples | Your files switch, uploading a C file, and
// the card that stands in for the panels and the comparison while a user program compiles or after it
// fails. Nothing here is built unless /api/release reports the user programs setting on.
(() => {
  const LIMITS = "One C file, up to 200 lines. Standard headers are allowed.";
  const WAIT = "irexplorer compiles the unoptimised -O0 state, applies the curated pass sequence one pass at a time, "
    + "and compiles the recompiled O3 state separately. This usually takes about 5 s.";
  const EMPTY_PROMPTS = {
    curated: "Choose a curated file to start comparing.",
    yours: "Upload a C file, or choose one of your files, to start comparing.",
  };

  // This tab's uploads, oldest first: { programId, fileName, source }. A failed upload is never kept.
  const uploads = [];
  let mode = "curated";
  // The user program on screen or being opened, if any.
  let current = null;
  // What the card shows in place of the panels: null (no card), { kind: "compiling", fileName, started }
  // or { kind: "failed", fileName, error }, where error is the server's { code, message, … }.
  let card = null;
  let ticking = null;
  // Whether the paste box stands in for the source lines, and the button to return focus to when it closes.
  let pasting = false;
  let pasteReturn = null;

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

  function build() {
    const sourcePanel = document.querySelector("#source-panel");
    const controls = sourcePanel.querySelector(".source-controls");
    view.sourcePanel = sourcePanel;
    view.shell = document.querySelector("#workspace-shell");
    view.sourceLines = document.querySelector("#source-lines");
    view.fileControl = controls.querySelector('label[for="example-select"]');
    view.modes = ["curated", "yours"].map(value => h("input", {
      type: "radio", name: "source-mode", value, onchange: () => setMode(value),
    }));
    view.mode = h("fieldset", { id: "source-mode", class: "source-mode" }, h("legend", { class: "sr-only" }, "Source"),
      h("label", {}, view.modes[0], "Curated examples"), h("label", {}, view.modes[1], "Your files"));
    view.yourSelect = h("select", { id: "your-file-select", onchange: () => openUpload(view.yourSelect.value) });
    view.yourControl = h("label", { id: "your-file-control", for: "your-file-select" }, "Your file", view.yourSelect);
    view.upload = h("button", { id: "program-upload", type: "button", onclick: () => view.fileInput.click() }, "Upload…");
    view.pasteOpen = h("button", { id: "program-paste-open", type: "button", onclick: openPaste }, "Paste…");
    controls.prepend(view.mode);
    view.fileControl.after(view.yourControl, view.upload, view.pasteOpen);
    view.fileInput = h("input", { id: "program-file-input", type: "file", accept: ".c", hidden: true, onchange: () => {
      const [file] = view.fileInput.files;
      view.fileInput.value = "";
      if (file) uploadFile(file);
    } });
    view.choose = h("button", { type: "button", class: "primary", onclick: () => view.fileInput.click() }, "Choose a file…");
    view.pasteInstead = h("button", { type: "button", onclick: openPaste }, "Paste source instead");
    // Stands in for the source prompt while Your files is selected (see style.css).
    view.drop = h("div", { id: "program-drop", class: "program-drop" },
      h("p", { class: "program-drop-title" }, "Drop a .c file here"),
      h("p", {}, LIMITS), h("div", { class: "program-actions" }, view.choose, view.pasteInstead));
    view.pasteName = h("input", { id: "program-paste-name", type: "text", value: "program.c", spellcheck: "false", autocomplete: "off" });
    view.pasteSource = h("textarea", { id: "program-paste-source", rows: "16", spellcheck: "false" });
    view.pasteCompile = h("button", { id: "program-paste-compile", type: "submit", class: "primary" }, "Compile");
    // Stands in for the source lines while open, over any open user program (see style.css).
    view.paste = h("form", { id: "program-paste", class: "program-paste", "aria-label": "Paste C source", onsubmit: event => {
      event.preventDefault();
      compile(view.pasteName.value.trim(), view.pasteSource.value);
    }, onkeydown: event => { if (event.key === "Escape") closePaste(); } },
      h("label", { for: "program-paste-name" }, "File name", view.pasteName),
      h("label", { for: "program-paste-source" }, "C source", view.pasteSource),
      h("div", { class: "program-actions" }, view.pasteCompile,
        h("button", { id: "program-paste-cancel", type: "button", onclick: closePaste }, "Cancel")));
    view.sourceLines.after(view.drop, view.paste, view.fileInput);
    view.chip = h("span", { id: "program-chip", class: "program-chip" }, "Your file");
    const summary = document.querySelector("#source-summary");
    const title = h("div", { class: "source-title" });
    summary.replaceWith(title);
    title.append(summary, view.chip);
    view.card = h("section", { id: "program-card", class: "panel program-card", "aria-labelledby": "program-card-heading" });
    view.shell.append(view.card);
    for (const type of ["dragenter", "dragover", "dragleave", "drop"]) sourcePanel.addEventListener(type, dragFile);
    render();
  }

  function render() {
    const yours = mode === "yours";
    const compiling = card?.kind === "compiling";
    view.sourcePanel.dataset.mode = mode;
    for (const input of view.modes) {
      input.checked = input.value === mode;
      input.disabled = compiling;
    }
    view.fileControl.hidden = yours;
    view.yourControl.hidden = view.upload.hidden = view.pasteOpen.hidden = !yours;
    const placeholder = new Option(uploads.length ? "Choose one of your files…" : "No files yet", "");
    placeholder.disabled = true;
    view.yourSelect.replaceChildren(placeholder, ...uploads.map(upload => new Option(upload.fileName, upload.programId)));
    view.yourSelect.value = current?.programId || "";
    view.yourSelect.disabled = compiling || !uploads.length;
    view.upload.disabled = view.choose.disabled = compiling;
    view.pasteOpen.disabled = view.pasteInstead.disabled = view.pasteCompile.disabled = compiling;
    view.paste.hidden = !pasting;
    view.sourcePanel.toggleAttribute("data-pasting", pasting);
    // Re-enabled by the workspace once a curated example or user program can be chosen again.
    if (compiling) elements.exampleSelect.disabled = true;
    view.shell.setAttribute("aria-busy", String(compiling));
    view.chip.hidden = !(yours && sourceState.data);
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
    renderCard();
  }

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
      const { started } = card;
      // Whole seconds for sighted users only; the status was announced once when the compile started.
      const elapsed = h("span", { class: "program-elapsed", "aria-hidden": "true" });
      const tick = () => { elapsed.textContent = `${Math.floor((performance.now() - started) / 1000)} s`; };
      tick();
      ticking = setInterval(tick, 250);
      view.card.replaceChildren(
        h("h2", { id: "program-card-heading" }, `Compiling ${card.fileName} · `, elapsed),
        h("p", {}, WAIT));
    } else {
      view.card.replaceChildren(...failureContent(card));
    }
  }

  function failureContent({ fileName, error }) {
    return [
      h("h2", { id: "program-card-heading" }, `${fileName} could not be opened`),
      h("p", { class: "program-failure-message" }, error.message),
      ...(error.code === "compile_failed" ? compileFailure(error) : []),
      h("div", { class: "program-actions" },
        h("button", { type: "button", onclick: () => view.fileInput.click() }, "Choose another file…")),
    ];
  }

  // Each diagnostic in order; one against the upload is a button that shows its line in the source.
  function compileFailure({ diagnostics, output }) {
    const items = diagnostics.map(diagnostic => {
      const { file, line, column, severity, message } = diagnostic;
      const text = inUpload(diagnostic) ? `Line ${line}, column ${column}: ${message}` : `${file}, line ${line}, column ${column}: ${message}`;
      return h("li", { "data-severity": severity }, h("span", { class: "program-diagnostic-severity" }, severity),
        inUpload(diagnostic) ? h("button", { type: "button", onclick: () => showSourceLine(line) }, text) : h("span", {}, text));
    });
    return [
      ...(items.length ? [h("ul", { class: "program-diagnostics", "aria-label": "Compiler diagnostics" }, ...items)] : []),
      h("details", { class: "program-output" }, h("summary", {}, "Full compiler output"), h("pre", {}, output)),
    ];
  }

  function setMode(next) {
    mode = next;
    current = null;
    pasting = false;
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
    const accepted = mode === "yours" && card?.kind !== "compiling";
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
    await compile(file.name, await file.text());
  }

  async function compile(fileName, source) {
    if (card?.kind === "compiling") return;
    mode = "yours";
    current = null;
    pasting = false;
    closeWorkspace();
    sourceState.data = { file: fileName, text: source };
    renderSource();
    card = { kind: "compiling", fileName, started: performance.now() };
    render();
    announce(`Compiling ${fileName}.`);
    const result = await postProgram(fileName, source);
    if (!result.ok) {
      card = { kind: "failed", fileName, error: result.error };
      render();
      announce(`Error: ${result.error.message}`, "error");
      return;
    }
    const { program } = result;
    if (!uploads.some(upload => upload.programId === program.programId)) uploads.push(program);
    current = program;
    await loadProgram(program);
    card = null;
    render();
  }

  // POST /api/programs and wait for the compile: { ok: true, program } or { ok: false, error }.
  async function postProgram(fileName, source) {
    let response;
    try {
      response = await fetch("/api/programs", {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ fileName, source }),
      });
    } catch {
      return { ok: false, error: { code: "unreachable", message: "irexplorer could not be reached. Check that it is running." } };
    }
    const body = await response.json().catch(() => ({}));
    if (response.ok) return { ok: true, program: { programId: body.programId, fileName: body.fileName, source } };
    return { ok: false, error: { message: `The compile failed with status ${response.status}.`, ...body.error } };
  }

  // The paste box keeps what was last typed in it, so a refused paste can be corrected.
  function openPaste(event) {
    pasteReturn = event.currentTarget;
    pasting = true;
    render();
    view.pasteSource.focus();
  }

  function closePaste() {
    pasting = false;
    render();
    // The button that opened the box, or Paste… if that one has gone with the drop zone.
    (pasteReturn?.checkVisibility() ? pasteReturn : view.pasteOpen).focus();
  }

  // A held upload opens at once: its kept source shows while the views load, and nothing is compiled.
  async function openUpload(programId) {
    const upload = uploads.find(item => item.programId === programId);
    if (!upload) return;
    current = upload;
    card = null;
    pasting = false;
    const opened = loadProgram(upload);
    render();
    await opened;
  }

  fetch("/api/release", { cache: "no-store" }).then(response => response.ok ? response.json() : null).then(release => {
    if (release?.config?.userPrograms === true) build();
  }).catch(() => {});
})();
