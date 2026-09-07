// Recorded source evidence only; correspondence selection stays in the workspace.
const sourceState = { data: null, anchors: [] };

function renderSource() {
  const viewer = document.querySelector('#source-lines');
  viewer.replaceChildren();
  const data = sourceState.data;
  document.querySelector('#source-summary').textContent = data ? `C source · ${data.file} · verified input` : 'C source · loading';
  if (!data) return;
  const lines = data.text.split('\n');
  lines.forEach((text, index) => {
    if (index === lines.length - 1 && !text) return;
    const line = document.createElement('button');
    line.type = 'button';
    line.className = 'source-line';
    line.dataset.line = String(index + 1);
    line.setAttribute('aria-label', `${data.file}, line ${index + 1}: ${text}`);
    const number = document.createElement('span');
    number.className = 'line-number';
    number.textContent = String(index + 1);
    const code = document.createElement('code');
    code.textContent = text || ' ';
    line.append(number, code);
    line.addEventListener('click', () => {
      if (!appState.ready) return;
      clearSelection();
      sourceState.anchors = [{ file: data.file, line: index + 1 }];
      applySourceHighlights();
      renderComparison();
      for (const side of ['left', 'right']) {
        renderPanel(side);
        scrollWithin(elements[side].viewer, elements[side].viewer.querySelector('.ir-line.is-source, .cfg-node.is-source'));
      }
    });
    viewer.append(line);
  });
}

function applySourceHighlights(message = '') {
  const data = sourceState.data;
  if (!data) return;
  const anchors = sourceState.anchors;
  const matchesAnchor = location => anchors.some(a => a.file === location.file && a.line === location.line
    && (a.column === undefined || a.column === location.column));
  const counts = [];
  for (const side of ['left', 'right']) {
    const panel = appState.panels[side];
    const matches = (panel.mappings || []).filter(m => matchesAnchor(m.location));
    panel.sourceNodeIds = new Set(matches.flatMap(m => [m.instructionId, m.blockId]));
    counts.push(`${side}: ${matches.length ? `${new Set(matches.map(m => m.instructionId)).size} mapped instructions` : 'No recorded source mapping'}`);
  }
  const locations = anchors.map(a => `${a.file}:${a.line}${a.column === undefined ? '' : ':' + a.column}`);
  document.querySelector('#source-summary').textContent = `C source · ${data.file}${locations.length ? ' · ' + locations.join(', ') : ' · verified input'}`;
  document.querySelector('#source-status').textContent = message || (anchors.length
    ? `debugLoc · ${counts.join('; ')}. All matches are highlighted in the selected function; absence does not establish removal.`
    : 'Verified canonical input. Select a C line, IR instruction, or CFG block.');
  for (const line of document.querySelectorAll('.source-line')) {
    const selected = anchors.some(a => a.file === data.file && a.line === Number(line.dataset.line));
    line.classList.toggle('is-source', selected);
    line.setAttribute('aria-pressed', String(selected));
  }
}

function revealNodeSource(side, nodeId) {
  const matches = (appState.panels[side].mappings || []).filter(m => m.instructionId === nodeId || m.blockId === nodeId);
  sourceState.anchors = [...new Map(matches.map(m => [JSON.stringify(m.location), m.location])).values()];
  applySourceHighlights(matches.length ? '' : 'No recorded source mapping for this selection. This does not establish removal.');
  if (matches.length) {
    document.querySelector('#source-panel').open = true;
    scrollWithin(document.querySelector('#source-lines'), document.querySelector('.source-line.is-source'));
  }
}

// Scroll only the bounded viewer, keeping the source, controls, and task in place.
function scrollWithin(container, node) {
  if (!node) return;
  const bounds = container.getBoundingClientRect();
  const target = node.getBoundingClientRect();
  if (target.top < bounds.top || target.bottom > bounds.bottom) {
    container.scrollTop += target.top - bounds.top - 12;
  }
  if (target.left < bounds.left || target.right > bounds.right) {
    container.scrollLeft += target.left - bounds.left - 12;
  }
}
