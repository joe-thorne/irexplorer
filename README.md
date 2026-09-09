# irexplorer

Explore curated LLVM IR and CFG states, or complete the integrated evaluation study.

## Run locally

Start Docker Desktop, then run from this directory:

```sh
docker compose up -d --wait
```

Open **http://localhost:8000**. Use **Explore** or **Study** in the navigation. The first startup builds the application image if it is absent; subsequent starts reuse it. No host Python environment or LLVM installation is required.

```sh
docker compose stop       # Stop; retain sessions.
docker compose start      # Resume.
docker compose down       # Remove container; retain sessions.
```

Release **0.1.0** is the local testing baseline following Joe's completed E7 review. The image runs natively on this Mac's Linux/ARM64 Docker runtime. The separate LLVM generation service remains pinned to Linux/AMD64. Local submissions are labelled `local` in exports and stored in the `irexplorer_study-data` volume at `/data/local/responses.sqlite3`. The database is created by the first submission. Browser drafts remain in the current tab until submission.

## Versions and rebuilding

The navigation shows the application version. `/api/release` provides its exact source fingerprint, instrument versions, and artefact checksum. The full file manifest is inside the image at `/opt/irexplorer/release.json`. This fingerprints packaged files, including uncommitted changes, rather than claiming that an older Git commit represents the build. Application releases do not automatically change the instrument or database schema versions.

The delivered image is also retained as `irexplorer:0.1.0-356c169e1580`. For an intentional new release, choose the next version and build it:

```sh
export IREXPLORER_VERSION=0.1.1
docker compose build app
docker compose up -d --no-build --pull never --wait
```

Keep `IREXPLORER_VERSION` set when operating that version, or record it in your local `.env` file. Without it, Compose selects `0.1.0`. Do not rebuild an accepted version with different source. Static files use `Cache-Control: no-store`; ordinary refresh loads current HTML/scripts without revision parameters in the browser address.

## Export and backup

Use a new destination name each time. These commands run after at least one submission:

```sh
docker compose exec app python -m src.backend.evaluation.cli export /data/local/responses.sqlite3 /data/export-01
docker compose cp app:/data/export-01 ~/Desktop/irexplorer-export-01
docker compose exec app python -m src.backend.evaluation.cli backup /data/local/responses.sqlite3 /data/backup-01.sqlite3
docker compose cp app:/data/backup-01.sqlite3 ~/Desktop/irexplorer-backup-01.sqlite3
```

Exports contain raw JSON, analysis CSV, and a codebook. Copies on the same volume survive container replacement; copy backups onto the Mac as above to retain a copy outside Docker. See [study operations](docs/evaluation-operations.md) for restore and deletion details.

For a completely empty local test store, `docker compose down --volumes` deletes this Compose project's stored sessions, exports, and backups. Export anything you want to retain first. A fresh browser tab starts a new draft; closing a tab does not delete submitted sessions.

## Verification and development

```sh
docker build --target test -t irexplorer-test:0.1.0 .
docker run --rm --read-only --tmpfs /tmp --network none irexplorer-test:0.1.0
```

The application build verifies all 135 pinned artefacts. The test target runs the full backend suite without adding tests to the application image. `scripts/check_app.mjs` runs the current browser regression against `http://localhost:8000`, using Node 22+ and isolated headless Chrome on CDP port 9239. It submits a test session. By default it prints results only; set `IREXPLORER_CHECK_OUTPUT` to an external temporary directory if captures are needed.

Verified on 9 September 2026: 74 container backend tests, 32 browser assertions, 20 draft/timing checks, and 10 submission checks; desktop/narrow inspection; replacement persistence, original-receipt retry, ordinary refresh across builds, and identical JSON/CSV/codebook export after backup/restore. Container runtime is non-root, application files are read-only, and only localhost port 8000 is published. No compiler artefacts were regenerated.

For host development, use `.venv/bin/python -m src.backend.api.server` with the existing requirements lock; its default address is `http://127.0.0.1:8000`. Stop the container first to free that port. Historical E0–E7 evidence remains under `docs/evaluation-captures/`; new work uses this README and the existing [implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md), without additional review packs.
