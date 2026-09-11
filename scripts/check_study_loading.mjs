// Exercise the actual study bootstrap with the shipped content, without a browser.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const content = JSON.parse(await readFile(new URL('../src/backend/evaluation/participant-content.json', import.meta.url)));
const source = await readFile(new URL('../src/frontend/study.js', import.meta.url), 'utf8');
async function load(definition, ok = true) {
  let reads = 0;
  const element = () => ({ hidden: false, innerHTML: '', dataset: {},
    classList: { toggle() {} }, addEventListener() {}, focus() {},
    querySelector() { return { ...element(), textContent: '' }; }, querySelectorAll() { return []; } });
  const elements = new Map();
  const context = {
    window: { StudyDraft: { storage() { return { mode: 'local', read() { reads++; return null; } }; } },
      StudySubmit: { controller: () => ({ read() {} }) }, addEventListener() {}, scrollTo() {} },
    document: { querySelector(selector) { if (!elements.has(selector)) elements.set(selector, element()); return elements.get(selector); }, addEventListener() {} },
    location: { hash: '#/study' }, setInterval() {},
    fetch: async url => ({ ok: url === '/api/study/content' && ok, json: async () => definition }),
  };
  await vm.runInNewContext(source, context);
  return { html: elements.get('#study-screen').innerHTML, reads };
}
for (const mode of ['local', 'preview', 'pilot', 'live']) {
  const result = await load({ ...content, mode });
  assert.match(result.html, /Information and consent/);
  assert.equal(result.reads, 1, 'Compatible content reaches local draft recovery');
}
for (const definition of [{ ...content, contentVersion: 'unsupported' }, { ...content, mode: 'unsupported' }]) {
  const result = await load(definition);
  assert.match(result.html, /Study content unavailable/);
  assert.equal(result.reads, 0, 'Unsupported content must not read or overwrite drafts');
}
assert.match((await load(content, false)).html, /Retry loading forms/);
console.log('Study loading checks passed: current content in all modes, incompatible content, and failed requests.');
