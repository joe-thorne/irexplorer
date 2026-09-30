"""Final-only SQLite collection. No compiler/query dependencies or request logging."""
import hashlib
import json
import os
import re
import sqlite3
import tempfile
import uuid
from dataclasses import astuple, dataclass
from pathlib import Path

from src.backend.release import metadata

from .content import participant_content, participant_snapshot, validate_answers

ROOT = Path(__file__).resolve().parents[3]
UUID = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', re.I)
MAX_BODY = 128 * 1024
SCHEMA_VERSION = 3
SNAPSHOT_COLUMNS = ('digest', 'digest_algorithm', 'identity_version', 'canonicalisation',
                    'canonicalisation_version', 'package_schema_version', 'instrument_version',
                    'content_version', 'study_version', 'canonical_content')
# Version 3 adds the immutable participant-content registry. Submission columns and raw
# submission_json are unchanged; earlier rows keep an explicit unavailable-definition marker.
_SNAPSHOT_REGISTRY = (
    'CREATE TABLE participant_content (digest TEXT PRIMARY KEY NOT NULL, digest_algorithm TEXT NOT NULL, '
    'identity_version INTEGER NOT NULL, canonicalisation TEXT NOT NULL, canonicalisation_version INTEGER NOT NULL, '
    'package_schema_version INTEGER NOT NULL, instrument_version TEXT NOT NULL, content_version TEXT NOT NULL, '
    'study_version TEXT NOT NULL, canonical_content BLOB NOT NULL)',
    'ALTER TABLE submissions ADD COLUMN content_digest TEXT REFERENCES participant_content(digest)',
    "ALTER TABLE submissions ADD COLUMN content_provenance TEXT NOT NULL DEFAULT 'legacy_unavailable'",
    # Triggers hold regardless of a connection's foreign-key setting, including private CLI connections.
    'CREATE TRIGGER participant_content_immutable BEFORE UPDATE ON participant_content '
    "BEGIN SELECT RAISE(ABORT, 'Participant content snapshots are immutable'); END",
    'CREATE TRIGGER participant_content_referenced BEFORE DELETE ON participant_content '
    'WHEN EXISTS (SELECT 1 FROM submissions WHERE content_digest = OLD.digest) '
    "BEGIN SELECT RAISE(ABORT, 'Participant content snapshot is referenced'); END",
    'CREATE TRIGGER submissions_require_snapshot BEFORE INSERT ON submissions '
    "WHEN NEW.content_provenance IS NOT 'snapshot' OR NOT EXISTS "
    '(SELECT 1 FROM participant_content WHERE digest = NEW.content_digest) '
    "BEGIN SELECT RAISE(ABORT, 'New submissions require a registered participant-content snapshot'); END",
    'CREATE TRIGGER submissions_provenance_fixed BEFORE UPDATE OF content_digest, content_provenance ON submissions '
    "WHEN (OLD.content_provenance = 'snapshot' AND (NEW.content_provenance IS NOT 'snapshot' "
    'OR NEW.content_digest IS NOT OLD.content_digest)) '
    "OR (NEW.content_provenance = 'snapshot' AND NOT EXISTS "
    '(SELECT 1 FROM participant_content WHERE digest = NEW.content_digest)) '
    "OR (NEW.content_provenance IS NOT 'snapshot' AND (NEW.content_provenance IS NOT 'legacy_unavailable' "
    'OR NEW.content_digest IS NOT NULL)) '
    "BEGIN SELECT RAISE(ABORT, 'Submission content provenance cannot be replaced'); END",
)


class StudyError(Exception):
    def __init__(self, status, code, message):
        self.status, self.code, self.message = status, code, message


