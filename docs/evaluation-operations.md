# Study collection and researcher operations

The local container stores assessment sessions separately from compiler queries. Start/stop, export, backup, and reset commands are in the [README](../README.md). Use `http://localhost:8000` consistently: `localhost` and `127.0.0.1` are different submission origins.

| Setting | Container behaviour |
|---|---|
| `IREXPLORER_COLLECTION_MODE` | `local`; `preview` is for synthetic testing; `pilot` and `live` collect research data and start only with a finished configuration ([below](#pilot-and-live-collection)) |
| `IREXPLORER_STUDY_DIR` | `/data`, backed by the named `study-data` volume; each mode has its own database |
| `IREXPLORER_STUDY_ORIGIN` | `http://localhost:8000`; the exact origin is required for submission |
| `IREXPLORER_ACCEPTED_INSTRUMENTS` | Unset: first deliveries are accepted only for the installed participant package |
| Application revision | Baked version plus source fingerprint, also exposed by `/api/release`; recorded by the server on submission |

The submission store is `/data/<collection-mode>/submissions.sqlite3`. SQLite schema version 4 stores rows in `submissions`, with submitted JSON in `submission_json`, and keeps the `participant_content_snapshots` registry of participant-content snapshots (added in version 3). Each snapshot holds the canonical public participant-content bytes (package schema plus content, without collection mode or enabled status), their SHA-256 digest, the identity, digest-algorithm and canonicalisation versions, and the instrument/content/study identities. The server computes and verifies a snapshot at startup for the installed package and for each configured accepted instrument release (below); submitted JSON cannot supply or register one. Each new submission records `content_provenance = snapshot` and the `content_digest` of the snapshot it was validated against; a submission's provenance cannot be changed afterwards, except that the verified provenance backfill (below) can link a legacy row once; the snapshot registration and submission insert commit in one transaction before the receipt is returned. A stored snapshot with the same digest but different bytes is an integrity failure: the submission is refused with `storage_unavailable`, nothing is replaced, and export, backup, and restore reject the store (participant deletion still proceeds, as described below). Snapshots cannot be updated, and a referenced snapshot cannot be deleted. A stored submission's ID, digest, submitted JSON, receipt, and release metadata cannot be updated.

First use moves a legacy `responses.sqlite3` file into place and migrates a version-1 `responses` table, a version-2 `submissions` table, or a version-3 store to version 4 without rewriting submitted answers, submission IDs or digests, receipts, or release metadata. Rows stored before snapshots existed are marked `content_provenance = legacy_unavailable` with no digest: they have unavailable participant-content provenance, and current content is never substituted. Exports report this stored value as `unavailable`. Version 4 adds only the empty `provenance_backfill` column and the triggers described under [provenance backfill](#backfill-verified-legacy-provenance). Repeated initialisation is a no-op; any other schema version fails without change. Local and preview stores migrate independently. Version-1, version-2, and version-3 backups remain readable and can be restored; opening a restored older store performs the same migration. Canonicalisation remains version 1 and the submitted JSON schema remains version 2. Writes are transactional, duplicate retries return the original receipt, and conflicting reuse is rejected. Server acknowledgement follows commit. Directories use mode 0700 and database files 0600. Local collection starts on first submission. Application changes do not rewrite existing records or their release metadata.

The image binds Uvicorn inside the container, while Compose publishes only the Mac's localhost port. Access logging is disabled. This local baseline does not configure hosted infrastructure or amend the study instruments.

## Host Python configuration

The Python runner defaults to origin `http://127.0.0.1:8000` and collection mode `preview`. Set `IREXPLORER_STUDY_DIR` to an absolute writable directory outside the repository to choose storage explicitly. Set `IREXPLORER_COLLECTION_MODE=local` and `IREXPLORER_STUDY_ORIGIN=http://127.0.0.1:8000` for a host local run. The retired `IREXPLORER_STUDY_MODE` variable causes a startup error that names `IREXPLORER_COLLECTION_MODE`. These environment variables apply to the process at startup. Run the CLI below with `.venv/bin/python -m src.backend.evaluation.cli` and the corresponding database path when using host Python.

## Accepted instrument releases

By default a first delivery is accepted only when it names the installed package's study, content, and instrument identities; there is no grace period for drafts from an earlier release. To let outstanding drafts from one earlier release be submitted, a researcher must deliberately package that release and enable it. Package it with the thesis `build_content.py --package-public DEST` export from its frozen release, which writes only `participant-package-v2.json` and `public-manifest.json`. Then set `IREXPLORER_ACCEPTED_INSTRUMENTS` to that absolute directory; separate several directories with the platform path separator (`:` on Linux and in the container). At startup each configured pair must pass the same checks as the installed package: exact package bytes, manifest, canonical identity, and content schema. Its identities must also differ from the installed release and from every other configured release. Otherwise the application does not start. A submission naming an accepted earlier release is validated against that release's own membership, options, and rules, and linked to that release's participant-content snapshot. The content endpoint still serves only the installed package, and a submission cannot supply or register a release. Remove the setting and restart to stop accepting the earlier release. Receipt recovery for already committed submissions does not depend on this setting. The shipped configuration enables no earlier release, and enabling one does not approve participant-release commitments.

## Export and codebook

Run commands locally as the researcher; no HTTP export/list endpoint exists. Use a fresh output directory, outside the repositories:

```sh
docker compose exec app python -m src.backend.evaluation.cli export /data/local/submissions.sqlite3 /data/my-export
```

`submissions.json` preserves submitted JSON answers and schema version, receipts, and release metadata. `submissions.csv` is UTF-8 long format: participant/submission/receipt IDs, study/content/instrument/consent versions, server release metadata, `section` (consent, pre-survey, post-survey, or task), item ID, status, raw value, duration, interruption flag, and the legacy `setupReached` column. Task summary rows carry outcomes/time; item rows retain partial answers separately. Null is an empty value with an explicit status. Multi-choice codes are JSON arrays.

Exports never read the running application's participant content. `snapshots/<digest>.json` holds the exact canonical public bytes of every participant-content snapshot referenced by an exported record; each file's SHA-256 is its digest. `codebook.json` (codebook schema version 4, independent of the SQLite store version) has one snapshot codebook per referenced snapshot under `codebooks`, keyed by digest, with its instrument/content/study identities, package schema version, field wording/options/response rules, scales, and membership, all read from the stored snapshot. Each JSON record carries `contentProvenance`: either `snapshot` with the exact digest, identities, `codebook` (the key of its snapshot codebook), and `snapshotFile`; or `unavailable` with `codebook: null` for a record stored before snapshots were recorded. A link made later by the provenance backfill also carries `backfill`, the evidence stored with it, so it is distinguishable from a link made at submission. `unavailableDefinitions` lists those submission IDs with the same marker. The CSV repeats this as `contentProvenance` and `contentDigest`, which is the codebook key (blank when unavailable). Never interpret an unavailable record with any snapshot codebook; consult its historical instrument. `instrumentDefinitions` and the analysis/timing notes remain historical guidance by instrument version, not exact definitions.

To join private researcher interpretation, pass each frozen instrument release directory (for example `Docs/evaluation/releases/<freeze-identity>/` in the thesis repository) with `--researcher-pack`, once per release:

```sh
.venv/bin/python -m src.backend.evaluation.cli export "$DB" "$EXPORT" --researcher-pack "$RELEASES/<freeze-identity>"
```

Before anything is written, the export checks the release's researcher manifest hashes for the three files it reads (public package, public manifest, and researcher pack; the release's other files are not read or exported); the public package's canonical identity; the researcher pack's canonical identity; that the pack, its codebook, and both manifests name the same public identity; the freeze identity; and that the public content is byte-identical to a snapshot referenced by an exported record. Two packs for one snapshot, a pack for content no exported record used, or a release directory inside the application repository are also rejected. A rejection exits with status 1, names the failed check without printing pack content, and writes no export. A verified pack appears in `researcher-codebooks.json` under its public digest, and that snapshot codebook's `researcherPack` names the researcher digest. Researcher packs are read only by this private command: they are never packaged into the application, loaded at startup, or served. Keep releases and joined exports in private researcher storage.

CSV text beginning with formula operators after whitespace, or tab/line-break prefixes, receives a leading apostrophe. JSON preserves the original text; do not strip that CSV protection when opening free text in a spreadsheet. CSV quoting preserves commas, quotes, and multiline Unicode text. Raw ratings are never reverse-scored during collection/export; a joined researcher pack declares transforms such as answered-only Q3 reverse-coding and the qualitative P13/Q14 pairing, but they are applied only in separate analysis files. Participant task status (completed, skipped, could not work it out) is not a researcher outcome or correctness code. For v0.5 and v0.6, a later, separate analysis applies `6 - value` only to answered Q3; Q8 is multiple choice and Q10 is positive. The older Q3/Q8/Q10 reversal applies only to v0.1; retain not-applicable/unanswered counts and P13/Q14 pairing. Keep researcher coding and assistance notes separate, joined by participant code and item/task ID. Separate records by `instrumentVersion`: v0.5 P3 combines completed and current enrolment, while v0.6 has one status field per course. Never recode v0.5 P3 as v0.6 statuses. Unanswered v0.6 course fields are unknown, not “Neither”; course exposure alone does not establish expertise. Report background flags non-exclusively, including overlap and unknown where optional data are missing.

For v0.7, `durationMs` is task-presentation duration: visible time starts when the task appears and includes reading, workspace exploration, and answering. Hidden-tab time, explicit pauses, and reload downtime are excluded. This measure is distinct from v0.5/v0.6 post-setup active duration and must not be pooled with it. `setupReached` was collected only in v0.5/v0.6; it is no longer an analysed outcome, and the CSV cell is blank for v0.7. An absent legacy value means unknown. Snapshot codebooks describe only the records that name them; analyse legacy records against their historical instruments. `interrupted` is a coarse boolean, not an event history. Abrupt termination can lose the interval since the last successful one-second checkpoint. No abandoned/incomplete sessions are submitted; their exclusion is an analysis limitation.

## Backfill verified legacy provenance

A record stored before snapshots existed can be linked to its exact historical participant content only when a frozen public package shows that content and the researcher names the link explicitly. Nothing is inferred from a version label, and the running package is never consulted. Run this privately on a backup copy, outside the repositories:

```sh
.venv/bin/python -m src.backend.evaluation.cli backfill-provenance "$BACKUP" "$BACKFILLED" \
  --release "$PUBLIC_PAIR" --links "$LINKS"
```

`--release` (repeatable) names a directory holding a frozen public pair, `participant-package-v2.json` and `public-manifest.json`. This can be a frozen instrument release directory (for example `Docs/evaluation/releases/<freeze-identity>/` in the thesis repository) or a `build_content.py --package-public` export; only those two files are read. Each pair must pass the same byte, manifest, schema, and canonical-identity checks as an installed package. `$LINKS` is a JSON file written by the researcher:

```json
{"backfillSchemaVersion": 1, "links": [
  {"submissionId": "…", "submissionDigest": "<stored submission digest>", "contentDigest": "<public identity digest>"}
]}
```

Each record may appear once. A record is linked only when all of these hold:

- the store holds that submission ID with that submission digest, and the stored JSON still has that digest;
- a supplied release has the content digest;
- the stored JSON names that release's study, content, and instrument identities;
- no other supplied release or stored snapshot carries the same identities, so a version label cannot be what decides the link;
- the stored JSON is admissible under that release's own membership, options, and rules.

The operation copies `$BACKUP` with the backup API to the new file `$BACKFILLED`, which must not exist, and migrates the copy to the current schema. It then applies every link in one transaction and verifies the result. It records `content_provenance = snapshot`, the snapshot's `content_digest`, and `provenance_backfill` evidence, registering the response-free snapshot if it is new.

The source is never modified. The submission ID, digest, submitted JSON, receipt, and release metadata are unchanged in the copy. The store triggers reject every other provenance change, and any change to those columns.

- **Repeats.** A record already linked to the named digest, whether at submission or by an earlier backfill, is left unchanged, so repeating a run on its output is a no-op.
- **Failures.** A record with different existing provenance is a conflict. That fails the run, as do any failed check, an unverified release, and a malformed links file. The command exits with status 1, prints `Provenance backfill rejected: <check>. Nothing was written.`, naming the failed check with its link or release position but no answers or identifiers, and removes the new file.
- **Unlinked records.** Records that are not named, or cannot be verified, stay `unavailable` in exports.

The command prints how many records were linked and how many were already linked. Before use, export the copy and check its links, counts, and receipts. To put it into service, stop collection, then follow the restore replacement steps with the verified copy.

Limitations:

- The tool checks that a record is consistent with the frozen artefact. It cannot prove which release was deployed when the record was collected, so keep the deployment evidence that justifies each link with the links file.
- Instruments with no frozen public package cannot be verified; currently this is any instrument before v0.11.
- The store triggers protect integrity, not access. Private file permissions remain the control.

See [ADR 0004](adr/0004-controlled-provenance-backfill.md). Backfill is a private researcher operation with no HTTP endpoint. It does not approve participant-release commitments.

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

Participant deletion removes matching rows with SQLite secure deletion and compacts the database. Participant-content snapshots contain no respondent data and remain after deletion; backups copy them with the submissions that reference them, and backup, restore, and export verify every snapshot digest and submission link. Participant deletion requires only a sound SQLite file: if snapshot verification fails, the deletion still completes, the command warns without printing responses and exits with status 3 (usage errors exit with status 2 and delete nothing). Do not export or back up that store; restore its snapshots from a verified backup, then repeat the deletion on the restored copy. Perform deletion on each retained backup or replace affected backups, remove/recreate exports, and update any separate coding/assistance files. Deletion works on a retained backup at any supported schema version without migrating it. `purge` accepts explicitly named database/JSON/CSV files; it never recursively deletes a directory. Stop collection first. Database sidecars are removed with the named database. Inventory host snapshots and separately copied files too. File removal cannot promise physical erasure from SSDs or host snapshots. A hosted study must define its withdrawal cutoff and retention endpoint separately.

The application runner disables Uvicorn access logs. Study errors are controlled, do not echo answers/paths, and the study package logs no request bodies, IPs, or participant IDs. Synthetic testing found no answer/identifier in request URLs, browser runtime exceptions, or application diagnostics. This does not configure proxy or host logs. Hosting would require separate infrastructure configuration and verification.

## Failure and receipt behaviour

Only Submit answers sends a submission. Before it, Stop/discard removes local drafts. Before a request, the browser saves a frozen submission and a new cryptographic submission UUID in a separate tab-scoped recovery record. It does not send on unload. A first successful commit returns 201; an identical retry returns 200 with the original receipt; conflicting reuse returns 409 without stored answers. The committed submission is looked up before current-instrument validation, so a lost-response retry still receives its original receipt after an application or package upgrade. An uncommitted draft whose identities do not name an accepted instrument release is rejected with `422 unsupported_instrument`: nothing is stored, and the answers and submission ID are not changed. The browser keeps the frozen submission in the tab and reports it as incompatible, without claiming a save. Discarding it is the participant's explicit choice. The recovery record is unchanged, so after a refresh the tab offers the same retry again, and the server reports the same incompatibility unless the release has since been accepted. Acceptance is decided only by the server's configuration. A draft from an accepted earlier release is validated under that release's rules. Transport failure/timeouts retain the exact submission, including ID and rounded durations. In-flight and uncertain states prevent edits and discard/reset claims. Refresh restores retry state; closing the tab is not a supported recovery workflow.

An acknowledged receipt replaces the frozen submission, then the original answer draft is removed. Failure in either cleanup step stays visible and offers retry; success is not falsely described as local erasure. An explicitly selected memory-only participant journey can submit but cannot promise refresh recovery, and unavailable storage can require cleanup retry. Keep the tab and receipt code. Corrupt/unreadable submission recovery blocks normal progression and offers recovery retry or explicitly acknowledged memory-only continuation; a previous server record may exist.

The included flow supports local collection and synthetic preview testing. Pilot and live collection use the same flow, but the application starts in those modes only with the finished configuration described below; opening collection still requires the human release approval in that section.

## Pilot and live collection

Every collection mode that starts accepts submissions; `/api/study/content` reports the configured `collectionMode` with `submissionEnabled: true`. Pilot and live collection hold research data, so the application refuses to start in either mode, before any store is opened, when:

- `IREXPLORER_STUDY_ORIGIN` is unset or not an exact `https://` origin (the unset default is the HTTP development origin);
- the application is a development build: a host checkout (whatever `IREXPLORER_APP_REVISION` says) or a revision of `development`; or
- the installed participant package, or any configured accepted instrument release, has a content identity containing `preview` or a study identity containing `synthetic`.

The startup error names the failed condition. Each mode keeps its own store at `<study-dir>/<collection-mode>/submissions.sqlite3`: a pilot or live store is created on its first submission, never copied, renamed, or migrated from a preview or local store, and a submission ID committed in another mode has no receipt there. Final-only submission, exact-origin validation, commit before receipt, identical-retry receipts, and the private CLI operations are the same in every mode.

The live systemd environment must set `IREXPLORER_COLLECTION_MODE=live`, `IREXPLORER_STUDY_ORIGIN=https://<canonical-host>` and `IREXPLORER_STUDY_DIR=/var/lib/irexplorer`, and deploy a non-development, immutable release whose `/api/release` fingerprint is recorded. The exact deployment and host checks are in [Prepare for live evaluation](../../deploy/uq-webproject/LIVE-EVALUATION.md), not in this local-collection guide. The startup guards check configuration only; they do not approve a participant release.

Before configuring live collection, record D3 (withdrawal process and participant code), D4 (private storage, access, backups, retention and deletion), and D5 (all participant-facing, ethics and infrastructure-disclosure confirmations) in the thesis instruments. Verify nginx, systemd journal and upstream UQ logging against the participant disclosure as required by `LIVE-EVALUATION.md`; application request logging alone is not that verification. Joe is the release approver, after Joel has confirmed the D3–D5 participant/ethics commitments.

Use this checklist for the cutover:

- [ ] Freeze and rebuild the participant content and truthful study/content/instrument identities; run backend, draft/submission and browser checks with synthetic data, including retry, export and restore.
- [ ] Verify the canonical HTTPS origin, the immutable release fingerprint and the artefact checksum locally and through the public origin.
- [ ] Confirm `/var/lib/irexplorer/live/` is a new, empty store; never rename or reuse the preview database.
- [ ] Run the documented health, release and study-content checks, and verify `mode: live` and `submissionEnabled: true` before opening collection.
- [ ] Record Joe's approval, the release fingerprint, checksum, versions, canonical URL, opening time and data location; retain the verified off-zone backup procedure.

Do not set `IREXPLORER_COLLECTION_MODE=live` on the public service until every item is complete.
