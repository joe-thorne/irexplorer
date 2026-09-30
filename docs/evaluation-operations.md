# Study collection and researcher operations

The local container stores assessment sessions separately from compiler queries. Start/stop, export, backup, and reset commands are in the [README](../README.md). Use `http://localhost:8000` consistently: `localhost` and `127.0.0.1` are different submission origins.

| Setting | Container behaviour |
|---|---|
| `IREXPLORER_COLLECTION_MODE` | `local`; `preview` is for synthetic testing; `pilot` and `live` remain disabled pending separate approval |
| `IREXPLORER_STUDY_DIR` | `/data`, backed by the named `study-data` volume; each mode has its own database |
| `IREXPLORER_STUDY_ORIGIN` | `http://localhost:8000`; the exact origin is required for submission |
| Application revision | Baked version plus source fingerprint, also exposed by `/api/release`; recorded by the server on submission |

The submission store is `/data/<collection-mode>/submissions.sqlite3`. SQLite schema version 3 stores rows in `submissions`, with submitted JSON in `submission_json`, and adds the `participant_content_snapshots` registry of participant-content snapshots. Each snapshot holds the canonical public participant-content bytes (package schema plus content, without collection mode or enabled status), their SHA-256 digest, the identity, digest-algorithm and canonicalisation versions, and the instrument/content/study identities. The server computes and verifies its snapshot from the installed package at startup; submitted JSON cannot supply or register one. Each new submission records `content_provenance = snapshot` and the `content_digest` of the snapshot it was validated against; a submission's provenance cannot be changed afterwards; the snapshot registration and submission insert commit in one transaction before the receipt is returned. A stored snapshot with the same digest but different bytes is an integrity failure: the submission is refused with `storage_unavailable`, nothing is replaced, and export, backup, and restore reject the store (participant deletion still proceeds, as described below). Snapshots cannot be updated, and a referenced snapshot cannot be deleted.

First use moves a legacy `responses.sqlite3` file into place and migrates a version-1 `responses` table or version-2 `submissions` table to version 3 without rewriting submitted answers, submission IDs or digests, receipts, or release metadata. Rows stored before snapshots existed are marked `content_provenance = legacy_unavailable` with no digest: they have unavailable participant-content provenance, and current content is never substituted. Exports report this stored value as `unavailable`. Repeated initialisation is a no-op; any other schema version fails without change. Local and preview stores migrate independently. Version-1 and version-2 backups remain readable and can be restored; opening a restored older store performs the same migration. Canonicalisation remains version 1 and the submitted JSON schema remains version 2. Writes are transactional, duplicate retries return the original receipt, and conflicting reuse is rejected. Server acknowledgement follows commit. Directories use mode 0700 and database files 0600. Local collection starts on first submission. Application changes do not rewrite existing records or their release metadata.

The image binds Uvicorn inside the container, while Compose publishes only the Mac's localhost port. Access logging is disabled. This local baseline does not configure hosted infrastructure or amend the study instruments.

## Host Python configuration

The Python runner defaults to origin `http://127.0.0.1:8000` and collection mode `preview`. Set `IREXPLORER_STUDY_DIR` to an absolute writable directory outside the repository to choose storage explicitly. Set `IREXPLORER_COLLECTION_MODE=local` and `IREXPLORER_STUDY_ORIGIN=http://127.0.0.1:8000` for a host local run. The retired `IREXPLORER_STUDY_MODE` variable causes a startup error that names `IREXPLORER_COLLECTION_MODE`. These environment variables apply to the process at startup. Run the CLI below with `.venv/bin/python -m src.backend.evaluation.cli` and the corresponding database path when using host Python.

## Export and codebook

Run commands locally as the researcher; no HTTP export/list endpoint exists. Use a fresh output directory, outside the repositories:

```sh
docker compose exec app python -m src.backend.evaluation.cli export /data/local/submissions.sqlite3 /data/my-export
```

`submissions.json` preserves submitted JSON answers and schema version, receipts, and release metadata. `submissions.csv` is UTF-8 long format: participant/submission/receipt IDs, study/content/instrument/consent versions, server release metadata, `section` (consent, pre-survey, post-survey, or task), item ID, status, raw value, duration, interruption flag, and the legacy `setupReached` column. Task summary rows carry outcomes/time; item rows retain partial answers separately. Null is an empty value with an explicit status. Multi-choice codes are JSON arrays.

