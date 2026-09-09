const PASS_ACTIONS = Object.freeze({
  mem2reg: "promote eligible local variables to SSA values",
  instcombine: "simplify instruction forms",
  simplifycfg: "simplify control-flow structure",
  gvn: "reuse equivalent computations",
  "instcombine,simplifycfg": "clean up instructions and control flow",
  "loop-simplify,lcssa": "put loops in a regular form",
  "loop-rotate": "reshape loop control flow",
  licm: "move loop-invariant work when safe",
  indvars: "simplify induction variables",
  "loop-vectorize": "attempt safe loop vectorisation",
});

const appState = {
  exampleId: null,
  states: null,
  functionName: null,
  selection: null,
  selectionInput: null,
  refreshId: 0,
  loadId: 0,
  ready: false,
  manualSetup: false,
  summary: null,
  panels: {
    left: { ordinal: 0, viewType: "ir", ir: null, cfg: null, function: null, selectedNodeIds: new Set() },
    right: { ordinal: 1, viewType: "ir", ir: null, cfg: null, function: null, selectedNodeIds: new Set() },
  },
};

const elements = {
  exampleSelect: document.querySelector("#example-select"),
  functionControl: document.querySelector("#function-control"),
  functionSelect: document.querySelector("#function-select"),
  notice: document.querySelector("#notice"),
  emptyState: document.querySelector("#empty-state"),
  workspace: document.querySelector("#workspace"),
  comparisonAction: document.querySelector("#comparison-action"),
  selectionStatus: document.querySelector("#selection-status"),
  left: panelElements("left"),
  right: panelElements("right"),
};

function panelElements(side) {
  return {
    previous: document.querySelector(`#${side}-previous`),
    next: document.querySelector(`#${side}-next`),
    stateLabel: document.querySelector(`#${side}-state-label`),
    heading: document.querySelector(`#${side}-heading`),
    state: document.querySelector(`#${side}-state`),
    view: document.querySelector(`#${side}-view`),
    description: document.querySelector(`#${side}-description`),
    viewer: document.querySelector(`#${side}-viewer`),
  };
}

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = typeof body.error === "string" ? body.error : body.error?.message;
    throw new Error(message || `Request failed with status ${response.status}.`);
  }
  return body;
}

function announce(message, kind = "info") {
  elements.notice.textContent = message;
  elements.notice.dataset.kind = kind;
}

function showError(error) {
  const template = document.querySelector("#error-template");
  const errorState = template.content.firstElementChild.cloneNode(true);
  errorState.querySelector(".error-message").textContent = error.message;
  elements.emptyState.replaceWith(errorState);
  elements.emptyState = errorState;
  elements.workspace.hidden = true;
  announce(`Error: ${error.message}`, "error");
}

function clearError() {
  if (!elements.emptyState.classList.contains("error-state")) return;
  const empty = document.createElement("section");
  empty.id = "empty-state";
  empty.className = "empty-state panel";
  empty.innerHTML = "<h2>Choose a curated file to start comparing.</h2><p>Select a state and a representation in either panel, then select an IR line or CFG block to follow its recorded link.</p>";
  elements.emptyState.replaceWith(empty);
  elements.emptyState = empty;
}

async function loadExamples() {
  try {
    const { examples } = await request("/api/examples");
    const placeholder = new Option("Choose a curated file…", "");
    placeholder.disabled = true;
    placeholder.selected = true;
    elements.exampleSelect.replaceChildren(placeholder, ...examples.map((exampleId) => (
      new Option(exampleId.replaceAll("_", " "), exampleId)
    )));
    elements.exampleSelect.disabled = false;
    announce("Choose a curated file to compare its recorded optimisation states.");
  } catch (error) {
    showError(error);
  }
}

