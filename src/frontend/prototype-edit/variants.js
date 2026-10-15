// PROTOTYPE ONLY (irexplorer#71, throwaway branch prototype/editing-flow). Three placements of the M2
// editor on the real Explore page, switched with ?variant=A|B|C:
//   A · In the source pane: the C source pane itself becomes the editor; the panels keep the last compile.
//   B · Beside the compiled source: the editor takes the panels' place; the source pane keeps what was compiled.
//   C · Separate editing step: the editor takes the whole workbench until you compile or discard.
// The core below is shared: how an edit starts (Edit a copy, Edit, New…), what it remembers as the
// original, Restore original, and compiling through the real M1 flow (programs.js), whose compiling,
// failure and cancel cards are reused unchanged.
(() => {
  const { h, create: createEditor, changedLines } = window.PrototypeEditor;
  const STARTER = "// A small C program: at least one function, up to 200 lines.\n\nint square(int x) {\n    return x * x;\n}\n";
  const ORIGINS_KEY = "prototype.edit.origins";
  const settings = () => window.PrototypeServer.settings;

  // Where each compiled edit came from, by programId: { kind: "curated", exampleId, fileName, text } or
  // { kind: "upload", fileName, text } or { kind: "blank" }. Kept for the tab, like the uploads.
  const origins = (() => { try { return JSON.parse(sessionStorage.getItem(ORIGINS_KEY)) || {}; } catch { return {}; } })();
  const keepOrigins = () => { try { sessionStorage.setItem(ORIGINS_KEY, JSON.stringify(origins)); } catch { /* prototype */ } };

  // The edit in progress, if any: { fileName, base, origin, parentProgramId, phase, errors, title }.
  // base: the text the editor started from (what the panels show, or "" for a new program).
  // phase: "editing" while the editor is open, "compiling" while the M1 card stands in for it.
  let session = null;
  let editor = null;
  let variant = null;
  let P = null;

  const on = (element, name, value) => { if (element && element[name] !== value) element[name] = value; };

  // ---- Starting an edit -------------------------------------------------------------------------------

  function originOf(programId, fileName, text) {
    return origins[programId] || { kind: "upload", fileName, text };
  }

  function startFromScreen() {
    if (appState.exampleId && sourceState.data) {
      const text = sourceState.data.text;
      begin({ fileName: `${appState.exampleId}.c`, base: text, origin: { kind: "curated", exampleId: appState.exampleId, fileName: `${appState.exampleId}.c`, text },
        parentProgramId: null, title: `Editing a copy of curated ${appState.exampleId.replaceAll("_", " ")}` });
    } else if (P.current) {
      const { programId, fileName, source } = P.current;
      begin({ fileName, base: source, origin: originOf(programId, fileName, source), parentProgramId: programId, title: `Editing ${fileName}` });
    }
  }

  function startBlank() {
    begin({ fileName: "program.c", base: "", origin: { kind: "blank" }, parentProgramId: null, title: "New program",
      initial: settings().blankStart === "empty" ? "" : STARTER });
  }

  function begin({ initial, ...rest }) {
    session = { ...rest, phase: "editing", errors: [], text: initial ?? rest.base };
    if (P.mode !== "yours" && !appState.exampleId) P.setMode("yours");
    variant.open(session);
    sync();
    editor?.focus();
    announce(`${session.title}. Compile to explore it.`);
  }

  // ---- Inside the editor -----------------------------------------------------------------------------

  const dirty = () => Boolean(session && editor && editor.text !== session.base);
  const canRestore = () => Boolean(session && editor && session.origin.kind !== "blank" && editor.text !== session.origin.text);

  // The editor and its standard controls, for a variant to lay out.
  function editorParts() {
    editor = createEditor({ text: session.text, label: `C source of ${session.fileName}`, onChange: changed, onSubmit: compileEdit });
    const name = h("input", { type: "text", class: "proto-edit-name", value: session.fileName, spellcheck: "false", autocomplete: "off",
      oninput: event => { session.fileName = event.target.value; } });
    const nameField = h("label", { class: "proto-edit-name-field" }, "File name", name);
    const status = h("p", { class: "proto-edit-status", role: "status" });
    const compile = h("button", { type: "button", class: "primary", onclick: compileEdit }, "Compile");
    const restore = h("button", { type: "button", onclick: restoreOriginal }, "Restore original");
    const discard = h("button", { type: "button", onclick: discard_ }, "Discard edits");
    const actions = h("div", { class: "program-actions proto-edit-actions" }, compile, restore, discard);
    const diagnostics = h("ul", { class: "program-diagnostics proto-edit-diagnostics", "aria-label": "Compiler diagnostics", hidden: true });
    parts = { name, nameField, status, compile, restore, discard, actions, diagnostics };
    changed();
    return parts;
  }
  let parts = null;

  function changed() {
    if (!session || !editor || !parts) return;
    session.text = editor.text;
    const changedSet = session.base ? changedLines(session.base, editor.text) : new Set();
    const errorLines = new Set(session.errors.map(error => error.line));
    editor.setMarks({ error: errorLines, changed: variant.marksChanges ? changedSet : new Set() });
    parts.restore.hidden = session.origin.kind === "blank";
    parts.restore.disabled = !canRestore();
    parts.discard.textContent = session.base ? (dirty() ? "Discard edits" : "Close editor") : "Discard";
    parts.status.textContent = statusText(changedSet);
    parts.status.classList.toggle("is-dirty", dirty());
    variant.changed?.(session, changedSet);
  }

  function statusText(changedSet) {
    if (!session.base) return "Not compiled yet.";
    if (!dirty()) return "No edits yet. The panels show this source.";
    const n = changedSet.size;
    return `Edited · not compiled · ${n} line${n === 1 ? "" : "s"} new or changed`;
  }

  function restoreOriginal() {
    editor.setText(session.origin.text);
    announce(`Restored the original ${session.origin.kind === "curated" ? "curated example" : "upload"}. ⌘Z undoes it.`);
  }

  function discard_() {
    if (dirty() && !confirm(`Discard your edits to ${session.fileName}?`)) return;
    const blankNothing = !session.base;
    close();
    if (blankNothing) P.render();
  }

  function close() {
    session = null;
    variant.close();
    editor = null;
    parts = null;
    sync();
  }

  // Compile through the real M1 flow. On success the edit becomes a user program and opens in the panels;
  // on compile_failed the editor comes back with the error lines marked; any other failure leaves M1's card,
  // with Back to editing added.
  async function compileEdit() {
    if (!session || P.compiling) return;
    const edit = session;
    edit.text = editor.text;
    edit.errors = [];
    edit.phase = "compiling";
    variant.hide();
    sync();
    await P.compile(edit.fileName.trim(), edit.text);
    if (session !== edit) return;
    const card = P.card;
    if (!card && P.current) {
      const { programId } = P.current;
      if (edit.origin.kind !== "blank" && !(edit.origin.kind === "upload" && edit.origin.text === P.current.source)) {
        origins[programId] = edit.origin;
      } else if (edit.origin.kind === "blank") {
        origins[programId] = { kind: "blank" };
      }
      keepOrigins();
      // A recompiled edit of one of your files replaces it in Your file (unless the tray says otherwise).
      if (settings().editReplaces !== false && edit.parentProgramId && edit.parentProgramId !== programId) {
        const index = P.uploads.findIndex(upload => upload.programId === edit.parentProgramId);
        if (index >= 0) { P.uploads.splice(index, 1); P.keepUploads(); P.render(); }
      }
      close();
      return;
    }
    if (card?.kind === "failed" && card.error.code === "compile_failed") {
      edit.errors = (card.error.diagnostics || []).filter(diagnostic => !diagnostic.file.includes("/"));
      reopen();
      return;
    }
    // Cancelled, refused, unsupported or the compiler was unavailable: M1's card, plus Back to editing.
    sync();
  }

  function reopen() {
    session.phase = "editing";
    variant.open(session);
    renderDiagnostics();
    changed();
    window.PrototypeEdit.decorateCard(P.view.card, P.card);
    sync();
    if (session.errors[0]) editor.showLine(session.errors[0].line);
  }

  function renderDiagnostics() {
    if (!parts) return;
    parts.diagnostics.hidden = !session.errors.length;
    parts.diagnostics.replaceChildren(...session.errors.map(({ line, column, severity, message }) => h("li", { "data-severity": severity },
      h("span", { class: "program-diagnostic-severity" }, severity),
      h("button", { type: "button", onclick: () => editor.showLine(line) }, `Line ${line}, column ${column}: ${message}`))));
  }

  // M1's card, decorated: Back to editing whenever an edit is waiting, and (in A, where the card sits
  // beside the open editor) its diagnostics jump to the editor's lines instead of the hidden source.
  window.PrototypeEdit = {
    decorateCard(element, card) {
      if (!session || !card || card.kind === "compiling") return;
      const open = Boolean(editor && session.phase === "editing");
      const actions = element.querySelector(".program-actions");
      if (open) actions?.querySelector(".proto-back")?.remove();
      else if (actions && !actions.querySelector(".proto-back")) {
        actions.prepend(h("button", { type: "button", class: "primary proto-back", onclick: reopen }, "Back to editing"));
        for (const other of actions.querySelectorAll(".primary:not(.proto-back)")) other.classList.remove("primary");
      }
      if (open) {
        for (const button of element.querySelectorAll(".program-diagnostics button")) {
          const line = Number(/Line (\d+)/.exec(button.textContent)?.[1]);
          button.replaceWith(h("button", { type: "button", onclick: () => editor.showLine(line) }, button.textContent));
        }
      }
    },
  };

  // ---- What the page shows around the editor ------------------------------------------------------------

  const bar = {};
  function buildBar() {
    bar.edit = h("button", { type: "button", class: "proto-edit-open", onclick: startFromScreen }, "Edit");
    bar.origin = h("p", { class: "program-renamed proto-origin" });
    bar.element = h("div", { class: "proto-edit-bar" }, bar.origin, bar.edit);
    // M2 folds Paste… into New…: the editor is also where pasted source goes.
    bar.new = h("button", { type: "button", id: "proto-new", onclick: startBlank }, "New…");
    bar.dropNew = h("button", { type: "button", onclick: startBlank }, "Write or paste a program");
  }

  function sync() {
    if (!P?.view.mode) return;
    const attached = P.view.mode.isConnected;
    if (!attached) {
      if (session) close();
      bar.element.remove(); bar.new.remove(); bar.dropNew.remove();
      return;
    }
    if (!bar.element.isConnected) P.view.renamed.after(bar.element);
    if (!bar.new.isConnected) P.view.pasteOpen.after(bar.new);
    if (!bar.dropNew.isConnected) P.view.pasteInstead.after(bar.dropNew);
    P.view.pasteOpen.hidden = true;
    P.view.pasteInstead.hidden = true;
    on(bar.new, "hidden", P.mode !== "yours");

    const editing = Boolean(session);
    const shown = !editing && !P.card && Boolean(sourceState.data) && Boolean(appState.exampleId || appState.programId);
    on(bar.edit, "hidden", !shown);
    on(bar.edit, "textContent", appState.exampleId ? "Edit a copy" : "Edit");
    // While an edit is open the file cannot change underneath it: compile or discard first.
    const lock = editing || P.compiling;
    for (const input of P.view.modes) on(input, "disabled", lock);
    on(elements.exampleSelect, "disabled", lock || elements.exampleSelect.options.length < 2);
    on(P.view.yourSelect, "disabled", lock || !P.uploads.length);
    on(P.view.upload, "disabled", lock);
    on(P.view.choose, "disabled", lock);
    on(bar.new, "disabled", lock);
    on(bar.dropNew, "disabled", lock);

    const origin = appState.programId && !editing ? origins[appState.programId] : null;
    on(bar.origin, "hidden", !origin || origin.kind === "blank");
    if (origin && origin.kind !== "blank") {
      const label = origin.kind === "curated" ? `curated ${origin.exampleId.replaceAll("_", " ")}` : `your upload ${origin.fileName}`;
      if (bar.origin.dataset.label !== label) {
        bar.origin.dataset.label = label;
        bar.origin.replaceChildren(`Edited from ${label}. `,
          h("button", { type: "button", class: "proto-link", onclick: () => openOriginal(origin) }, "Open the original"));
      }
    } else delete bar.origin.dataset.label;

    for (const option of P.view.yourSelect.options) {
      const known = origins[option.value];
      if (known && known.kind !== "blank" && !option.textContent.endsWith(" · edited")) option.textContent += " · edited";
      if (known?.kind === "blank" && !option.textContent.endsWith(" · new")) option.textContent += " · new";
    }
    variant.sync?.(session);
  }

  async function openOriginal(origin) {
    if (origin.kind === "curated") {
      P.setMode("curated");
      elements.exampleSelect.value = origin.exampleId;
      elements.exampleSelect.dispatchEvent(new Event("change"));
      return;
    }
    const held = P.uploads.find(upload => upload.source === origin.text);
    if (held) await P.openUpload(held.programId);
    else await P.compile(origin.fileName, origin.text);
  }

  // ---- The three layouts -------------------------------------------------------------------------------

  const shell = () => document.querySelector("#workspace-shell");
  const sourcePanel = () => document.querySelector("#source-panel");

  const variants = {
    A: {
      name: "In the source pane",
      marksChanges: true,
      open(edit) {
        this.close();
        const p = editorParts();
        this.element = h("div", { class: "proto-edit-a" },
          h("div", { class: "proto-edit-a-top" }, p.nameField),
          p.status, editor.element, p.actions);
        sourcePanel().dataset.protoEditing = "A";
        document.querySelector("#source-lines").after(this.element);
        p.status.setAttribute("title", "The panels still show the last compile until you compile again.");
      },
      changed(edit) {
        // The panels stay usable but stale: say so on them.
        for (const panel of document.querySelectorAll(".viewer-panel")) panel.classList.toggle("proto-stale", dirty());
      },
      hide() { this.close(); },
      close() {
        this.element?.remove();
        this.element = null;
        delete sourcePanel().dataset.protoEditing;
        for (const panel of document.querySelectorAll(".viewer-panel")) panel.classList.remove("proto-stale");
      },
    },

    B: {
      name: "Beside the compiled source",
      marksChanges: true,
      open(edit) {
        this.close();
        const p = editorParts();
        this.element = h("section", { class: "panel proto-edit-b", "aria-labelledby": "proto-edit-b-heading" },
          h("header", { class: "proto-edit-b-heading" },
            h("h2", { id: "proto-edit-b-heading" }, edit.title),
            h("div", { class: "proto-edit-b-controls" }, p.nameField, p.actions)),
          p.status, p.diagnostics, editor.element);
        shell().dataset.protoEditing = "B";
        shell().append(this.element);
        // The source pane keeps what was compiled, as a reference to edit against.
        this.note = h("p", { class: "proto-edit-b-note" }, edit.base
          ? "Compiled source, as the panels showed it. Your draft is on the right; changed lines are marked in its margin."
          : "Nothing is compiled yet. Write your program on the right.");
        sourcePanel().querySelector(".source-heading").after(this.note);
        sourcePanel().dataset.protoReference = edit.base ? "compiled" : "none";
      },
      hide() { this.close(); },
      close() {
        this.element?.remove();
        this.note?.remove();
        this.element = this.note = null;
        delete shell().dataset.protoEditing;
        delete sourcePanel().dataset.protoReference;
      },
    },

    C: {
      name: "Separate editing step",
      marksChanges: false,
      open(edit) {
        this.close();
        const p = editorParts();
        const from = edit.origin.kind === "curated" ? "Your copy is a new program in Your files; the curated example never changes."
          : edit.origin.kind === "upload" ? "Compiling makes a new version of this file; the original stays available."
            : "Compiling adds it to Your files.";
        this.element = h("section", { class: "panel proto-edit-c", "aria-labelledby": "proto-edit-c-heading" },
          h("header", { class: "proto-edit-c-heading" },
            h("div", {}, h("h2", { id: "proto-edit-c-heading", tabindex: "-1" }, edit.title), h("p", { class: "proto-edit-c-from" }, from)),
            p.actions),
          h("div", { class: "proto-edit-c-row" }, p.nameField, p.status),
          p.diagnostics, editor.element);
        shell().dataset.protoEditing = "C";
        shell().append(this.element);
      },
      hide() { this.close(); },
      close() {
        this.element?.remove();
        this.element = null;
        delete shell().dataset.protoEditing;
      },
    },
  };

  window.PrototypeVariants = variants;
  window.PrototypeEditState = { get session() { return session; }, get dirty() { return dirty(); }, origins };

  const requested = new URLSearchParams(location.search).get("variant");
  window.PrototypeVariantKey = Object.hasOwn(variants, requested) ? requested : "A";
  variant = variants[window.PrototypeVariantKey];

  // programs.js builds its controls once /api/release answers, which can be before or after this script runs.
  function init() {
    if (P) return;
    P = window.ProgramsPrototype;
    buildBar();
    let queued = false;
    const observer = new MutationObserver(() => {
      if (queued) return;
      queued = true;
      requestAnimationFrame(() => { queued = false; sync(); });
    });
    observer.observe(document.querySelector("#workspace-shell"), { subtree: true, childList: true, attributes: true, attributeFilter: ["hidden"] });
    window.addEventListener("hashchange", () => setTimeout(sync));
    sync();
  }
  if (window.ProgramsPrototype?.view.mode) init();
  else document.addEventListener("programs-ready", init);
})();
