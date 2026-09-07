"""Reproduce E0 researcher evidence without changing artefacts or serving answers.

Run from irexplorer: .venv/bin/python scripts/audit_e0.py
Requires the parent thesis checkout for the draft instrument mapping.
"""
from __future__ import annotations
import hashlib
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from fastapi.testclient import TestClient
from src.backend.api.app import create_app
from src.backend.api.query import QueryService
from src.backend.ingest.curated import load_prebaked_curated_timeline
from src.backend.toolchain import curated
from src.backend.toolchain.integrity import verify_curated_snapshot


def check(condition, message):
    if not condition:
        raise ValueError(message)


def normalise(text):
    return ' '.join(text.replace('*', '').replace('`', '').split())


def content_audit():
    folder = ROOT.parent / 'Docs' / 'evaluation'
    content = json.loads((folder / 'e0-participant-content.json').read_text())
    private = json.loads((folder / 'e0-researcher-mapping.json').read_text())
    sources = {}
    for name, digest in private['sources'].items():
        raw = (folder / 'instruments' / name).read_bytes()
        check(hashlib.sha256(raw).hexdigest() == digest, f'Instrument changed: {name}; review/version the mapping.')
        sources[name] = normalise(raw.decode())
    check(set(content) == {'instrumentVersion', 'projectionVersion', 'scales', 'fields', 'taskOrder'}, 'Unexpected projection metadata')
    expected = {f'C{i}' for i in range(1, 7)} | {f'P{i}' for i in range(1, 14)} | {f'Q{i}' for i in range(1, 21)}
    expected |= {'P1.other', 'P3.other', 'P12.detail'}
    expected |= {f'T{n}{s}' for n, suffixes in [(1, 'ab'), (2, 'abc'), (3, 'abc'), (4, 'abcd'), (5, 'abc'), (6, 'abc')] for s in suffixes}
    check(len(content['fields']) == len(expected), 'Duplicate/missing fields')
    check({f['id'] for f in content['fields']} == expected, 'Item inventory mismatch')
    check(content['taskOrder'] == [f'T{i}' for i in range(7)], 'Task order changed')
    check(set(content['scales']) == {'familiarity', 'agreement', 'confidence', 'likelihood'}, 'Unexpected scale')
    for scale in content['scales'].values():
        check([o['value'] for o in scale] == [1, 2, 3, 4, 5], 'Scale codes changed')
        for o in scale:
            check(set(o) == {'value', 'label'}, 'Unexpected scale property')
            check(any(normalise(o['label']) in s for s in sources.values()), 'Scale label not sourced')
    allowed = {'id', 'source', 'prompt', 'type', 'required', 'options', 'scale', 'notApplicableLabel'}
    for f in content['fields']:
        check(set(f) <= allowed, f"Researcher/unknown field in projection: {f['id']}")
        source = sources[f['source']]
        check(f['source'] == private['itemSources'][f['id']], 'Wrong source mapping')
        check(len(f['prompt']) > 3 and normalise(f['prompt']) in source, f"Unsourced/truncated prompt: {f['id']}")
        check(f['required'] == (f['id'].startswith('C') or f['id'] == 'P1'), 'Requiredness changed')
        check(f['type'] in {'boolean', 'text', 'short_text', 'single', 'multiple', 'rating'}, 'Unknown answer type')
        if 'options' in f:
            check([o['value'] for o in f['options']] == list(range(1, len(f['options']) + 1)), 'Option coding changed')
            for o in f['options']:
                check(set(o) == {'value', 'label'}, 'Unexpected option metadata')
                check(normalise(o['label']) in source, f"Unsourced option: {f['id']} {o['label']}")
        if 'scale' in f:
            check(f['scale'] in content['scales'], 'Unresolved scale')
        if 'notApplicableLabel' in f:
            check(f['notApplicableLabel'] in source, 'Unsourced extra option')
    return {'fields': len(expected), 'instrumentVersion': content['instrumentVersion'], 'projectionVersion': content['projectionVersion'], 'sourceSha256': private['sources'], 'participantProjectionSha256': hashlib.sha256((folder / 'e0-participant-content.json').read_bytes()).hexdigest()}