Exports never read the running application's participant content. `snapshots/<digest>.json` holds the exact canonical public bytes of every participant-content snapshot referenced by an exported record; each file's SHA-256 is its digest. `codebook.json` (codebook schema version 4, independent of the SQLite store version) has one snapshot codebook per referenced snapshot under `codebooks`, keyed by digest, with its instrument/content/study identities, package schema version, field wording/options/response rules, scales, and membership, all read from the stored snapshot. Each JSON record carries `contentProvenance`: either `snapshot` with the exact digest, identities, `codebook` (the key of its snapshot codebook), and `snapshotFile`; or `unavailable` with `codebook: null` for a record stored before snapshots were recorded. `unavailableDefinitions` lists those submission IDs with the same marker. The CSV repeats this as `contentProvenance` and `contentDigest`, which is the codebook key (blank when unavailable). Never interpret an unavailable record with any snapshot codebook; consult its historical instrument. `instrumentDefinitions` and the analysis/timing notes remain historical guidance by instrument version, not exact definitions.

To join private researcher interpretation, pass each frozen instrument release directory (for example `Docs/evaluation/releases/<freeze-identity>/` in the thesis repository) with `--researcher-pack`, once per release:

```sh
.venv/bin/python -m src.backend.evaluation.cli export "$DB" "$EXPORT" --researcher-pack "$RELEASES/<freeze-identity>"
```

Before anything is written, the export checks the release's researcher manifest hashes for the public package, public manifest, and researcher pack; the public package's canonical identity; the researcher pack's canonical identity; that the pack, its codebook, and both manifests name the same public identity; the freeze identity; and that the public content is byte-identical to a snapshot referenced by an exported record. Two packs for one snapshot, a pack for content no exported record used, or a release directory inside the application repository are also rejected. A rejection exits with status 1, names the failed check without printing pack content, and writes no export. A verified pack appears in `researcher-codebooks.json` under its public digest, and that snapshot codebook's `researcherPack` names the researcher digest. Researcher packs are read only by this private command: they are never packaged into the application, loaded at startup, or served. Keep releases and joined exports in private researcher storage.

CSV text beginning with formula operators after whitespace, or tab/line-break prefixes, receives a leading apostrophe. JSON preserves the original text; do not strip that CSV protection when opening free text in a spreadsheet. CSV quoting preserves commas, quotes, and multiline Unicode text. Raw ratings are never reverse-scored during collection/export; a joined researcher pack declares transforms such as answered-only Q3 reverse-coding and the qualitative P13/Q14 pairing, but they are applied only in separate analysis files. Participant task status (completed, skipped, could not work it out) is not a researcher outcome or correctness code. For v0.5 and v0.6, a later, separate analysis applies `6 - value` only to answered Q3; Q8 is multiple choice and Q10 is positive. The older Q3/Q8/Q10 reversal applies only to v0.1; retain not-applicable/unanswered counts and P13/Q14 pairing. Keep researcher coding and assistance notes separate, joined by participant code and item/task ID. Separate records by `instrumentVersion`: v0.5 P3 combines completed and current enrolment, while v0.6 has one status field per course. Never recode v0.5 P3 as v0.6 statuses. Unanswered v0.6 course fields are unknown, not “Neither”; course exposure alone does not establish expertise. Report background flags non-exclusively, including overlap and unknown where optional data are missing.

For v0.7, `durationMs` is task-presentation duration: visible time starts when the task appears and includes reading, workspace exploration, and answering. Hidden-tab time, explicit pauses, and reload downtime are excluded. This measure is distinct from v0.5/v0.6 post-setup active duration and must not be pooled with it. `setupReached` was collected only in v0.5/v0.6; it is no longer an analysed outcome, and the CSV cell is blank for v0.7. An absent legacy value means unknown. Snapshot codebooks describe only the records that name them; analyse legacy records against their historical instruments. `interrupted` is a coarse boolean, not an event history. Abrupt termination can lose the interval since the last successful one-second checkpoint. No abandoned/incomplete sessions are submitted; their exclusion is an analysis limitation.

## Backup, restore, withdrawal, and retention

```sh
docker compose exec app python -m src.backend.evaluation.cli backup /data/local/submissions.sqlite3 /data/my-backup.sqlite3
docker compose stop app
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli restore /data/my-backup.sqlite3 /data/my-restored.sqlite3
```

Backup uses SQLite's consistent backup API and verifies schema/integrity. Restore creates a new file and refuses overwrite. Stop collection before a restore; verify its record counts/receipts/export before replacing the configured database. Keep the previous database as a protected rollback copy until verified, then include it in retention/deletion inventory. The named local volume survives application replacement. Copy backups onto the Mac as described in the README; a backup on the same volume is lost if that volume is deleted.

```sh
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli delete-participant /data/my-restored.sqlite3 PARTICIPANT_UUID --confirm
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli purge /data/my-restored.sqlite3 --confirm
```