async function loadExample(setup = null) {
  const exampleId = elements.exampleSelect.value;
  if (!exampleId) return;
  const retainedFunction = setup?.example && appState.exampleId === exampleId ? appState.functionName : null;
  const loadId = ++appState.loadId;
  ++appState.refreshId;
  appState.ready = false;
  clearSelection();
  sourceState.data = null;
  sourceState.anchors = [];
  renderSource();
  elements.workspace.hidden = true;
  elements.exampleSelect.disabled = true;
  announce(`Loading ${exampleId}…`);
  try {
    clearError();
    const [states, source] = await Promise.all([
      request(`${apiRoot(exampleId)}/states`), request(`${apiRoot(exampleId)}/source`),
    ]);
    if (loadId !== appState.loadId) return;
    appState.states = states.states;
    sourceState.data = source;
    renderSource();
    appState.exampleId = exampleId;
    appState.functionName = retainedFunction;
    appState.panels.left.ordinal = 0;
    appState.panels.left.viewType = "ir";
    appState.panels.right.ordinal = Math.min(1, appState.states.length - 1);
    appState.panels.right.viewType = "ir";
    for (const side of ["left", "right"]) {
      if (setup?.[side]) {
        appState.panels[side].ordinal = setup[side].ordinal;
        appState.panels[side].viewType = setup[side].view;
      }
    }
    renderStateOptions();
    elements.left.view.value = appState.panels.left.viewType;
    elements.right.view.value = appState.panels.right.viewType;
    if (appState.manualSetup) {
      for (const side of ["left", "right"]) {
        appState.panels[side].ordinal = null;
        appState.panels[side].viewType = "";
        const placeholder = new Option("Choose a state…", "");
        placeholder.disabled = true;
        elements[side].state.prepend(placeholder);
        elements[side].state.value = "";
        if (!elements[side].view.querySelector('option[value=""]')) {
          const viewPlaceholder = new Option("Choose a view…", "");
          viewPlaceholder.disabled = true;
          elements[side].view.prepend(viewPlaceholder);
        }
        elements[side].view.value = "";
        elements[side].viewer.replaceChildren();
        elements[side].description.textContent = "";
        elements[side].stateLabel.textContent = "";
        elements[side].heading.textContent = side === "left" ? "Left panel" : "Right panel";
        elements[side].previous.disabled = elements[side].next.disabled = true;
      }
      appState.summary = null;
      renderSummary();
      elements.emptyState.hidden = true;
      elements.workspace.hidden = false;
      announce("Choose the states and views described in the task instructions.");
      return;
    }
    await refreshWorkspace();
    if (loadId !== appState.loadId || !appState.ready) return;
    elements.emptyState.hidden = true;
    elements.workspace.hidden = false;
    announce(`${exampleId} is ready. Configure either panel, then select an artefact to follow its recorded link.`);
    document.dispatchEvent(new Event("workspace-ready"));
  } catch (error) {
    if (loadId !== appState.loadId) return;
    document.querySelector("#source-status").textContent = `Source unavailable: ${error.message} Choose a file to retry.`;
    showError(error);
  } finally {
    if (loadId === appState.loadId) elements.exampleSelect.disabled = false;
  }
}

function renderStateOptions() {
  for (const side of ["left", "right"]) {
    const control = elements[side].state;
    control.replaceChildren(...appState.states.map((state) => (
      new Option(stateOptionLabel(state), String(state.ordinal))
    )));
    control.value = String(appState.panels[side].ordinal);
    control.disabled = false;
    elements[side].view.disabled = false;
  }
}

function stateOptionLabel(state) {
  if (state.ordinal === 0) return `0 · Unoptimised baseline · ${state.stateId}`;
  if (state.transition?.kind === "recompiled") return `${state.ordinal} · Separately compiled ${state.transition.level} · ${state.stateId}`;
  const noOp = state.transition?.noOp ? " · no recorded change" : "";
  const end = state.stateId === "final_cleanup" ? " · End of teaching chain" : "";
  return `After pass ${state.ordinal}: ${state.transition?.passName || "recorded pass"} · ${state.stateId}${end}${noOp}`;
}

