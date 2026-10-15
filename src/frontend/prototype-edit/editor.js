// PROTOTYPE ONLY (irexplorer#71). The editor every variant shares: a native <textarea> laid exactly over
// the existing C highlighter (source.js's highlightCSource), with a line-number gutter. Nothing is
// vendored and nothing needs 'unsafe-inline', so it works under the app's default-src 'self' policy.
// The tray can switch it to a plain textarea, to judge what the highlighting is worth.
//
// Keys: Tab indents (four spaces), Shift+Tab outdents, Enter keeps the line's indent, Ctrl/⌘+Enter
// compiles. Escape releases Tab, so the next Tab or Shift+Tab leaves the editor (as in VS Code and
// CodeMirror), and the hint under the editor says so. Edits go through execCommand("insertText"), so
// the browser's own undo (⌘Z) covers indenting and Restore original too.
window.PrototypeEditor = (() => {
  const INDENT = "    ";

  function h(tag, attributes = {}, ...children) {
    const element = document.createElement(tag);
    for (const [name, value] of Object.entries(attributes)) {
      if (name === "class") element.className = value;
      else if (name.startsWith("on")) element.addEventListener(name.slice(2), value);
      else if (value === true) element.setAttribute(name, "");
      else if (value !== false && value != null) element.setAttribute(name, value);
    }
    element.append(...children.flat().filter(child => child != null && child !== false));
    return element;
  }

  // { element, textarea, text, setText(text), setMarks({ error, changed }), focus() }
  function create({ text = "", label = "C source", onChange = () => {}, onSubmit = () => {} } = {}) {
    const plain = window.PrototypeServer?.settings.plainEditor === true;
    const gutter = h("div", { class: "proto-editor-gutter", "aria-hidden": "true" });
    const highlight = h("pre", { class: "proto-editor-highlight", "aria-hidden": "true" });
    const textarea = h("textarea", {
      class: "proto-editor-input", spellcheck: "false", autocapitalize: "off", autocomplete: "off",
      wrap: "off", "aria-label": label, "aria-describedby": "",
    });
    const hint = h("p", { class: "proto-editor-hint" });
    const body = h("div", { class: "proto-editor-body" }, highlight, textarea);
    const element = h("div", { class: `proto-editor${plain ? " is-plain" : ""}` }, h("div", { class: "proto-editor-frame" }, gutter, body), hint);
    const hintId = `proto-editor-hint-${Math.random().toString(36).slice(2, 8)}`;
    hint.id = hintId;
    textarea.setAttribute("aria-describedby", hintId);
    textarea.value = text;
    let marks = { error: new Set(), changed: new Set() };
    let tabReleased = false;

    function lineCount() { return textarea.value.split("\n").length; }

    function paint() {
      const lines = textarea.value.split("\n");
      gutter.replaceChildren(...lines.map((_, index) => {
        const number = index + 1;
        const classes = ["proto-gutter-line"];
        if (marks.error.has(number)) classes.push("is-error");
        else if (marks.changed.has(number)) classes.push("is-changed");
        return h("span", { class: classes.join(" ") }, String(number));
      }));
      if (plain) return;
      const state = { inBlockComment: false };
      highlight.replaceChildren(...lines.map((line, index) => {
        const code = h("span", { class: `proto-highlight-line${marks.error.has(index + 1) ? " is-error" : ""}` });
        highlightCSource(code, line || " ", state);
        return code;
      }));
      syncScroll();
    }

    function syncScroll() {
      highlight.style.transform = `translate(${-textarea.scrollLeft}px, ${-textarea.scrollTop}px)`;
      gutter.scrollTop = textarea.scrollTop;
    }

    function renderHint() {
      const lines = lineCount() - (textarea.value.endsWith("\n") ? 1 : 0);
      const limit = lines > 200 ? ` · ${lines} lines: over the 200-line limit` : ` · ${lines} of 200 lines`;
      hint.textContent = tabReleased
        ? `Tab now moves focus out of the editor. Type to go back to indenting${limit}.`
        : `Tab indents · Esc then Tab leaves the editor · Ctrl/⌘+Enter compiles${limit}`;
      hint.classList.toggle("is-over", lines > 200);
    }

    // Replace the selection, keeping the browser's undo history.
    function insert(value) {
      if (!document.execCommand("insertText", false, value)) {
        textarea.setRangeText(value, textarea.selectionStart, textarea.selectionEnd, "end");
        textarea.dispatchEvent(new Event("input"));
      }
    }

    function lineStart(position) { return textarea.value.lastIndexOf("\n", position - 1) + 1; }

    function indent(outdent) {
      const { selectionStart: start, selectionEnd: end, value } = textarea;
      const first = lineStart(start);
      if (!outdent && start === end) { insert(INDENT); return; }
      const last = end > first && value[end - 1] === "\n" ? end - 1 : end;
      const block = value.slice(first, last);
      const changed = block.split("\n").map(line => outdent ? line.replace(/^ {1,4}|^\t/, "") : INDENT + line).join("\n");
      textarea.setSelectionRange(first, last);
      insert(changed);
      textarea.setSelectionRange(first, first + changed.length);
    }

    textarea.addEventListener("keydown", event => {
      if (event.key === "Escape") { tabReleased = true; renderHint(); return; }
      if (event.key === "Tab" && !tabReleased && !event.altKey && !event.metaKey && !event.ctrlKey) {
        event.preventDefault();
        indent(event.shiftKey);
        return;
      }
      if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) { event.preventDefault(); onSubmit(); return; }
      if (event.key === "Enter" && !event.shiftKey && !event.altKey) {
        event.preventDefault();
        const current = textarea.value.slice(lineStart(textarea.selectionStart), textarea.selectionStart);
        const leading = /^[ \t]*/.exec(current)[0];
        insert(`\n${leading}${/\{\s*$/.test(current) ? INDENT : ""}`);
        return;
      }
      if (event.key !== "Tab" && event.key !== "Shift" && tabReleased) { tabReleased = false; renderHint(); }
    });
    textarea.addEventListener("input", () => { paint(); renderHint(); onChange(textarea.value); });
    textarea.addEventListener("scroll", syncScroll);
    textarea.addEventListener("blur", () => { if (tabReleased) { tabReleased = false; renderHint(); } });

    paint();
    renderHint();

    return {
      element, textarea,
      get text() { return textarea.value; },
      // Replace everything as one undoable edit.
      setText(value) {
        textarea.focus();
        textarea.select();
        insert(value);
        textarea.setSelectionRange(0, 0);
        textarea.scrollTop = 0;
      },
      setMarks(next) { marks = { error: next.error || new Set(), changed: next.changed || new Set() }; paint(); },
      showLine(number) {
        const position = textarea.value.split("\n").slice(0, number - 1).join("\n").length + (number > 1 ? 1 : 0);
        textarea.focus();
        textarea.setSelectionRange(position, position);
        const lineHeight = parseFloat(getComputedStyle(textarea).lineHeight);
        textarea.scrollTop = Math.max(0, (number - 4) * lineHeight);
      },
      focus() { textarea.focus(); },
    };
  }

  // The lines of `after` that are new or changed against `before` (a plain LCS; 200 lines at most).
  function changedLines(before, after) {
    const a = before.split("\n"), b = after.split("\n");
    const table = Array.from({ length: a.length + 1 }, () => new Uint16Array(b.length + 1));
    for (let i = a.length - 1; i >= 0; i--) for (let j = b.length - 1; j >= 0; j--) {
      table[i][j] = a[i] === b[j] ? table[i + 1][j + 1] + 1 : Math.max(table[i + 1][j], table[i][j + 1]);
    }
    const changed = new Set();
    let i = 0, j = 0;
    while (j < b.length) {
      if (i < a.length && a[i] === b[j]) { i++; j++; }
      else if (i < a.length && table[i + 1][j] >= table[i][j + 1]) i++;
      else { changed.add(j + 1); j++; }
    }
    return changed;
  }

  return { create, changedLines, h };
})();
