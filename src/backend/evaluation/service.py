"""Final-only SQLite collection. No compiler/query dependencies or request logging."""
import hashlib
import json
import os
import re
import sqlite3
import tempfile
import uuid
from contextlib import suppress
from dataclasses import astuple, dataclass
from pathlib import Path
from typing import NamedTuple

from src.backend.release import metadata

from .content import (
    SUBMISSION_IDENTITY_KEYS,
    InstrumentRelease,
    packaged_release,
    participant_content,
    participant_snapshot,
    validate_answers,
)

ROOT = Path(__file__).resolve().parents[3]
UUID = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', re.I)
MAX_BODY = 128 * 1024
# Submission canonicalisation contract recorded in each row's release metadata. Receipt recovery
# applies a stored row's own version, so a change here needs a new version, never an edit.
CANONICAL_VERSION = 1
SCHEMA_VERSION = 3
SNAPSHOT_TABLE = 'participant_content_snapshots'
SNAPSHOT_COLUMNS = ('digest', 'digest_algorithm', 'identity_version', 'canonicalisation',
                    'canonicalisation_version', 'package_schema_version', 'instrument_version',
                    'content_version', 'study_version', 'canonical_content')
# content_provenance values: a new row names its snapshot; a row stored before schema 3
# has unavailable participant-content provenance and no digest.
PROVENANCE_SNAPSHOT = 'snapshot'
PROVENANCE_LEGACY_UNAVAILABLE = 'legacy_unavailable'
# Version 3 adds the immutable participant-content snapshot registry. Existing submission
# columns and raw submission_json are unchanged. Triggers hold regardless of a connection's
# foreign-key setting, including private CLI connections.
_SNAPSHOT_SCHEMA = (
    f'CREATE TABLE {SNAPSHOT_TABLE} (digest TEXT PRIMARY KEY NOT NULL, digest_algorithm TEXT NOT NULL, '
    'identity_version INTEGER NOT NULL, canonicalisation TEXT NOT NULL, canonicalisation_version INTEGER NOT NULL, '
    'package_schema_version INTEGER NOT NULL, instrument_version TEXT NOT NULL, content_version TEXT NOT NULL, '
    'study_version TEXT NOT NULL, canonical_content BLOB NOT NULL)',
    f'ALTER TABLE submissions ADD COLUMN content_digest TEXT REFERENCES {SNAPSHOT_TABLE}(digest)',
    f"ALTER TABLE submissions ADD COLUMN content_provenance TEXT NOT NULL DEFAULT '{PROVENANCE_LEGACY_UNAVAILABLE}' "
    f"CHECK (content_provenance IN ('{PROVENANCE_SNAPSHOT}', '{PROVENANCE_LEGACY_UNAVAILABLE}'))",
    f'CREATE TRIGGER snapshots_immutable BEFORE UPDATE ON {SNAPSHOT_TABLE} '
    "BEGIN SELECT RAISE(ABORT, 'Participant-content snapshots are immutable'); END",
    f'CREATE TRIGGER snapshots_referenced BEFORE DELETE ON {SNAPSHOT_TABLE} '
    'WHEN EXISTS (SELECT 1 FROM submissions WHERE content_digest = OLD.digest) '
    "BEGIN SELECT RAISE(ABORT, 'Participant-content snapshot is referenced'); END",
    'CREATE TRIGGER submissions_require_snapshot BEFORE INSERT ON submissions '
    f"WHEN NEW.content_provenance IS NOT '{PROVENANCE_SNAPSHOT}' "
    f'OR NOT EXISTS (SELECT 1 FROM {SNAPSHOT_TABLE} WHERE digest = NEW.content_digest) '
    "BEGIN SELECT RAISE(ABORT, 'New submissions require a registered participant-content snapshot'); END",
    'CREATE TRIGGER submissions_provenance_immutable BEFORE UPDATE OF content_digest, content_provenance '
    "ON submissions BEGIN SELECT RAISE(ABORT, 'Submission content provenance is immutable'); END",
)


class StudyError(Exception):
    def __init__(self, status, code, message):
        self.status, self.code, self.message = status, code, message


def storage_unavailable():
    """The retryable storage failure; it never names a path, SQL error, or stored answer."""
    return StudyError(503, 'storage_unavailable', 'Receipt unavailable. Retain this tab and retry the same submission.')


class StoredSubmission(NamedTuple):
    """The stored columns a retry is compared with; field names are the column names."""
    digest: str
    submission_json: str
    receipt: str
    release: str

    @classmethod
    def find(cls, db, submission_id):
        row = db.execute(f"SELECT {', '.join(cls._fields)} FROM submissions WHERE submission_id=?",
                         (submission_id,)).fetchone()
        return None if row is None else cls(*row)