async function refreshWorkspace() {
  if (!appState.exampleId || Object.values(appState.panels).some(panel => panel.ordinal === null || !panel.viewType)) return;
  let selectionInput = appState.selectionInput;
  if (selectionInput?.kind === "node" && selectionInput.ordinal !== appState.panels[selectionInput.side].ordinal)
    selectionInput = sourceState.anchors.length ? { kind: "source", anchors: sourceState.anchors } : null;
  const refreshId = ++appState.refreshId;
  appState.ready = false;
  appState.summary = null;
  renderSummary();
  elements.workspace.setAttribute("aria-busy", "true");
  document.querySelector("#source-status").textContent = "Loading recorded mappings…";
  const apiBase = apiRoot(appState.exampleId);
  try {
    const [leftIr, rightIr, summary] = await Promise.all([
      request(`${apiBase}/states/${appState.panels.left.ordinal}/ir`),
      request(`${apiBase}/states/${appState.panels.right.ordinal}/ir`),
      request(`${apiBase}/summary?fromOrdinal=${appState.panels.left.ordinal}&toOrdinal=${appState.panels.right.ordinal}`),
    ]);
    if (refreshId !== appState.refreshId) return;
    appState.panels.left.ir = leftIr;
    appState.panels.right.ir = rightIr;
    const commonFunctions = commonFunctionNames(leftIr, rightIr);
    if (!commonFunctions.length) throw new Error("The selected states do not share a comparable function.");
    if (!commonFunctions.includes(appState.functionName)) appState.functionName = commonFunctions[0];
    renderFunctionOptions(commonFunctions);
    for (const side of ["left", "right"]) {
      const panel = appState.panels[side];
      panel.function = panel.ir.functions.find((fn) => fn.name === appState.functionName) || null;
      panel.cfg = null;
    }
    const views = await Promise.all(["left", "right"].map(async (side) => {
      const panel = appState.panels[side];
      const base = `${apiBase}/states/${panel.ordinal}`;
      const query = `?functionId=${encodeURIComponent(panel.function.id)}`;
      const [cfg, mappings] = await Promise.all([
        panel.viewType === "cfg" ? request(`${base}/cfg${query}`) : Promise.resolve(null),
        request(`${base}/source-mappings${query}`),
      ]);
      return { side, cfg, mappings: mappings.mappings };
    }));
    if (refreshId !== appState.refreshId) return;
    for (const view of views) Object.assign(appState.panels[view.side], view);
    appState.summary = summary;
    appState.ready = true;
    renderSummary();
    elements.workspace.setAttribute("aria-busy", "false");
    if (selectionInput) selectWorkspace(selectionInput, { scroll: false });
    else {
      clearSelection();
      applySourceHighlights();
      renderComparison();
      renderPanel("left");
      renderPanel("right");
    }
    document.dispatchEvent(new Event("workspace-ready"));
  } catch (error) {
    if (refreshId === appState.refreshId) {
      elements.workspace.setAttribute("aria-busy", "false");
      document.querySelector("#source-status").textContent = `Mappings unavailable: ${error.message} Choose the file again to retry.`;
      showError(error);
    }
  }
}

function commonFunctionNames(leftIr, rightIr) {
  const rightNames = new Set(rightIr.functions.map((fn) => fn.name));
  return leftIr.functions.map((fn) => fn.name).filter((name) => rightNames.has(name));
}

function renderFunctionOptions(names) {
  elements.functionSelect.replaceChildren(...names.map((name) => new Option(name, name)));
  elements.functionSelect.value = appState.functionName;
  elements.functionControl.hidden = names.length <= 1;
}

function clearSelection() {
  appState.selection = null;
  appState.selectionInput = null;
  sourceState.anchors = [];
  sourceState.rangeStart = null;
  for (const panel of Object.values(appState.panels)) {
    panel.selectedNodeIds = new Set();
    panel.selectedInstructionIds = new Set();
    panel.sourceNodeIds = new Set();
  }
}

