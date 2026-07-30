const appState = {
  session: null,
  ir: null,
  cfg: null,
  source: null,
  selectedFunctionId: null,
  selectedBlockId: null,
  selectedInstructionId: null,
  currentOrdinal: 0,
  comparisonFromOrdinal: 0,
  comparisonToOrdinal: 1,
  showNoOpStates: false,
  irScope: "function",
  irFilter: "",
  cfgNeighbourhood: false,
};

const PASS_ROLES = Object.freeze({
  mem2reg: "Turn eligible local stack variables into SSA values.",
  instcombine: "Simplify individual instruction forms.",
  simplifycfg: "Simplify branches and basic-block structure.",
  gvn: "Reuse computations already known to have the same value.",
  "instcombine,simplifycfg": "Apply a cleanup of instruction forms and control flow.",
  "loop-simplify,lcssa": "Put loops into a more regular form for later passes.",
  "loop-rotate": "Reshape loop control flow when doing so is safe.",
  licm: "Move loop-invariant work out of loops when it is safe.",
  indvars: "Simplify loop induction variables.",
  "loop-vectorize": "Attempt safe vectorisation of loop work.",
});

const elements = {
  exampleSelect: document.querySelector("#example-select"),
  loadButton: document.querySelector("#load-example"),
  notice: document.querySelector("#notice"),
  emptyState: document.querySelector("#empty-state"),
  explorer: document.querySelector("#explorer"),
  previousState: document.querySelector("#previous-state"),
  nextState: document.querySelector("#next-state"),
  guidedTimeline: document.querySelector("#guided-timeline"),
  fullPipeline: document.querySelector("#full-pipeline"),
  navigationTree: document.querySelector("#navigation-tree"),
  irDescription: document.querySelector("#ir-description"),
  irView: document.querySelector("#ir-view"),
  cfgDescription: document.querySelector("#cfg-description"),
  cfgView: document.querySelector("#cfg-view"),
  sourceDescription: document.querySelector("#source-description"),
  sourceView: document.querySelector("#source-view"),
  coordinationView: document.querySelector("#coordination-view"),
  storyHeading: document.querySelector("#story-heading"),
  passRole: document.querySelector("#pass-role"),
  compareBaseline: document.querySelector("#compare-baseline"),
  summaryContext: document.querySelector("#summary-context"),
  storyOutcomes: document.querySelector("#story-outcomes"),
  summaryItems: document.querySelector("#summary-items"),
  summaryDetail: document.querySelector("#summary-detail"),
  debugToggle: document.querySelector("#debug-toggle"),
  irScope: document.querySelector("#ir-scope"),
  irFilter: document.querySelector("#ir-filter"),
  clearIrFilter: document.querySelector("#clear-ir-filter"),
  irResultCount: document.querySelector("#ir-result-count"),
  cfgNeighbourhood: document.querySelector("#cfg-neighbourhood"),
  invalidRequest: document.querySelector("#invalid-request"),
};

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(body.error || `Request failed with status ${response.status}.`);
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
  elements.explorer.hidden = true;
  announce(`Error: ${error.message}`, "error");
}

function clearErrorOrEmpty() {
  if (elements.emptyState.classList.contains("error-state")) {
    const empty = document.createElement("section");
    empty.id = "empty-state";
    empty.className = "empty-state panel";
    empty.innerHTML = "<p class=\"eyebrow\">Start exploring</p><h2>Choose an example to inspect its optimisation timeline.</h2><p>The baseline and optimised outputs are preserved compiler artefacts. Select a state, function, or basic block to focus the views.</p>";
    elements.emptyState.replaceWith(empty);
    elements.emptyState = empty;
  }
}

function selectedOrdinal() {
  return appState.currentOrdinal;
}

async function loadExamples() {
  try {
    const { examples } = await request("/api/examples");
    elements.exampleSelect.replaceChildren(...examples.map((exampleId) => {
      const option = document.createElement("option");
      option.value = exampleId;
      option.textContent = exampleId.replaceAll("_", " ");
      return option;
    }));
    elements.exampleSelect.disabled = false;
    elements.loadButton.disabled = false;
    announce("Choose a curated example, then load its comparison.");
  } catch (error) {
    showError(error);
  }
}

