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
  selectionId: 0,
  refreshId: 0,
  loadId: 0,
  ready: false,
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

async function loadExample() {
  const exampleId = elements.exampleSelect.value;
  if (!exampleId) return;
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
    appState.functionName = null;
    appState.panels.left.ordinal = 0;
    appState.panels.left.viewType = "ir";
    appState.panels.right.ordinal = Math.min(1, appState.states.length - 1);
    appState.panels.right.viewType = "ir";
    renderStateOptions();
    elements.left.view.value = "ir";
    elements.right.view.value = "ir";
    await refreshWorkspace();
    if (loadId !== appState.loadId || !appState.ready) return;
    elements.emptyState.hidden = true;
    elements.workspace.hidden = false;
    announce(`${exampleId} is ready. Configure either panel, then select an artefact to follow its recorded link.`);
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
  if (!appState.exampleId) return;
  const refreshId = ++appState.refreshId;
  appState.ready = false;
  appState.summary = null;
  renderSummary();
  ++appState.selectionId;
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
    applySourceHighlights();
    renderComparison();
    renderPanel("left");
    renderPanel("right");
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
  appState.selectionId += 1;
  appState.selection = null;
  for (const panel of Object.values(appState.panels)) panel.selectedNodeIds = new Set();
}

function selectionRequestIsCurrent(selectionRequest) {
  return selectionRequest.id === appState.selectionId
    && selectionRequest.exampleId === appState.exampleId
    && selectionRequest.originOrdinal === appState.panels[selectionRequest.originSide].ordinal
    && selectionRequest.targetOrdinal === appState.panels[selectionRequest.targetSide].ordinal;
}

function mappingMatchesSelectionRequest(mapping, selectionRequest) {
  return mapping.ordinal === selectionRequest.originOrdinal
    && mapping.nodeId === selectionRequest.nodeId
    && mapping.counterpartOrdinal === selectionRequest.targetOrdinal;
}

function renderComparison() {
  const leftState = stateFor("left");
  const rightState = stateFor("right");
  elements.comparisonAction.textContent = comparisonAction(leftState, rightState);
  const [from, to] = [leftState, rightState].sort((a, b) => a.ordinal - b.ordinal);
  document.querySelector("#pass-purpose").textContent = to.ordinal === from.ordinal + 1 && to.transition?.kind === "derived"
    ? `General pass purpose: ${PASS_ACTIONS[to.transition.passName] || "perform its recorded optimisation action"}. This describes the pass, not an observed outcome.` : "";
  const evidence = document.querySelector("#selection-evidence");
  evidence.hidden = !appState.selection?.evidence;
  evidence.querySelector("pre").textContent = appState.selection?.evidence || "";
  if (!appState.selection) {
    elements.selectionStatus.className = "selection-status";
    elements.selectionStatus.textContent = "Selection confidence: select an IR line or CFG block to follow its recorded link.";
    return;
  }
  elements.selectionStatus.className = `selection-status${appState.selection.unresolved ? " is-unresolved" : ""}`;
  elements.selectionStatus.textContent = `Selection: ${appState.selection.text}`;
}

function comparisonAction(leftState, rightState) {
  if (leftState.ordinal === rightState.ordinal) return `Both panels show ${leftState.stateId}; no cross-state action is being compared.`;
  const [from, to] = leftState.ordinal < rightState.ordinal ? [leftState, rightState] : [rightState, leftState];
  const direction = leftState.ordinal > rightState.ordinal ? " Earlier state is on the right; outcomes below follow timeline order." : "";
  if (to.transition?.kind === "recompiled") return `${from.stateId} → ${to.stateId}: separately compiled ${to.transition.level} output comparison${to.ordinal > from.ordinal + 1 ? ` across ${to.ordinal - from.ordinal} transitions` : ""}; not the result of one pass.${direction}`;
  if (to.ordinal !== from.ordinal + 1) return `${from.stateId} → ${to.stateId}: composed comparison across ${to.ordinal - from.ordinal} recorded transitions; no single pass is attributed.${direction}`;
  return `${from.stateId} → ${to.stateId}: pass ${to.ordinal}, ${to.transition?.passName}.${direction}`;
}

