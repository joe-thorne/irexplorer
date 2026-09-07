"""Shared survey definition and validation, independent of compiler queries."""
import json
from pathlib import Path


def participant_content():
    # This file contains only participant content. Explicit top-level allowlist
    # prevents future private release/analysis metadata becoming public by default.
    definition = json.loads(Path(__file__).with_name('participant-content.json').read_text())
    return {key: definition[key] for key in (
        'instrumentVersion', 'contentVersion', 'studyVersion', 'mode', 'submissionEnabled',
        'scales', 'information', 'fields', 'preSections', 'postSections',
    )}


def validate_answers(stage, answers, *, complete=False):
    """Validate E4 raw survey values; E6 still owns the submission envelope.

    Return item errors without echoing answers. Missing optional items remain
    unanswered. In-progress drafts may omit P1; a completed pre-survey may not.
    """
    content = participant_content()
    if stage not in ('pre', 'post') or not isinstance(answers, dict):
        return {'stage': 'Invalid survey.'}
    fields = {f['id']: f for f in content['fields'] if f['id'].startswith('P' if stage == 'pre' else 'Q')}
    errors = {key: 'Unknown item.' for key in answers.keys() - fields.keys()}
    for key, field in fields.items():
        answer = answers.get(key, {'status': 'unanswered', 'value': None})
        if not isinstance(answer, dict) or set(answer) != {'status', 'value'}:
            errors[key] = 'Invalid answer.'
            continue
        status, value = answer['status'], answer['value']
        if status == 'unanswered' and value is None:
            if complete and field['required']:
                errors[key] = 'Choose an answer for P1.'
            continue
        if status == 'not_applicable' and value is None and (field.get('notApplicableLabel') or field.get('optionStatuses')):
            continue
        valid = status == 'answered'
        if field['type'] == 'text':
            valid = valid and isinstance(value, str) and bool(value.strip()) and len(value) <= field['maxLength']
        else:
            options = field.get('options') or content['scales'][field['scale']]
            allowed = {o['value'] for o in options if str(o['value']) not in field.get('optionStatuses', {})}
            values = value if field['type'] == 'multiple' else [value]
            valid = valid and isinstance(values, list) and bool(values) and all(type(v) is int and v in allowed for v in values)
            if valid:
                valid = len(set(values)) == len(values) and not (field.get('exclusiveValue') in values and len(values) > 1)
        if valid and 'condition' in field:
            condition = field['condition']
            parent = answers.get(condition['field'], {})
            selected = parent.get('value')
            selected = selected if isinstance(selected, list) else [selected]
            valid = parent.get('status') == 'answered' and any(v in condition['values'] for v in selected)
        if not valid:
            errors[key] = 'Answer does not match this item’s options or text limit.'
    return errors
