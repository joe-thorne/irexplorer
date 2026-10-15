// The C source editor for user programs: a native textarea laid exactly over source.js's C highlighter,
// with a line-number gutter. The textarea's own text is transparent, so what shows is the highlighted copy
// behind it and the textarea's caret and selection. Nothing is vendored and nothing is inline, so it works
// under the default-src 'self' content security policy. programs.js builds it in Explore only.
window.ProgramEditor = (() => {
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

  // An editor of C source: { element, textarea, text, load(text), focus() }. onInput runs after each edit;
  // onSubmit on Ctrl/⌘+Enter.
  function create({ label, onInput = () => {}, onSubmit = () => {} }) {
    const numbers = h("div", { class: "editor-numbers" });
    const gutter = h("div", { class: "editor-gutter", "aria-hidden": "true" }, numbers);
    const highlight = h("pre", { class: "editor-highlight", "aria-hidden": "true" });
    const textarea = h("textarea", {
      class: "editor-input", "aria-label": label, wrap: "off", spellcheck: "false", autocapitalize: "off", autocomplete: "off",
    });
    const element = h("div", { class: "program-editor-frame" }, gutter, h("div", { class: "editor-body" }, highlight, textarea));

    // One number and one highlighted line per line of text, the last (empty or not) included, as the caret can be there.
    function paint() {
      const lines = textarea.value.split("\n");
      const state = { inBlockComment: false };
      numbers.replaceChildren(...lines.map((_, index) => h("span", {}, String(index + 1))));
      highlight.replaceChildren(...lines.map(line => {
        const code = h("span");
        highlightCSource(code, line || " ", state);
        return code;
      }));
      follow();
    }

    // The gutter and the highlighted copy move with the textarea's scrolling (a style property, which the
    // content security policy allows, unlike a style attribute).
    function follow() {
      highlight.style.transform = `translate(${-textarea.scrollLeft}px, ${-textarea.scrollTop}px)`;
      numbers.style.transform = `translateY(${-textarea.scrollTop}px)`;
    }

    textarea.addEventListener("keydown", event => {
      if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        onSubmit();
      }
    });
    textarea.addEventListener("input", () => { paint(); onInput(); });
    textarea.addEventListener("scroll", follow);

    return {
      element, textarea,
      get text() { return textarea.value; },
      // Start afresh on `text`, scrolled to the top with the caret at the start.
      load(text) {
        textarea.value = text;
        textarea.setSelectionRange(0, 0);
        textarea.scrollTop = textarea.scrollLeft = 0;
        paint();
      },
      focus() { textarea.focus(); },
    };
  }

  return { create };
})();