@dataclass(frozen=True)
class Config:
    directory: Path
    collection_mode: str = 'preview'
    origin: str = 'http://127.0.0.1:8000'
    app_revision: str = metadata()['revision']

    def __post_init__(self):
        if self.collection_mode not in ('local', 'preview', 'pilot', 'live'):
            raise ValueError('Unsupported collection mode')
        if self.directory.resolve().is_relative_to(ROOT):
            raise ValueError('Study storage must be outside the application repository')
        if not re.fullmatch(r'https?://[^/]+', self.origin):
            raise ValueError('Configure an exact origin without a trailing slash')

    @property
    def enabled(self):
        # Local assessment and legacy preview stores are separate from research data.
        return self.collection_mode in ('local', 'preview')

    @property
    def path(self):
        return self.directory / self.collection_mode / 'submissions.sqlite3'

    @classmethod
    def environment(cls):
        if 'IREXPLORER_STUDY_MODE' in os.environ:
            raise ValueError('IREXPLORER_STUDY_MODE was retired; use IREXPLORER_COLLECTION_MODE.')
        default = Path(tempfile.gettempdir()) / f'irexplorer-study-{os.getuid()}'
        return cls(Path(os.environ.get('IREXPLORER_STUDY_DIR', default)),
                   os.environ.get('IREXPLORER_COLLECTION_MODE', 'preview'),
                   os.environ.get('IREXPLORER_STUDY_ORIGIN', 'http://127.0.0.1:8000'),
                   os.environ.get('IREXPLORER_APP_REVISION', metadata()['revision']))


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def validate(submission):
    c = participant_content()
    keys = {'submissionId', 'participantCode', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consent',
            'pre', 'post', 'tasks'}
    def require(ok):
        if not ok:
            raise StudyError(422, 'invalid_submission',
                             'Check consent, P1, versions, task outcomes, and answer limits. No answers were changed.')
    require(isinstance(submission, dict) and set(submission) == keys)
    require(all(isinstance(submission[k], str) and UUID.fullmatch(submission[k])
                for k in ('submissionId', 'participantCode')))
    require(submission['submissionId'] != submission['participantCode'])
    require(all(submission[k] == c[k] for k in ('studyVersion', 'contentVersion', 'instrumentVersion')))
    consent = submission['consent']
    require(isinstance(consent, dict) and set(consent) == {'version', 'acknowledgements'})
    require(consent['version'] == c['contentVersion'])
    a = consent['acknowledgements']
    require(isinstance(a, dict) and set(a) == set(c['membership']['consent'])
            and all(v is True for v in a.values()))
    def answers(section, values):
        require(isinstance(values, dict)
                and set(values) == set(c['membership'][section]))
        require(not validate_answers(section, values, complete=True))
    answers('pre', submission['pre'])
    answers('post', submission['post'])
    ts = submission['tasks']
    require(isinstance(ts, list) and len(ts) == len(c['tasks']))
    for task, t in zip(c['tasks'], ts, strict=True):
        require(isinstance(t, dict)
                and set(t) == {'id', 'status', 'durationMs', 'interrupted', 'answers'})
        require(t['id'] == task['id']
                and t['status'] in (['completed'] if task['id'] == 'T0'
                                    else ['completed', 'skipped', 'could_not_work_out']))
        require(type(t['durationMs']) is int and 0 <= t['durationMs'] <= 86400000 and type(t['interrupted']) is bool)
        answers(t['id'], t['answers'])
    # Multi-choice order has no research meaning; preserve raw codes as a set.
    result = json.loads(canonical(submission))
    for group in [result['pre'], result['post'], *[t['answers'] for t in result['tasks']]]:
        for answer in group.values():
            if isinstance(answer['value'], list):
                answer['value'].sort()
    return result


