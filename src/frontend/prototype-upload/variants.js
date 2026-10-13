// PROTOTYPE ONLY (irexplorer#47): three structurally different upload flows for the Explore page.
//   A  File selector  — upload is an entry in the File select; nothing on screen changes until a
//                       compile succeeds; status and failures sit under the File control.
//   B  Source drop zone — the source panel switches between Curated and Your files; the source pane
//                       is a drop zone (pick, drop or paste); compiling and failures take over the
//                       panels, with failures marked against the source lines.
//   C  Dialog         — a page-level button opens a dialog that owns checking, compiling and
//                       failures; the page changes only when a program is ready.
(() => {
  const h = (tag, attrs = {}, ...children) => {
    const element = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs)) {
      if (key === 'class') element.className = value;
      else if (key.startsWith('on')) element.addEventListener(key.slice(2), value);
      else if (value === true) element.setAttribute(key, '');
      else if (value !== false && value != null) element.setAttribute(key, value);
    }
    element.append(...children.flat().filter(child => child != null && child !== false));
    return element;
  };
  const client = window.ProgramClient;
  const select = () => document.querySelector('#example-select');
  const sourcePanel = () => document.querySelector('#source-panel');
  const filePicker = onFile => {
    const input = h('input', { type: 'file', accept: '.c,text/x-c', hidden: true, class: 'proto-file-input' });
    input.addEventListener('change', async () => {
      const file = input.files[0];
      if (file) onFile(file.name, await file.arrayBuffer());
      input.value = '';
    });
    document.body.append(input);
    return input;
  };
  const spinner = () => h('span', { class: 'proto-spinner', 'aria-hidden': 'true' });

  // Option values in the real File select: the workspace loads a program through it.
  function ensureOption(program, { label = program.fileName, group = null, hidden = false } = {}) {
    const value = `program:${program.programId}`;
    let option = [...select().options].find(item => item.value === value);
    if (!option) {
      option = new Option(label, value);
      (group || select()).append(option);
    }
    option.textContent = label;
    option.hidden = hidden;
    return option;
  }

  function failureHeading(error, fileName) {
    return ({
      invalid_program: `${fileName} was not sent`,
      compile_failed: `${fileName} did not compile`,
      unsupported_program: `irexplorer cannot show ${fileName}`,
      compile_timeout: `Compiling ${fileName} took too long`,
      compiler_busy: 'The compiler is busy',
      compiler_unavailable: 'The compiler is not running',
      cancelled: 'Compiling cancelled',
    })[error.code] || 'Something went wrong';
  }

  // Shared content of a failure; each variant decides where it goes.
  function failureBody(error, source, { excerpts = false, onLine = null } = {}) {
    const nodes = [h('p', { class: 'proto-failure-message' }, error.message)];
    if (error.diagnostics?.length) {
      const lines = source.split('\n');
      nodes.push(h('ol', { class: 'proto-diagnostics' }, error.diagnostics.map(diagnostic => {
        const text = `Line ${diagnostic.line}, column ${diagnostic.column}: ${diagnostic.message.replace(/^error:\s*/, '')}`;
        return h('li', {},
          onLine ? h('button', { type: 'button', class: 'proto-link', onclick: () => onLine(diagnostic.line) }, text) : text,
          excerpts ? h('pre', { class: 'proto-excerpt' }, `${String(diagnostic.line).padStart(3)} | ${lines[diagnostic.line - 1] ?? ''}\n    | ${' '.repeat(Math.max(0, diagnostic.column - 1))}^`) : null);
      })));
      if (error.diagnostics.length >= 20) nodes.push(h('p', { class: 'proto-muted' }, 'Only the first 20 problems are listed.'));
    }
    if (error.output) nodes.push(h('details', {}, h('summary', {}, 'Full compiler output'), h('pre', { class: 'proto-output' }, error.output)));
    if (error.detail) nodes.push(h('details', {}, h('summary', {}, 'Parser message'), h('pre', { class: 'proto-output' }, error.detail)));
    return nodes;
  }

  // ---------------------------------------------------------------- A: File selector
  const VariantA = {
    key: 'A', name: 'File selector',
    async build() {
      await examplesReady;
      const control = select();
      const placeholder = control.options[0];
      placeholder.textContent = 'Choose a file…';
      const curated = h('optgroup', { label: 'Curated examples' }, [...control.options].filter(option => option.value));
      this.uploads = h('optgroup', { label: 'Your uploads' });
      control.replaceChildren(placeholder, curated, new Option('Upload a C file…', '__upload'));
      for (const program of client.programs) this.addUpload(program);
      const input = filePicker((name, content) => this.acceptFile(name, content));
      let previous = control.value;
      control.addEventListener('change', event => {
        if (control.value !== '__upload') { previous = control.value; this.clearFailure(); return; }
        event.stopImmediatePropagation();
        control.value = previous;
        input.click();
      }, true);
      this.status = h('p', { class: 'pa-status', role: 'status' });
      this.failure = h('section', { class: 'pa-failure', role: 'alert', hidden: true });
      document.querySelector('.source-controls').after(this.status, this.failure);
      this.input = input;
      document.addEventListener('prototype:compile', event => this.onCompile(event.detail));
      document.addEventListener('prototype:tick', event => this.tick(event.detail));
      document.addEventListener('workspace-ready', () => this.showIdentity());
    },
    addUpload(program) {
      if (!this.uploads.isConnected) select().insertBefore(this.uploads, select().lastElementChild);
      return ensureOption(program, { group: this.uploads });
    },
    tick(seconds) { if (this.timer) this.timer.textContent = `${seconds} s`; },
    onCompile({ phase, reason, fileName }) {
      const busy = phase === 'start';
      select().disabled = busy;
      sourcePanel().setAttribute('aria-busy', String(busy));
      if (busy) {
        this.timer = h('span', { class: 'proto-timer', 'aria-hidden': 'true' }, '0 s');
        this.status.replaceChildren(spinner(), reason === 'recover'
          ? `Recompiling ${fileName}: the server no longer had it… ` : `Compiling ${fileName}… `, this.timer);
        this.status.classList.add('is-busy');
      } else { this.timer = null; this.status.classList.remove('is-busy'); this.showIdentity(); }
    },
    showIdentity() {
      const program = client.current();
      this.status.replaceChildren();
      if (program && program.fileName !== program.originalName)
        this.status.append(`Uploaded “${program.originalName}” as ${program.fileName}.`);
    },
    clearFailure() { this.failure.hidden = true; this.failure.replaceChildren(); },
    showFailure(error, prepared) {
      this.failure.replaceChildren(
        h('h3', {}, failureHeading(error, prepared.fileName)),
        ...failureBody(error, prepared.source, { excerpts: true }),
        h('div', { class: 'proto-actions' },
          h('button', { type: 'button', onclick: () => this.input.click() }, 'Upload another file…'),
          h('button', { type: 'button', onclick: () => this.clearFailure() }, 'Dismiss')),
        appState.exampleId ? h('p', { class: 'proto-muted' }, 'The comparison on screen has not changed.') : null);
      this.failure.hidden = false;
    },
    async acceptFile(name, content) {
      if (client.busy) return;
      this.clearFailure();
      const prepared = client.prepare(name, content);
      if (prepared.refusal) return this.showFailure({ code: 'invalid_program', message: prepared.refusal }, prepared);
      const result = await client.compile(prepared, { onTick: seconds => this.tick(seconds) });
      if (!result.ok) return this.showFailure(result.error, prepared);
      this.addUpload(client.program(result.programId));
      await client.open(result.programId);
    },
  };

  // ---------------------------------------------------------------- B: Source drop zone
  const VariantB = {
    key: 'B', name: 'Source drop zone',
    async build() {
      await examplesReady;
      const controls = document.querySelector('.source-controls');
      const fileLabel = controls.querySelector('label[for="example-select"]');
      this.mode = h('div', { class: 'pb-mode', role: 'radiogroup', 'aria-label': 'Source' },
        ['curated', 'yours'].map(value => h('label', {},
          h('input', { type: 'radio', name: 'pb-mode', value, onchange: () => this.setMode(value) }),
          value === 'curated' ? 'Curated examples' : 'Your files')));
      this.yourSelect = h('select', { id: 'pb-your-select', onchange: () => this.yourSelect.value && client.open(this.yourSelect.value) });
      this.yours = h('div', { class: 'pb-yours', hidden: true },
        h('label', { for: 'pb-your-select' }, 'Your file', this.yourSelect),
        h('div', { class: 'pb-buttons' },
          h('button', { type: 'button', onclick: () => this.input.click() }, 'Upload…'),
          h('button', { type: 'button', onclick: () => { this.showDrop(true); this.pasteArea.hidden = false; this.pasteText.focus(); } }, 'Paste…')));
      controls.before(this.mode);
      fileLabel.after(this.yours);
      this.fileLabel = fileLabel;
      this.input = filePicker((name, content) => this.acceptFile(name, content));
      this.chip = h('span', { class: 'pb-chip', hidden: true }, 'Your file');
      this.renamed = h('p', { class: 'proto-muted pb-renamed', hidden: true });
      document.querySelector('#source-summary').after(this.chip);
      controls.after(this.renamed);
      this.pasteName = h('input', { type: 'text', value: 'program.c', id: 'pb-paste-name', spellcheck: 'false' });
      this.pasteText = h('textarea', { id: 'pb-paste-text', rows: '10', spellcheck: 'false', placeholder: 'int square(int x) {\n    return x * x;\n}' });
      this.pasteArea = h('div', { class: 'pb-paste', hidden: true },
        h('label', { for: 'pb-paste-name' }, 'File name', this.pasteName),
        h('label', { for: 'pb-paste-text' }, 'C source', this.pasteText),
        h('div', { class: 'proto-actions' },
          h('button', { type: 'button', class: 'primary', onclick: () => this.acceptFile(this.pasteName.value.trim() || 'program.c', this.pasteText.value) }, 'Compile'),
          h('button', { type: 'button', onclick: () => { this.pasteArea.hidden = true; } }, 'Cancel')));
      this.drop = h('div', { class: 'pb-drop', hidden: true },
        h('p', { class: 'pb-drop-title' }, 'Drop a .c file here'),
        h('p', { class: 'proto-muted' }, 'One C file, up to 200 lines. Standard headers are allowed.'),
        h('div', { class: 'proto-actions' },
          h('button', { type: 'button', class: 'primary', onclick: () => this.input.click() }, 'Choose a file…'),
          h('button', { type: 'button', onclick: () => { this.pasteArea.hidden = false; this.pasteText.focus(); } }, 'Paste source instead')),
        this.pasteArea);
      this.preview = h('div', { class: 'source-lines pb-preview', hidden: true, 'aria-label': 'Uploaded C source, not yet compiled' });
      document.querySelector('#source-lines').after(this.drop, this.preview);
      this.card = h('section', { class: 'panel pb-card', hidden: true, 'aria-live': 'polite' });
      document.querySelector('#workspace-shell').append(this.card);
      const panel = sourcePanel();
      panel.addEventListener('dragover', event => { if (this.current === 'yours') { event.preventDefault(); panel.classList.add('is-dragging'); } });
      panel.addEventListener('dragleave', () => panel.classList.remove('is-dragging'));
      panel.addEventListener('drop', async event => {
        panel.classList.remove('is-dragging');
        if (this.current !== 'yours') return;
        event.preventDefault();
        const file = event.dataTransfer.files[0];
        if (file) this.acceptFile(file.name, await file.arrayBuffer());
      });
      document.addEventListener('prototype:compile', event => this.onCompile(event.detail));
      document.addEventListener('prototype:tick', event => this.tick(event.detail));
      document.addEventListener('workspace-ready', () => this.showIdentity());
      this.refreshYours();
      this.setMode(client.programs.length ? 'yours' : 'curated');
    },
    refreshYours() {
      const programs = client.programs;
      this.yourSelect.replaceChildren(h('option', { value: '', disabled: true, selected: true }, programs.length ? 'Choose one of your files…' : 'No files yet'),
        ...programs.map(program => { ensureOption(program, { hidden: true }); return new Option(program.fileName, program.programId); }));
      const current = client.current();
      if (current) this.yourSelect.value = current.programId;
      this.yourSelect.disabled = !programs.length;
    },
    setMode(mode) {
      this.current = mode;
      this.mode.querySelector(`input[value="${mode}"]`).checked = true;
      this.fileLabel.hidden = mode !== 'curated';
      this.yours.hidden = mode !== 'yours';
      this.showDrop(mode === 'yours' && !client.current() && !client.busy);
    },
    showDrop(show) {
      this.drop.hidden = !show;
      document.querySelector('#source-lines').hidden = show || !this.preview.hidden;
      document.querySelector('#source-prompt').hidden = show || Boolean(sourceState.data);
    },
    showPreview(prepared, marked = new Set()) {
      this.preview.replaceChildren(...prepared.source.replace(/\n$/, '').split('\n').map((text, index) =>
        h('div', { class: `pb-preview-line${marked.has(index + 1) ? ' is-error' : ''}`, 'data-line': String(index + 1) },
          h('span', { class: 'line-number' }, String(index + 1)), h('code', {}, text || ' '))));
      this.preview.hidden = false;
      this.drop.hidden = true;
      document.querySelector('#source-lines').hidden = true;
      document.querySelector('#source-prompt').hidden = true;
      document.querySelector('#source-summary').textContent = `C source · ${prepared.fileName}`;
    },
    hidePreview() { this.preview.hidden = true; document.querySelector('#source-lines').hidden = false; },
    showCard(...children) {
      this.card.replaceChildren(...children);
      this.card.hidden = false;
      elements.workspace.hidden = true;
      elements.emptyState.hidden = true;
    },
    tick(seconds) { if (this.timer) this.timer.textContent = `${seconds} s`; },
    onCompile({ phase, reason, fileName }) {
      const busy = phase === 'start';
      for (const control of [this.yourSelect, select(), ...this.yours.querySelectorAll('button'), ...this.drop.querySelectorAll('button')]) control.disabled = busy || (control === this.yourSelect && !client.programs.length);
      document.querySelector('#workspace-shell').setAttribute('aria-busy', String(busy));
      if (busy) {
        this.timer = h('span', { class: 'proto-timer', 'aria-hidden': 'true' }, '0 s');
        this.showCard(h('div', { class: 'pb-progress' }, spinner(),
          h('h2', {}, reason === 'recover' ? `Recompiling ${fileName}` : `Compiling ${fileName}`, ' ', this.timer)),
          h('p', {}, reason === 'recover'
            ? 'The server no longer had this program (it restarts empty), so the browser sent the source again.'
            : 'irexplorer compiles it at -O0, runs the ten curated passes one at a time, and compiles it again at -O3. This usually takes about 5 s.'),
          h('p', { class: 'proto-muted' }, 'The two panels and the comparison open here when it is ready.'));
      } else this.timer = null;
    },
    showIdentity() {
      const program = client.current();
      this.card.hidden = true;
      this.hidePreview();
      this.chip.hidden = !program;
      this.renamed.hidden = !(program && program.fileName !== program.originalName);
      if (program) this.renamed.textContent = `Renamed from “${program.originalName}”.`;
      this.refreshYours();
      if (program && this.current !== 'yours') this.setMode('yours');
      if (!program && this.current === 'yours') this.setMode('curated');
    },
    jumpTo(line) {
      const row = this.preview.querySelector(`[data-line="${line}"]`);
      this.preview.querySelectorAll('.is-focus').forEach(item => item.classList.remove('is-focus'));
      row?.classList.add('is-focus');
      row?.scrollIntoView({ block: 'center' });
    },
    async acceptFile(name, content) {
      if (client.busy) return;
      if (this.current !== 'yours') this.setMode('yours');
      const prepared = client.prepare(name, content);
      if (prepared.refusal) {
        return this.showCard(h('h2', {}, failureHeading({ code: 'invalid_program' }, prepared.originalName)),
          h('p', { class: 'proto-failure-message' }, prepared.refusal),
          h('p', { class: 'proto-muted' }, 'Nothing was sent to the compiler.'),
          h('div', { class: 'proto-actions' }, h('button', { type: 'button', onclick: () => this.input.click() }, 'Choose another file…')));
      }
      this.pasteArea.hidden = true;
      this.chip.hidden = false;
      this.renamed.hidden = !prepared.renamed;
      this.renamed.textContent = `Renamed from “${prepared.originalName}”.`;
      this.showPreview(prepared);
      const result = await client.compile(prepared, { onTick: seconds => this.tick(seconds) });
      if (result.ok) { this.refreshYours(); await client.open(result.programId); return; }
      const marked = new Set((result.error.diagnostics || []).map(diagnostic => diagnostic.line));
      this.showPreview(prepared, marked);
      this.showCard(h('h2', {}, failureHeading(result.error, prepared.fileName)),
        ...failureBody(result.error, prepared.source, { onLine: line => this.jumpTo(line) }),
        h('div', { class: 'proto-actions' },
          h('button', { type: 'button', onclick: () => this.input.click() }, 'Choose another file…'),
          ['compiler_busy', 'compile_timeout', 'compiler_unavailable'].includes(result.error.code)
            ? h('button', { type: 'button', onclick: () => this.acceptFile(prepared.originalName, prepared.source) }, 'Try again') : null));
    },
  };

  // ---------------------------------------------------------------- C: Dialog
  const VariantC = {
    key: 'C', name: 'Dialog',
    async build() {
      await examplesReady;
      this.opener = h('button', { type: 'button', class: 'pc-open primary', onclick: () => this.open() }, 'Compile your own C file…');
      document.querySelector('#explore-heading').after(this.opener);
      this.badge = h('span', { class: 'pb-chip', hidden: true }, 'Uploaded');
      document.querySelector('#source-summary').after(this.badge);
      this.banner = h('p', { class: 'pc-banner', role: 'status', hidden: true });
      this.opener.after(this.banner);
      this.dialog = h('dialog', { class: 'pc-dialog', 'aria-labelledby': 'pc-title' });
      this.dialog.addEventListener('cancel', event => { if (client.busy) event.preventDefault(); });
      document.body.append(this.dialog);
      this.input = filePicker((name, content) => this.choose(name, content));
      for (const program of client.programs) ensureOption(program, { label: `${program.fileName} · uploaded` });
      document.addEventListener('prototype:compile', event => this.onRecover(event.detail));
      document.addEventListener('prototype:tick', event => { if (this.bannerTimer) this.bannerTimer.textContent = `${event.detail} s`; });
      document.addEventListener('workspace-ready', () => { this.badge.hidden = !client.current(); });
    },
    onRecover({ phase, reason, fileName }) {
      if (reason !== 'recover') return;
      this.opener.disabled = phase === 'start';
      this.banner.hidden = phase !== 'start';
      this.bannerTimer = h('span', { class: 'proto-timer', 'aria-hidden': 'true' }, '0 s');
      if (phase === 'start') this.banner.replaceChildren(spinner(), `Recompiling ${fileName}: the server no longer had it… `, this.bannerTimer);
    },
    open(prepared = null) {
      this.tab = this.tab || 'file';
      this.prepared = prepared;
      this.renderChoose();
      if (!this.dialog.open) this.dialog.showModal();
    },
    async acceptFile(name, content) { this.open(); this.choose(name, content); },
    choose(name, content) { this.tab = 'file'; this.prepared = client.prepare(name, content); this.renderChoose(); },
    frame(...children) {
      this.dialog.replaceChildren(h('h2', { id: 'pc-title' }, 'Compile your own C file'), ...children);
    },
    renderChoose() {
      const tabs = h('div', { class: 'pc-tabs', role: 'tablist' }, [['file', 'Choose a file'], ['paste', 'Paste source']].map(([value, label]) =>
        h('button', { type: 'button', role: 'tab', 'aria-selected': String(this.tab === value), onclick: () => { this.tab = value; this.prepared = null; this.renderChoose(); } }, label)));
      let body;
      if (this.tab === 'file') {
        body = h('div', { class: 'pc-file' },
          h('button', { type: 'button', onclick: () => this.input.click() }, this.prepared ? 'Choose a different file…' : 'Choose a file…'),
          h('span', { class: 'pc-file-name' }, this.prepared ? this.prepared.originalName : 'No file chosen'));
      } else {
        const name = h('input', { type: 'text', id: 'pc-name', value: this.pasteName || 'program.c', spellcheck: 'false' });
        const text = h('textarea', { id: 'pc-text', rows: '12', spellcheck: 'false' });
        text.value = this.pasteText || '';
        const update = () => { this.pasteName = name.value; this.pasteText = text.value; this.prepared = text.value ? client.prepare(name.value.trim() || 'program.c', text.value) : null; this.renderChecks(); };
        name.addEventListener('input', update); text.addEventListener('input', update);
        body = h('div', { class: 'pc-paste' }, h('label', { for: 'pc-name' }, 'File name', name), h('label', { for: 'pc-text' }, 'C source', text));
        if (text.value) this.prepared = client.prepare(name.value, text.value);
      }
      this.checks = h('div', { class: 'pc-checks', 'aria-live': 'polite' });
      this.compileButton = h('button', { type: 'button', class: 'primary', onclick: () => this.compile() }, 'Compile');
      this.frame(
        h('p', { class: 'proto-muted' }, 'irexplorer compiles one C file through the same steps as the curated examples: -O0, ten passes one at a time, and a separate -O3. Standard headers are allowed.'),
        tabs, body, this.checks,
        h('div', { class: 'proto-actions' }, this.compileButton, h('button', { type: 'button', onclick: () => this.dialog.close() }, 'Cancel')));
      this.renderChecks();
    },
    renderChecks() {
      const prepared = this.prepared;
      this.compileButton.disabled = !prepared || Boolean(prepared.refusal);
      if (!prepared) { this.checks.replaceChildren(); return; }
      this.checks.replaceChildren(
        h('ul', {}, prepared.checks.map(check => h('li', { class: check.ok ? 'is-ok' : 'is-bad' }, h('span', { 'aria-hidden': 'true' }, check.ok ? '✓ ' : '✗ '), check.label, check.ok ? '' : h('span', { class: 'sr-only' }, ' (not met)')))),
        prepared.refusal ? h('p', { class: 'proto-failure-message' }, prepared.refusal)
          : h('p', {}, 'Will be compiled as ', h('strong', {}, prepared.fileName), prepared.renamed ? ` (renamed from “${prepared.originalName}”: only letters, digits, “.”, “_” and “-” are kept).` : '.'));
    },
    async compile() {
      const prepared = this.prepared;
      const timer = h('span', { class: 'proto-timer', 'aria-hidden': 'true' }, '0 s');
      const controller = new AbortController();
      this.frame(h('div', { class: 'pc-progress', 'aria-busy': 'true' }, spinner(), h('p', { role: 'status' }, `Compiling ${prepared.fileName}… `, timer)),
        h('p', { class: 'proto-muted' }, 'This usually takes about 5 s. The comparison opens when it is ready.'),
        h('div', { class: 'proto-actions' }, h('button', { type: 'button', onclick: () => controller.abort() }, 'Cancel')));
      this.opener.disabled = true;
      const result = await client.compile(prepared, { onTick: seconds => { timer.textContent = `${seconds} s`; }, signal: controller.signal });
      this.opener.disabled = false;
      if (result.ok) {
        ensureOption(client.program(result.programId), { label: `${result.fileName} · uploaded` });
        this.dialog.close();
        this.prepared = null;
        await client.open(result.programId);
        return;
      }
      this.frame(h('h3', { class: 'pc-failure-title' }, failureHeading(result.error, prepared.fileName)),
        ...failureBody(result.error, prepared.source, { excerpts: true }),
        h('div', { class: 'proto-actions' },
          h('button', { type: 'button', class: 'primary', onclick: () => this.renderChoose() }, 'Back'),
          ['compiler_busy', 'compile_timeout', 'compiler_unavailable', 'cancelled'].includes(result.error.code)
            ? h('button', { type: 'button', onclick: () => this.compile() }, 'Try again') : null,
          h('button', { type: 'button', onclick: () => this.dialog.close() }, 'Close')));
    },
  };

  window.PrototypeVariants = { A: VariantA, B: VariantB, C: VariantC };
})();
