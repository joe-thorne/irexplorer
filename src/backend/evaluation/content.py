"""Shared participant content and answer validation, independent of compiler queries."""
import hashlib
import json
from copy import deepcopy
from dataclasses import dataclass
from functools import cache
from pathlib import Path

PACKAGE_PATH = Path(__file__).with_name('participant-package-v2.json')
MANIFEST_PATH = Path(__file__).with_name('public-manifest.json')

CONTENT_KEYS = frozenset({
    'instrumentVersion', 'contentVersion', 'studyVersion', 'scales', 'fields',
    'preSections', 'postSections', 'tasks', 'taskIntroduction', 'information',
    'membership', 'journey', 'glossary', 'messages',
})
IDENTITY_KEYS = frozenset({
    'identityVersion', 'algorithm', 'canonicalisation', 'canonicalisationVersion',
    'digest', 'instrumentVersion', 'contentVersion', 'studyVersion',
})
MANIFEST_KEYS = frozenset({'manifestSchemaVersion', 'packageSchemaVersion', 'identity', 'artifact'})


def canonical_bytes(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False).encode('utf-8')


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('Duplicate JSON object key')
        result[key] = value
    return result


def _reject_constant(_value):
    raise ValueError('Non-finite JSON number')


def _read_json(data):
    return json.loads(data, object_pairs_hook=_unique_object, parse_constant=_reject_constant)


def strict_json_loads(data):
    """Parse JSON, rejecting duplicate object keys and non-finite numbers."""
    return _read_json(data)


def _only(value, keys, label, *, required=()):
    if not isinstance(value, dict) or not set(required).issubset(value) or not set(value).issubset(keys):
        raise ValueError(f'Unsupported public participant structure: {label}')


def _strings(values, label):
    if not isinstance(values, list) or any(not isinstance(value, str) or not value for value in values):
        raise ValueError(f'Invalid public participant text list: {label}')


def _options(values, label):
    if not isinstance(values, list) or not values:
        raise ValueError(f'Invalid response options: {label}')
    seen = set()
    for option in values:
        _only(option, {'value', 'label'}, label, required={'value', 'label'})
        value = option['value']
        if type(value) is not int and not isinstance(value, str):
            raise ValueError(f'Invalid response option code: {label}')
        if not isinstance(option['label'], str) or not option['label'] or value in seen:
            raise ValueError(f'Invalid or duplicate response option: {label}')
        seen.add(value)
    return seen


def _membership(content):
    """Return each declared membership list after checking it against its owner."""
    fields = content['fields']
    if not isinstance(fields, list) or any(not isinstance(field, dict) or not isinstance(field.get('id'), str)
                                            for field in fields):
        raise ValueError('Invalid participant fields')
    field_ids = [field['id'] for field in fields]
    if len(set(field_ids)) != len(field_ids):
        raise ValueError('Duplicate participant field')
    owners = {'consent': list(content['membership'].get('consent', []))}
    for section in content['preSections']:
        owners[section['id']] = list(section.get('fields', []))
    for section in content['postSections']:
        owners[section['id']] = [field_id for group in section.get('groups', [])
                                 for field_id in group.get('fields', [])] or list(section.get('fields', []))
        for group in section.get('groups', []):
            owners[group['id']] = list(group.get('fields', []))
    for task in content['tasks']:
        owners[task['id']] = list(task.get('fields', []))
    pre = [field for section in content['preSections'] for field in section.get('fields', [])]
    post = [field_id for item in content['postSections'] for field_id in (
        [field_id for group in item.get('groups', []) for field_id in group.get('fields', [])]
        or item.get('fields', []))]
    owners.update({'pre': pre, 'post': post})
    declared = content['membership']
    if not isinstance(declared, dict) or set(declared) != set(owners):
        raise ValueError('Participant membership does not match its sections')
    for owner, member_ids in owners.items():
        if not isinstance(member_ids, list) or any(not isinstance(field_id, str) for field_id in member_ids):
            raise ValueError(f'Invalid membership for {owner}')
        if declared[owner] != member_ids:
            raise ValueError(f'Participant membership differs from {owner}')
        if len(set(member_ids)) != len(member_ids) or any(field_id not in field_ids for field_id in member_ids):
            raise ValueError(f'Unknown or duplicate field in {owner}')
    memberships = [declared['consent'], declared['pre'], declared['post'],
                   *(declared[task['id']] for task in content['tasks'])]
    flattened = [field_id for group in memberships for field_id in group]
    if len(flattened) != len(field_ids) or set(flattened) != set(field_ids):
        raise ValueError('Every participant field must have one explicit owner')
    return declared


