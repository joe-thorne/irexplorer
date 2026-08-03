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
  session: null,
  functionName: null,
  selection: null,
  refreshId: 0,
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
  if (!response.ok) throw new Error(body.error || `Request failed with status ${response.status}.`);
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

async function loadExample() {
  const exampleId = elements.exampleSelect.value;
  if (!exampleId) return;
  elements.exampleSelect.disabled = true;
  announce(`Loading ${exampleId}…`);
  try {
    clearError();
    appState.session = await request("/api/session", {
      method: "POST",
      body: JSON.stringify({ exampleId }),
    });
    appState.functionName = null;
    appState.selection = null;
    appState.panels.left.ordinal = 0;
    appState.panels.left.viewType = "ir";
    appState.panels.right.ordinal = Math.min(1, appState.session.states.length - 1);
    appState.panels.right.viewType = "ir";
    renderStateOptions();
    elements.left.view.value = "ir";
    elements.right.view.value = "ir";
    await refreshWorkspace();
    elements.emptyState.hidden = true;
    elements.workspace.hidden = false;
    announce(`${exampleId} is ready. Configure either panel, then select an artefact to follow its recorded link.`);
  } catch (error) {
    showError(error);
  } finally {
    elements.exampleSelect.disabled = false;
  }
}

function renderStateOptions() {
  for (const side of ["left", "right"]) {
    const control = elements[side].state;
    control.replaceChildren(...appState.session.states.map((state) => (
      new Option(stateOptionLabel(state), String(state.ordinal))
    )));
    control.value = String(appState.panels[side].ordinal);
    control.disabled = false;
    elements[side].view.disabled = false;
  }
}

function stateOptionLabel(state) {
  if (state.ordinal === 0) return `${state.stateId} — baseline`;
  if (state.transition?.kind === "recompiled") return `${state.stateId} — recompiled ${state.transition.level} anchor`;
  const noOp = state.transition?.noOp ? " (no recorded change)" : "";
  return `${state.stateId} — ${state.transition?.passName || "recorded state"}${noOp}`;
}