function renderComparison() {
  renderOptimisations();
  const leftState = stateFor("left");
  const rightState = stateFor("right");
  elements.comparisonAction.textContent = comparisonAction(leftState, rightState);
  const input = appState.selectionInput;
  const context = document.querySelector("#selection-context");
  const trace = appState.selection?.trace;
  document.querySelector("#trace-counts").hidden = !trace;
  if (!trace) {
    context.textContent = "Select a C line, IR instruction, or CFG block to trace it.";
    elements.selectionStatus.className = "selection-status";
    elements.selectionStatus.textContent = "The recorded correspondence and detected optimisations will appear here.";
    return;
  }
  const source = [...new Set(sourceState.anchors.map(a => a.file + ":" + a.line))].join(", ");
  context.textContent = input.kind === "source" ? "C source · " + source
    : (input.side === "left" ? "Left" : "Right") + " panel · "
      + formatNode(nodeContext(appState.panels[input.side].ir, input.nodeId)) + (source ? " · " + source : "");
  for (const side of ["left", "right"])
    document.querySelector("#" + side + "-trace-count").textContent = trace.members[side].size;
  elements.selectionStatus.className = "selection-status" + (trace.unresolved ? " is-unresolved" : "");
  const relations = new Map();
  for (const link of trace.links) {
    const label = link.confidence === "none" ? "unresolved" : link.relation + " · " + link.confidence + " confidence";
    relations.set(label, (relations.get(label) || 0) + 1);
  }
  elements.selectionStatus.textContent = trace.sameState ? "The same instructions are highlighted in both views."
    : [...relations].map(([label, count]) => count + " recorded " + (count === 1 ? "link" : "links") + ": " + label + ".").join(" ")
      + (trace.unresolved ? " Some instructions cannot be traced with the available evidence." : "");
}

function comparisonAction(leftState, rightState) {
  if (leftState.ordinal === rightState.ordinal) return "Same state · two views";
  const [from, to] = leftState.ordinal < rightState.ordinal ? [leftState, rightState] : [rightState, leftState];
  const direction = leftState.ordinal > rightState.ordinal
    ? "Tracing backwards. Explanations describe the forward change (Right → Left)." : "";
  const scope = to.transition?.kind === "recompiled" ? "Separate compilation comparison."
    : to.ordinal === from.ordinal + 1 ? "One recorded pass."
    : (to.ordinal - from.ordinal) + " recorded passes.";
  return scope + (direction ? " " + direction : "");
}

function stateFor(side) {
  return appState.states?.find((state) => state.ordinal === appState.panels[side].ordinal);
}

function renderPanel(side) {
  const panel = appState.panels[side];
  const controls = elements[side];
  const state = stateFor(side);
  controls.stateLabel.textContent = stateOptionLabel(state);
  controls.previous.disabled = panel.ordinal === 0;
  controls.next.disabled = panel.ordinal === appState.states.length - 1;
  controls.heading.textContent = `${side === "left" ? "Left" : "Right"}: ${state.stateId}`;
  controls.state.value = String(panel.ordinal);
  controls.view.value = panel.viewType;
  controls.viewer.replaceChildren();
  if (!panel.function) {
    controls.description.textContent = "The selected function is unavailable in this state.";
    controls.viewer.append(emptyViewer("No comparable function is available."));
    return;
  }
  if (panel.viewType === "ir") renderIr(side);
  else renderCfg(side);
}

function renderIr(side) {
  const panel = appState.panels[side];
  const { viewer, description } = elements[side];
  const fn = panel.function;
  const instructionCount = fn.blocks.reduce((count, block) => count + block.instructions.length, 0);
  description.textContent = `${panel.ir.stateId} · ${fn.name} · ${fn.blocks.length} basic blocks · ${instructionCount} instructions · Dotted underlines: hover or focus for help.`;
  const signature = document.createElement("code");
  signature.className = "ir-signature";
  signature.innerHTML = highlightIr(stripDebug(fn.signature));
  viewer.append(signature);
  let lineNumber = 1;
  fn.blocks.forEach((block) => {
    const blockElement = document.createElement("section");
    blockElement.className = selectionClass(side, block.id, "ir-block");
    blockElement.dataset.nodeId = block.id;
    const heading = document.createElement("button");
    heading.type = "button";
    heading.className = "ir-block-heading";
    heading.textContent = `${block.label}:`;
    heading.dataset.help = "Basic block: a named sequence of instructions entered at the start and ending with a control-flow instruction.";
    heading.setAttribute("aria-pressed", String(panel.selectedNodeIds.has(block.id)));
    heading.addEventListener("click", () => selectNode(side, block.id));
    blockElement.append(heading);
    block.instructions.forEach((instruction) => {
      const line = document.createElement("div");
      line.className = selectionClass(side, instruction.id, "ir-line");
      line.dataset.nodeId = instruction.id;
      line.setAttribute("role", "button");
      line.setAttribute("tabindex", "0");
      line.setAttribute("aria-label", `Select IR instruction ${instruction.opcode}`);
      line.setAttribute("aria-pressed", String(panel.selectedNodeIds.has(instruction.id)));
      line.innerHTML = `<span class="line-number">${lineNumber++}</span><code>${highlightIr(stripDebug(instruction.text))}</code>`;
      const select = () => selectNode(side, instruction.id);
      line.addEventListener("click", select);
      line.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") { event.preventDefault(); select(); }
      });
      blockElement.append(line);
    });
    viewer.append(blockElement);
  });
}