Participant deletion removes matching rows with SQLite secure deletion and compacts the database. Participant-content snapshots contain no respondent data and remain after deletion; backups copy them with the submissions that reference them, and backup, restore, and export verify every snapshot digest and submission link. Participant deletion requires only a sound SQLite file: if snapshot verification fails, the deletion still completes, the command warns without printing responses and exits with status 3 (usage errors exit with status 2 and delete nothing). Do not export or back up that store; restore its snapshots from a verified backup, then repeat the deletion on the restored copy. Perform deletion on each retained backup or replace affected backups, remove/recreate exports, and update any separate coding/assistance files. `purge` accepts explicitly named database/JSON/CSV files; it never recursively deletes a directory. Stop collection first. Database sidecars are removed with the named database. Inventory host snapshots and separately copied files too. File removal cannot promise physical erasure from SSDs or host snapshots. A hosted study must define its withdrawal cutoff and retention endpoint separately.

The application runner disables Uvicorn access logs. Study errors are controlled, do not echo answers/paths, and the study package logs no request bodies, IPs, or participant IDs. Synthetic testing found no answer/identifier in request URLs, browser runtime exceptions, or application diagnostics. This does not configure proxy or host logs. Hosting would require separate infrastructure configuration and verification.

## Failure and receipt behaviour

Only Submit answers sends a submission. Before it, Stop/discard removes local drafts. Before a request, the browser saves a frozen submission and a new cryptographic submission UUID in a separate tab-scoped recovery record. It does not send on unload. A first successful commit returns 201; an identical retry returns 200 with the original receipt; conflicting reuse returns 409 without stored answers. The committed submission is looked up before current-instrument validation, so a lost-response retry still receives its original receipt after an application or package upgrade. An uncommitted older-release draft is still validated as a first delivery and is rejected without a receipt, leaving the frozen submission in the tab. Transport failure/timeouts retain the exact submission, including ID and rounded durations. In-flight and uncertain states prevent edits and discard/reset claims. Refresh restores retry state; closing the tab is not a supported recovery workflow.

An acknowledged receipt replaces the frozen submission, then the original answer draft is removed. Failure in either cleanup step stays visible and offers retry; success is not falsely described as local erasure. An explicitly selected memory-only participant journey can submit but cannot promise refresh recovery, and unavailable storage can require cleanup retry. Keep the tab and receipt code. Corrupt/unreadable submission recovery blocks normal progression and offers recovery retry or explicitly acknowledged memory-only continuation; a previous server record may exist.

The included flow supports local collection and synthetic preview testing. Pilot and live collection require separate approval and remain disabled.

## Release step: enabling live collection

This is a future, human-approved release step; it does not enable collection in the shipped application. Keep `pilot` disabled. The deliberate code change, made only in the frozen live-release branch after the checks below, is in `src/backend/evaluation/service.py`:

```python
@property
def enabled(self):
    # Local assessment and synthetic preview stores stay separate from research data.
    return self.collection_mode in ('local', 'preview', 'live')
```

Do not apply that change to a development checkout or to a service with an HTTP, missing, or non-canonical origin. The live systemd environment must set `IREXPLORER_COLLECTION_MODE=live`, `IREXPLORER_STUDY_ORIGIN=https://<canonical-host>` and `IREXPLORER_STUDY_DIR=/var/lib/irexplorer`; deploy a non-development, immutable release whose `/api/release` fingerprint is recorded. The exact deployment and host checks are in [Prepare for live evaluation](../../deploy/uq-webproject/LIVE-EVALUATION.md), not in this local-collection guide.

Before changing `Config.enabled`, record D3 (withdrawal process and participant code), D4 (private storage, access, backups, retention and deletion), and D5 (all participant-facing, ethics and infrastructure-disclosure confirmations) in the thesis instruments. Verify nginx, systemd journal and upstream UQ logging against the participant disclosure as required by `LIVE-EVALUATION.md`; application request logging alone is not that verification. Joe is the release approver, after Joel has confirmed the D3–D5 participant/ethics commitments.

Use this checklist for the cutover:

- [ ] Freeze and rebuild the participant content and truthful study/content/instrument identities; run backend, draft/submission and browser checks with synthetic data, including retry, export and restore.
- [ ] Verify the canonical HTTPS origin, the immutable release fingerprint and the artefact checksum locally and through the public origin.
- [ ] Confirm `/var/lib/irexplorer/live/` is a new, empty store; never rename or reuse the preview database.
- [ ] Run the documented health, release and study-content checks, and verify `mode: live` and `submissionEnabled: true` before opening collection.
- [ ] Record Joe's approval, the release fingerprint, checksum, versions, canonical URL, opening time and data location; retain the verified off-zone backup procedure.

Until every item is complete, leave the current `Config.enabled` implementation unchanged. Its dedicated regression test asserts that the shipped `live` configuration rejects a submission with `503 collection_disabled` without creating a database.