class StudyService:
    def __init__(self, config):
        self.config = config
        # Fail application startup if the packaged public instrument is missing or its
        # manifest/identity does not verify. The snapshot is computed from the package
        # alone, before collection mode or enabled status can be attached to content.
        participant_content()
        self.snapshot = participant_snapshot()

    def content(self):
        return {**participant_content(), 'collectionMode': self.config.collection_mode,
                'submissionEnabled': self.config.enabled}

    def connect(self):
        path = self.config.path
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(path.parent, 0o700)
        legacy_path = path.with_name('responses.sqlite3')
        if legacy_path.exists():
            if path.exists():
                raise sqlite3.DatabaseError('Both the retired response store and submission store exist')
            try:
                os.replace(legacy_path, path)
            except FileNotFoundError:
                # Another request may have completed the one-time file move.
                if not path.exists():
                    raise
            for suffix in ('-wal', '-shm', '-journal'):
                old_sidecar = Path(str(legacy_path) + suffix)
                if old_sidecar.exists():
                    try:
                        os.replace(old_sidecar, Path(str(path) + suffix))
                    except FileNotFoundError:
                        if not Path(str(path) + suffix).exists():
                            raise
        db = sqlite3.connect(path, timeout=10)
        os.chmod(path, 0o600)
        try:
            db.execute('PRAGMA synchronous=FULL')
            db.execute('BEGIN IMMEDIATE')
            version = db.execute('PRAGMA user_version').fetchone()[0]
            if version not in (0, 1, 2, SCHEMA_VERSION):
                raise sqlite3.DatabaseError('Unsupported schema')
            if version == 0:
                db.execute('CREATE TABLE submissions (submission_id TEXT PRIMARY KEY, '
                           'digest TEXT NOT NULL, submission_json TEXT NOT NULL, receipt TEXT NOT NULL, '
                           'release TEXT NOT NULL)')
            elif version == 1:
                db.execute('ALTER TABLE responses RENAME TO submissions')
                db.execute('ALTER TABLE submissions RENAME COLUMN payload TO submission_json')
            if version != SCHEMA_VERSION:
                for statement in _SNAPSHOT_REGISTRY:
                    db.execute(statement)
                db.execute(f'PRAGMA user_version={SCHEMA_VERSION}')
            db.commit()
            return db
        except Exception:
            db.rollback()
            db.close()
            raise

    def register_snapshot(self, db):
        """Register this process's snapshot in the caller's open transaction, never replacing one."""
        expected = astuple(self.snapshot)  # Field order matches SNAPSHOT_COLUMNS.
        stored = db.execute(f"SELECT {', '.join(SNAPSHOT_COLUMNS)} FROM participant_content WHERE digest=?",
                            (self.snapshot.digest,)).fetchone()
        if stored is None:
            db.execute(f"INSERT INTO participant_content ({', '.join(SNAPSHOT_COLUMNS)}) "
                       f"VALUES ({', '.join('?' * len(SNAPSHOT_COLUMNS))})", expected)
        elif tuple(stored) != expected:
            raise sqlite3.IntegrityError('A registered snapshot differs from the packaged content with its digest')

    def submit(self, submission):
        if not self.config.enabled:
            raise StudyError(503, 'collection_disabled', 'Participant collection is not enabled.')
        submission = validate(submission)
        body = canonical(submission)
        digest = hashlib.sha256(body.encode()).hexdigest()
        receipt = {k: submission[k] for k in ('submissionId', 'participantCode', 'studyVersion')}
        receipt['receiptId'] = str(uuid.uuid4())
        checksum = next(line.split('=', 1)[1]
                        for line in (ROOT / 'docs/curated-artefacts.sha256').read_text().splitlines()
                        if line.startswith('sha256='))
        release = {'schemaVersion': 2, 'canonicalVersion': 1, 'mode': self.config.collection_mode,
                   'appRevision': self.config.app_revision, 'artefactSha256': checksum}
        db = None
        try:
            db = self.connect()
            with db:
                db.execute('BEGIN IMMEDIATE')
                row = db.execute('SELECT digest, receipt FROM submissions WHERE submission_id=?',
                                 (submission['submissionId'],)).fetchone()
                if row:
                    if row[0] != digest:
                        raise StudyError(409, 'submission_conflict',
                                         'This submission ID was used with different answers. '
                                         'Keep the code and contact the researcher.')
                    return json.loads(row[1]), False
                self.register_snapshot(db)
                db.execute('INSERT INTO submissions (submission_id, digest, submission_json, receipt, release, '
                           "content_digest, content_provenance) VALUES (?, ?, ?, ?, ?, ?, 'snapshot')",
                           (submission['submissionId'], digest, body, canonical(receipt), canonical(release),
                            self.snapshot.digest))
            # Leaving the transaction committed both rows; only now is a receipt returned.
            return receipt, True
        except (sqlite3.Error, OSError):
            raise StudyError(503, 'storage_unavailable',
                             'Receipt unavailable. Retain this tab and retry the same submission.') from None
        finally:
            if db is not None:
                db.close()
