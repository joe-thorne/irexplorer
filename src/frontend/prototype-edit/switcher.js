// PROTOTYPE ONLY (irexplorer#71). Floating variant switcher (?variant=A|B|C, ← and → keys) and a
// scenario tray: the next compile's outcome, compile time, the editor's highlighting, how a new program
// starts, whether a recompiled edit replaces its file in Your file, and a readout of what each side holds.
(() => {
  if (!["localhost", "127.0.0.1", "[::1]"].includes(location.hostname)) return;
  const { h } = window.PrototypeEditor;
  const variants = window.PrototypeVariants;
  const keys = Object.keys(variants);
  const key = window.PrototypeVariantKey;
  const params = new URLSearchParams(location.search);
  const server = window.PrototypeServer;
  const go = target => { params.set("variant", target); location.search = params.toString(); };
  const step = delta => go(keys[(keys.indexOf(key) + delta + keys.length) % keys.length]);

  const select = (id, options, value, onchange) => {
    const element = h("select", { id }, options.map(([v, label]) => new Option(label, v)));
    element.value = value;
    element.addEventListener("change", () => onchange(element.value));
    return element;
  };
  const outcome = select("proto-outcome", [["auto", "as the source says"], ["compiler_unavailable", "compiler_unavailable"]],
    server.settings.nextOutcome, value => { server.settings.nextOutcome = value; server.save(); });
  const speed = select("proto-speed", [["1000", "1 s"], ["4000", "4 s (emulated compiler)"], ["9000", "9 s"]],
    String(server.settings.compileMs), value => { server.settings.compileMs = Number(value); server.save(); });
  const highlighting = select("proto-highlight", [["overlay", "Highlighted (textarea over highlighter)"], ["plain", "Plain textarea"]],
    server.settings.plainEditor ? "plain" : "overlay", value => { server.settings.plainEditor = value === "plain"; server.save(); });
  const blank = select("proto-blank", [["starter", "A starter function"], ["empty", "Empty"]],
    server.settings.blankStart || "starter", value => { server.settings.blankStart = value; server.save(); });
  const replaces = select("proto-replaces", [["yes", "Replaces it (one entry per file)"], ["no", "Is added beside it"]],
    server.settings.editReplaces === false ? "no" : "yes", value => { server.settings.editReplaces = value === "yes"; server.save(); });

  const readout = h("dl", { class: "proto-readout" });
  const renderReadout = () => {
    const state = window.PrototypeEditState;
    const programs = window.ProgramsPrototype;
    const names = list => list.length ? list.map(program => program.fileName).join(", ") : "nothing";
    const session = state.session;
    const origin = appState.programId ? state.origins[appState.programId] : null;
    readout.replaceChildren(
      h("dt", {}, "Server holds"), h("dd", {}, `${names(server.programs)} (of 16)`),
      h("dt", {}, "Your file lists"), h("dd", {}, programs ? names(programs.uploads) : "—"),
      h("dt", {}, "On screen"), h("dd", {}, appState.programId ? `user program ${programs?.current?.fileName ?? ""}${origin ? ` (from ${origin.kind}${origin.exampleId ? ` ${origin.exampleId}` : ""})` : ""}` : appState.exampleId ? `curated ${appState.exampleId}` : "nothing"),
      h("dt", {}, "Edit"), h("dd", {}, session ? `${session.phase}: ${session.fileName}${state.dirty ? ", unsaved edits" : ""}; original is ${session.origin.kind}` : "none"));
  };
  setInterval(renderReadout, 500);

  const tray = h("section", { class: "proto-tray", hidden: sessionStorage.getItem("prototype.edit.tray") !== "open", "aria-label": "Prototype scenarios" },
    h("p", { class: "proto-tray-title" }, "Scenarios (reload after changing the editor or the start)"),
    h("div", { class: "proto-settings" },
      h("label", { for: "proto-outcome" }, "Next compile", outcome),
      h("label", { for: "proto-speed" }, "Compile time", speed),
      h("label", { for: "proto-highlight" }, "Editor", highlighting),
      h("label", { for: "proto-blank" }, "New… starts with", blank),
      h("label", { for: "proto-replaces" }, "A recompiled edit of your file", replaces),
      h("button", { type: "button", onclick: () => server.restart() }, "Restart server (forgets every program)")),
    h("p", { class: "proto-tray-tip" }, "Fake compile errors: a missing ';', an unclosed '{', #error, or the names totl, reslt or vlaue."),
    readout);
  const trayButton = h("button", { type: "button", class: "proto-tray-toggle", "aria-expanded": String(!tray.hidden), onclick: () => {
    tray.hidden = !tray.hidden;
    trayButton.setAttribute("aria-expanded", String(!tray.hidden));
    sessionStorage.setItem("prototype.edit.tray", tray.hidden ? "closed" : "open");
  } }, "Scenarios");
  const bar = h("div", { class: "proto-switcher", role: "region", "aria-label": "Prototype variant switcher" },
    h("button", { type: "button", "aria-label": "Previous variant", onclick: () => step(-1) }, "←"),
    h("span", { class: "proto-switcher-label" }, `${key} · ${variants[key].name}`),
    h("button", { type: "button", "aria-label": "Next variant", onclick: () => step(1) }, "→"),
    trayButton);
  document.body.append(tray, bar);
  document.body.classList.add("has-prototype-switcher");
  renderReadout();

  document.addEventListener("keydown", event => {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
    if (event.target.closest("input, textarea, select, [contenteditable], dialog, .ir-line, .cfg-node, .source-line") || event.altKey || event.metaKey || event.ctrlKey) return;
    step(event.key === "ArrowLeft" ? -1 : 1);
  });
})();
