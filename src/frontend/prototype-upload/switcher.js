// PROTOTYPE ONLY (irexplorer#47). Floating variant switcher (?variant=A|B|C, ← and → keys) and a
// scenario tray: sample files to "choose", forced server outcomes, compile time, server restart,
// whether the browser keeps uploads across a reload, and a readout of what each side holds.
(() => {
  if (!['localhost', '127.0.0.1', '[::1]'].includes(location.hostname)) return;
  const variants = window.PrototypeVariants;
  const keys = Object.keys(variants);
  const params = new URLSearchParams(location.search);
  const key = keys.includes(params.get('variant')) ? params.get('variant') : 'A';
  const variant = variants[key];
  const server = window.PrototypeServer;
  const client = window.ProgramClient;
  const h = (tag, attrs = {}, ...children) => {
    const element = document.createElement(tag);
    for (const [name, value] of Object.entries(attrs)) {
      if (name === 'class') element.className = value;
      else if (name.startsWith('on')) element.addEventListener(name.slice(2), value);
      else if (value === true) element.setAttribute(name, '');
      else if (value !== false && value != null) element.setAttribute(name, value);
    }
    element.append(...children.flat().filter(child => child != null && child !== false));
    return element;
  };

  const go = target => { params.set('variant', target); location.search = params.toString(); };
  const step = delta => go(keys[(keys.indexOf(key) + delta + keys.length) % keys.length]);

  // Explore only: Study never builds the upload control.
  const inStudy = () => location.hash.startsWith('#/study');
  window.addEventListener('hashchange', () => { if (inStudy() !== startedInStudy) location.reload(); });
  const startedInStudy = inStudy();
  if (!startedInStudy) variant.build();

  const bytes = text => new TextEncoder().encode(text).buffer;
  const samples = [
    ['score.c', 'same text as the curated score example', async () => bytes((await server.curatedSources()).score)],
    ['My Program (2).c', 'binary search under an unsafe name', async () => bytes((await server.curatedSources()).binary_search)],
    ['quick sort.c', 'two functions', async () => bytes((await server.curatedSources()).quick_sort)],
    ['broken.c', 'two compile errors', async () => bytes('#include <stdio.h>\n\nint total(int *values, int n) {\n    int sum = 0\n    for (int i = 0; i < n; ++i)\n        sum += values[i];\n    return totl;\n}\n')],
    ['dispatch.c', 'computed goto', async () => bytes('int dispatch(int op, int x) {\n    static void *table[] = { &&add, &&sub };\n    goto *table[op & 1];\nadd:\n    return x + 1;\nsub:\n    return x - 1;\n}\n')],
    ['declarations.c', 'no function definition', async () => bytes('#include <stddef.h>\n\nint square(int x);\nsize_t length(const char *text);\n')],
    ['long.c', '250 lines', async () => bytes(`int sum(int x) {\n${Array.from({ length: 247 }, (_, i) => `    x += ${i};`).join('\n')}\n    return x;\n}\n`)],
    ['notes.txt', 'not a .c file', async () => bytes('Remember to compile with -O3.\n')],
    ['empty.c', 'empty', async () => bytes('')],
    ['latin1.c', 'not UTF-8', async () => new Uint8Array([...new TextEncoder().encode('// caf'), 0xe9, ...new TextEncoder().encode('\nint f(void) { return 0; }\n')]).buffer],
  ];

  const outcome = h('select', { id: 'proto-outcome' },
    [['auto', 'as the file says'], ['compile_failed', 'compile_failed'], ['parser_failure', 'unsupported_program (parser failure)'],
      ['compile_timeout', 'compile_timeout (waits 30 s)'], ['compiler_busy', 'compiler_busy (as from a second tab)'], ['compiler_unavailable', 'compiler_unavailable']]
      .map(([value, label]) => new Option(label, value)));
  outcome.value = server.settings.nextOutcome;
  outcome.addEventListener('change', () => { server.settings.nextOutcome = outcome.value; server.saveSettings(); });
  const speed = h('select', { id: 'proto-speed' }, [[1000, '1 s'], [5000, '5 s (emulated compiler)'], [12000, '12 s']].map(([value, label]) => new Option(label, String(value))));
  speed.value = String(server.settings.compileMs);
  speed.addEventListener('change', () => { server.settings.compileMs = Number(speed.value); server.saveSettings(); });
  const keep = h('input', { type: 'checkbox', id: 'proto-keep' });
  keep.checked = server.settings.keepAcrossReload;
  keep.addEventListener('change', () => { server.settings.keepAcrossReload = keep.checked; server.saveSettings(); client.persist(); });
  const readout = h('dl', { class: 'proto-readout' });
  const renderReadout = () => {
    const names = list => list.length ? list.map(program => program.fileName).join(', ') : 'nothing';
    const current = client.current();
    readout.replaceChildren(
      h('dt', {}, 'Server holds'), h('dd', {}, `${names(server.programs)} (of 16)`),
      h('dt', {}, 'Browser keeps'), h('dd', {}, names(client.programs)),
      h('dt', {}, 'On screen'), h('dd', {}, current ? `${current.fileName} (user program, backed by curated ${server.programs.find(p => p.programId === current.programId)?.backing ?? '?'})` : appState.exampleId ? `${appState.exampleId} (curated)` : 'nothing'),
      h('dt', {}, 'Compiling'), h('dd', {}, client.busy ? 'yes' : 'no'));
  };
  for (const name of ['prototype:server', 'prototype:settings', 'prototype:compile', 'workspace-ready']) document.addEventListener(name, () => { outcome.value = server.settings.nextOutcome; renderReadout(); });

  const tray = h('section', { class: 'proto-tray', hidden: sessionStorage.getItem('prototype.upload.tray') !== 'open', 'aria-label': 'Prototype scenarios' },
    h('p', { class: 'proto-tray-title' }, 'Pretend to choose a file'),
    h('div', { class: 'proto-samples' }, samples.map(([name, note, content]) =>
      h('button', { type: 'button', title: note, onclick: async () => { if (!startedInStudy) variant.acceptFile(name, await content()); } }, name, h('small', {}, note)))),
    h('div', { class: 'proto-settings' },
      h('label', { for: 'proto-outcome' }, 'Next compile', outcome),
      h('label', { for: 'proto-speed' }, 'Compile time', speed),
      h('label', { class: 'proto-check', for: 'proto-keep' }, keep, 'Browser keeps uploads across a reload'),
      h('button', { type: 'button', onclick: () => server.restart() }, 'Restart server (forgets every program)')),
    readout);
  const trayButton = h('button', { type: 'button', class: 'proto-tray-toggle', 'aria-expanded': String(!tray.hidden), onclick: () => {
    tray.hidden = !tray.hidden;
    trayButton.setAttribute('aria-expanded', String(!tray.hidden));
    sessionStorage.setItem('prototype.upload.tray', tray.hidden ? 'closed' : 'open');
  } }, 'Scenarios');
  const bar = h('div', { class: 'proto-switcher', role: 'region', 'aria-label': 'Prototype variant switcher' },
    h('button', { type: 'button', 'aria-label': 'Previous variant', onclick: () => step(-1) }, '←'),
    h('span', { class: 'proto-switcher-label' }, `${key} · ${variant.name}`),
    h('button', { type: 'button', 'aria-label': 'Next variant', onclick: () => step(1) }, '→'),
    trayButton);
  document.body.append(tray, bar);
  document.body.classList.add('has-prototype-switcher');
  renderReadout();

  document.addEventListener('keydown', event => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    if (event.target.closest('input, textarea, select, [contenteditable], dialog, .ir-line, .cfg-node, .source-line') || event.altKey || event.metaKey || event.ctrlKey) return;
    step(event.key === 'ArrowLeft' ? -1 : 1);
  });
})();