async function loadExample() {
  const exampleId = elements.exampleSelect.value;
  elements.loadButton.disabled = true;
  announce(`Loading ${exampleId}…`);
  try {
    appState.session = await request("/api/session", {
      method: "POST",
      body: JSON.stringify({ exampleId }),
    });
    appState.showNoOpStates = false;
    appState.irScope = "function";
    appState.irFilter = "";
    appState.cfgNeighbourhood = false;
    elements.irScope.value = appState.irScope;
    elements.irFilter.value = appState.irFilter;
    elements.cfgNeighbourhood.checked = appState.cfgNeighbourhood;
    elements.fullPipeline.open = false;
    const stateLoaded = await renderState(0);
    if (!stateLoaded) return;
    elements.emptyState.hidden = true;
    elements.explorer.hidden = false;
    announce(`${exampleId} is ready. Use the state and navigation controls to explore it.`);
  } catch (error) {
    showError(error);
  } finally {
    elements.loadButton.disabled = false;
  }
}

async function renderState(ordinal, focusedNodeId = null) {
  if (!appState.session) return;
  const state = appState.session.states.find((candidate) => candidate.ordinal === ordinal);
  announce(`Loading ${state.stateId}…`);
  try {
    const [ir, source] = await Promise.all([
      request(`/api/ir?ordinal=${ordinal}`),
      request(`/api/source?ordinal=${ordinal}`),
    ]);
    const focusContext = focusedNodeId ? irContext(ir, focusedNodeId) : null;
    const currentFunction = focusContext?.function
      || ir.functions.find((item) => item.id === appState.selectedFunctionId)
      || ir.functions[0];
    appState.ir = ir;
    appState.source = source;
    if (!focusContext && appState.selectedInstructionId && !irContext(ir, appState.selectedInstructionId)) {
      appState.selectedInstructionId = null;
    }
    appState.selectedFunctionId = currentFunction?.id ?? null;
    const functionBlocks = currentFunction?.blocks || [];
    if (focusContext?.block) {
      appState.selectedBlockId = focusContext.block.id;
      appState.selectedInstructionId = focusContext.instruction?.id ?? null;
    } else if (!functionBlocks.some((block) => block.id === appState.selectedBlockId)) {
      appState.selectedBlockId = functionBlocks[0]?.id ?? null;
      appState.selectedInstructionId = null;
    }
    appState.cfg = currentFunction
      ? await request(`/api/cfg?ordinal=${ordinal}&functionId=${encodeURIComponent(currentFunction.id)}`)
      : null;
    const focusedId = focusedNodeId || appState.selectedInstructionId || appState.selectedBlockId;
    await request("/api/focus", {
      method: "POST",
      body: JSON.stringify({ ordinal, nodeId: focusedId }),
    });
    appState.currentOrdinal = ordinal;
    const storyStates = meaningfulTimelineStates();
    const storyIndex = storyStates.findIndex((candidate) => candidate.ordinal === ordinal);
    appState.comparisonFromOrdinal = ordinal === 0
      ? 0
      : storyStates[Math.max(0, storyIndex - 1)].ordinal;
    appState.comparisonToOrdinal = ordinal === 0
      ? storyStates[1]?.ordinal ?? 0
      : ordinal;
    renderTimeline();
    renderNavigation();
    renderIr();
    renderCfg();
    renderSource();
    await renderComparison();
    await renderCoordination();
    announce(`Showing ${state.stateId}.`);
    return true;
  } catch (error) {
    showError(error);
    return false;
  }
}

function meaningfulTimelineStates() {
  return appState.session.states.filter((state) => (
    state.ordinal === 0 || appState.showNoOpStates || !state.transition?.noOp
  ));
}

function renderTimeline() {
  const states = appState.session.states;
  const ordinal = appState.currentOrdinal;
  const noOpCount = states.filter((state) => state.transition?.noOp).length;
  const visibleStates = meaningfulTimelineStates();
  const visibleIndex = visibleStates.findIndex((state) => state.ordinal === ordinal);
  elements.previousState.disabled = visibleIndex <= 0;
  elements.nextState.disabled = visibleIndex === -1 || visibleIndex === visibleStates.length - 1;
  elements.fullPipeline.hidden = noOpCount === 0;
  elements.guidedTimeline.replaceChildren(...visibleStates.map((state) => {
    const item = document.createElement("li");
    const button = document.createElement("button");
    const transition = state.transition;
    button.type = "button";
    button.className = `timeline-marker${state.ordinal === ordinal ? " is-current" : ""}${transition?.noOp ? " is-noop" : ""}${transition?.kind === "recompiled" ? " is-anchor" : ""}`;
    button.textContent = state.stateId;
    button.title = stateLabel(state);
    button.setAttribute("aria-current", String(state.ordinal === ordinal));
    button.setAttribute("aria-label", `${state.stateId}: ${stateLabel(state)}`);
    button.addEventListener("click", () => renderState(state.ordinal));
    item.append(button);
    return item;
  }));
}