def _validate_content(content, identity):
    if not isinstance(content, dict) or set(content) != CONTENT_KEYS:
        raise ValueError('Unsupported participant content schema')
    if not isinstance(identity, dict) or set(identity) != IDENTITY_KEYS:
        raise ValueError('Unsupported participant identity schema')
    if any(not isinstance(content.get(key), str) or not content[key]
           for key in ('instrumentVersion', 'contentVersion', 'studyVersion')):
        raise ValueError('Participant version tuple is incomplete')
    if any(identity[key] != content[key] for key in ('instrumentVersion', 'contentVersion', 'studyVersion')):
        raise ValueError('Participant identity tuple does not match content')
    if (type(identity['identityVersion']) is not int or identity['identityVersion'] != 1
            or type(identity['canonicalisationVersion']) is not int or identity['canonicalisationVersion'] != 1
            or identity['algorithm'] != 'sha256' or identity['canonicalisation'] != 'sorted-json-utf8-v1'
            or not isinstance(identity['digest'], str)
            or len(identity['digest']) != 64
            or any(char not in '0123456789abcdef' for char in identity['digest'])):
        raise ValueError('Unsupported participant identity')
    if not all(isinstance(content[key], expected) for key, expected in {
        'scales': dict, 'fields': list, 'preSections': list, 'postSections': list,
        'tasks': list, 'taskIntroduction': list, 'information': list, 'membership': dict,
        'journey': dict, 'glossary': list, 'messages': dict,
    }.items()):
        raise ValueError('Invalid participant content structure')
    for scale, values in content['scales'].items():
        if not isinstance(scale, str) or not scale:
            raise ValueError('Invalid scale identifier')
        _options(values, scale)
    membership = _membership(content)
    fields = {field['id']: field for field in content['fields']}
    required_by_type = {
        'boolean': {'id', 'prompt', 'type', 'required', 'presentation'},
        'single': {'id', 'prompt', 'type', 'required', 'presentation', 'options'},
        'multiple': {'id', 'prompt', 'type', 'required', 'presentation', 'options', 'exclusiveValue'},
        'rating': {'id', 'prompt', 'type', 'required', 'presentation', 'scale'},
        'text': {'id', 'prompt', 'type', 'required', 'presentation', 'maxLength'},
        'short_text': {'id', 'prompt', 'type', 'required', 'presentation', 'maxLength'},
    }
    allowed_by_type = {
        **required_by_type,
        'single': required_by_type['single'] | {'optionStatuses'},
        'multiple': required_by_type['multiple'] | {'optionStatuses'},
        'rating': required_by_type['rating'] | {'notApplicableLabel', 'optionStatuses'},
        'text': required_by_type['text'] | {'condition', 'inabilityLabel'},
        'short_text': required_by_type['short_text'] | {'condition', 'inabilityLabel'},
    }
    controls = {'checkbox', 'checkboxes', 'radio', 'select', 'textarea', 'input'}
    code_sets = {}
    for field in fields.values():
        kind = field.get('type')
        if kind not in allowed_by_type:
            raise ValueError(f"Unsupported response type for {field['id']}")
        _only(field, allowed_by_type[kind], f"field {field['id']}", required=required_by_type[kind])
        presentation = field.get('presentation')
        if (not isinstance(presentation, dict) or set(presentation) != {'control'}
                or presentation['control'] not in controls):
            raise ValueError(f"Invalid presentation hint for {field['id']}")
        if (not isinstance(field.get('prompt'), str) or not field['prompt']
                or not isinstance(field.get('required'), bool)):
            raise ValueError(f"Invalid participant field {field['id']}")
        control = presentation['control']
        controls_by_type = {
            'boolean': {'checkbox'}, 'single': {'radio', 'select'}, 'multiple': {'checkboxes'},
            'rating': {'radio', 'select'}, 'text': {'input', 'textarea'}, 'short_text': {'input', 'textarea'},
        }
        if control not in controls_by_type[kind]:
            raise ValueError(f"Presentation control does not match {field['id']}")
        if kind in ('single', 'multiple'):
            codes = _options(field['options'], field['id'])
        elif kind == 'rating':
            if field['scale'] not in content['scales']:
                raise ValueError(f"Unknown response scale for {field['id']}")
            codes = _options(content['scales'][field['scale']], field['scale'])
        elif kind in ('text', 'short_text'):
            codes = set()
            if type(field.get('maxLength')) is not int or not 1 <= field['maxLength'] <= 4000:
                raise ValueError(f"Invalid text limit for {field['id']}")
        else:
            codes = set()
        statuses = field.get('optionStatuses', {})
        if not isinstance(statuses, dict) or any(str(code) not in {str(value) for value in codes}
                                                 or status not in {'not_applicable', 'could_not_work_out'}
                                                 for code, status in statuses.items()):
            raise ValueError(f"Invalid special response status for {field['id']}")
        if kind == 'multiple' and field['exclusiveValue'] not in codes:
            raise ValueError(f"Unknown exclusive response code for {field['id']}")
        code_sets[field['id']] = codes
    base_owners = {'consent': set(membership['consent']), 'pre': set(membership['pre']),
                   'post': set(membership['post']), **{task['id']: set(membership[task['id']])
                                                       for task in content['tasks']}}
    for field in fields.values():
        condition = field.get('condition')
        if condition is None:
            continue
        _only(condition, {'field', 'values'}, f"condition for {field['id']}", required={'field', 'values'})
        parent_id, values = condition['field'], condition['values']
        if (parent_id not in fields or not isinstance(values, list) or not values
                or any(type(value) is not int and not isinstance(value, str) for value in values)
                or not any(field['id'] in owner and parent_id in owner for owner in base_owners.values())
                or not set(values).issubset(code_sets[parent_id])):
            raise ValueError(f"Invalid conditional response rule for {field['id']}")
    for section in [*content['preSections'], *content['postSections']]:
        allowed = {'id', 'title', 'intro', 'fields', 'groups'}
        _only(section, allowed, f"section {section.get('id')}", required={'id', 'title'})
        if 'intro' in section and not isinstance(section['intro'], str):
            raise ValueError(f"Invalid section introduction for {section['id']}")
        if 'fields' in section and not isinstance(section['fields'], list):
            raise ValueError(f"Invalid section membership for {section['id']}")
        for group in section.get('groups', []):
            _only(group, {'id', 'title', 'fields'}, f"group {group.get('id')}", required={'id', 'title', 'fields'})
    for task in content['tasks']:
        task_keys = {'id', 'title', 'goal', 'instructions', 'fields', 'setup', 'inheritWorkspace', 'entryWorkspace'}
        task_required = {'id', 'title', 'goal', 'instructions', 'fields', 'setup', 'entryWorkspace'}
        _only(task, task_keys, f"task {task.get('id')}", required=task_required)
        if not all(isinstance(task[key], str) and task[key] for key in ('title', 'goal', 'instructions')):
            raise ValueError(f"Invalid task text for {task['id']}")
        for workspace_key in ('setup', 'entryWorkspace'):
            workspace = task[workspace_key]
            if not isinstance(workspace, dict):
                raise ValueError(f"Invalid {workspace_key} for {task['id']}")
            if workspace_key == 'entryWorkspace':
                if set(workspace) == {'inherit', 'selection'}:
                    if workspace != {'inherit': 'previous', 'selection': 'clear'}:
                        raise ValueError(f"Invalid inherited workspace for {task['id']}")
                else:
                    _only(workspace, {'example', 'left', 'right', 'selection'},
                          f"entry workspace for {task['id']}", required={'example', 'left', 'right', 'selection'})
            else:
                _only(workspace, {'example', 'function', 'left', 'right'}, f"target setup for {task['id']}")
            for side in ('left', 'right'):
                if side in workspace:
                    _only(workspace[side], {'ordinal', 'view'}, f"{workspace_key} {side} for {task['id']}",
                          required={'ordinal', 'view'})
    for section in content['information']:
        _only(section, {'id', 'title', 'blocks'}, f"information section {section.get('id')}",
              required={'id', 'title', 'blocks'})
        for block in section['blocks']:
            _only(block, {'kind', 'text', 'items', 'id', 'role'},
                  f"information block {block.get('id')}", required={'kind', 'id', 'role'})
            if block['kind'] == 'paragraph':
                if set(block) != {'kind', 'text', 'id', 'role'} or not isinstance(block['text'], str):
                    raise ValueError('Invalid information paragraph')
            elif block['kind'] in ('ordered', 'unordered'):
                if set(block) != {'kind', 'items', 'id', 'role'}:
                    raise ValueError('Invalid information list')
                _strings(block['items'], f"information block {block['id']}")
            else:
                raise ValueError('Unsupported information block kind')
    if any(not isinstance(text, str) or not text for text in content['taskIntroduction']):
        raise ValueError('Invalid task introduction')
    _only(content['journey'], {'sectionOrder', 'taskOrder', 'introductions', 'timingPolicy'}, 'journey',
          required={'sectionOrder', 'taskOrder', 'introductions', 'timingPolicy'})
    journey = content['journey']
    _strings(journey['sectionOrder'], 'journey section order')
    _strings(journey['taskOrder'], 'journey task order')
    _only(journey['introductions'], {'pre', 'post'}, 'journey introductions', required={'pre', 'post'})
    if any(not isinstance(text, str) or not text for text in journey['introductions'].values()):
        raise ValueError('Invalid journey introduction')
    policy = journey['timingPolicy']
    _only(policy, {'measure', 'starts', 'includes', 'excludes', 'timeLimit', 'setupReachedCollected'},
          'journey timing policy', required={'measure', 'starts', 'includes', 'excludes', 'timeLimit',
                                              'setupReachedCollected'})
    _strings(policy['includes'], 'journey timing inclusions')
    _strings(policy['excludes'], 'journey timing exclusions')
    if (not isinstance(policy['measure'], str) or not isinstance(policy['starts'], str)
            or (policy['timeLimit'] is not None and type(policy['timeLimit']) is not int)
            or not isinstance(policy['setupReachedCollected'], bool)):
        raise ValueError('Invalid journey timing policy')
    for item in content['glossary']:
        _only(item, {'id', 'match', 'text'}, f"glossary item {item.get('id')}", required={'id', 'match', 'text'})
        if any(not isinstance(item[key], str) or not item[key] for key in ('id', 'match', 'text')):
            raise ValueError('Invalid glossary content')
    if any(not isinstance(key, str) or not isinstance(text, str) or not text
           for key, text in content['messages'].items()):
        raise ValueError('Invalid journey messages')
    role_blocks = [block for section in content['information'] for block in section.get('blocks', [])]
    roles = [block.get('role') for block in role_blocks]
    if roles.count('study-purpose') != 1 or roles.count('submission-guidance') != 1:
        raise ValueError('Study purpose and submission guidance roles must each occur once')
    return membership


