const appState = {
  session: null,
  ir: null,
  cfg: null,
  selectedFunctionId: null,
  selectedBlockId: null,
};

const elements = {
  exampleSelect: document.querySelector("#example-select"),
  loadButton: document.querySelector("#load-example"),
  notice: document.querySelector("#notice"),
  emptyState: document.querySelector("#empty-state"),
  explorer: document.querySelector("#explorer"),
  stateOptions: document.querySelector("#state-options"),
  navigationTree: document.querySelector("#navigation-tree"),
  irDescription: document.querySelector("#ir-description"),
  irView: document.querySelector("#ir-view"),
  cfgDescription: document.querySelector("#cfg-description"),
  cfgView: document.querySelector("#cfg-view"),
  summaryContext: document.querySelector("#summary-context"),
  summaryItems: document.querySelector("#summary-items"),
  debugToggle: document.querySelector("#debug-toggle"),
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
    empty.innerHTML = "<p class=\"eyebrow\">Start exploring</p><h2>Choose an example to inspect its two optimisation states.</h2><p>The baseline and optimised outputs are preserved compiler artefacts. Select a state, function, or basic block to focus the views.</p>";
    elements.emptyState.replaceWith(empty);
    elements.emptyState = empty;
  }
}

function selectedOrdinal() {
  return Number(document.querySelector("input[name=state]:checked")?.value ?? 0);
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
    const [summary, stateLoaded] = await Promise.all([request("/api/summary"), renderState(0)]);
    if (!stateLoaded) return;
    renderSummary(summary);
    elements.emptyState.hidden = true;
    elements.explorer.hidden = false;
    announce(`${exampleId} is ready. Use the state and navigation controls to explore it.`);
  } catch (error) {
    showError(error);
  } finally {
    elements.loadButton.disabled = false;
  }
}

async function renderState(ordinal) {
  if (!appState.session) return;
  const state = appState.session.states.find((candidate) => candidate.ordinal === ordinal);
  announce(`Loading ${state.stateId}…`);
  try {
    const ir = await request(`/api/ir?ordinal=${ordinal}`);
    const currentFunction = ir.functions.find((item) => item.id === appState.selectedFunctionId) || ir.functions[0];
    appState.ir = ir;
    appState.selectedFunctionId = currentFunction?.id ?? null;
    const functionBlocks = currentFunction?.blocks || [];
    if (!functionBlocks.some((block) => block.id === appState.selectedBlockId)) {
      appState.selectedBlockId = functionBlocks[0]?.id ?? null;
    }
    appState.cfg = currentFunction
      ? await request(`/api/cfg?ordinal=${ordinal}&functionId=${encodeURIComponent(currentFunction.id)}`)
      : null;
    await request("/api/focus", {
      method: "POST",
      body: JSON.stringify({ ordinal, nodeId: appState.selectedBlockId }),
    });
    renderStateOptions();
    renderNavigation();
    renderIr();
    renderCfg();
    announce(`Showing ${state.stateId}.`);
    return true;
  } catch (error) {
    showError(error);
    return false;
  }
}

function renderStateOptions() {
  const ordinal = selectedOrdinal();
  elements.stateOptions.replaceChildren(...appState.session.states.map((state) => {
    const label = document.createElement("label");
    label.className = "state-option";
    const input = document.createElement("input");
    input.name = "state";
    input.type = "radio";
    input.value = String(state.ordinal);
    input.checked = state.ordinal === ordinal;
    input.addEventListener("change", () => renderState(state.ordinal));
    const text = document.createElement("span");
    text.innerHTML = `<strong>${state.stateId}</strong><br><small>${state.ordinal === 0 ? "Unoptimised baseline" : "Recompiled -O3 anchor"}</small>`;
    label.append(input, text);
    return label;
  }));
}

function renderSummary(summary) {
  elements.summaryContext.textContent = summary.context;
  elements.summaryItems.replaceChildren(...summary.items.map((item) => {
    const listItem = document.createElement("li");
    listItem.textContent = item.text;
    return listItem;
  }));
}

function renderNavigation() {
  elements.navigationTree.replaceChildren(...appState.ir.functions.map((fn) => {
    const group = document.createElement("div");
    group.className = "function-group";
    group.append(navigationButton(fn.name, "function-button", fn.id === appState.selectedFunctionId, async () => {
      appState.selectedFunctionId = fn.id;
      appState.selectedBlockId = fn.blocks[0]?.id ?? null;
      await renderState(selectedOrdinal());
    }));
    fn.blocks.forEach((block) => group.append(navigationButton(
      block.label,
      "block-button",
      block.id === appState.selectedBlockId,
      async () => {
        appState.selectedFunctionId = fn.id;
        appState.selectedBlockId = block.id;
        await request("/api/focus", {
          method: "POST",
          body: JSON.stringify({ ordinal: selectedOrdinal(), nodeId: block.id }),
        });
        renderNavigation();
        renderIr();
        renderCfg();
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
  elements.irDescription.textContent = `${appState.ir.stateId} · ${fn.name} · ${fn.blocks.length} basic block${fn.blocks.length === 1 ? "" : "s"}`;
  elements.irView.replaceChildren();
  const signature = document.createElement("code");
  signature.className = "ir-signature";
  signature.innerHTML = highlightIr(stripDebug(fn.signature, showDebug));
  elements.irView.append(signature);
  let lineNumber = 1;
  fn.blocks.forEach((block) => {
    const blockElement = document.createElement("section");
    blockElement.className = `ir-block${block.id === appState.selectedBlockId ? " is-selected" : ""}`;
    blockElement.id = `ir-${block.id.replaceAll("/", "-")}`;
    blockElement.innerHTML = `<div class="ir-block-heading">${escapeHtml(block.label)}:</div>`;
    block.instructions.forEach((instruction) => {
      const line = document.createElement("div");
      line.className = "ir-line";
      line.innerHTML = `<span class="line-number">${lineNumber}</span><code>${highlightIr(stripDebug(instruction.text, showDebug))}</code>`;
      blockElement.append(line);
      lineNumber += 1;
    });
    elements.irView.append(blockElement);
  });
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
  elements.cfgDescription.textContent = `${appState.ir.stateId} · ${fn.name} · edges are labelled from the API CFG response`;
  elements.cfgView.replaceChildren();
  if (!cfg || cfg.blocks.length === 0) {
    elements.cfgView.innerHTML = '<p class="cfg-empty">No control-flow graph is available for this function.</p>';
    return;
  }
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
  svg.classList.add("cfg-svg");
  svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", `Control-flow graph for ${fn.name}`);
  svg.innerHTML = '<defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 Z" fill="#60758a" /></marker></defs>';
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
  cfg.blocks.forEach((block) => {
    const point = positions.get(block.id);
    const node = document.createElementNS(namespace, "g");
    node.setAttribute("class", `cfg-node${block.id === appState.selectedBlockId ? " is-selected" : ""}`);
    node.setAttribute("transform", `translate(${point.x}, ${point.y})`);
    node.setAttribute("role", "button");
    node.setAttribute("tabindex", "0");
    node.setAttribute("aria-label", `Focus basic block ${block.label}`);
    const focusBlock = async () => {
      appState.selectedBlockId = block.id;
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
elements.invalidRequest.addEventListener("click", async () => {
  try {
    await request("/api/cfg?ordinal=0&functionId=missing");
  } catch (error) {
    showError(error);
  }
});

loadExamples();
