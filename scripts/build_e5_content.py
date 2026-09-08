"""Assemble participant-only tasks from the unchanged runsheet and E0 field audit."""
import argparse
import json
from build_e4_content import build as surveys, SOURCE, TARGET, plain


def build():
    content = surveys()  # Also verifies all four original instrument hashes.
    mapping = json.loads((SOURCE / 'e0-participant-content.json').read_text())
    content.update(contentVersion='e5-preview-1', studyVersion='e5-synthetic-1')
    content['scales'] = mapping['scales']
    for original in mapping['fields']:
        if not original['id'].startswith('T'):
            continue
        field = {k: v for k, v in original.items() if k != 'source'}
        if field['type'] in ('text', 'short_text'):
            field['maxLength'] = 256 if field['type'] == 'short_text' else 4000
        if field['id'] == 'T2a':
            field['optionStatuses'] = {'11': 'could_not_work_out'}
        if field['id'] in ('T3a', 'T4a'):
            field['inabilityLabel'] = 'I could not work this out'
        content['fields'].append(field)
    setups = [
        {'example': 'score', 'left': {'ordinal': 0, 'view': 'ir'}, 'right': {'ordinal': 1, 'view': 'ir'}},
        {'example': 'score', 'left': {'ordinal': 0, 'view': 'ir'}, 'right': {'ordinal': 12, 'view': 'ir'}},
        {'example': 'score', 'left': {'ordinal': 0, 'view': 'ir'}, 'right': {'ordinal': 0, 'view': 'ir'}},
        {'example': 'binary_search', 'left': {'ordinal': 3, 'view': 'ir'}, 'right': {'ordinal': 3, 'view': 'cfg'}},
        {'example': 'binary_search', 'left': {'ordinal': 6, 'view': 'cfg'}, 'right': {'ordinal': 7, 'view': 'cfg'}},
        {'example': 'quick_sort', 'left': {'ordinal': 0, 'view': 'ir'}, 'right': {'ordinal': 9, 'view': 'ir'}},
        {},
    ]
    raw = (SOURCE / 'instruments/02-task-runsheet.md').read_text()
    content['taskIntroduction'] = [
        plain(raw.split('## Before you start\n\n')[1].split('\n\n')[0]),
        # Accurate generation description required by the web plan, not a change to the source instrument.
        'Each program has fourteen recorded states: an unoptimised baseline, twelve successive states produced by running the teaching passes on the preceding output, and a separately compiled -O3 state for comparison.',
        'If a task defeats you, say so and move on. Six tasks in twenty minutes is a deliberately brisk pace and nobody is expected to finish all of them cleanly.',
    ]
    content['tasks'] = []
    for n in range(7):
        tid = f'T{n}'
        section = raw.split(f'## {tid} — ', 1)[1].split('\n## ', 1)[0]
        title, body = section.split('\n', 1)
        title = title.split(' *(')[0]
        goal = plain(body.split('**Goal:** ', 1)[1].split('\n', 1)[0])
        instructions = body.split('**Goal:** ', 1)[1].split('\n', 1)[1]
        instructions = instructions.split(f'**{tid}a.**')[0].split('> *[Facilitator')[0].strip().removesuffix('---').strip()
        instructions = plain(instructions.replace('```c\n', '').replace('```', ''))
        content['tasks'].append({'id': tid, 'title': title, 'goal': goal, 'instructions': instructions,
                                 'fields': [f['id'] for f in content['fields'] if f['id'].startswith(tid)],
                                 'setup': setups[n]})
    return content


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, indent=2) + '\n'
    if args.check:
        assert TARGET.read_text() == text, 'E5 content differs from source mapping.'
        print('60 fields, T0–T6 goals/instructions/setups and scales match; four original instruments unchanged.')
    else:
        TARGET.write_text(text)
