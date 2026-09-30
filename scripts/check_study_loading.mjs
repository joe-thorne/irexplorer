// Exercise the actual study bootstrap with the shipped content, without a browser.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const participantPackage = JSON.parse(await readFile(new URL('../src/backend/evaluation/participant-package-v2.json', import.meta.url)));
const content = {packageSchemaVersion: participantPackage.packageSchemaVersion,
  packageIdentity: participantPackage.identity, ...participantPackage.content};
const source = await readFile(new URL('../src/frontend/study.js', import.meta.url), 'utf8');
async function load(definition, ok = true) {
  let reads = 0;
  const element = () => ({ hidden: false, innerHTML: '', dataset: {}, textContent: '',
    classList: { toggle() {} }, addEventListener() {}, focus() {}, setAttribute() {},
    querySelector() { return { ...element(), textContent: '' }; }, querySelectorAll() { return []; } });
  const elements = new Map();
  const fieldsFor = (_definition, section) => section === 'consent'
    ? definition.fields.filter(field => definition.membership.consent.includes(field.id))
    : definition.fields.filter(field => definition.membership[section]?.includes(field.id));
  const blankDraft = () => ({ participantCode: 'synthetic', preComplete: false, p13Locked: false,
    pre: Object.fromEntries(fieldsFor(definition, 'pre').map(field => [field.id, {status: 'unanswered', value: null}])),
    post: {}, tasks: Object.fromEntries(definition.tasks.map(task => [task.id, {status: 'pending', presented: false, paused: false, answers: {}}])) });
  const context = { console,
    window: { StudyDraft: { fieldsFor, visible: () => true, currentTask: () => 'T0', storage() { return { mode: 'local', read() { reads++; return definition.testDraft ? blankDraft() : null; } }; } },
      StudySubmit: { controller: () => ({ read() {} }) }, addEventListener() {}, scrollTo() {} },
    document: { querySelector(selector) { if (!elements.has(selector)) elements.set(selector, element()); return elements.get(selector); }, addEventListener() {} },
    location: { hash: definition.testDraft ? '#/study/pre' : '#/study' }, history: { replaceState() {} }, setInterval() {},
    fetch: async url => ({ ok: url === '/api/study/content' && ok, json: async () => definition }),
  };
  await vm.runInNewContext(source, context);
  return { html: elements.get('#study-screen').innerHTML, reads };
}
for (const mode of ['local', 'preview', 'pilot', 'live']) {
  const result = await load({ ...content, collectionMode: mode, submissionEnabled: mode === 'local' || mode === 'preview' });
  assert.match(result.html, /Information and consent/);
  assert.equal(result.reads, 1, 'Compatible content reaches local draft recovery');
}
for (const definition of [{ ...content, contentVersion: 'unsupported' }, { ...content, collectionMode: 'unsupported' }]) {
  const result = await load(definition);
  assert.match(result.html, /Study content unavailable/);
  assert.equal(result.reads, 0, 'Unsupported content must not read or overwrite drafts');
}
assert.match((await load(content, false)).html, /Retry loading forms/);
const hinted = structuredClone(content);
hinted.collectionMode = 'local';
hinted.submissionEnabled = true;
hinted.testDraft = true;
hinted.fields.find(field => field.id === 'P1').presentation.control = 'select';
hinted.fields.find(field => field.id === 'P13').type = 'short_text';
hinted.fields.find(field => field.id === 'P13').presentation.control = 'input';
const renderedHints = await load(hinted);
assert.match(renderedHints.html, /<select id="answer-P1"/);
assert.match(renderedHints.html, /<input id="answer-P13" type="text"/);
assert.doesNotMatch(renderedHints.html, /<input id="answer-P13"[^>]*maxlength=/);
assert.equal(renderedHints.reads, 1);
console.log('Study loading checks passed: current content in all modes, incompatible content, and failed requests.');
