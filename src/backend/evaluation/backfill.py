"""Verify explicit evidence linking legacy submissions to exact historical participant content.

The private provenance backfill links a record stored before participant-content snapshots only
when the researcher names the record, its stored submission digest, and a content digest, and
supplies the frozen public package with that digest. A version label alone never selects
content, and current packaged content is never consulted. Records nobody links, or whose link
does not verify, keep their unavailable provenance.
"""
import json
import sqlite3
from dataclasses import dataclass
from pathlib import Path

from .content import SUBMISSION_IDENTITY_KEYS, InstrumentRelease, packaged_release, strict_json_loads
from .service import (
    PROVENANCE_SNAPSHOT,
    SNAPSHOT_TABLE,
    StudyError,
    StudyService,
    canonical,
    validate,
)

LINKS_SCHEMA_VERSION = 1
LINK_KEYS = frozenset({'submissionId', 'submissionDigest', 'contentDigest'})
# Stored with each backfilled row, so exports distinguish it from a link made at submission.
BACKFILL_EVIDENCE = {'backfillVersion': 1, 'evidence': 'frozen-public-package'}


class BackfillError(ValueError):
    """Backfill evidence does not verify. Messages name the failed check, never stored answers."""


@dataclass(frozen=True)
class BackfillEvidence:
    """Verified frozen releases, keyed by content digest, and the researcher's explicit links."""
    releases: dict[str, InstrumentRelease]
    links: tuple[dict[str, str], ...]


@dataclass(frozen=True)
class BackfillResult:
    linked: int
    unchanged: int


def load_evidence(release_directories, links_path):
    """Verify every supplied frozen public package and read the links file, before any store is touched.

    Each directory holds a frozen public pair (`participant-package-v2.json` and
    `public-manifest.json`), checked like an installed package: exact bytes, manifest, schema, and
    canonical identity. The links file is `{"backfillSchemaVersion": 1, "links": [...]}` with one
    `{submissionId, submissionDigest, contentDigest}` object per record, each record at most once.
    """
    releases = {}
    for position, directory in enumerate(release_directories, start=1):
        try:
            release = packaged_release(Path(directory))
        except (OSError, ValueError, TypeError, KeyError):
            raise BackfillError(f'release {position}: the frozen public package does not verify') from None
        releases.setdefault(release.snapshot.digest, release)
    if not releases:
        raise BackfillError('no frozen release was supplied')
    try:
        data = strict_json_loads(Path(links_path).read_bytes())
    except OSError:
        raise BackfillError('the links file cannot be read') from None
    except ValueError:
        raise BackfillError('the links file is not strict JSON') from None
    links = data.get('links') if isinstance(data, dict) else None
    if (not isinstance(data, dict) or set(data) != {'backfillSchemaVersion', 'links'}
            or type(data['backfillSchemaVersion']) is not int or data['backfillSchemaVersion'] != LINKS_SCHEMA_VERSION
            or not isinstance(links, list) or not links):
        raise BackfillError('unsupported links file')
    seen = set()
    for position, link in enumerate(links, start=1):
        if (not isinstance(link, dict) or set(link) != LINK_KEYS
                or not all(isinstance(value, str) for value in link.values())):
            raise BackfillError(f'link {position}: unsupported link')
        if link['submissionId'] in seen:
            raise BackfillError(f'link {position}: the submission is linked more than once')
        seen.add(link['submissionId'])
    return BackfillEvidence(releases, tuple(links))


def link_verified_records(db, evidence):
    """Apply every link in the caller's open transaction, or raise BackfillError for the first that fails.

    The caller rolls back on failure, so a run links all of its records or none.
    """
    linked = unchanged = 0
    for position, link in enumerate(evidence.links, start=1):
        try:
            changed = _link(db, link, evidence.releases)
        except BackfillError as error:
            raise BackfillError(f'link {position}: {error}') from None
        linked += changed
        unchanged += not changed
    return BackfillResult(linked, unchanged)


def _link(db, link, releases):
    """Link one legacy record after verifying it; return False when it already has this exact link."""
    row = db.execute('SELECT digest, submission_json, content_provenance, content_digest FROM submissions '
                     'WHERE submission_id=?', (link['submissionId'],)).fetchone()
    if row is None:
        raise BackfillError('the submission is not in the store')
    submission_digest, submission_json, provenance, content_digest = row
    if submission_digest != link['submissionDigest']:
        raise BackfillError('the submission digest does not match the stored record')
    if provenance == PROVENANCE_SNAPSHOT:
        if content_digest == link['contentDigest']:
            return False
        raise BackfillError('the stored record already links different participant content; nothing was replaced')
    release = releases.get(link['contentDigest'])
    if release is None:
        raise BackfillError('no supplied frozen release has the declared content digest')
    try:
        submission = json.loads(submission_json)
    except ValueError:
        raise BackfillError('the stored record is not readable') from None
    identities = tuple(submission.get(key) for key in SUBMISSION_IDENTITY_KEYS) if isinstance(submission, dict) else ()
    if identities != release.identities:
        raise BackfillError('the stored record names different study/content/instrument identities')
    known = {digest for digest, other in releases.items() if other.identities == identities}
    known.update(digest for (digest,) in db.execute(
        f'SELECT digest FROM {SNAPSHOT_TABLE} WHERE study_version=? AND content_version=? AND instrument_version=?',
        identities))
    if known != {release.snapshot.digest}:
        raise BackfillError('other participant content carries the same identities, so the evidence is ambiguous')
    try:
        validate(submission, {identities: release})
    except StudyError:
        raise BackfillError("the stored record is not admissible under the release's own rules") from None
    try:
        StudyService.register_snapshot(db, release.snapshot)
    except sqlite3.IntegrityError:
        raise BackfillError('a stored snapshot with the declared digest differs from the release') from None
    db.execute('UPDATE submissions SET content_provenance=?, content_digest=?, provenance_backfill=? '
               'WHERE submission_id=?',
               (PROVENANCE_SNAPSHOT, release.snapshot.digest, canonical(BACKFILL_EVIDENCE), link['submissionId']))
    return True
