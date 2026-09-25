# Study collection and researcher operations

The local container stores assessment sessions separately from compiler queries. Start/stop, export, backup, and reset commands are in the [README](../README.md). Use `http://localhost:8000` consistently: `localhost` and `127.0.0.1` are different submission origins.

| Setting | Container behaviour |
|---|---|
| `IREXPLORER_COLLECTION_MODE` | `local`; `preview` is for synthetic testing; `pilot` and `live` remain disabled pending separate approval |
| `IREXPLORER_STUDY_DIR` | `/data`, backed by the named `study-data` volume; each mode has its own database |
| `IREXPLORER_STUDY_ORIGIN` | `http://localhost:8000`; the exact origin is required for submission |
| Application revision | Baked version plus source fingerprint, also exposed by `/api/release`; recorded by the server on submission |

The submission store is `/data/<collection-mode>/submissions.sqlite3`. SQLite schema version 2 stores rows in `submissions`, with submitted JSON in `submission_json`; first use moves a legacy `responses.sqlite3` file into place and migrates a version-1 `responses` table without rewriting submitted answers, receipts, or release metadata. Local and preview stores migrate independently. Version-1 backups remain readable and can be restored; opening a restored version-1 store performs the same migration. Canonicalisation remains version 1 and the submitted JSON schema remains version 2. Writes are transactional, duplicate retries return the original receipt, and conflicting reuse is rejected. Server acknowledgement follows commit. Directories use mode 0700 and database files 0600. Local collection starts on first submission. Application changes do not rewrite existing records or their release metadata.

The image binds Uvicorn inside the container, while Compose publishes only the Mac's localhost port. Access logging is disabled. This local baseline does not configure hosted infrastructure or amend the study instruments.

## Host Python configuration

The Python runner defaults to origin `http://127.0.0.1:8000` and collection mode `preview`. Set `IREXPLORER_STUDY_DIR` to an absolute writable directory outside the repository to choose storage explicitly. Set `IREXPLORER_COLLECTION_MODE=local` and `IREXPLORER_STUDY_ORIGIN=http://127.0.0.1:8000` for a host local run. The retired `IREXPLORER_STUDY_MODE` variable causes a startup error that names `IREXPLORER_COLLECTION_MODE`. These environment variables apply to the process at startup. Run the CLI below with `.venv/bin/python -m src.backend.evaluation.cli` and the corresponding database path when using host Python.

## Export and codebook

Run commands locally as the researcher; no HTTP export/list endpoint exists. Use a fresh output directory, outside the repositories:

```sh
docker compose exec app python -m src.backend.evaluation.cli export /data/local/submissions.sqlite3 /data/my-export
```

`submissions.json` preserves submitted JSON answers and schema version, receipts, and release metadata. `submissions.csv` is UTF-8 long format: participant/submission/receipt IDs, study/content/instrument/consent versions, server release metadata, `section` (consent, pre-survey, post-survey, or task), item ID, status, raw value, duration, interruption flag, and setupReached. Task summary rows carry outcomes/time; item rows retain partial answers separately. Null is an empty value with an explicit status. Multi-choice codes are JSON arrays. `codebook.json` uses the same `section` term and includes all source-backed field IDs/options/scales and the analysis/timing rules.

CSV text beginning with formula operators after whitespace, or tab/line-break prefixes, receives a leading apostrophe. JSON preserves the original text; do not strip that CSV protection when opening free text in a spreadsheet. CSV quoting preserves commas, quotes, and multiline Unicode text. Raw ratings are never reverse-scored during collection/export. For the current v0.5 instrument, a later, separate analysis applies `6 - value` only to answered Q3; Q8 is multiple choice and Q10 is positive. The older Q3/Q8/Q10 reversal applies only to v0.1; retain not-applicable/unanswered counts and P13/Q14 pairing. Keep researcher coding and assistance notes separate, joined by participant code and item/task ID. P3 measures completed/current course exposure together. Report background flags non-exclusively, including overlap and unknown where optional data are missing.

Post-setup active durations include visible reading, workspace exploration, and answering after a usable comparison is ready; initial reading and setup are excluded. They exclude hidden-tab time, explicit pauses, and reload downtime; they are neither total task nor pure comprehension times. setupReached=false identifies pre-setup skip/inability with zero time and unanswered fields; absent setupReached in legacy exports means unknown. Codebook fields/scales describe the labelled current version only; analyse legacy records against their historical instruments. `interrupted` is a coarse boolean, not an event history. Abrupt termination can lose the interval since the last successful one-second checkpoint. No abandoned/incomplete sessions are submitted; their exclusion is an analysis limitation.

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

Participant deletion removes matching rows with SQLite secure deletion and compacts the database. Perform deletion on each retained backup or replace affected backups, remove/recreate exports, and update any separate coding/assistance files. `purge` accepts explicitly named database/JSON/CSV files; it never recursively deletes a directory. Stop collection first. Database sidecars are removed with the named database. Inventory host snapshots and separately copied files too. File removal cannot promise physical erasure from SSDs or host snapshots. A hosted study must define its withdrawal cutoff and retention endpoint separately.

The application runner disables Uvicorn access logs. Study errors are controlled, do not echo answers/paths, and the study package logs no request bodies, IPs, or participant IDs. Synthetic testing found no answer/identifier in request URLs, browser runtime exceptions, or application diagnostics. This does not configure proxy or host logs. Hosting would require separate infrastructure configuration and verification.

## Failure and receipt behaviour

Only Submit answers sends a submission. Before it, Stop/discard removes local drafts. Before a request, the browser saves a frozen submission and a new cryptographic submission UUID in a separate tab-scoped recovery record. It does not send on unload. A first successful commit returns 201; an identical retry returns 200 with the original receipt; conflicting reuse returns 409 without stored answers. Transport failure/timeouts retain the exact submission, including ID and rounded durations. In-flight and uncertain states prevent edits and discard/reset claims. Refresh restores retry state; closing the tab is not a supported recovery workflow.

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