function stateLabel(state) {
  if (state.ordinal === 0) return "Unoptimised baseline";
  if (state.transition.kind === "recompiled") return `Recompiled ${state.transition.level} anchor`;
  const remarkLabel = state.transition.remarkCount
    ? ` · ${state.transition.remarkCount} ${state.transition.remarkCount === 1 ? "remark" : "remarks"}`
    : "";
  if (state.transition.noOp) return `No change · ${state.transition.passName}${remarkLabel}`;
  return `${state.transition.passName}${remarkLabel}`;
}

async function renderComparison() {
  const fromOrdinal = appState.comparisonFromOrdinal;
  const toOrdinal = appState.comparisonToOrdinal;
  const from = appState.session.states.find((state) => state.ordinal === fromOrdinal);
  const to = appState.session.states.find((state) => state.ordinal === toOrdinal);
  if (!from || !to) return;
  const summary = await request(`/api/summary?fromOrdinal=${fromOrdinal}&toOrdinal=${toOrdinal}`);
  elements.storyHeading.textContent = `What changed from ${from.stateId} to ${to.stateId}?`;
  elements.passRole.textContent = `Pass role: ${passRole(to)} Recorded outcomes below are specific to this curated example.`;
  elements.summaryContext.classList.toggle("is-anchor", to.transition?.kind === "recompiled");
  elements.compareBaseline.disabled = toOrdinal === 0 || fromOrdinal === 0;
  elements.compareBaseline.textContent = toOrdinal === 0
    ? "Choose a later state to compare with the baseline"
    : `Compare baseline to ${to.stateId}`;
  renderSummary(summary);
}

function renderSummary(summary) {
  elements.summaryContext.textContent = summary.context;
  const primaryItems = summary.items.slice(0, 3);
  elements.storyOutcomes.replaceChildren(...primaryItems.map(renderSummaryItem));
  elements.summaryDetail.hidden = summary.items.length <= primaryItems.length;
  elements.summaryItems.replaceChildren(...summary.items.map(renderSummaryItem));
}

function renderSummaryItem(item) {
    const listItem = document.createElement("li");
    const claim = document.createElement("span");
    claim.textContent = item.text;
    listItem.append(claim);
    if (item.evidence?.length) {
      const evidence = document.createElement("details");
      evidence.className = "summary-evidence";
      const label = document.createElement("summary");
      const linkCount = item.evidence.filter((entry) => entry.type === "link").length;
      const remarkCount = item.evidence.filter((entry) => entry.type === "remark").length;
      const parts = [];
      if (linkCount) parts.push(`${linkCount} ${linkCount === 1 ? "correspondence link" : "correspondence links"}`);
      if (remarkCount) parts.push(`${remarkCount} ${remarkCount === 1 ? "pass remark" : "pass remarks"}`);
      label.textContent = `Evidence: ${parts.join(" · ")}`;
      const list = document.createElement("div");
      list.className = "summary-evidence-list";
      item.evidence.forEach((entry) => list.append(renderSummaryEvidence(entry)));
      evidence.append(label, list);
      listItem.append(evidence);
    }
    return listItem;
}

function passRole(state) {
  if (state.ordinal === 0) return "This is the unoptimised starting point.";
  if (state.transition?.kind === "recompiled") {
    return "This is a separately compiled -O3 output anchor, not the result of one pass.";
  }
  return PASS_ROLES[state.transition?.passName]
    || "This recorded pass has a specialised role in the configured optimisation pipeline.";
}