def main(output: Path | None = None):
    report = {'capturedAt': datetime.now().astimezone().isoformat(), 'implementationRevision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(), 'content': content_audit()}
    verify_curated_snapshot()
    report['artefactSnapshot'] = (ROOT / 'docs/curated-artefacts.sha256').read_text().strip()
    query = QueryService()
    timelines = {}
    report['examples'] = {}
    for example in curated.list_examples():
        timeline = load_prebaked_curated_timeline(example)
        timelines[example] = timeline
        source = curated.read_source(example)
        source_md5 = hashlib.md5(source.encode()).hexdigest()
        states = []
        for ordinal, state in enumerate(timeline.states):
            check(state.ordinal == ordinal and state.state_id == curated.PASS_STATES[ordinal].state_id, 'State identity mismatch')
            state.validate()
            check(state.origin_command == curated.origin_command(example, state.state_id), 'Provenance mismatch')
            ir = curated.read_ir(example, state.state_id)
            checksums = re.findall(r'!DIFile\(filename: "[^"]*' + re.escape(example) + r'\.c"[^\n]*checksumkind: CSK_MD5, checksum: "([0-9a-f]+)"', ir)
            check(bool(checksums) and set(checksums) == {source_md5}, f'Source input differs from debug checksum: {example}/{ordinal}')
            functions = query.ir(example, ordinal)['functions']
            for function in functions:
                query.cfg(example, ordinal, function['id'])
            source_edges = [e for e in state.edges if e.relation == 'sourceMap']
            for edge in source_edges:
                check(edge.label == 'debugLoc', 'Unexpected source relation')
                loc = state.by_id[edge.from_id].attributes['source']
                check(Path(loc.file).name == example + '.c' and 0 < loc.line <= len(source.splitlines()), 'Unresolved source anchor')
            states.append({'ordinal': ordinal, 'stateId': state.state_id, 'functions': [{'id': f['id'], 'name': f['name']} for f in functions], 'sourceMappings': len(source_edges)})
        check(len(states) == 14, 'Incomplete timeline')
        report['examples'][example] = {'sourceFile': f'examples/curated/{example}.c', 'sourceMd5': source_md5, 'sourceSha256': hashlib.sha256(source.encode()).hexdigest(), 'states': states}
    score = timelines['score']
    def instructions(state): return [n for n in state.nodes if n.kind == 'Instruction']
    wasted = {}
    for ordinal in (0, 1, 2, 12):
        nodes = instructions(score.states[ordinal])
        line = [n for n in nodes if getattr(n.attributes.get('source'), 'line', None) == 3]
        wasted[str(ordinal)] = [{'id': n.stable_id, 'text': n.attributes['text']} for n in line]
    for ordinal in ('0', '1'):
        texts = [n['text'] for n in wasted[ordinal]]
        check(sum('mul nsw' in t for t in texts) == 2 and any('sub nsw' in t for t in texts), 'T2 baseline computation changed')
    check(not wasted['2'] and not wasted['12'], 'T2 needs re-audit: computation still mapped')
    # Actual operations are checked too: missing debug locations alone are not deletion.
    check(not any(n.attributes.get('result') in {'%mul1', '%mul2', '%sub', '%add'} for n in instructions(score.states[2])), 'T2 operations remain')
    report['T1'] = {str(i): {'instructions': len(instructions(score.states[i])), 'blocks': sum(n.kind == 'BasicBlock' for n in score.states[i].nodes), 'opcodes': [n.attributes['opcode'] for n in instructions(score.states[i])]} for i in (0, 12)}
    report['T2'] = {'sourceLine': 3, 'lineEvidence': wasted, 'firstAbsentOrdinal': 2, 'stateId': 'instcombine'}
    binary = timelines['binary_search'].states[3]
    cmp = binary.by_id['fn0/bb1/i2']
    check(cmp.attributes['text'].startswith('%cmp = icmp slt i32 %lo.0, %hi.0'), 'T3 comparison changed')
    edges = binary.cfg_successors[binary.contains_parent[cmp.stable_id]]
    targets = [{'label': e.label, 'block': binary.by_id[e.to_id].display_name} for e in edges]
    check(targets == [{'label': 'true', 'block': 'while.body'}, {'label': 'false', 'block': 'while.end'}], 'T3 edges changed')
    report['T3'] = {'ordinal': 3, 'stateId': binary.state_id, 'instructionId': cmp.stable_id, 'text': cmp.attributes['text'], 'blockId': 'fn0/bb1', 'blockLabel': 'while.cond', 'outgoing': targets}
    cfg6, cfg7 = (query.cfg('binary_search', i, 'fn0') for i in (6, 7))
    check((len(cfg6['blocks']), len(cfg6['edges']), len(cfg7['blocks']), len(cfg7['edges'])) == (7, 9, 8, 11), 'T4 topology changed')
    check(any(e['fromId'] == e['toId'] == 'fn0/bb2' and e['label'] == 'true' for e in cfg7['edges']), 'T4 self-loop changed')
    report['T4'] = {'before': cfg6, 'after': cfg7}
    mapping = query.counterparts('quick_sort', 0, 'fn0/bb0/i9', 9)
    check(mapping['confidence'] == 'approximate' and mapping['counterparts'], 'T5 example no longer reachable')
    report['T5'] = {'example': 'quick_sort', 'function': 'quick_sort', 'fromOrdinal': 0, 'toOrdinal': 9, 'mapping': mapping}
    with TestClient(create_app()) as client:
        for path in ['/e0-participant-content.json', '/docs/evaluation-captures/e0-task-evidence.json', '/scripts/audit_e0.py', '/api/study/content']:
            check(client.get(path).status_code == 404, f'Researcher/draft path is public: {path}')
        check(client.post('/api/study/submissions', json={'synthetic': True}).status_code in {404, 405}, 'E0 unexpectedly collects responses')
    report['checks'] = ['60 source-backed participant fields; no researcher properties in projection', '42 states/commands/source debug checksums/functions resolve', 'Pinned aggregate and invariant validation passed', 'T1–T5 evidence assertions passed', 'Researcher files and proposed study endpoint not served']
    output = output or ROOT / 'docs/evaluation-captures/e0-task-evidence.json'
    output.write_text(json.dumps(report, indent=2) + '\n')
    print('\n'.join(report['checks']))


if __name__ == '__main__':
    main()
