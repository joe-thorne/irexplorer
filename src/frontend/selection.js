// One instruction-level trace for C ranges, IR instructions, and whole CFG blocks.
// Source-location context and recorded cross-state links remain distinct evidence.
function sourceMatches(location, sourceLocations) {
  const filename = path => path.split('/').at(-1);
  return sourceLocations.some(sourceLocation => filename(sourceLocation.file) === filename(location.file) && sourceLocation.line === location.line
    && (sourceLocation.column === undefined || sourceLocation.column === location.column));
}

function uniqueLocations(locations) {
  return [...new Map(locations.map(location => [JSON.stringify(location), location])).values()];
}

function instructionIds(panel, nodeId) {
  for (const block of panel.function?.blocks || []) {
    if (block.id === nodeId) return block.instructions.map(instruction => instruction.id);
    if (block.instructions.some(instruction => instruction.id === nodeId)) return [nodeId];
  }
  return [];
}

function buildSelectionTrace(panels, summary, selection) {
  const sides = ['left', 'right'];
  const validIds = Object.fromEntries(sides.map(side => [side, new Set((panels[side].function?.blocks || []).flatMap(block => block.instructions.map(instruction => instruction.id)))]));
  const seeds = { left: new Set(), right: new Set() };
  let sourceLocations = selection.sourceLocations || [];
  if (selection.kind === 'node') {
    const panel = panels[selection.side];
    for (const id of instructionIds(panel, selection.nodeId)) seeds[selection.side].add(id);
    sourceLocations = uniqueLocations((panel.mappings || [])
      .filter(mapping => seeds[selection.side].has(mapping.instructionId)).map(mapping => mapping.location));
  } else {
    for (const side of sides) {
      for (const mapping of panels[side].mappings || []) {
        if (validIds[side].has(mapping.instructionId) && sourceMatches(mapping.location, sourceLocations)) seeds[side].add(mapping.instructionId);
      }
    }
  }
  const members = Object.fromEntries(sides.map(side => [side, new Set(seeds[side])]));
  const covered = { left: new Set(), right: new Set() };
  const links = [];
  const sameState = panels.left.ordinal === panels.right.ordinal;
  if (sameState) {
    const ids = new Set([...seeds.left, ...seeds.right]);
    for (const side of sides) {
      for (const id of ids) {
        if (validIds[side].has(id)) members[side].add(id);
      }
      covered[side] = new Set(members[side]);
    }
  } else {
    const fromSide = panels.left.ordinal < panels.right.ordinal ? 'left' : 'right';
    const toSide = fromSide === 'left' ? 'right' : 'left';
    for (const link of summary?.links || []) {
      if (!link.fromNodeIds.some(id => seeds[fromSide].has(id))
          && !link.toNodeIds.some(id => seeds[toSide].has(id))) continue;
      links.push(link);
      for (const [side, ids] of [[fromSide, link.fromNodeIds], [toSide, link.toNodeIds]]) {
        for (const id of ids) {
          if (!validIds[side].has(id)) continue;
          covered[side].add(id);
          // Unresolved records must not become asserted counterparts.
          if (link.confidence !== 'unresolved') members[side].add(id);
        }
      }
    }
  }
  if (selection.kind === 'node') {
    sourceLocations = uniqueLocations(sides.flatMap(side => (panels[side].mappings || [])
      .filter(mapping => members[side].has(mapping.instructionId)).map(mapping => mapping.location)));
  }
  const missing = sides.reduce((count, side) =>
    count + [...seeds[side]].filter(id => !covered[side].has(id)).length, 0);
  const unresolved = missing > 0 || links.some(link => link.confidence === 'unresolved')
    || !sides.some(side => seeds[side].size);
  return { seeds, members, sourceLocations, links, sameState, missing, unresolved };
}

function relationWording(link) {
  if (link.confidence === 'unresolved') return 'unresolved';
  if (link.confidence === 'plausible') return `${link.relation} · plausible but unconfirmed confidence`;
  return `${link.relation} · ${link.confidence} confidence`;
}

function groupOptimisations(events) {
  const groups = new Map();
  for (const event of events) {
    const key = JSON.stringify([event.name, event.purpose, event.fromOrdinal, event.toOrdinal, event.certainty]);
    if (!groups.has(key)) groups.set(key, {
      name: event.name, purpose: event.purpose, certainty: event.certainty,
      fromOrdinal: event.fromOrdinal, toOrdinal: event.toOrdinal,
      fromStateId: event.fromStateId, toStateId: event.toStateId, changes: [],
    });
    const group = groups.get(key);
    if (!group.changes.includes(event.change)) group.changes.push(event.change);
  }
  return [...groups.values()];
}

function optimisationNote(trace, optimisationGroups) {
  if (optimisationGroups.length) return '';
  if (trace.sameState) return 'Same state: no cross-state optimisation change is being compared.';
  if (trace.links.length && trace.links.every(link => link.relation === 'same' && link.confidence === 'exact'))
    return 'No instruction change recorded for this selection between these states.';
  return 'No specific optimisation identified for this selection from the recorded evidence.';
}