function renderSummaryEvidence(entry) {
  const item = document.createElement("article");
  item.className = `summary-evidence-item is-${entry.type}`;
  if (entry.type === "link") {
    const title = document.createElement("strong");
    title.textContent = `Link ${entry.index + 1}: ${entry.relation} (${entry.confidence})`;
    const endpoints = document.createElement("p");
    endpoints.textContent = `${formatEvidenceNodes(entry.from)} → ${formatEvidenceNodes(entry.to)}`;
    item.append(title, endpoints);
    if (entry.evidence) {
      const detail = document.createElement("p");
      detail.className = "muted";
      detail.textContent = entry.evidence;
      item.append(detail);
    }
    return item;
  }

  const title = document.createElement("strong");
  title.textContent = `Pass remark ${entry.index + 1}: ${entry.passName || "unnamed pass"} · ${entry.name || "unnamed remark"}`;
  const detail = document.createElement("p");
  const location = entry.location ? ` at ${entry.location.file}:${entry.location.line}:${entry.location.column}` : "";
  const mapped = entry.instructionIds?.length
    ? ` Mapped to ${entry.instructionIds.join(", ")}.`
    : " No IR instruction shares its recorded debug location.";
  detail.textContent = `${entry.function ? `Function ${entry.function}` : "No function recorded"}${location}.${mapped}`;
  const raw = document.createElement("pre");
  raw.textContent = entry.raw;
  item.append(title, detail, raw);
  return item;
}

function formatEvidenceNodes(nodes) {
  if (!nodes?.length) return "∅";
  return nodes.map((node) => `${node.kind} ${node.displayName} (${node.id})`).join(", ");
}

function renderNavigation() {
  elements.navigationTree.replaceChildren(...appState.ir.functions.map((fn) => {
    const group = document.createElement("div");
    group.className = "function-group";
    group.append(navigationButton(fn.name, "function-button", fn.id === appState.selectedFunctionId, async () => {
      appState.selectedFunctionId = fn.id;
      appState.selectedBlockId = fn.blocks[0]?.id ?? null;
      appState.selectedInstructionId = null;
      await renderState(selectedOrdinal());
    }));
    fn.blocks.forEach((block) => group.append(navigationButton(
      block.label,
      "block-button",
      block.id === appState.selectedBlockId,
      async () => {
        appState.selectedFunctionId = fn.id;
        appState.selectedBlockId = block.id;
        appState.selectedInstructionId = null;
        await request("/api/focus", {
          method: "POST",
          body: JSON.stringify({ ordinal: selectedOrdinal(), nodeId: block.id }),
        });
        renderNavigation();
        renderIr();
        renderCfg();
        renderSource();
        await renderCoordination();
        announce(`Focused basic block ${block.label}.`);
      },
    )));
    return group;
  }));
}

function navigationButton(name, className, isCurrent, onClick) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = `nav-button ${className}`;
  button.textContent = name;
  button.setAttribute("aria-current", String(isCurrent));
  button.addEventListener("click", onClick);
  return button;
}

