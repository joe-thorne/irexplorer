// The C source editor for user programs: a native textarea laid exactly over source.js's C highlighter,
// with a line-number gutter. The textarea's own text is transparent, so what shows is the highlighted copy
// behind it and the textarea's caret and selection. Nothing is vendored and nothing is inline, so it works
// under the default-src 'self' content security policy. programs.js builds it in Explore only.
window.ProgramEditor = (() => {
  const INDENT = "    ";

  // How far `before` and `after` (two arrays of lines, or two strings) agree from the start and, in what is
  // left, from the end: [head, tail].
  function sharedEnds(before, after) {
    let head = 0, tail = 0;
    while (head < before.length && head < after.length && before[head] === after[head]) head += 1;
    while (tail < before.length - head && tail < after.length - head && before.at(-1 - tail) === after.at(-1 - tail)) tail += 1;
    return [head, tail];
  }

  // The 1-based numbers of the lines in `after` that are new or changed against `before` (null: every line
  // is new): those outside a longest common run of lines. Only what lies between a shared head and tail is
  // compared, so a small edit to a long program stays cheap.
  function changedLines(before, after) {
    const changed = new Set();
    if (before === null) {
      after.forEach((_, index) => changed.add(index + 1));
      return changed;
    }
    const [head, tail] = sharedEnds(before, after);
    const old = before.slice(head, before.length - tail), now = after.slice(head, after.length - tail);
    // common[i][j]: the longest common run of old[i…] and now[j…].
    const common = Array.from({ length: old.length + 1 }, () => new Uint16Array(now.length + 1));
    for (let i = old.length - 1; i >= 0; i -= 1) {
      for (let j = now.length - 1; j >= 0; j -= 1) {
        common[i][j] = old[i] === now[j] ? common[i + 1][j + 1] + 1 : Math.max(common[i + 1][j], common[i][j + 1]);
      }
    }
    for (let i = 0, j = 0; j < now.length;) {
      if (i < old.length && old[i] === now[j]) { i += 1; j += 1; }
      else if (i < old.length && common[i + 1][j] >= common[i][j + 1]) i += 1;
      else { changed.add(head + j + 1); j += 1; }
    }
    return changed;
  }

  // The one editor of C source: { element, text, start, edited, load(text, { compiled, start }),
  // replaceText(text), focus(), markErrors(lines), showLine(line, column) }. The margin marks the lines that
  // are new or changed against the compiled source the edit started from, and a status line, shown once the
  // text differs from what it started as, counts them. The hint under it gives the keys and the line count.
  // onInput runs after each edit; onSubmit on Ctrl/⌘+Enter.
  function create({ label, onInput = () => {}, onSubmit = () => {} }) {
    const numbers = h("div", { class: "editor-numbers" });
    const gutter = h("div", { class: "editor-gutter", "aria-hidden": "true" }, numbers);
    const highlight = h("pre", { class: "editor-highlight", "aria-hidden": "true" });
    const textarea = h("textarea", {
      class: "editor-input", "aria-label": label, wrap: "off", spellcheck: "false", autocapitalize: "off", autocomplete: "off",
    });
    const frame = h("div", { class: "program-editor-frame" }, gutter, h("div", { class: "editor-body" }, highlight, textarea));
    // The keys, and the line count against the limit, which the textarea is described by.
    const count = h("span");
    const hint = h("p", { id: "program-editor-hint", class: "editor-hint" },
      "Tab indents · Shift+Tab outdents · Enter keeps the indent · Esc, then Tab, leaves the editor · Ctrl/⌘+Enter compiles · ", count);
    textarea.setAttribute("aria-describedby", hint.id);
    // The only sign that the text is an Uncompiled edit; announced, once it says something new.
    const status = h("p", { class: "editor-status", role: "status" });
    const element = h("div", { class: "editor" }, status, frame, hint);
    // What the margin compares with (null: nothing compiled yet), and the text the edit started as.
    let compiled = null, start = "";
    // The lines a failed compile reported errors on, marked until the next load or markErrors.
    let errors = new Set();

    // One number and one highlighted line per line of text, the last (empty or not) included, as the caret can be there.
    function paint() {
      const lines = textarea.value.split("\n");
      const state = { inBlockComment: false };
      const changed = changedLines(compiled === null ? null : AcceptedProgram.lines(compiled), AcceptedProgram.lines(textarea.value));
      const marks = number => [changed.has(number) && "is-changed", errors.has(number) && "is-error"].filter(Boolean).join(" ") || null;
      numbers.replaceChildren(...lines.map((_, index) => h("span", { class: marks(index + 1) }, String(index + 1))));
      highlight.replaceChildren(...lines.map((line, index) => {
        const code = h("span", { class: errors.has(index + 1) ? "is-error" : null });
        highlightCSource(code, line || " ", state);
        return code;
      }));
      follow();
      const counted = AcceptedProgram.lines(textarea.value).length, over = counted > AcceptedProgram.MAX_LINES;
      count.textContent = `${counted} / ${AcceptedProgram.MAX_LINES} lines${over ? ": too many to compile" : ""}`;
      hint.classList.toggle("is-over", over);
      const said = textarea.value === start ? ""
        : `Edited · not compiled · ${changed.size} ${changed.size === 1 ? "line" : "lines"} new or changed`;
      if (status.textContent !== said) status.textContent = said;
    }

    // The gutter and the highlighted copy move with the textarea's scrolling (a style property, which the
    // content security policy allows, unlike a style attribute).
    function follow() {
      highlight.style.transform = `translate(${-textarea.scrollLeft}px, ${-textarea.scrollTop}px)`;
      numbers.style.transform = `translateY(${-textarea.scrollTop}px)`;
    }

    // Replace from…to with `text` through the browser's own editing, so that its undo steps back through
    // the change, then select selectFrom…selectTo. Only the part that differs is replaced, so undo restores
    // just that. Where the browser cannot edit (execCommand is refused), the text changes without undo.
    function replace(from, to, text, selectFrom, selectTo) {
      const old = textarea.value.slice(from, to);
      const [head, tail] = sharedEnds(old, text);
      const middle = text.slice(head, text.length - tail);
      if (head + tail < old.length || middle) {
        textarea.setSelectionRange(from + head, to - tail);
        if (!document.execCommand(middle ? "insertText" : "delete", false, middle)) {
          textarea.setRangeText(middle, from + head, to - tail);
          textarea.dispatchEvent(new Event("input", { bubbles: true }));
        }
      }
      textarea.setSelectionRange(selectFrom, selectTo);
    }

    // Tab and Shift+Tab: indent or outdent the line the selection starts on, or every line it covers (a
    // selection that ends at the start of a line leaves that line out). A single line keeps the selection
    // on its text; several lines end up selected whole.
    function indent(outdent) {
      const { value, selectionStart: start, selectionEnd: end } = textarea;
      const from = value.lastIndexOf("\n", start - 1) + 1;
      const last = end > start && value[end - 1] === "\n" ? end - 1 : end;
      const to = value.indexOf("\n", last) === -1 ? value.length : value.indexOf("\n", last);
      const lines = value.slice(from, to).split("\n");
      const removed = lines.map(line => (outdent ? /^( {1,4}|\t)/.exec(line)?.[0].length ?? 0 : 0));
      const block = lines.map((line, index) => {
        if (outdent) return line.slice(removed[index]);
        return lines.length > 1 && !line ? line : INDENT + line;
      }).join("\n");
      if (lines.length > 1) {
        replace(from, to, block, from, from + block.length);
        return;
      }
      const moved = position => (outdent ? position - Math.min(removed[0], position - from) : position + INDENT.length);
      replace(from, to, block, moved(start), moved(end));
    }

    // Enter: a new line with the indent of the line it splits (no more of it than lies before the caret).
    function newLine() {
      const { value, selectionStart: start, selectionEnd: end } = textarea;
      const from = value.lastIndexOf("\n", start - 1) + 1;
      const kept = "\n" + /^[ \t]*/.exec(value.slice(from, start))[0];
      replace(start, end, kept, start + kept.length, start + kept.length);
    }

    // Esc releases Tab for the next press, so that keyboard users can always leave the editor; any other
    // key (bar the modifiers themselves) takes the release back, as does leaving.
    let tabReleased = false;
    textarea.addEventListener("keydown", event => {
      if (event.isComposing) return;
      const released = tabReleased;
      if (!["Shift", "Control", "Alt", "Meta"].includes(event.key)) tabReleased = event.key === "Escape";
      if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        onSubmit();
      } else if (event.key === "Tab" && !released && !event.ctrlKey && !event.metaKey && !event.altKey) {
        event.preventDefault();
        indent(event.shiftKey);
      } else if (event.key === "Enter" && !event.altKey) {
        event.preventDefault();
        newLine();
      }
    });
    textarea.addEventListener("blur", () => { tabReleased = false; });
    textarea.addEventListener("input", () => { paint(); onInput(); });
    textarea.addEventListener("scroll", follow);

    return {
      element,
      get text() { return textarea.value; },
      // What the edit started as (see load).
      get start() { return start; },
      // Whether the text differs from what the edit started as.
      get edited() { return textarea.value !== start; },
      // Start afresh on `text`, scrolled to the top with the caret at the start. `compiled` is the compiled
      // source the edit started from, which the margin and the status line compare with (null for a new
      // program, every line of which is new); `start` is what the edit started as, which an unedited text
      // matches (the text loaded, unless an edit is being picked up again).
      load(text, { compiled: from = null, start: as = text } = {}) {
        compiled = from;
        start = as;
        errors = new Set();
        textarea.value = text;
        textarea.setSelectionRange(0, 0);
        textarea.scrollTop = textarea.scrollLeft = 0;
        paint();
      },
      // Replace the whole text with `text` as an edit, which the browser's undo reverses (unlike load), and
      // leave the caret at the start.
      replaceText(text) {
        textarea.focus();
        replace(0, textarea.value.length, text, 0, 0);
        textarea.scrollTop = textarea.scrollLeft = 0;
      },
      focus() { textarea.focus(); },
      // Mark these line numbers as the ones a failed compile reported errors on (none: clear the marks).
      markErrors(lines) {
        errors = new Set(lines);
        paint();
      },
      // Put the caret on `line` (at `column`, as far as the line reaches), focused and scrolled into view.
      showLine(line, column = 1) {
        const lines = textarea.value.split("\n").slice(0, line);
        const at = lines.slice(0, -1).reduce((offset, text) => offset + text.length + 1, 0)
          + Math.min(Math.max(column - 1, 0), lines.at(-1)?.length ?? 0);
        textarea.focus();
        textarea.setSelectionRange(at, at);
        const height = parseFloat(getComputedStyle(textarea).lineHeight), top = (lines.length - 1) * height;
        if (top < textarea.scrollTop || top + height > textarea.scrollTop + textarea.clientHeight) {
          textarea.scrollTop = Math.max(0, top - textarea.clientHeight / 3);
        }
        follow();
      },
    };
  }

  return { create };
})();
