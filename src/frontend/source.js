// Source rendering and source-location context for the shared instruction trace.
const sourceState = { data: null, anchors: [], rangeStart: null };

function renderSource() {
  const viewer = document.querySelector('#source-lines');
  viewer.replaceChildren();
  const data = sourceState.data;
  document.querySelector('#source-summary').textContent = data ? `C source · ${data.file}` : 'C source';
  document.querySelector("#source-prompt").hidden = Boolean(data);
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
    line.title = 'Select this source line. Shift-click another line to select a range.';
    line.addEventListener('click', event => selectSourceLine(index + 1, event.shiftKey));
    line.addEventListener('keydown', event => {
      if (event.shiftKey && (event.key === 'Enter' || event.key === ' ')) {
        event.preventDefault();
        selectSourceLine(index + 1, true);
      }
    });
    viewer.append(line);
  });
}

function applySourceHighlights(message = '') {
  const data = sourceState.data;
  if (!data) return;
  const anchors = sourceState.anchors;
  const matchesAnchor = location => sourceMatches(location, anchors);
  const counts = [];
  for (const side of ['left', 'right']) {
    const panel = appState.panels[side];
    const matches = (panel.mappings || []).filter(m => matchesAnchor(m.location));
    panel.sourceNodeIds = new Set(matches.flatMap(m => [m.instructionId, m.blockId]));
    counts.push(`${side}: ${matches.length ? `${new Set(matches.map(m => m.instructionId)).size} mapped instructions` : 'No recorded source mapping'}`);
  }
  document.querySelector('#source-status').textContent = message || (anchors.length
    ? `C → left: ${anchors.map(a => a.file + ':' + a.line).join(', ')} · ${counts[0].replace('left: ', '')}. Right: ${counts[1].replace('right: ', '')}. These are source-location matches; missing matches do not prove removal.`
    : appState.selection ? 'C → left: no recorded source location for this selection. The cross-state trace is shown below.' : 'C → left: select a C line, IR instruction, or CFG block. Shift-click C lines to select a range.');
  for (const line of document.querySelectorAll('.source-line')) {
    const selected = anchors.some(a => a.file === data.file && a.line === Number(line.dataset.line));
    line.classList.toggle('is-source', selected);
    line.setAttribute('aria-pressed', String(selected));
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
