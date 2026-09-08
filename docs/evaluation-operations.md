# E6 study collection and researcher operations

8 September 2026. Synthetic preview implemented; participant pilot/live collection is disabled in code until E7/E8 resolve and version the consent/release conditions. This is a single-host SQLite service, separate from compiler queries. No deployment has occurred.

## Configuration and preview

From `irexplorer/`:

```sh
IREXPLORER_STUDY_ORIGIN=http://127.0.0.1:8006 IREXPLORER_STUDY_DIR=/private/tmp/irexplorer-e6-review .venv/bin/python -c 'from src.backend.api.server import run_server; run_server(port=8006)'
```

Open `http://127.0.0.1:8006/?revision=e6-submission-1#/study`. Use invented answers only. The E6 server uses port 8006 to avoid replacing the earlier server on 8000. Starting the ordinary server uses origin `http://127.0.0.1:8000` and a separate default temporary directory `irexplorer-study-<uid>` beneath Python's OS temporary directory. Use the exact configured hostname: `localhost` and `127.0.0.1` are different origins.

| Setting | Behaviour |
|---|---|
| `IREXPLORER_STUDY_MODE` | `preview` by default; `pilot` and `live` are recognised but refuse all submissions in this revision |
| `IREXPLORER_STUDY_DIR` | Absolute private directory outside both repositories; each mode uses its own `<mode>/responses.sqlite3` |
| `IREXPLORER_STUDY_ORIGIN` | Exact scheme, host, and port, without trailing slash; required Origin header and no permissive CORS |
| `IREXPLORER_APP_REVISION` | Trusted operator release label; default `e6-submission-1`. Before release, set this to the deployed revision and freeze/build checksums |

A client cannot set mode, revision, schema, or artefact checksum. The artefact checksum comes from the checked-in pinned aggregate snapshot; E6 verifies it against the artefacts, without claiming fresh Docker regeneration. Pilot/live need an explicitly configured durable host location and a reviewed release, rather than the temporary preview default. UQ Cloud proxy, persistent volume, access/error logging, snapshots, and backups still require E8 inspection. No arbitrary environment switch enables real participation in E6.

SQLite schema version 1 stores `submission_id` (primary key), canonical SHA-256 digest, validated response JSON, minimal receipt JSON, and server release JSON in `responses`. Each submission uses a separate connection, a ten-second lock timeout, `BEGIN IMMEDIATE`, and `synchronous=FULL`; commit precedes success. Unknown schema versions fail closed. Directories containing the database use mode 0700 and database files 0600. No connection or mutable response enters the immutable query cache. No compiler invocation is reachable from this package.

Canonicalisation version 1 uses sorted object keys, compact UTF-8 JSON, finite numbers, and ascending multi-choice codes (unordered sets in the instrument). Arrays of tasks retain T0–T6 order. Raw text and scalar ratings are preserved. E5 fractional accumulated durations are rounded once at the final browser boundary, without changing local timing. The server accepts integer 0–86,400,000 ms per task. This is a reviewable technical bound, with no countdown or forced task timeout. The 128 KiB request, 4,000-code-point text, and 256-code-point short-text limits remain preview limits pending instrument freeze.

## Export and codebook

Run commands locally as the researcher; no HTTP export/list endpoint exists. Use a fresh output directory, outside the repositories:

```sh
.venv/bin/python -m src.backend.evaluation.cli export /private/tmp/irexplorer-e6-review/preview/responses.sqlite3 /private/tmp/irexplorer-e6-review/my-export
```

`responses.json` preserves raw strings, ratings, non-answer statuses, consent, ordered tasks, receipts, and release metadata. `responses.csv` is UTF-8 long format: participant/submission/receipt IDs, study/content/instrument/consent versions, server release metadata, stage, item ID, status, raw value, duration, and interruption flag. Task summary rows carry outcomes/time; item rows retain partial answers separately. Null is an empty value with an explicit status. Multi-choice codes are JSON arrays. `codebook.json` includes all source-backed field IDs/options/scales and the analysis/timing rules.