def load_participant_package(package_path=PACKAGE_PATH, manifest_path=MANIFEST_PATH):
    """Verify the exact packaged bytes and canonical public identity before use."""
    package_path, manifest_path = Path(package_path), Path(manifest_path)
    if package_path.exists() != manifest_path.exists():
        raise ValueError('Participant package and public manifest must be installed together')
    if not package_path.exists():
        raise FileNotFoundError('The expanded participant package is not installed')
    package_bytes = package_path.read_bytes()
    manifest = _read_json(manifest_path.read_bytes())
    if not isinstance(manifest, dict) or set(manifest) != MANIFEST_KEYS:
        raise ValueError('Unsupported public manifest schema')
    artifact = manifest.get('artifact')
    if (type(manifest['manifestSchemaVersion']) is not int or manifest['manifestSchemaVersion'] != 1
            or type(manifest['packageSchemaVersion']) is not int or manifest['packageSchemaVersion'] != 2
            or not isinstance(artifact, dict) or set(artifact) != {'file', 'sha256'}
            or artifact['file'] != package_path.name
            or not isinstance(artifact['sha256'], str) or len(artifact['sha256']) != 64
            or any(char not in '0123456789abcdef' for char in artifact['sha256'])
            or artifact['sha256'] != hashlib.sha256(package_bytes).hexdigest()):
        raise ValueError('Public manifest does not match the participant package bytes')
    package = _read_json(package_bytes)
    if not isinstance(package, dict) or set(package) != {'packageSchemaVersion', 'identity', 'content'}:
        raise ValueError('Unsupported participant package structure')
    if (type(package['packageSchemaVersion']) is not int or package['packageSchemaVersion'] != 2
            or manifest['packageSchemaVersion'] != package['packageSchemaVersion']):
        raise ValueError('Unsupported participant package version')
    identity = package['identity']
    if manifest['identity'] != identity:
        raise ValueError('Public manifest identity does not match the package')
    _validate_content(package['content'], identity)
    content_snapshot(package)  # Rejects a package whose canonical bytes do not match its identity.
    return package


