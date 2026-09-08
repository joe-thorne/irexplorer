"""Final-only SQLite collection. No compiler/query dependencies or request logging."""
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import tempfile
import uuid
from dataclasses import dataclass

from .content import participant_content, validate_answers

ROOT = Path(__file__).resolve().parents[3]
UUID = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', re.I)
MAX_BODY = 128 * 1024


class StudyError(Exception):
    def __init__(self, status, code, message):
        self.status, self.code, self.message = status, code, message


@dataclass(frozen=True)
class Config:
    directory: Path
    mode: str = 'preview'
    origin: str = 'http://127.0.0.1:8000'
    app_revision: str = 'e6-submission-1'

    def __post_init__(self):
        if self.mode not in ('preview', 'pilot', 'live'):
            raise ValueError('Unsupported collection mode')
        if self.directory.resolve().is_relative_to(ROOT.parent):
            raise ValueError('Study storage must be outside the project repositories')
        if not re.fullmatch(r'https?://[^/]+', self.origin):
            raise ValueError('Configure an exact origin without a trailing slash')

    @property
    def enabled(self):
        # The inherited consent is synthetic-only. E7/E8 must version/freeze it
        # before participant collection can be enabled, even by an operator.
        return self.mode == 'preview'

    @property
    def path(self):
        return self.directory / self.mode / 'responses.sqlite3'

    @classmethod
    def environment(cls):
        default = Path(tempfile.gettempdir()) / f'irexplorer-study-{os.getuid()}'
        return cls(Path(os.environ.get('IREXPLORER_STUDY_DIR', default)),
                   os.environ.get('IREXPLORER_STUDY_MODE', 'preview'),
                   os.environ.get('IREXPLORER_STUDY_ORIGIN', 'http://127.0.0.1:8000'),
                   os.environ.get('IREXPLORER_APP_REVISION', 'e6-submission-1'))


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def validate(payload):
    c = participant_content()
    keys = {'submissionId', 'participantCode', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consent', 'pre', 'post', 'tasks'}
    def require(ok):
        if not ok:
            raise StudyError(422, 'invalid_submission', 'Check consent, P1, versions, task outcomes, and answer limits. No answers were changed.')
    require(isinstance(payload, dict) and set(payload) == keys)
    require(all(isinstance(payload[k], str) and UUID.fullmatch(payload[k]) for k in ('submissionId', 'participantCode')))
    require(payload['submissionId'] != payload['participantCode'])
    require(all(payload[k] == c[k] for k in ('studyVersion', 'contentVersion', 'instrumentVersion')))
    consent = payload['consent']
    require(isinstance(consent, dict) and set(consent) == {'version', 'acknowledgements'})
    require(consent['version'] == c['contentVersion'])
    a = consent['acknowledgements']
    require(isinstance(a, dict) and set(a) == {f['id'] for f in c['fields'] if f['id'].startswith('C')} and all(v is True for v in a.values()))
    def answers(stage, values):
        prefix = {'pre': 'P', 'post': 'Q'}.get(stage, stage)
        require(isinstance(values, dict) and set(values) == {f['id'] for f in c['fields'] if f['id'].startswith(prefix)})
        require(not validate_answers(stage, values, complete=True))
    answers('pre', payload['pre'])
    answers('post', payload['post'])
    ts = payload['tasks']
    require(isinstance(ts, list) and len(ts) == 7)
    for i, t in enumerate(ts):
        require(isinstance(t, dict) and set(t) == {'id', 'status', 'durationMs', 'interrupted', 'answers'})
        require(t['id'] == f'T{i}' and t['status'] in (['completed'] if i == 0 else ['completed', 'skipped', 'could_not_work_out']))
        require(type(t['durationMs']) is int and 0 <= t['durationMs'] <= 86400000 and type(t['interrupted']) is bool)
        answers(t['id'], t['answers'])
    # Multi-choice order has no research meaning; preserve raw codes as a set.
    result = json.loads(canonical(payload))
    for group in [result['pre'], result['post'], *[t['answers'] for t in result['tasks']]]:
        for answer in group.values():
            if isinstance(answer['value'], list):
                answer['value'].sort()
    return result


class StudyService:
    def __init__(self, config):
        self.config = config

    def content(self):
        return {**participant_content(), 'mode': self.config.mode, 'submissionEnabled': self.config.enabled}

    def connect(self):
        path = self.config.path
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(path.parent, 0o700)
        db = sqlite3.connect(path, timeout=10)
        os.chmod(path, 0o600)
        try:
            db.execute('PRAGMA synchronous=FULL')
            version = db.execute('PRAGMA user_version').fetchone()[0]
            if version not in (0, 1):
                raise sqlite3.DatabaseError('Unsupported schema')
            if version == 0:
                db.execute('CREATE TABLE IF NOT EXISTS responses (submission_id TEXT PRIMARY KEY, digest TEXT NOT NULL, payload TEXT NOT NULL, receipt TEXT NOT NULL, release TEXT NOT NULL)')
                db.execute('PRAGMA user_version=1')
                db.commit()
            return db
        except Exception:
            db.close()
            raise

    def submit(self, payload):
        if not self.config.enabled:
            raise StudyError(503, 'collection_disabled', 'Participant collection is not enabled.')
        payload = validate(payload)
        body = canonical(payload)
        digest = hashlib.sha256(body.encode()).hexdigest()
        receipt = {k: payload[k] for k in ('submissionId', 'participantCode', 'studyVersion')}
        receipt['receiptId'] = str(uuid.uuid4())
        checksum = next(line.split('=', 1)[1] for line in (ROOT / 'docs/curated-artefacts.sha256').read_text().splitlines() if line.startswith('sha256='))
        release = {'schemaVersion': 1, 'canonicalVersion': 1, 'mode': self.config.mode,
                   'appRevision': self.config.app_revision, 'artefactSha256': checksum}
        db = None
        try:
            db = self.connect()
            with db:
                db.execute('BEGIN IMMEDIATE')
                row = db.execute('SELECT digest, receipt FROM responses WHERE submission_id=?', (payload['submissionId'],)).fetchone()
                if row:
                    if row[0] != digest:
                        raise StudyError(409, 'submission_conflict', 'This submission ID was used with different answers. Keep the code and contact the researcher.')
                    return json.loads(row[1]), False
                db.execute('INSERT INTO responses VALUES (?, ?, ?, ?, ?)', (payload['submissionId'], digest, body, canonical(receipt), canonical(release)))
            return receipt, True
        except (sqlite3.Error, OSError):
            raise StudyError(503, 'storage_unavailable', 'Receipt unavailable. Retain this tab and retry the same submission.') from None
        finally:
            if db is not None:
                db.close()
