// Keep the explanation focused on the selected states and current trace.
function statePurpose(state) {
  if (state.ordinal === 0) return "-O0 is the unoptimised baseline: most optimisations are disabled.";
  if (state.transition?.kind === "recompiled") return state.transition.level + " enables an aggressive optimisation pipeline. This output is compiled separately, rather than being the next pass in the teaching chain.";
  return (PASS_ACTIONS[state.transition?.passName] || "Apply the recorded compiler pass") + ". This is the pass’s purpose, not proof that it changed the selected line.";
}

function renderSummary() {
  for (const side of ["left", "right"]) {
    const state = stateFor(side);
    document.querySelector("#" + side + "-purpose").textContent =
      state ? side[0].toUpperCase() + side.slice(1) + ": " + stateOptionLabel(state) + " — " + statePurpose(state) : "";
  }
  if (!appState.summary) {
    elements.comparisonAction.textContent = "";
    elements.selectionStatus.textContent = "Choose both states and views to trace a selection.";
  }
}