@dataclass(frozen=True)
class Config:
    directory: Path
    collection_mode: str = 'preview'
    origin: str = 'http://127.0.0.1:8000'
    app_revision: str = metadata()['revision']
    # Directories of frozen public packages accepted for first deliveries besides the installed one.
    # Empty by default: only the installed package is accepted, with no grace period.
    accepted_instruments: tuple[Path, ...] = ()

    def __post_init__(self):
        if self.collection_mode not in ('local', 'preview', 'pilot', 'live'):
            raise ValueError('Unsupported collection mode')
        if not all(isinstance(path, Path) and path.is_absolute() for path in self.accepted_instruments):
            raise ValueError('Configure each accepted instrument package as an absolute directory')
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
                   os.environ.get('IREXPLORER_APP_REVISION', metadata()['revision']),
                   tuple(Path(directory) for directory
                         in os.environ.get('IREXPLORER_ACCEPTED_INSTRUMENTS', '').split(os.pathsep) if directory))


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def canonical_submission(submission):
    """Apply canonicalisation version 1 without consulting any instrument.

    Multi-choice order has no research meaning, so answer values that are lists are stored as
    sorted sets; `canonical` then fixes key order and encoding. Structure the contract does not
    recognise is left as sent, so it can only match a stored record that is identical.
    """
    result = json.loads(canonical(submission))
    if not isinstance(result, dict):
        return result
    tasks = result.get('tasks') if isinstance(result.get('tasks'), list) else []
    groups = [result.get('pre'), result.get('post'), *[t.get('answers') for t in tasks if isinstance(t, dict)]]
    for group in groups:
        for answer in group.values() if isinstance(group, dict) else ():
            if isinstance(answer, dict) and isinstance(answer.get('value'), list):
                with suppress(TypeError):  # Mixed values cannot be a stored multi-choice answer.
                    answer['value'] = sorted(answer['value'])
    return result


def receipt_for_retry(stored, submission):
    """Return the stored receipt for an identical retry, or raise a conflict that discloses nothing.

    The retry must name the stored instrument identities and match the stored digest under the
    row's own canonicalisation version; current-instrument rules are not consulted.
    """
    try:
        stored_submission = json.loads(stored.submission_json)
        canonical_version = json.loads(stored.release).get('canonicalVersion', CANONICAL_VERSION)
    except (ValueError, AttributeError):
        # An unreadable stored record is a storage fault, not a statement about this retry.
        raise storage_unavailable() from None
    if (canonical_version == CANONICAL_VERSION
            and isinstance(stored_submission, dict)
            and all(submission.get(key) == stored_submission.get(key) for key in SUBMISSION_IDENTITY_KEYS)
            and hashlib.sha256(canonical(canonical_submission(submission)).encode()).hexdigest() == stored.digest):
        return json.loads(stored.receipt)
    raise StudyError(409, 'submission_conflict',
                     'This submission ID was used with different answers. Keep the code and contact the researcher.')


def accepted_releases(installed, directories):
    """The instrument releases first deliveries may name, keyed by their identities.

    The installed release is always accepted; any other only when its frozen public pair is one of
    the server-configured `directories`. Every configured pair is verified before collection starts.
    """
    releases = {}
    for release in (installed, *map(packaged_release, directories)):
        if release.identities in releases:
            raise ValueError('Accepted instrument packages must have distinct study/content/instrument identities')
        releases[release.identities] = release
    return releases


INVALID_MESSAGE = 'Check consent, P1, versions, task outcomes, and answer limits. No answers were changed.'


def validate(submission, releases):
    """Validate a first delivery under the accepted release it names; return it canonicalised and that release."""
    keys = {'submissionId', 'participantCode', 'studyVersion', 'contentVersion', 'instrumentVersion', 'consent',
            'pre', 'post', 'tasks'}
    def require(ok):
        if not ok:
            raise StudyError(422, 'invalid_submission', INVALID_MESSAGE)
    require(isinstance(submission, dict) and set(submission) == keys)
    require(all(isinstance(submission[k], str) and UUID.fullmatch(submission[k])
                for k in ('submissionId', 'participantCode')))
    require(submission['submissionId'] != submission['participantCode'])
    release = releases.get(tuple(submission[key] for key in SUBMISSION_IDENTITY_KEYS))
    if release is None:
        # Nothing is stored and nothing is rewritten; the same message, with a code the browser can act on.
        raise StudyError(422, 'unsupported_instrument', INVALID_MESSAGE)
    c = release.content
    consent = submission['consent']
    require(isinstance(consent, dict) and set(consent) == {'version', 'acknowledgements'})
    require(consent['version'] == c['contentVersion'])
    a = consent['acknowledgements']
    require(isinstance(a, dict) and set(a) == set(c['membership']['consent'])
            and all(v is True for v in a.values()))
    def answers(section, values):
        require(isinstance(values, dict)
                and set(values) == set(c['membership'][section]))
        require(not validate_answers(section, values, complete=True, content=c))
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
    return canonical_submission(submission), release