function renderCfg(side) {
  const panel = appState.panels[side];
  const { viewer, description } = elements[side];
  const cfg = panel.cfg;
  if (!cfg || !cfg.blocks.length) {
    description.textContent = "No control-flow graph is available for this function.";
    viewer.append(emptyViewer("No control-flow graph is available."));
    return;
  }
  description.textContent = `${panel.ir.stateId} · ${panel.function.name} · ${cfg.blocks.length} basic blocks · ${cfg.edges.length} edges`;
  // Layout depends on topology, never on pane width. Zoom scales the finished drawing.
  const graph = new dagre.graphlib.Graph({ multigraph: true });
  graph.setGraph({ rankdir: "TB", nodesep: 36, edgesep: 18, ranksep: 32, marginx: 24, marginy: 24 });
  cfg.blocks.forEach(block => graph.setNode(block.id, { width: Math.max(100, block.label.length * 7.3 + 28), height: 48 }));
  cfg.edges.forEach((edge, index) => graph.setEdge(edge.fromId, edge.toId,
    { width: (edge.label || "").length * 6.5, height: edge.label ? 16 : 0, labelpos: "c" }, String(index)));
  dagre.layout(graph);
  const { width, height } = graph.graph();
  const positions = new Map(cfg.blocks.map(block => {
    const node = graph.node(block.id);
    return [block.id, { ...node, x: node.x - node.width / 2, y: node.y - node.height / 2 }];
  }));
  const namespace = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(namespace, "svg");
  const markerId = `arrow-${side}`;
  svg.classList.add("cfg-svg");
  svg.style.width = `${width}px`;
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("role", "group");
  svg.setAttribute("aria-label", `Control-flow graph for ${panel.function.name} in ${panel.ir.stateId}`);
  const sizeLabel = document.createElement("label");
  sizeLabel.className = "cfg-size";
  sizeLabel.htmlFor = `${side}-cfg-size`;
  sizeLabel.textContent = "Graph zoom";
  const size = document.createElement("select");
  size.id = `${side}-cfg-size`;
  size.setAttribute("aria-label", `${side === "left" ? "Left" : "Right"} graph zoom`);
  size.append(new Option("Fit width", "fit"), new Option("50%", "50"), new Option("75%", "75"),
    new Option("100% (actual size)", "actual"), new Option("125%", "125"), new Option("150%", "150"));
  size.value = panel.cfgSize || "fit";
  const applySize = () => {
    svg.style.maxWidth = "none";
    svg.style.width = size.value === "fit" ? "100%" : `${width * (size.value === "actual" ? 1 : Number(size.value) / 100)}px`;
  };
  applySize();
  size.addEventListener("change", () => { panel.cfgSize = size.value; applySize(); });
  sizeLabel.append(size);
  viewer.append(sizeLabel);
  svg.innerHTML = `<defs><marker id="${markerId}" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 Z" fill="#60758a" /></marker></defs>`;
  let hoveredEdge = null, focusedEdge = null;
  const traceEdge = () => {
    const active = hoveredEdge || focusedEdge;
    svg.classList.toggle("is-tracing", Boolean(active));
    svg.querySelectorAll(".cfg-edge").forEach(path => path.classList.toggle("is-traced", path === active));
  };
  cfg.edges.forEach((edge, index) => {
    const route = graph.edge({ v: edge.fromId, w: edge.toId, name: String(index) });
    const path = document.createElementNS(namespace, "path");
    path.setAttribute("class", "cfg-edge");
    path.dataset.fromId = edge.fromId;
    path.dataset.toId = edge.toId;
    path.setAttribute("d", route.points.map((p, i) => `${i ? "L" : "M"} ${p.x} ${p.y}`).join(" "));
    path.setAttribute("tabindex", "0");
    path.addEventListener("mouseenter", () => { hoveredEdge = path; traceEdge(); });
    path.addEventListener("mouseleave", () => { hoveredEdge = null; traceEdge(); });
    path.addEventListener("focus", () => { focusedEdge = path; traceEdge(); });
    path.addEventListener("blur", () => { focusedEdge = null; traceEdge(); });
    path.setAttribute("marker-end", `url(#${markerId})`);
    const title = document.createElementNS(namespace, "title");
    title.textContent = `${cfg.blocks.find(b => b.id === edge.fromId).label} → ${cfg.blocks.find(b => b.id === edge.toId).label}: ${edge.label || "unlabelled"}`;
    path.setAttribute("aria-label", title.textContent);
    path.append(title);
    svg.append(path);
    if (edge.label) {
      const label = document.createElementNS(namespace, "text");
      label.setAttribute("class", "cfg-edge-label");
      label.setAttribute("x", route.x);
      label.setAttribute("y", route.y + 4);
      label.setAttribute("text-anchor", "middle");
      label.textContent = edge.label;
      svg.append(label);
    }
  });
  cfg.blocks.forEach((block) => {
    const point = positions.get(block.id);
    const node = document.createElementNS(namespace, "g");
    node.setAttribute("class", selectionClass(side, block.id, "cfg-node"));
    node.dataset.nodeId = block.id;
    node.setAttribute("transform", `translate(${point.x}, ${point.y})`);
    node.setAttribute("role", "button");
    node.setAttribute("tabindex", "0");
    node.setAttribute("aria-label", `Select basic block ${block.label}`);
    node.setAttribute("aria-pressed", String(panel.selectedNodeIds.has(block.id)));
    const select = () => selectNode(side, block.id);
    node.addEventListener("click", select);
    node.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") { event.preventDefault(); select(); }
    });
    const rectangle = document.createElementNS(namespace, "rect");
    rectangle.setAttribute("width", String(point.width)); rectangle.setAttribute("height", String(point.height)); rectangle.setAttribute("rx", "6");
    const label = document.createElementNS(namespace, "text");
    label.setAttribute("x", String(point.width / 2)); label.setAttribute("y", "29"); label.setAttribute("text-anchor", "middle");
    label.textContent = block.label;
    const title = document.createElementNS(namespace, "title");
    const memberIds = instructionIds(panel, block.id);
    const tracedCount = memberIds.filter(id => panel.selectedInstructionIds?.has(id)).length;
    title.textContent = "Basic block " + block.label + ": instructions executed in sequence. Arrows show where control can go next."
      + (appState.selection ? ` ${tracedCount} of ${memberIds.length} instructions belong to the current trace.` : "");
    node.setAttribute("aria-label", `Select basic block ${block.label}`
      + (appState.selection ? `; ${tracedCount} of ${memberIds.length} instructions in the current trace` : ""));
    node.append(title, rectangle, label);
    svg.append(node);
  });
  viewer.append(svg);
  const edgeList = document.createElement("details");
  const heading = document.createElement("summary");
  heading.textContent = `Edges as text (${cfg.edges.length})`;
  const list = document.createElement("ul");
  for (const edge of cfg.edges) {
    const item = document.createElement("li");
    item.textContent = `${cfg.blocks.find(b => b.id === edge.fromId).label} → ${cfg.blocks.find(b => b.id === edge.toId).label}: ${edge.label || "unlabelled"}`;
    list.append(item);
  }
  edgeList.append(heading, list);
  viewer.append(edgeList);
}