function stateFor(side) {
  return appState.states.find((state) => state.ordinal === appState.panels[side].ordinal);
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
  const nodeWidth = Math.max(160, ...cfg.blocks.map(block => block.label.length * 7 + 28));
  const nodeHeight = 48;
  const blockOrder = new Map(cfg.blocks.map((block, index) => [block.id, index]));
  const forward = cfg.edges.filter(edge => blockOrder.get(edge.toId) > blockOrder.get(edge.fromId));
  const backward = cfg.edges.filter(edge => blockOrder.get(edge.toId) <= blockOrder.get(edge.fromId));
  const nodeX = 35 + forward.length * 24;
  const width = nodeX + nodeWidth + 85 + backward.length * 24;
  const height = cfg.blocks.length * 150 + 40;
  const positions = new Map(cfg.blocks.map((block, index) => [block.id, {
    x: nodeX, y: 35 + index * 150,
  }]));
  const namespace = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(namespace, "svg");
  const markerId = `arrow-${side}`;
  svg.classList.add("cfg-svg");
  svg.style.width = `${width}px`;
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("role", "group");
  svg.setAttribute("aria-label", `Control-flow graph for ${panel.function.name} in ${panel.ir.stateId}`);
  svg.innerHTML = `<defs><marker id="${markerId}" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 Z" fill="#60758a" /></marker></defs>`;
  cfg.edges.forEach((edge) => {
    const from = positions.get(edge.fromId);
    const to = positions.get(edge.toId);
    if (!from || !to) return;
    const isForward = blockOrder.get(edge.toId) > blockOrder.get(edge.fromId);
    const laneIndex = (isForward ? forward : backward).indexOf(edge);
    const laneX = isForward ? nodeX - 24 * (laneIndex + 1) : nodeX + nodeWidth + 30 + 24 * laneIndex;
    const outgoing = cfg.edges.filter(e => e.fromId === edge.fromId);
    const incoming = cfg.edges.filter(e => e.toId === edge.toId);
    const startY = from.y + 8 + 30 * (outgoing.indexOf(edge) + 1) / (outgoing.length + 1);
    const endY = to.y + 8 + 30 * (incoming.indexOf(edge) + 1) / (incoming.length + 1);
    const startX = isForward ? from.x : from.x + nodeWidth;
    const endX = isForward ? to.x - 3 : to.x + nodeWidth + 3;
    const loop = edge.fromId === edge.toId;
    const path = document.createElementNS(namespace, "path");
    path.setAttribute("class", "cfg-edge");
    path.dataset.fromId = edge.fromId;
    path.dataset.toId = edge.toId;
    path.setAttribute("d", loop
      ? `M ${startX} ${from.y + 10} C ${laneX + 60} ${from.y - 45}, ${laneX + 60} ${from.y + 93}, ${endX} ${from.y + 38}`
      : `M ${startX} ${startY} H ${laneX} V ${endY} H ${endX}`);
    path.setAttribute("marker-end", `url(#${markerId})`);
    const title = document.createElementNS(namespace, "title");
    title.textContent = `${cfg.blocks.find(b => b.id === edge.fromId).label} → ${cfg.blocks.find(b => b.id === edge.toId).label}: ${edge.label || "unlabelled"}`;
    path.append(title);
    svg.append(path);
    if (edge.label) {
      const label = document.createElementNS(namespace, "text");
      const x = loop ? laneX + 35 : laneX - 5;
      const y = loop ? from.y + 24 : (startY + endY) / 2;
      label.setAttribute("class", "cfg-edge-label");
      label.setAttribute("transform", `translate(${x}, ${y}) rotate(-90)`);
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
    rectangle.setAttribute("width", String(nodeWidth)); rectangle.setAttribute("height", String(nodeHeight)); rectangle.setAttribute("rx", "6");
    const label = document.createElementNS(namespace, "text");
    label.setAttribute("x", String(nodeWidth / 2)); label.setAttribute("y", "29"); label.setAttribute("text-anchor", "middle");
    label.textContent = block.label;
    node.append(rectangle, label);
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

async function selectNode(originSide, nodeId) {
  if (!appState.ready) return;
  const targetSide = originSide === "left" ? "right" : "left";
  const origin = appState.panels[originSide];
  const target = appState.panels[targetSide];
  clearSelection();
  const selectionRequest = {
    id: appState.selectionId,
    exampleId: appState.exampleId,
    originSide,
    targetSide,
    originOrdinal: origin.ordinal,
    targetOrdinal: target.ordinal,
    nodeId,
  };
  origin.selectedNodeIds = new Set([nodeId]);
  const selected = nodeContext(origin.ir, nodeId);
  if (!selected) return;
  revealNodeSource(originSide, nodeId);
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
      const mapping = await request(`${apiRoot(selectionRequest.exampleId)}/states/${selectionRequest.originOrdinal}/counterparts?nodeId=${encodeURIComponent(nodeId)}&toOrdinal=${selectionRequest.targetOrdinal}`);
      if (!selectionRequestIsCurrent(selectionRequest)) return;
      if (!mappingMatchesSelectionRequest(mapping, selectionRequest)) {
        throw new Error("The counterpart response did not match the current selection.");
      }
      const targetIds = displayNodeIds(target, mapping.counterparts.map((counterpart) => counterpart.id));
      target.selectedNodeIds = new Set(targetIds);
      appState.selection = mappingStatus(originSide, selected, mapping, targetIds.length);
      appState.selection.evidence = JSON.stringify(mapping, null, 2);
    }
    renderComparison();
    renderPanel(originSide);
    renderPanel(targetSide);
    elements[originSide].viewer.querySelector(`[data-node-id="${CSS.escape(nodeId)}"]`)?.focus({ preventScroll: true });
    if (target.selectedNodeIds.size) scrollToLinkedNode(targetSide);
  } catch (error) {
    if (!selectionRequestIsCurrent(selectionRequest)) return;
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
    scrollWithin(elements[side].viewer, node);
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