class StudyService:
    def __init__(self, config):
        self.config = config
        # Fail application startup if the packaged public instrument is missing or its
        # manifest/identity does not verify. The snapshot is computed from the package
        # alone, before collection mode or enabled status can be attached to content.
        participant_content()
        self.snapshot = participant_snapshot()
        self.releases = accepted_releases(InstrumentRelease(participant_content(), self.snapshot),
                                          config.accepted_instruments)

    def content(self):
        return {**participant_content(), 'collectionMode': self.config.collection_mode,
                'submissionEnabled': self.config.enabled}

    def _retired_path(self):
        return self.config.path.with_name('responses.sqlite3')

    def connect(self):
        path = self.config.path
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        os.chmod(path.parent, 0o700)
        legacy_path = self._retired_path()
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
                for statement in _SNAPSHOT_SCHEMA:
                    db.execute(statement)
                db.execute(f'PRAGMA user_version={SCHEMA_VERSION}')
            db.commit()
            return db
        except Exception:
            db.rollback()
            db.close()
            raise

    @staticmethod
    def register_snapshot(db, snapshot):
        """Register a verified release's snapshot in the caller's open transaction, never replacing one."""
        expected = astuple(snapshot)  # Field order matches SNAPSHOT_COLUMNS.
        stored = db.execute(f"SELECT {', '.join(SNAPSHOT_COLUMNS)} FROM {SNAPSHOT_TABLE} WHERE digest=?",
                            (snapshot.digest,)).fetchone()
        if stored is None:
            db.execute(f"INSERT INTO {SNAPSHOT_TABLE} ({', '.join(SNAPSHOT_COLUMNS)}) "
                       f"VALUES ({', '.join('?' * len(SNAPSHOT_COLUMNS))})", expected)
        elif tuple(stored) != expected:
            raise sqlite3.IntegrityError('A registered snapshot differs from the packaged content with its digest')

    def stored_receipt(self, submission):
        """Look up an already-committed submission ID before any current-instrument validation.

        A committed submission keeps its receipt across application and package upgrades. Returns
        None when nothing is committed under the ID, so the submission is a first delivery.
        """
        submission_id = submission.get('submissionId') if isinstance(submission, dict) else None
        # Without an existing store nothing can be committed, so a lookup never creates one. An
        # existing older store is moved and migrated here, as on any first use.
        if not isinstance(submission_id, str) or not (self.config.path.exists() or self._retired_path().exists()):
            return None
        db = None
        try:
            db = self.connect()
            stored = StoredSubmission.find(db, submission_id)
        except (sqlite3.Error, OSError):
            raise storage_unavailable() from None
        finally:
            if db is not None:
                db.close()
        return None if stored is None else receipt_for_retry(stored, submission)

    def submit(self, submission):
        if not self.config.enabled:
            raise StudyError(503, 'collection_disabled', 'Participant collection is not enabled.')
        receipt = self.stored_receipt(submission)
        if receipt is not None:
            return receipt, False
        submission, instrument = validate(submission, self.releases)
        body = canonical(submission)
        digest = hashlib.sha256(body.encode()).hexdigest()
        receipt = {k: submission[k] for k in ('submissionId', 'participantCode', 'studyVersion')}
        receipt['receiptId'] = str(uuid.uuid4())
        checksum = next(line.split('=', 1)[1]
                        for line in (ROOT / 'docs/curated-artefacts.sha256').read_text().splitlines()
                        if line.startswith('sha256='))
        release = {'schemaVersion': 2, 'canonicalVersion': CANONICAL_VERSION, 'mode': self.config.collection_mode,
                   'appRevision': self.config.app_revision, 'artefactSha256': checksum}
        db = None
        try:
            db = self.connect()
            with db:
                db.execute('BEGIN IMMEDIATE')
                # A concurrent first delivery of the same ID may have committed since stored_receipt().
                stored = StoredSubmission.find(db, submission['submissionId'])
                if stored:
                    return receipt_for_retry(stored, submission), False
                self.register_snapshot(db, instrument.snapshot)
                db.execute('INSERT INTO submissions (submission_id, digest, submission_json, receipt, release, '
                           'content_digest, content_provenance) VALUES (?, ?, ?, ?, ?, ?, ?)',
                           (submission['submissionId'], digest, body, canonical(receipt), canonical(release),
                            instrument.snapshot.digest, PROVENANCE_SNAPSHOT))
            # Leaving the transaction committed both rows; only now is a receipt returned.
            return receipt, True
        except (sqlite3.Error, OSError):
            raise storage_unavailable() from None
        finally:
            if db is not None:
                db.close()
