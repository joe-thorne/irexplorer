// Presentation only: claims and their evidence are supplied by the query service.
function renderSummary() {
  const outcomes = document.querySelector('#comparison-outcomes');
  const evidence = document.querySelector('#comparison-evidence-body');
  const disclosure = document.querySelector('#comparison-evidence');
  outcomes.replaceChildren();
  evidence.replaceChildren();
  disclosure.open = false;
  disclosure.hidden = !appState.summary;
  const summary = appState.summary;
  if (!summary) {
    outcomes.textContent = 'Loading recorded outcomes…';
    document.querySelector('#comparison-action').textContent = '';
    document.querySelector('#pass-purpose').textContent = '';
    document.querySelector('#selection-status').textContent = 'Selection unavailable while the comparison loads.';
    document.querySelector('#selection-evidence').hidden = true;
    return;
  }
  const heading = document.createElement('strong');
  heading.textContent = `Recorded outcomes · ${summary.scope}`;
  outcomes.append(heading);
  const items = document.createElement('ul');
  for (const item of summary.items.slice(0, 3)) {
    const li = document.createElement('li');
    li.textContent = item.text;
    items.append(li);
  }
  if (!summary.items.length) {
    const p = document.createElement('p');
    p.textContent = summary.context;
    outcomes.append(p);
  } else outcomes.append(items);
  if (summary.items.length > 3) {
    const p = document.createElement('p');
    p.textContent = `${summary.items.length - 3} more recorded outcomes in the full evidence below.`;
    outcomes.append(p);
  }
  const context = document.createElement('p');
  context.textContent = `${summary.context} Evidence runs from ordinal ${summary.fromOrdinal} to ${summary.toOrdinal}, regardless of pane order. Link indices address this comparison; remark indices address its final transition. Counts describe matching records, not execution speed or semantic equivalence.`;
  evidence.append(context);
  for (const item of summary.items) {
    const detail = document.createElement('details');
    const label = document.createElement('summary');
    label.textContent = item.text;
    const record = document.createElement('pre');
    record.textContent = JSON.stringify({
      links: item.linkIndices.map(index => ({ index, ...summary.links[index] })),
      remarks: item.remarkIndices.map(index => ({ index, ...summary.steps.at(-1).remarks[index] })),
    }, null, 2);
    detail.append(label, record);
    evidence.append(detail);
  }
  const provenance = document.createElement('details');
  const label = document.createElement('summary');
  label.textContent = 'All comparison links, state commands, and transition remarks';
  const record = document.createElement('pre');
  record.textContent = JSON.stringify({ states: summary.states, steps: summary.steps, links: summary.links }, null, 2);
  provenance.append(label, record);
  evidence.append(provenance);
}
