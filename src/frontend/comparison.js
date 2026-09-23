// Keep the explanation focused on the selected states and current trace.
function statePurpose(state) {
  if (state.ordinal === 0) return "Most optimisations are disabled.";
  if (state.transition?.kind === "recompiled") return "Aggressive optimisation pipeline, compiled separately from the teaching chain.";
  const purpose = PASS_ACTIONS[state.transition?.passName] || "Apply the recorded compiler pass";
  return purpose[0].toUpperCase() + purpose.slice(1) + ".";
}

function renderSummary() {
  for (const side of ["left", "right"]) {
    const state = stateFor(side);
    const view = appState.panels[side].viewType;
    const name = !state ? "Choose a state" : state.ordinal === 0 ? "Unoptimised · -O0"
      : state.transition?.kind === "recompiled" ? "Separately compiled · " + state.transition.level
      : "After pass " + state.ordinal + " · " + state.transition?.passName;
    document.querySelector("#" + side + "-selected-state").textContent = name + (view ? " · " + view.toUpperCase() : "");
    document.querySelector("#" + side + "-purpose").textContent = state ? statePurpose(state) : "";
  }
  if (!appState.summary) {
    document.querySelector("#structural-claims").replaceChildren();
    document.querySelector("#optimisation-explanations").replaceChildren();
    elements.comparisonAction.textContent = "";
    document.querySelector("#source-status").textContent = "Choose both states and views to see the source mapping.";
    document.querySelector("#trace-counts").hidden = true;
    document.querySelector("#selection-context").textContent = "Choose both states and views to begin.";
    elements.selectionStatus.textContent = "Choose both states and views to trace a selection.";
  }
}

// Explain only transformations associated with this selection's recorded links.
function renderOptimisations() {
  const container = document.querySelector('#optimisation-explanations');
  container.replaceChildren();
  const evidence = appState.selection?.evidence;
  if (!evidence) return;
  const { trace, optimisationGroups: groups } = evidence;
  if (!groups.length) {
    const note = document.createElement('p');
    note.className = 'optimisation-note';
    note.textContent = trace.sameState ? 'Same state: no optimisation change to explain.'
      : trace.links.length && trace.links.every(link => link.relation === 'same' && link.confidence === 'exact')
        ? 'No instruction change recorded for this selection between these states.'
        : 'No specific optimisation identified for this selection from the recorded evidence.';
    container.append(note);
    return;
  }
  for (const event of groups) {
    const card = document.createElement('section');
    card.className = 'optimisation-explanation';
    const name = document.createElement('strong');
    name.textContent = event.name + (event.certainty === 'likely' ? ' · likely' : '');
    const purpose = document.createElement('p');
    purpose.textContent = 'Purpose: ' + event.purpose;
    const change = document.createElement('p');
    change.textContent = 'What changed: ' + event.changes.join(' ');
    const state = document.createElement('small');
    state.textContent = event.fromStateId + ' → ' + event.toStateId;
    card.append(name, purpose, change, state);
    container.append(card);
  }
}

// Structural claims remain tied to the selected correspondence records.
function renderStructuralClaims() {
  const container = document.querySelector('#structural-claims');
  container.replaceChildren();
  const claims = appState.selection?.evidence?.structuralClaims || [];
  if (!claims.length) return;
  const heading = document.createElement('h4');
  heading.textContent = 'Recorded structural claims';
  const list = document.createElement('ul');
  for (const claim of claims) {
    const item = document.createElement('li');
    item.textContent = claim.text;
    list.append(item);
  }
  container.append(heading, list);
}
