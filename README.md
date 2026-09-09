# irexplorer

Explore how LLVM optimisation passes transform C programs through coordinated source, intermediate representation (IR), and control-flow graph (CFG) views.

Choose a curated program, select two optimisation states, and follow corresponding instructions or blocks between them. The application ships with verified compiler outputs; running it does not require LLVM or compile user-supplied code.

## Run locally

Clone this repository and start Docker with Compose support:

```sh
git clone https://github.com/joe-thorne/irexplorer.git
cd irexplorer
docker compose up -d --build --wait
```

Open **http://localhost:8000**. The default page is **Explore**. An optional evaluation survey and task flow is available through **Study**, at **http://localhost:8000/#/study**. Local survey submissions stay in your local Docker volume; this is not a hosted research collection service.

This repository runs independently: no parent repository, submodules, external survey instruments, or university infrastructure are required. Frontend libraries and curated compiler data are included.

```sh
docker compose stop       # Stop; retain local submissions.
docker compose start      # Resume.
docker compose down       # Remove container; retain local submissions.
```

Only localhost port 8000 is published. The application runs as a non-root user with read-only application files. Local study data lives in the named `study-data` volume, at `/data/local/responses.sqlite3`; the database is created on the first submission. Use `localhost` consistently because submission validation checks the exact origin.

## Run with Python

Python 3.12 is the container runtime baseline. From the repository root:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install -r src/backend/requirements.lock
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000**. Stop the Docker application first if it already uses port 8000. The host runner uses the development release label and a separate preview study store by default; see [study operations](docs/evaluation-operations.md).

## Development and verification

- [Tests](tests/README.md): backend, browser, and study state checks.
- [Compiler environment](docs/environment.md): pinned LLVM toolchain and intentional artefact regeneration.
- [API](src/backend/api/README.md): curated query interfaces; interactive OpenAPI at `/docs` while running.
- [Study operations](docs/evaluation-operations.md): configuration, export, backup, restore, and deletion.
- [Accessibility](docs/accessibility.md): interface behaviour and testing limitations.

`src/frontend/` contains the browser application. `src/backend/` contains compiler tooling, immutable models, comparison analysis, the HTTP API, and the separate study service. `examples/curated/` and `artefacts/curated/` are required application data and reproducible compiler fixtures.

## Release identity

The navigation displays the application version. `/api/release` exposes its source fingerprint, instrument versions, and artefact checksum. Container builds verify all pinned compiler artefacts and generate `release.json` from the packaged inputs. Host checkouts without that file identify as development builds.

For a new version:

```sh
export IREXPLORER_VERSION=0.1.1
docker compose build app
docker compose up -d --no-build --pull never --wait
```

Keep the version set when operating that image, or record it in a local `.env` file. An accepted release version should identify one source state. Application versions, instrument versions, and database schema versions are independent.

## Licence

[MIT](LICENSE). Vendored frontend dependencies retain their own [licence notices](src/frontend/vendor/README.md).