async function refreshWorkspace() {
  if (!appState.session) return;
  const refreshId = ++appState.refreshId;
  try {
    const [leftIr, rightIr] = await Promise.all([
      request(`/api/ir?ordinal=${appState.panels.left.ordinal}`),
      request(`/api/ir?ordinal=${appState.panels.right.ordinal}`),
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
    const cfgRequests = ["left", "right"].map(async (side) => {
      const panel = appState.panels[side];
      if (panel.viewType !== "cfg" || !panel.function) return;
      panel.cfg = await request(`/api/cfg?ordinal=${panel.ordinal}&functionId=${encodeURIComponent(panel.function.id)}`);
    });
    await Promise.all(cfgRequests);
    if (refreshId !== appState.refreshId) return;
    renderComparison();
    renderPanel("left");
    renderPanel("right");
  } catch (error) {
    if (refreshId === appState.refreshId) showError(error);
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
  for (const panel of Object.values(appState.panels)) panel.selectedNodeIds = new Set();
}

function renderComparison() {
  const leftState = stateFor("left");
  const rightState = stateFor("right");
  elements.comparisonAction.textContent = comparisonAction(leftState, rightState);
  if (!appState.selection) {
    elements.selectionStatus.className = "selection-status";
    elements.selectionStatus.textContent = "Select an IR line or CFG block to follow its recorded link.";
    return;
  }
  elements.selectionStatus.className = `selection-status${appState.selection.unresolved ? " is-unresolved" : ""}`;
  elements.selectionStatus.textContent = appState.selection.text;
}

function comparisonAction(leftState, rightState) {
  if (leftState.ordinal === rightState.ordinal) return `Both panels show ${leftState.stateId}; no cross-state action is being compared.`;
  const [from, to] = leftState.ordinal < rightState.ordinal ? [leftState, rightState] : [rightState, leftState];
  if (to.ordinal !== from.ordinal + 1) {
    return `${from.stateId} → ${to.stateId}: composed comparison across ${to.ordinal - from.ordinal} recorded transitions; no single pass is attributed.`;
  }
  if (to.transition?.kind === "recompiled") return `${from.stateId} → ${to.stateId}: separately recompiled ${to.transition.level} anchor, not the result of one pass.`;
  const passName = to.transition?.passName || "recorded pass";
  const action = PASS_ACTIONS[passName] || "perform its recorded optimisation action";
  const noOp = to.transition?.noOp ? " No structural or value-level change was recorded." : "";
  return `${from.stateId} → ${to.stateId}: ${passName} — ${action}.${noOp}`;
}

function stateFor(side) {
  return appState.session.states.find((state) => state.ordinal === appState.panels[side].ordinal);
}

function renderPanel(side) {
  const panel = appState.panels[side];
  const controls = elements[side];
  const state = stateFor(side);
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
  description.textContent = `${panel.ir.stateId} · ${fn.name} · ${fn.blocks.length} basic blocks · ${instructionCount} instructions`;
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
  const columnCount = Math.min(3, Math.max(1, Math.ceil(Math.sqrt(cfg.blocks.length))));
  const cellWidth = 185;
  const cellHeight = 115;
  const width = Math.max(430, columnCount * cellWidth + 60);
  const rows = Math.ceil(cfg.blocks.length / columnCount);
  const height = Math.max(220, rows * cellHeight + 90);
  const positions = new Map(cfg.blocks.map((block, index) => [block.id, {
    x: 70 + (index % columnCount) * cellWidth,
    y: 65 + Math.floor(index / columnCount) * cellHeight,
  }]));
  const namespace = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(namespace, "svg");
  const markerId = `arrow-${side}`;
  svg.classList.add("cfg-svg");
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", `Control-flow graph for ${panel.function.name} in ${panel.ir.stateId}`);
  svg.innerHTML = `<defs><marker id="${markerId}" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 Z" fill="#60758a" /></marker></defs>`;
  cfg.edges.forEach((edge) => {
    const from = positions.get(edge.fromId);
    const to = positions.get(edge.toId);
    if (!from || !to) return;
    const line = document.createElementNS(namespace, "line");
    line.setAttribute("class", "cfg-edge");
    line.setAttribute("x1", String(from.x + 54));
    line.setAttribute("y1", String(from.y + 34));
    line.setAttribute("x2", String(to.x + 54));
    line.setAttribute("y2", String(to.y + 34));
    line.setAttribute("marker-end", `url(#${markerId})`);
    svg.append(line);
    if (edge.label) {
      const label = document.createElementNS(namespace, "text");
      label.setAttribute("class", "cfg-edge-label");
      label.setAttribute("x", String((from.x + to.x) / 2 + 54));
      label.setAttribute("y", String((from.y + to.y) / 2 + 27));
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
    rectangle.setAttribute("width", "108"); rectangle.setAttribute("height", "48"); rectangle.setAttribute("rx", "6");
    const label = document.createElementNS(namespace, "text");
    label.setAttribute("x", "54"); label.setAttribute("y", "29"); label.setAttribute("text-anchor", "middle");
    label.textContent = block.label;
    node.append(rectangle, label);
    svg.append(node);
  });
  viewer.append(svg);
}

function selectionClass(side, nodeId, baseClass) {
  if (!appState.panels[side].selectedNodeIds.has(nodeId)) return baseClass;
  return `${baseClass} ${appState.selection?.originSide === side ? "is-selected" : "is-linked"}`;
}

async function selectNode(originSide, nodeId) {
  const targetSide = originSide === "left" ? "right" : "left";
  const origin = appState.panels[originSide];
  const target = appState.panels[targetSide];
  clearSelection();
  origin.selectedNodeIds = new Set([nodeId]);
  const selected = nodeContext(origin.ir, nodeId);
  if (!selected) return;
  try {
    if (origin.ordinal === target.ordinal) {
      const targetIds = displayNodeIds(target, [nodeId]);
      target.selectedNodeIds = new Set(targetIds);
      appState.selection = {
        originSide,
        unresolved: false,
        text: `${formatNode(selected)} is selected in both views of ${stateFor(originSide).stateId}.`,
      };
    } else {
      const mapping = await request(`/api/counterparts?ordinal=${origin.ordinal}&nodeId=${encodeURIComponent(nodeId)}&toOrdinal=${target.ordinal}`);
      const targetIds = displayNodeIds(target, mapping.counterparts.map((counterpart) => counterpart.id));
      target.selectedNodeIds = new Set(targetIds);
      appState.selection = mappingStatus(originSide, selected, mapping, targetIds.length);
    }
    renderComparison();
    renderPanel(originSide);
    renderPanel(targetSide);
    if (target.selectedNodeIds.size) scrollToLinkedNode(targetSide);
  } catch (error) {
    appState.selection = { originSide, unresolved: true, text: `No cross-state mapping is available: ${error.message}` };
    renderComparison();
    renderPanel(originSide);
    renderPanel(targetSide);
  }
}

function mappingStatus(originSide, selected, mapping, displayedCount) {
  const targetState = stateFor(originSide === "left" ? "right" : "left");
  if (mapping.confidence === "none") {
    return { originSide, unresolved: true, text: `${formatNode(selected)} has no resolved counterpart in ${targetState.stateId}; matching completed without enough evidence to identify one.` };
  }
  if (!mapping.counterparts.length) {
    return { originSide, unresolved: true, text: `${formatNode(selected)} has no counterpart in ${targetState.stateId}: it is ${mapping.relation}.` };
  }
  const confidence = `${mapping.confidence} confidence`;
  const quantity = displayedCount === 1 ? "linked counterpart" : `${displayedCount} linked counterparts`;
  return { originSide, unresolved: false, text: `${formatNode(selected)} → ${quantity} in ${targetState.stateId} (${mapping.relation}; ${confidence}).` };
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

function scrollToLinkedNode(side) {
  requestAnimationFrame(() => {
    const node = elements[side].viewer.querySelector(".is-linked, .is-selected");
    node?.scrollIntoView({ block: "nearest", behavior: "smooth" });
  });
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

function highlightIr(text) {
  const escaped = escapeHtml(text);
  return escaped
    .replace(/(%[A-Za-z0-9._]+|@[-A-Za-z0-9._]+)/g, '<span class="token-value">$1</span>')
    .replace(/\b(alloca|store|load|br|ret|call|add|sub|mul|shl|icmp|define|tail)\b/g, '<span class="token-opcode">$1</span>')
    .replace(/\b(i1|i8|i16|i32|i64|ptr|void|label)\b/g, '<span class="token-keyword">$1</span>')
    .replace(/(?<![A-Za-z0-9_])-?\d+\b/g, '<span class="token-number">$&</span>');
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[character]);
}

elements.exampleSelect.addEventListener("change", loadExample);
elements.functionSelect.addEventListener("change", () => {
  appState.functionName = elements.functionSelect.value;
  clearSelection();
  refreshWorkspace();
});
for (const side of ["left", "right"]) {
  elements[side].state.addEventListener("change", () => {
    appState.panels[side].ordinal = Number(elements[side].state.value);
    clearSelection();
    refreshWorkspace();
  });
  elements[side].view.addEventListener("change", () => {
    appState.panels[side].viewType = elements[side].view.value;
    clearSelection();
    refreshWorkspace();
  });
}

loadExamples();