def _public_bytes(package):
    # Public identity covers only the package schema and participant content; deployment
    # collection flags are added later at the HTTP boundary and never enter these bytes.
    return canonical_bytes({'packageSchemaVersion': package['packageSchemaVersion'], 'content': package['content']})


@dataclass(frozen=True)
class ContentSnapshot:
    """Immutable canonical public participant content and the identity that names it."""
    digest: str
    algorithm: str
    identity_version: int
    canonicalisation: str
    canonicalisation_version: int
    package_schema_version: int
    instrument_version: str
    content_version: str
    study_version: str
    canonical_content: bytes


def stored_snapshot(row):
    """Rebuild a snapshot from a stored registry row, verifying its bytes against its identity.

    The row holds ContentSnapshot fields in declaration order. Raises ValueError when the digest,
    supported identity/canonicalisation versions, or the identities embedded in the bytes disagree.
    """
    snapshot = ContentSnapshot(*row)
    data = snapshot.canonical_content
    if (snapshot.algorithm != 'sha256' or not isinstance(data, bytes)
            or hashlib.sha256(data).hexdigest() != snapshot.digest
            or (snapshot.identity_version, snapshot.canonicalisation, snapshot.canonicalisation_version)
            != (1, 'sorted-json-utf8-v1', 1)):
        raise ValueError('Participant-content snapshot does not match its digest')
    try:
        public = _read_json(data)
        embedded = (public['packageSchemaVersion'], public['content']['instrumentVersion'],
                    public['content']['contentVersion'], public['content']['studyVersion'])
    except (ValueError, TypeError, KeyError):
        raise ValueError('Participant-content snapshot is not canonical public content') from None
    if embedded != (snapshot.package_schema_version, snapshot.instrument_version, snapshot.content_version,
                    snapshot.study_version):
        raise ValueError('Participant-content snapshot identities do not match its content')
    return snapshot