// The participant-facing comparison consumes this model without reinterpreting
// the immutable summary record or the trace it produced.
function buildComparisonEvidence(summary, trace) {
  const groups = new Map();
  for (const link of trace.links) {
    const wording = relationWording(link);
    groups.set(wording, (groups.get(wording) || 0) + 1);
  }
  const relationGroups = [...groups].map(([wording, count]) => ({ wording, count }));
  const linkIndices = new Set(trace.links.map(link => summary.links.indexOf(link)).filter(index => index >= 0));
  // A remark reference addresses summary.steps[stepIndex].remarks[remarkIndex].
  const steps = summary.steps || [];
  const referenceKey = ref => ref.stepIndex + ':' + ref.remarkIndex;
  const citedReferenceKeys = new Set();
  const remarks = [];
  for (const ref of (summary.items || []).flatMap(item => item.remarkReferences)) {
    const step = steps[ref.stepIndex];
    const remark = step?.remarks[ref.remarkIndex];
    if (citedReferenceKeys.has(referenceKey(ref)) || !remark?.location || !sourceMatches(remark.location, trace.sourceLocations))
      continue;
    citedReferenceKeys.add(referenceKey(ref));
    remarks.push({ ...remark, fromOrdinal: step.fromOrdinal, toOrdinal: step.toOrdinal });
  }
  const structuralClaims = (summary.items || []).filter(item =>
    item.linkIndices.some(index => linkIndices.has(index))
      || item.remarkReferences.some(ref => citedReferenceKeys.has(referenceKey(ref))));
  const optimisations = (summary.optimisations || []).filter(event =>
    event.linkIndices.some(index => linkIndices.has(index)));
  const optimisationGroups = groupOptimisations(optimisations);
  const note = optimisationNote(trace, optimisationGroups);
  const statusText = trace.sameState ? 'The same instructions are highlighted in both views.'
    : relationGroups.map(({ wording, count }) => count + ' recorded ' + (count === 1 ? 'link' : 'links')
      + ': ' + wording + '.').join(' ')
      + (trace.unresolved ? ' Some instructions cannot be traced with the available evidence.' : '');
  return { trace, links: trace.links, relationGroups, remarks, structuralClaims, optimisations, optimisationGroups, optimisationNote: note, statusText };
}

function traceDescription(trace) {
  const counts = `Left: ${trace.members.left.size} instructions; right: ${trace.members.right.size} instructions.`;
  if (!trace.seeds.left.size && !trace.seeds.right.size)
    return 'No recorded source mapping in the selected function and states. This does not establish removal.';
  if (trace.sameState) return counts + ' Same recorded state; matching instructions are shown in both views.';
  const groups = new Map();
  for (const link of trace.links) {
    const label = link.confidence === 'unresolved' ? 'unresolved'
      : `${link.relation} (${link.confidence} confidence)`;
    groups.set(label, (groups.get(label) || 0) + 1);
  }
  const relations = [...groups].map(([label, count]) => `${count} ${label}`).join('; ');
  return counts + (relations ? ` Recorded relations, earlier → later: ${relations}.` : '')
    + (trace.missing ? ` ${trace.missing} selected instructions have no recorded correspondence.` : '')
    + (trace.unresolved ? ' Part of this selection cannot be traced with the available evidence.' : '');
}

function selectSourceLine(line, extend = false) {
  if (!appState.ready || !sourceState.data) return;
  const start = extend && sourceState.rangeStart !== null ? sourceState.rangeStart : line;
  if (!extend || sourceState.rangeStart === null) sourceState.rangeStart = line;
  const sourceLocations = [];
  for (let number = Math.min(start, line); number <= Math.max(start, line); number++)
    sourceLocations.push({ file: sourceState.data.file, line: number });
  selectWorkspace({ kind: 'source', sourceLocations });
}

function selectNode(side, nodeId) {
  if (!appState.ready) return;
  sourceState.rangeStart = null;
  selectWorkspace({ kind: 'node', side, nodeId, ordinal: appState.panels[side].ordinal });
}

function selectWorkspace(input, { scroll = true } = {}) {
  if (!appState.ready) return;
  const rangeStart = sourceState.rangeStart;
  clearSelection();
  sourceState.rangeStart = rangeStart;
  appState.selectionInput = input;
  const trace = buildSelectionTrace(appState.panels, appState.summary, input);
  const evidence = buildComparisonEvidence(appState.summary, trace);
  sourceState.sourceLocations = trace.sourceLocations;
  appState.selection = {
    originSide: input.kind === 'node' ? input.side : 'source',
    trace,
    evidence,
    unresolved: trace.unresolved,
    text: (input.kind === 'node'
      ? formatNode(nodeContext(appState.panels[input.side].ir, input.nodeId))
      : `C source selection (${input.sourceLocations.length} ${input.sourceLocations.length === 1 ? 'line' : 'lines'})`)
      + '. ' + traceDescription(trace),
  };
  for (const side of ['left', 'right']) {
    const panel = appState.panels[side];
    panel.selectedInstructionIds = trace.members[side];
    panel.selectedNodeIds = new Set(displayNodeIds(panel, [...trace.members[side]]));
    if (panel.viewType === 'ir') {
      for (const block of panel.function.blocks) {
        if (block.instructions.length && block.instructions.every(instruction => trace.members[side].has(instruction.id)))
          panel.selectedNodeIds.add(block.id);
      }
    }
  }
  applySourceHighlights();
  renderComparison();
  renderPanel('left');
  renderPanel('right');
  if (!scroll) return;
  for (const side of ['left', 'right']) {
    scrollWithin(elements[side].viewer, elements[side].viewer.querySelector('.is-selected, .is-linked, .is-source'));
  }
  if (input.kind === 'node') {
    const panel = appState.panels[input.side];
    const focusId = panel.viewType === 'cfg'
      ? displayNodeIds(panel, [input.nodeId])[0] : input.nodeId;
    const focused = elements[input.side].viewer.querySelector(`[data-node-id="${CSS.escape(focusId || input.nodeId)}"]`);
    (focused?.querySelector('.ir-block-heading') || focused)?.focus({ preventScroll: true });
    if (trace.sourceLocations.length) {
      document.querySelector('#source-panel').open = true;
      scrollWithin(document.querySelector('#source-lines'), document.querySelector('.source-line.is-source'));
    }
  }
}
