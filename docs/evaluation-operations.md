# Study collection and researcher operations

9 September 2026. The local container stores assessment sessions separately from compiler queries. Start/stop, export, backup, and reset commands are in the [README](../README.md). Use `http://localhost:8000` consistently: `localhost` and `127.0.0.1` are different submission origins.

| Setting | Container behaviour |
|---|---|
| `IREXPLORER_STUDY_MODE` | `local`; legacy `preview` remains supported; `pilot` and `live` remain disabled |
| `IREXPLORER_STUDY_DIR` | `/data`, backed by the named `study-data` volume; each mode has its own database |
| `IREXPLORER_STUDY_ORIGIN` | `http://localhost:8000`; the exact origin is required for submission |
| Application revision | Baked version plus source fingerprint, also exposed by `/api/release`; recorded by the server on submission |

SQLite schema and canonicalisation remain version 1. Writes are transactional, duplicate retries return the original receipt, and conflicting reuse is rejected. Server acknowledgement follows commit. Directories use mode 0700 and database files 0600. Local collection starts on first submission. Application changes do not rewrite existing records or their release metadata.

The image binds Uvicorn inside the container, while Compose publishes only the Mac's localhost port. Access logging is disabled. This local baseline does not configure hosted infrastructure or amend the study instruments.

## Export and codebook

Run commands locally as the researcher; no HTTP export/list endpoint exists. Use a fresh output directory, outside the repositories:

```sh
docker compose exec app python -m src.backend.evaluation.cli export /data/local/responses.sqlite3 /data/my-export
```

`responses.json` preserves raw strings, ratings, non-answer statuses, consent, ordered tasks, receipts, and release metadata. `responses.csv` is UTF-8 long format: participant/submission/receipt IDs, study/content/instrument/consent versions, server release metadata, stage, item ID, status, raw value, duration, and interruption flag. Task summary rows carry outcomes/time; item rows retain partial answers separately. Null is an empty value with an explicit status. Multi-choice codes are JSON arrays. `codebook.json` includes all source-backed field IDs/options/scales and the analysis/timing rules.

CSV text beginning with formula operators after whitespace, or tab/line-break prefixes, receives a leading apostrophe. JSON preserves the original text; do not strip that CSV protection when opening free text in a spreadsheet. CSV quoting preserves commas, quotes, and multiline Unicode text. Raw ratings are never reverse-scored during collection/export. A later, separate analysis can apply `6 - value` to answered Q3, Q8, and Q10; retain not-applicable/unanswered counts and P13/Q14 pairing. Keep researcher coding and assistance notes separate, joined by participant code and item/task ID. Resolve the existing P3/strata ambiguities before analysis.

Active durations include visible reading, workspace exploration, and answering. They exclude hidden-tab time, explicit pauses, and reload downtime; they are not pure comprehension times. T1c maps to the T1 duration row. `interrupted` is a coarse boolean, not an event history. Abrupt termination can lose the interval since the last successful one-second checkpoint. No abandoned/incomplete sessions are submitted; their exclusion is an analysis limitation.

## Backup, restore, withdrawal, and retention

```sh
docker compose exec app python -m src.backend.evaluation.cli backup /data/local/responses.sqlite3 /data/my-backup.sqlite3
docker compose stop app
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli restore /data/my-backup.sqlite3 /data/my-restored.sqlite3
```

Backup uses SQLite's consistent backup API and verifies schema/integrity. Restore creates a new file and refuses overwrite. Stop collection before a restore; verify its record counts/receipts/export before replacing the configured database. Keep the previous database as a protected rollback copy until verified, then include it in retention/deletion inventory. The named local volume survives application replacement. Copy backups onto the Mac as described in the README; a backup on the same volume is lost if that volume is deleted.

```sh
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli delete-participant /data/my-restored.sqlite3 PARTICIPANT_UUID --confirm
docker compose run --rm --no-deps app python -m src.backend.evaluation.cli purge /data/my-restored.sqlite3 --confirm
```

Participant deletion removes matching rows with SQLite secure deletion and compacts the database. Perform deletion on each retained backup or replace affected backups, remove/recreate exports, and update any separate coding/assistance files. `purge` accepts explicitly named database/JSON/CSV files; it never recursively deletes a directory. Stop collection first. Database sidecars are removed with the named database. Inventory host snapshots and separately copied files too. File removal cannot promise physical erasure from SSDs or host snapshots. Joe/Joel still need to agree the withdrawal cutoff and retention endpoint; The local build leaves those instrument decisions unchanged.

The application runner disables Uvicorn access logs. Study errors are controlled, do not echo answers/paths, and the study package logs no request bodies, IPs, or participant IDs. Synthetic testing found no answer/identifier in request URLs, browser runtime exceptions, or application diagnostics. This is not an audit of the old preview process or future proxy/host logs. Hosting would require separate infrastructure configuration and verification.

## Failure and receipt behaviour

Only Submit responses sends answers. Before it, Stop/discard removes local drafts. Before a request, the browser saves a frozen envelope and a new cryptographic submission UUID in a separate tab-scoped recovery record. It does not send on unload. A first successful commit returns 201; an identical retry returns 200 with the original receipt; conflicting reuse returns 409 without stored answers. Transport failure/timeouts retain the exact envelope, including ID and rounded durations. In-flight and uncertain states prevent edits and discard/reset claims. Refresh restores retry state; closing the tab is not a supported recovery workflow.

An acknowledged receipt replaces the frozen payload, then the original answer draft is removed. Failure in either cleanup step stays visible and offers retry; success is not falsely described as local erasure. An explicitly selected memory-only session can submit but cannot promise refresh recovery, and unavailable storage can require cleanup retry. Keep the tab and receipt code. Corrupt/unreadable submission recovery blocks normal progression and offers recovery retry or explicitly acknowledged memory-only continuation; a previous server record may exist.

Use the local build for assessment; participant release remains a separate decision.