CSV text beginning with formula operators after whitespace, or tab/line-break prefixes, receives a leading apostrophe. JSON preserves the original text; do not strip that CSV protection when opening free text in a spreadsheet. CSV quoting preserves commas, quotes, and multiline Unicode text. Raw ratings are never reverse-scored during collection/export. A later, separate analysis can apply `6 - value` to answered Q3, Q8, and Q10; retain not-applicable/unanswered counts and P13/Q14 pairing. Keep researcher coding and assistance notes separate, joined by participant code and item/task ID. Resolve the existing P3/strata ambiguities before analysis.

Active durations include visible reading, workspace exploration, and answering. They exclude hidden-tab time, explicit pauses, and reload downtime; they are not pure comprehension times. T1c maps to the T1 duration row. `interrupted` is a coarse boolean, not an event history. Abrupt termination can lose the interval since the last successful one-second checkpoint. No abandoned/incomplete sessions are submitted; their exclusion is an analysis limitation.

## Backup, restore, withdrawal, and retention

```sh
.venv/bin/python -m src.backend.evaluation.cli backup /private/tmp/irexplorer-e6-review/preview/responses.sqlite3 /private/tmp/irexplorer-e6-review/my-backup.sqlite3
.venv/bin/python -m src.backend.evaluation.cli restore /private/tmp/irexplorer-e6-review/my-backup.sqlite3 /private/tmp/irexplorer-e6-review/my-restored.sqlite3
```

Backup uses SQLite's consistent backup API and verifies schema/integrity. Restore creates a new file and refuses overwrite. Stop collection before a restore; verify its record counts/receipts/export before replacing the configured database. Keep the previous database as a protected rollback copy until verified, then include it in retention/deletion inventory. Do not move preview or pilot records into the live store. A temporary preview path survives application restart but is not a durable production storage promise.

```sh
.venv/bin/python -m src.backend.evaluation.cli delete-participant /private/tmp/irexplorer-e6-review/my-restored.sqlite3 PARTICIPANT_UUID --confirm
.venv/bin/python -m src.backend.evaluation.cli purge /private/tmp/irexplorer-e6-review/my-restored.sqlite3 --confirm
```

Participant deletion removes matching rows with SQLite secure deletion and compacts the database. Perform deletion on each retained backup or replace affected backups, remove/recreate exports, and update any separate coding/assistance files. `purge` accepts explicitly named database/JSON/CSV files; it never recursively deletes a directory. Stop collection first. Database sidecars are removed with the named database. Inventory host snapshots and separately copied files too. File removal cannot promise physical erasure from SSDs or host snapshots. Joe/Joel still need to agree the withdrawal cutoff and retention endpoint; E6 does not invent them or change the instruments.

The application runner disables Uvicorn access logs. Study errors are controlled, do not echo answers/paths, and the study package logs no request bodies, IPs, or participant IDs. Synthetic testing found no answer/identifier in request URLs, browser runtime exceptions, or application diagnostics. This is not an audit of the old preview process or future proxy/host logs. Bind synthetic previews locally; authentication, TLS, proxy limits, and infrastructure logging are E8 deployment checks.

## Failure and receipt behaviour

Only Submit responses sends answers. Before it, Stop/discard removes local drafts. Before a request, the browser saves a frozen envelope and a new cryptographic submission UUID in a separate tab-scoped recovery record. It does not send on unload. A first successful commit returns 201; an identical retry returns 200 with the original receipt; conflicting reuse returns 409 without stored answers. Transport failure/timeouts retain the exact envelope, including ID and rounded durations. In-flight and uncertain states prevent edits and discard/reset claims. Refresh restores retry state; closing the tab is not a supported recovery workflow.

An acknowledged receipt replaces the frozen payload, then the original answer draft is removed. Failure in either cleanup step stays visible and offers retry; success is not falsely described as local erasure. An explicitly selected memory-only session can submit but cannot promise refresh recovery, and unavailable storage can require cleanup retry. Keep the tab and receipt code. Corrupt/unreadable submission recovery blocks normal progression and offers recovery retry or explicitly acknowledged memory-only synthetic continuation; a previous server record may exist.

Review the E6 pack before E7. No participant collection, recruitment, online dashboard, deployment, or instrument amendment is authorised by this synthetic implementation.