function selectionClass(side, nodeId, baseClass) {
  if (appState.panels[side].sourceNodeIds?.has(nodeId)) baseClass += " is-source";
  if (!appState.panels[side].selectedNodeIds.has(nodeId)) return baseClass;
  return `${baseClass} ${appState.selection?.originSide === side ? "is-selected" : "is-linked"}`;
}

function displayNodeIds(panel, nodeIds) {
  const displayIds = new Set();
  nodeIds.forEach((nodeId) => {
    const context = nodeContext(panel.ir, nodeId);
    if (!context) return;
    if (panel.viewType === "cfg" && context.instruction) displayIds.add(context.block.id);
    else displayIds.add(nodeId);
  });
  return [...displayIds];
}

function nodeContext(ir, nodeId) {
  for (const fn of ir.functions) {
    if (fn.id === nodeId) return { function: fn, block: null, instruction: null, node: fn };
    for (const block of fn.blocks) {
      if (block.id === nodeId) return { function: fn, block, instruction: null, node: block };
      const instruction = block.instructions.find((item) => item.id === nodeId);
      if (instruction) return { function: fn, block, instruction, node: instruction };
    }
  }
  return null;
}

function formatNode(context) {
  if (context.instruction) return `IR instruction ${context.instruction.displayName}`;
  if (context.block) return `Basic block ${context.block.label}`;
  return `Function ${context.function.name}`;
}