function renderIr() {
  const fn = appState.ir.functions.find((candidate) => candidate.id === appState.selectedFunctionId);
  const showDebug = elements.debugToggle.checked;
  const filter = appState.irFilter.trim().toLocaleLowerCase();
  const totalInstructions = fn.blocks.reduce(
    (count, block) => count + block.instructions.length,
    0,
  );
  const visibleBlocks = [];
  let lineNumber = 1;
  fn.blocks.forEach((block) => {
    const indexedInstructions = block.instructions.map((instruction) => ({
      instruction,
      lineNumber: lineNumber++,
    }));
    if (appState.irScope === "block" && block.id !== appState.selectedBlockId) return;
    const instructions = filter
      ? indexedInstructions.filter(({ instruction }) => instructionMatchesFilter(instruction, filter))
      : indexedInstructions;
    if (instructions.length) visibleBlocks.push({ block, instructions });
  });
  const visibleInstructions = visibleBlocks.reduce(
    (count, item) => count + item.instructions.length,
    0,
  );
  const selectedInstructionVisible = visibleBlocks.some(({ instructions }) => (
    instructions.some(({ instruction }) => instruction.id === appState.selectedInstructionId)
  ));
  const scopeLabel = appState.irScope === "block" ? "selected block" : "selected function";
  const hiddenSelection = appState.selectedInstructionId && !selectedInstructionVisible
    ? " · selected instruction is outside this display scope"
    : "";
  elements.irDescription.textContent = `${appState.ir.stateId} · ${fn.name} · ${visibleBlocks.length} of ${fn.blocks.length} basic blocks · ${visibleInstructions} of ${totalInstructions} instructions shown (${scopeLabel})${hiddenSelection}`;
  elements.irResultCount.textContent = filter
    ? `${visibleInstructions} matching instruction${visibleInstructions === 1 ? "" : "s"}`
    : `${visibleInstructions} instruction${visibleInstructions === 1 ? "" : "s"} shown`;
  elements.clearIrFilter.disabled = !filter;
  elements.irView.replaceChildren();
  const signature = document.createElement("code");
  signature.className = "ir-signature";
  signature.innerHTML = highlightIr(stripDebug(fn.signature, showDebug));
  elements.irView.append(signature);
  if (!visibleBlocks.length) {
    const empty = document.createElement("p");
    empty.className = "filtered-empty";
    empty.textContent = filter
      ? "No instructions in this scope match the filter. Clear it or choose the selected function scope."
      : "The selected block has no instructions to display.";
    elements.irView.append(empty);
    return;
  }
  visibleBlocks.forEach(({ block, instructions }) => {
    const blockElement = document.createElement("section");
    blockElement.className = `ir-block${block.id === appState.selectedBlockId ? " is-selected" : ""}`;
    blockElement.id = `ir-${block.id.replaceAll("/", "-")}`;
    blockElement.setAttribute("aria-current", String(block.id === appState.selectedBlockId));
    blockElement.innerHTML = `<div class="ir-block-heading">${escapeHtml(block.label)}:</div>`;
    instructions.forEach(({ instruction, lineNumber: instructionLineNumber }) => {
      const line = document.createElement("div");
      line.className = `ir-line${instruction.id === appState.selectedInstructionId ? " is-selected" : ""}${instruction.source ? " is-source-mapped" : ""}`;
      line.setAttribute("role", "button");
      line.setAttribute("tabindex", "0");
      line.setAttribute("aria-label", `Select IR instruction ${instruction.opcode}`);
      line.setAttribute("aria-pressed", String(instruction.id === appState.selectedInstructionId));
      line.innerHTML = `<span class="line-number">${instructionLineNumber}</span><code>${highlightIr(stripDebug(instruction.text, showDebug))}</code>`;
      const select = () => selectInstruction(instruction, block, fn);
      line.addEventListener("click", select);
      line.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          select();
        }
      });
      blockElement.append(line);
    });
    elements.irView.append(blockElement);
  });
}

function instructionMatchesFilter(instruction, filter) {
  return [
    instruction.text,
    instruction.opcode,
    instruction.result,
    instruction.source && `${instruction.source.file}:${instruction.source.line}`,
  ]
    .filter(Boolean)
    .join(" ")
    .toLocaleLowerCase()
    .includes(filter);
}

function irContext(ir, nodeId) {
  for (const fn of ir.functions) {
    if (fn.id === nodeId) return { function: fn, block: null, instruction: null };
    for (const block of fn.blocks) {
      if (block.id === nodeId) return { function: fn, block, instruction: null };
      const instruction = block.instructions.find((item) => item.id === nodeId);
      if (instruction) return { function: fn, block, instruction };
    }
  }
  return null;
}

async function selectInstruction(instruction, block, fn) {
  appState.selectedFunctionId = fn.id;
  appState.selectedBlockId = block.id;
  appState.selectedInstructionId = instruction.id;
  try {
    await request("/api/focus", {
      method: "POST",
      body: JSON.stringify({ ordinal: selectedOrdinal(), nodeId: instruction.id }),
    });
    renderNavigation();
    renderIr();
    renderCfg();
    renderSource();
    await renderCoordination();
    announce(`Selected ${instruction.opcode}; mapped locations are shown where recorded.`);
  } catch (error) {
    showError(error);
  }
}

function selectedInstruction() {
  if (!appState.selectedInstructionId) return null;
  return irContext(appState.ir, appState.selectedInstructionId)?.instruction || null;
}

function selectedNode() {
  const instruction = selectedInstruction();
  if (instruction) return instruction;
  if (!appState.selectedBlockId) return null;
  return { id: appState.selectedBlockId, kind: "BasicBlock", displayName: appState.selectedBlockId };
}