def content_snapshot(package):
    """Return the canonical public snapshot of a verified package, rechecking its digest."""
    identity = package['identity']
    data = _public_bytes(package)
    if hashlib.sha256(data).hexdigest() != identity['digest']:
        raise ValueError('Participant package canonical identity is invalid')
    return ContentSnapshot(
        identity['digest'], identity['algorithm'], identity['identityVersion'], identity['canonicalisation'],
        identity['canonicalisationVersion'], package['packageSchemaVersion'], identity['instrumentVersion'],
        identity['contentVersion'], identity['studyVersion'], data)


@cache
def _installed_package():
    return load_participant_package()


@cache
def participant_snapshot():
    """The installed package's snapshot, computed before any collection configuration applies."""
    return content_snapshot(_installed_package())


def participant_content():
    # StudyService loads this once during construction; cached immutable package
    # data is copied at the boundary so deployment flags cannot mutate it.
    package = _installed_package()
    return {'packageSchemaVersion': package['packageSchemaVersion'],
            'packageIdentity': deepcopy(package['identity']), **deepcopy(package['content'])}


def validate_answers(section, answers, *, complete=False):
    """Validate answers against explicit package membership and response rules."""
    content = participant_content()
    if (not isinstance(section, str) or section not in content['membership']
            or section == 'consent' or not isinstance(answers, dict)):
        return {'stage': 'Invalid survey.'}
    field_ids = content['membership'][section]
    fields = {field['id']: field for field in content['fields'] if field['id'] in field_ids}
    errors = {key: 'Unknown item.' for key in answers.keys() - fields.keys()}
    for key, field in fields.items():
        answer = answers.get(key, {'status': 'unanswered', 'value': None})
        if not isinstance(answer, dict) or set(answer) != {'status', 'value'}:
            errors[key] = 'Invalid answer.'
            continue
        status, value = answer['status'], answer['value']
        condition = field.get('condition')
        visible = True
        if condition:
            parent = answers.get(condition['field'])
            if not isinstance(parent, dict):
                parent = {}
            selected = parent.get('value')
            selected = selected if isinstance(selected, list) else [selected]
            visible = (parent.get('status') == 'answered'
                       and any(v in condition['values'] for v in selected))
        if not visible and (status != 'unanswered' or value is not None):
            errors[key] = 'Answer does not match this item’s options or text limit.'
            continue
        if status == 'unanswered' and value is None:
            if complete and field['required'] and visible:
                errors[key] = 'Choose an answer for P1.' if key == 'P1' else 'Complete this required follow-up.'
            continue
        if value is None and (
            (status == 'not_applicable'
             and (field.get('notApplicableLabel') or status in field.get('optionStatuses', {}).values()))
            or (status == 'could_not_work_out'
                and (field.get('inabilityLabel') or status in field.get('optionStatuses', {}).values()))
        ):
            continue
        valid = status == 'answered'
        if field['type'] in ('text', 'short_text'):
            valid = valid and isinstance(value, str) and bool(value.strip()) and len(value) <= field['maxLength']
        else:
            options = field.get('options') or content['scales'][field['scale']]
            allowed = {o['value'] for o in options if str(o['value']) not in field.get('optionStatuses', {})}
            values = value if field['type'] == 'multiple' else [value]
            valid = (valid and isinstance(values, list) and bool(values)
                     and all(type(v) is int and v in allowed for v in values))
            if valid:
                valid = (len(set(values)) == len(values)
                         and not (field.get('exclusiveValue') in values and len(values) > 1))
        if valid and 'condition' in field:
            condition = field['condition']
            parent = answers.get(condition['field'], {})
            selected = parent.get('value')
            selected = selected if isinstance(selected, list) else [selected]
            valid = parent.get('status') == 'answered' and any(v in condition['values'] for v in selected)
        if not valid:
            errors[key] = 'Answer does not match this item’s options or text limit.'
    return errors