function emptyViewer(message) {
  const empty = document.createElement("p");
  empty.className = "viewer-empty";
  empty.textContent = message;
  return empty;
}

function stripDebug(text) {
  return String(text || "").replace(/,?\s*!dbg\s*!\d+/g, "");
}

const IR_HELP = Object.freeze({
  alloca: "Allocate memory on the stack for this function call.",
  load: "Read a value from memory.", store: "Write a value to memory.",
  br: "Branch: jump to a basic block, optionally choosing between two targets using a condition.",
  ret: "Return from the function, optionally with a result.",
  call: "Call another function.", define: "Begin a function definition.",
  phi: "Choose a value according to which predecessor block control arrived from.",
  select: "Choose one of two values using a condition, without branching.",
  icmp: "Compare integers or pointers and produce an i1 true/false result.",
  fcmp: "Compare floating-point values and produce an i1 true/false result.",
  add: "Add two values.", sub: "Subtract the second value from the first.",
  mul: "Multiply two values.", shl: "Shift bits left.",
  lshr: "Shift bits right, filling with zeroes.", ashr: "Shift bits right, preserving the sign.",
  sdiv: "Signed integer division.", udiv: "Unsigned integer division.",
  srem: "Signed integer remainder.", urem: "Unsigned integer remainder.",
  and: "Bitwise AND.", or: "Bitwise OR.", xor: "Bitwise exclusive OR.",
  getelementptr: "Calculate an address within an object; this does not read memory.",
  sext: "Extend an integer to more bits, preserving its sign.",
  zext: "Extend an integer to more bits, filling with zeroes.",
  trunc: "Keep the low bits to produce a narrower integer.",
  bitcast: "Reinterpret a value using a compatible type without changing its bits.",
  ptr: "Pointer: an address in memory.", void: "No return value.",
  label: "A basic-block destination for control flow.",
  switch: "Choose a destination block by comparing a value with several cases.",
  unreachable: "Execution must never reach this instruction.",
  tail: "Marks a call that may be eligible for tail-call optimisation.",
  nsw: "No signed wrap: signed overflow makes the result poison (an invalid value).",
  nuw: "No unsigned wrap: unsigned overflow makes the result poison (an invalid value).",
  inbounds: "Adds address-calculation constraints; violating them produces poison.",
  align: "The guaranteed memory alignment, measured in bytes.",
  eq: "Equal.", ne: "Not equal.", slt: "Signed less than.", sle: "Signed less than or equal.",
  sgt: "Signed greater than.", sge: "Signed greater than or equal.",
  ult: "Unsigned less than.", ule: "Unsigned less than or equal.",
  ugt: "Unsigned greater than.", uge: "Unsigned greater than or equal.",
  true: "Boolean true (1).", false: "Boolean false (0).",
  null: "A null pointer.", undef: "An unspecified value.",
  poison: "An invalid value that can propagate and lead to undefined behaviour.",
});