function renderSource() {
  const instruction = selectedInstruction();
  const source = appState.source;
  elements.sourceView.replaceChildren();
  if (!source) {
    elements.sourceDescription.textContent = "Source is unavailable for this state.";
    return;
  }
  elements.sourceDescription.textContent = instruction?.source
    ? `${source.filename}:${instruction.source.line}:${instruction.source.column} is the recorded debug anchor for the selected instruction.`
    : "Select an IR instruction with a recorded debug location to highlight its source anchor.";
  elements.sourceView.replaceChildren(...source.lines.map((line) => {
    const button = document.createElement("button");
    const isSelected = instruction?.source?.line === line.number;
    const isMapped = line.instructionIds.length > 0;
    button.type = "button";
    button.className = `source-line${isSelected ? " is-selected" : ""}${isMapped ? " is-mapped" : ""}`;
    button.disabled = !isMapped;
    button.setAttribute(
      "aria-label",
      isMapped
        ? `Source line ${line.number}; select one of ${line.instructionIds.length} mapped IR instructions`
        : `Source line ${line.number}; no recorded IR mapping`,
    );
    if (isMapped) button.setAttribute("aria-pressed", String(isSelected));
    button.innerHTML = `<span class="line-number">${line.number}</span><code>${escapeHtml(line.text) || " "}</code>`;
    if (isMapped) {
      button.addEventListener("click", () => focusSourceLine(line));
    }
    return button;
  }));
}

async function focusSourceLine(line) {
  const preferredId = line.instructionIds.includes(appState.selectedInstructionId)
    ? appState.selectedInstructionId
    : line.instructionIds[0];
  const context = irContext(appState.ir, preferredId);
  if (!context?.instruction || !context.block || !context.function) return;
  await selectInstruction(context.instruction, context.block, context.function);
}

async function renderCoordination() {
  const node = selectedNode();
  elements.coordinationView.replaceChildren();
  if (!node) {
    elements.coordinationView.textContent = "Select an IR instruction or basic block to inspect recorded links.";
    return;
  }

  const selected = document.createElement("p");
  selected.className = "mapping-selection";
  selected.textContent = node.kind === "Instruction"
    ? `Selected IR instruction: ${node.opcode}.`
    : "Selected basic block: highlighted in both the IR and CFG views.";
  elements.coordinationView.append(selected);

  const instruction = selectedInstruction();
  const sourceStatus = document.createElement("p");
  sourceStatus.className = "mapping-source";
  sourceStatus.textContent = instruction?.source
    ? `Source mapping: ${appState.source.filename}:${instruction.source.line}:${instruction.source.column}.`
    : node.kind === "Instruction"
      ? "No debug source location is recorded for this instruction."
      : "Basic blocks have no direct source location; select an instruction to inspect a source anchor.";
  elements.coordinationView.append(sourceStatus);

  const counterpartOrdinal = counterpartTargetOrdinal();
  if (counterpartOrdinal === null) return;
  try {
    const mapping = await request(
      `/api/counterparts?ordinal=${selectedOrdinal()}&nodeId=${encodeURIComponent(node.id)}&toOrdinal=${counterpartOrdinal}`,
    );
    renderCounterpartMapping(mapping);
  } catch (error) {
    const unavailable = document.createElement("p");
    unavailable.className = "mapping-status is-absent";
    unavailable.textContent = `No cross-state mapping is available: ${error.message}`;
    elements.coordinationView.append(unavailable);
  }
}

function counterpartTargetOrdinal() {
  if (appState.currentOrdinal === appState.comparisonFromOrdinal) return appState.comparisonToOrdinal;
  if (appState.currentOrdinal === appState.comparisonToOrdinal) return appState.comparisonFromOrdinal;
  return null;
}

