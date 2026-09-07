"""Build/check participant-only E4 content against unchanged parent instruments.

Run with --check for a non-mutating fidelity audit. No Markdown is served at runtime.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / 'Docs/evaluation'
TARGET = ROOT / 'src/backend/evaluation/participant-content.json'


def plain(text):
    text = re.sub(r'\[confirm[^\]]*\]', '', text)
    return text.replace('**', '').replace('`', '').strip()


def build():
    mapping = json.loads((SOURCE / 'e0-participant-content.json').read_text())
    private = json.loads((SOURCE / 'e0-researcher-mapping.json').read_text())
    for name, digest in private['sources'].items():
        assert hashlib.sha256((SOURCE / 'instruments' / name).read_bytes()).hexdigest() == digest, name
    raw = (SOURCE / 'instruments/00-participant-information.md').read_text()
    information = []
    for section in re.split(r'^## ', raw, flags=re.M)[1:]:
        title, body = section.split('\n', 1)
        if title == 'Consent':
            continue
        blocks = []
        for paragraph in re.split(r'\n\s*\n', body):
            paragraph = plain(paragraph)
            if not paragraph or paragraph == '---':
                continue
            if paragraph.startswith(('1. ', '- ')):
                blocks.append({'kind': 'ordered' if paragraph.startswith('1.') else 'list',
                               'items': [re.sub(r'^(?:\d+\.|-) ', '', line) for line in paragraph.splitlines()]})
            else:
                blocks.append({'kind': 'paragraph', 'text': paragraph})
        information.append({'title': title, 'blocks': blocks})
    fields = []
    for original in mapping['fields']:
        if original['id'].startswith('T'):
            continue
        field = {k: v for k, v in original.items() if k != 'source'}
        if field['type'] == 'text':
            field['maxLength'] = 4000
        if field['id'] in ('P3', 'P10'):
            field['exclusiveValue'] = 6
        if field['id'] == 'P2':
            field['optionStatuses'] = {'6': 'not_applicable'}
        conditions = {'P1.other': ('P1', [5]), 'P3.other': ('P3', [7]), 'P12.detail': ('P12', [2, 3])}
        if field['id'] in conditions:
            parent, values = conditions[field['id']]
            field['condition'] = {'field': parent, 'values': values}
        fields.append(field)
    return {
        'instrumentVersion': mapping['instrumentVersion'], 'contentVersion': 'e4-preview-1',
        'studyVersion': 'e4-synthetic-1', 'mode': 'preview', 'submissionEnabled': False,
        'scales': {k: v for k, v in mapping['scales'].items() if k != 'confidence'},
        'information': information, 'fields': fields,
        'preSections': [
            {'title': 'Section A — Background', 'fields': ['P1', 'P1.other', 'P2', 'P3', 'P3.other']},
            {'title': 'Section B — Familiarity', 'intro': 'For each of the following, how familiar are you?',
             'fields': [f'P{i}' for i in range(4, 13)] + ['P12.detail']},
            {'title': 'Section C — Expectation', 'intro': '2–3 sentences, optional.', 'fields': ['P13']}],
        'postSections': [
            {'title': 'Section A — Rating statements', 'intro': 'Strongly disagree · Disagree · Neither agree nor disagree · Agree · Strongly agree. Plus a separate Not applicable / did not use this option on every item.',
             'groups': [{'title': title, 'fields': [f'Q{i}' for i in ids]} for title, ids in [
                 ('Seeing what changed', range(1, 4)), ('Working out which pass was responsible', range(4, 6)),
                 ('The two views together', range(6, 9)), ('Exploring', range(9, 11)), ('Clarity', range(11, 13)), ('Trust', [13])]]},
            {'title': 'Section B — In your own words', 'intro': 'Answer as much or as little as you like. These matter more to the research than the ratings above.', 'fields': [f'Q{i}' for i in range(14, 19)]},
            {'title': 'Section C — Two closing questions', 'fields': ['Q19', 'Q20']}],
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, indent=2) + '\n'
    if args.check:
        assert TARGET.read_text() == text, 'E4 content differs from source mapping; rebuild/review it.'
        print('42 consent/survey fields, information prose, section order, options and scales match; four instrument hashes unchanged.')
    else:
        TARGET.write_text(text)