function highlightIr(text) {
  // Tokenise raw text once: subsequent replacements must never alter generated markup.
  const tokens = String(text).match(/[%@](?:"[^"]*"|[-A-Za-z0-9$._]+)|[A-Za-z_][A-Za-z_0-9.]*|-?\d+(?:\.\d+)?|[^\w\s]|\s+/g) || [];
  return tokens.map((token, index) => {
    let help = IR_HELP[token], kind = "opcode";
    if (token.startsWith("%")) {
      help = tokens.slice(0, index).filter(t => t.trim()).at(-1) === "label"
        ? "% names a local basic block here: a destination for control flow."
        : "% names a local value (an SSA variable) or basic block. Each SSA value is defined once.";
      kind = "value";
    } else if (token.startsWith("@")) {
      help = "@ names a global symbol, such as a function or global variable."; kind = "value";
    } else if (/^i\d+$/.test(token)) {
      help = "An integer type with " + token.slice(1) + " bits." + (token === "i1" ? " Commonly used for true/false conditions." : ""); kind = "keyword";
    } else if (/^-?\d/.test(token)) {
      help = "A numeric constant; its meaning depends on the surrounding instruction or type."; kind = "number";
    } else if (token === "=") help = "Names the result of the instruction on the right with the SSA value on the left.";
    else if (token === "[") help = "Starts a group, such as a phi value/predecessor pair or an array type.";
    else if (token === "]") help = "Ends this group.";
    else if (token === ",") help = "Separates operands or entries.";
    return help ? '<span class="token-' + kind + ' ir-help" tabindex="0" data-help="' + escapeHtml(help) + '">' + escapeHtml(token) + '</span>' : escapeHtml(token);
  }).join("");
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[character]);
}

function apiRoot(exampleId) {
  return `/api/examples/${encodeURIComponent(exampleId)}`;
}

elements.exampleSelect.addEventListener("change", loadExample);
elements.functionSelect.addEventListener("change", () => {
  appState.functionName = elements.functionSelect.value;
  sourceState.anchors = [];
  clearSelection();
  refreshWorkspace();
});
for (const side of ["left", "right"]) {
  for (const [control, delta] of [["previous", -1], ["next", 1]]) {
    elements[side][control].addEventListener("click", () => {
      const ordinal = appState.panels[side].ordinal + delta;
      if (ordinal < 0 || ordinal >= appState.states.length) return;
      elements[side].state.value = String(ordinal);
      elements[side].state.dispatchEvent(new Event("change"));
    });
  }
  elements[side].state.addEventListener("change", () => {
    appState.panels[side].ordinal = Number(elements[side].state.value);
    refreshWorkspace();
  });
  elements[side].view.addEventListener("change", () => {
    appState.panels[side].viewType = elements[side].view.value;
    refreshWorkspace();
  });
}

const examplesReady = loadExamples();

// Study setup seam: presentation configuration only. No answers, node selection,
// persistence, compiler parsing, or task-specific matching belongs in the workspace.
window.StudyWorkspace = {
  get ready() { return appState.ready && !elements.workspace.hidden; },
  reset() {
    ++appState.loadId;
    ++appState.refreshId;
    appState.manualSetup = true;
    appState.ready = false;
    appState.exampleId = null;
    appState.states = null;
    appState.summary = null;
    appState.functionName = null;
    clearSelection();
    sourceState.data = null;
    sourceState.anchors = [];
    renderSource();
    elements.exampleSelect.value = "";
    elements.exampleSelect.disabled = false;
    elements.functionControl.hidden = true;
    elements.workspace.hidden = true;
    elements.workspace.setAttribute("aria-busy", "false");
    clearError();
    elements.emptyState.hidden = false;
    announce("Choose a source, then select the states and views in the task instructions.");
  },
};