function renderCounterpartMapping(mapping) {
  const status = document.createElement("p");
  const confidence = mapping.confidence;
  status.className = `mapping-status is-${confidence}`;
  if (confidence === "none") {
    status.textContent = "Cross-state counterpart is unresolved; matching completed without enough evidence to identify one.";
  } else if (mapping.counterparts.length === 0) {
    status.className = "mapping-status is-absent";
    status.textContent = `No counterpart exists in state ${mapping.counterpartOrdinal}: this node is ${mapping.relation}.`;
  } else {
    status.textContent = `Mapped counterpart${mapping.counterparts.length === 1 ? "" : "s"} in state ${mapping.counterpartOrdinal} (${confidence} confidence; ${mapping.relation}).`;
  }
  elements.coordinationView.append(status);

  if (mapping.evidence) {
    const evidence = document.createElement("p");
    evidence.className = "mapping-evidence";
    evidence.textContent = `Evidence: ${mapping.evidence}`;
    elements.coordinationView.append(evidence);
  }
  if (!mapping.counterparts.length || mapping.confidence === "none") return;

  const counterparts = document.createElement("div");
  counterparts.className = "counterpart-actions";
  mapping.counterparts.forEach((counterpart) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "quiet-button";
    button.textContent = `View ${counterpart.displayName} in state ${mapping.counterpartOrdinal}`;
    button.addEventListener("click", () => renderState(mapping.counterpartOrdinal, counterpart.id));
    counterparts.append(button);
  });
  elements.coordinationView.append(counterparts);
}

function stripDebug(text, showDebug) {
  if (showDebug) return text;
  return text.replace(/,?\s*!dbg\s*!\d+/g, "");
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

function renderCfg() {
  const cfg = appState.cfg;
  const fn = appState.ir.functions.find((candidate) => candidate.id === appState.selectedFunctionId);
  elements.cfgView.replaceChildren();
  if (!cfg || cfg.blocks.length === 0) {
    elements.cfgDescription.textContent = "No control-flow graph is available for this function.";
    elements.cfgView.innerHTML = '<p class="cfg-empty">No control-flow graph is available for this function.</p>';
    return;
  }
  const focusedBlockIds = new Set([appState.selectedBlockId]);
  if (appState.cfgNeighbourhood) {
    cfg.edges.forEach((edge) => {
      if (edge.fromId === appState.selectedBlockId) focusedBlockIds.add(edge.toId);
      if (edge.toId === appState.selectedBlockId) focusedBlockIds.add(edge.fromId);
    });
  }
  const blocks = appState.cfgNeighbourhood
    ? cfg.blocks.filter((block) => focusedBlockIds.has(block.id))
    : cfg.blocks;
  const blockIds = new Set(blocks.map((block) => block.id));
  const edges = cfg.edges.filter((edge) => blockIds.has(edge.fromId) && blockIds.has(edge.toId));
  elements.cfgDescription.textContent = `${appState.ir.stateId} · ${fn.name} · ${blocks.length} of ${cfg.blocks.length} basic blocks shown · edges are labelled from the API CFG response${appState.cfgNeighbourhood ? " · selected block and direct neighbours" : ""}`;
  const columnCount = Math.min(3, Math.max(1, Math.ceil(Math.sqrt(blocks.length))));
  const cellWidth = 185;
  const cellHeight = 115;
  const width = Math.max(430, columnCount * cellWidth + 60);
  const rows = Math.ceil(blocks.length / columnCount);
  const height = Math.max(220, rows * cellHeight + 90);
  const positions = new Map(blocks.map((block, index) => [block.id, {
    x: 70 + (index % columnCount) * cellWidth,
    y: 65 + Math.floor(index / columnCount) * cellHeight,
  }]));
  const namespace = "http://www.w3.org/2000/svg";
  const svg = document.createElementNS(namespace, "svg");
  svg.classList.add("cfg-svg");
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", `Control-flow graph for ${fn.name}`);
  svg.innerHTML = '<defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 Z" fill="#60758a" /></marker></defs>';
  edges.forEach((edge) => {
    const from = positions.get(edge.fromId);
    const to = positions.get(edge.toId);
    if (!from || !to) return;
    const line = document.createElementNS(namespace, "line");
    line.setAttribute("class", "cfg-edge");
    line.setAttribute("x1", String(from.x + 54));
    line.setAttribute("y1", String(from.y + 34));
    line.setAttribute("x2", String(to.x + 54));
    line.setAttribute("y2", String(to.y + 34));
    line.setAttribute("marker-end", "url(#arrow)");
    svg.append(line);
    const label = document.createElementNS(namespace, "text");
    label.setAttribute("class", "cfg-edge-label");
    label.setAttribute("x", String((from.x + to.x) / 2 + 54));
    label.setAttribute("y", String((from.y + to.y) / 2 + 27));
    label.setAttribute("text-anchor", "middle");
    label.textContent = edge.label;
    svg.append(label);
  });
  blocks.forEach((block) => {
    const point = positions.get(block.id);
    const node = document.createElementNS(namespace, "g");
    node.setAttribute("class", `cfg-node${block.id === appState.selectedBlockId ? " is-selected" : ""}`);
    node.setAttribute("transform", `translate(${point.x}, ${point.y})`);
    node.setAttribute("role", "button");
    node.setAttribute("tabindex", "0");
    node.setAttribute("aria-label", `Focus basic block ${block.label}`);
    node.setAttribute("aria-pressed", String(block.id === appState.selectedBlockId));
    const focusBlock = async () => {
      appState.selectedBlockId = block.id;
      appState.selectedInstructionId = null;
      try {
        await request("/api/focus", {
          method: "POST",
          body: JSON.stringify({ ordinal: selectedOrdinal(), nodeId: block.id }),
        });
      } catch (error) {
        showError(error);
        return;
      }
      renderNavigation();
      renderIr();
      renderCfg();
      renderSource();
      await renderCoordination();
      announce(`Focused basic block ${block.label}.`);
      document.querySelector(`#ir-${block.id.replaceAll("/", "-")}`)?.scrollIntoView({ block: "nearest" });
    };
    node.addEventListener("click", focusBlock);
    node.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") { event.preventDefault(); focusBlock(); }
    });
    const rectangle = document.createElementNS(namespace, "rect");
    rectangle.setAttribute("width", "108"); rectangle.setAttribute("height", "48"); rectangle.setAttribute("rx", "6");
    const label = document.createElementNS(namespace, "text");
    label.setAttribute("x", "54"); label.setAttribute("y", "29"); label.setAttribute("text-anchor", "middle");
    label.textContent = block.label;
    node.append(rectangle, label);
    svg.append(node);
  });
  elements.cfgView.append(svg);
}

elements.loadButton.addEventListener("click", loadExample);
elements.debugToggle.addEventListener("change", renderIr);
elements.irScope.addEventListener("change", () => {
  appState.irScope = elements.irScope.value;
  renderIr();
});
elements.irFilter.addEventListener("input", () => {
  appState.irFilter = elements.irFilter.value;
  renderIr();
});
elements.clearIrFilter.addEventListener("click", () => {
  appState.irFilter = "";
  elements.irFilter.value = "";
  renderIr();
  elements.irFilter.focus();
});
elements.cfgNeighbourhood.addEventListener("change", () => {
  appState.cfgNeighbourhood = elements.cfgNeighbourhood.checked;
  renderCfg();
});
elements.previousState.addEventListener("click", () => {
  const states = meaningfulTimelineStates();
  const index = states.findIndex((state) => state.ordinal === appState.currentOrdinal);
  if (index > 0) renderState(states[index - 1].ordinal);
});
elements.nextState.addEventListener("click", () => {
  const states = meaningfulTimelineStates();
  const index = states.findIndex((state) => state.ordinal === appState.currentOrdinal);
  if (index !== -1 && index < states.length - 1) renderState(states[index + 1].ordinal);
});
elements.fullPipeline.addEventListener("toggle", () => {
  appState.showNoOpStates = elements.fullPipeline.open;
  const current = appState.session?.states[appState.currentOrdinal];
  if (!appState.showNoOpStates && current?.transition?.noOp) {
    const precedingChange = appState.session.states
      .slice(0, current.ordinal)
      .reverse()
      .find((state) => state.ordinal === 0 || !state.transition?.noOp);
    if (precedingChange) {
      renderState(precedingChange.ordinal);
      return;
    }
  }
  renderTimeline();
});
elements.compareBaseline.addEventListener("click", async () => {
  if (!appState.session || appState.comparisonToOrdinal === 0) return;
  appState.comparisonFromOrdinal = 0;
  try {
    await renderComparison();
    announce(`Comparing the baseline with ${appState.session.states[appState.comparisonToOrdinal].stateId}.`);
  } catch (error) {
    showError(error);
  }
});
elements.invalidRequest.addEventListener("click", async () => {
  try {
    await request("/api/cfg?ordinal=0&functionId=missing");
  } catch (error) {
    showError(error);
  }
});

loadExamples();
