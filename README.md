# irexplorer

Explore how LLVM optimisation passes transform C programs through coordinated source, intermediate representation (IR), and control-flow graph (CFG) views.

Choose a curated program, select two optimisation states, and follow corresponding instructions or blocks between them. The application ships with verified compiler outputs; running it does not require LLVM or compile user-supplied code unless you start the separate [user-programs stack](#run-with-user-programs).

## Project status

The curated application, local study flow, submission/retry service, and researcher export tools are implemented. Local and preview modes support synthetic testing; pilot and live collection start only from a deliberately configured release with finished participant content, a released build, and an HTTPS origin (see [evaluation operations](docs/evaluation-operations.md#pilot-and-live-collection)). This standalone repository keeps only current technical documentation—completed thesis audits, phase plans, and research worklists belong outside the application repository.

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

Only localhost port 8000 is published. The application runs as a non-root user with read-only application files. Local submissions live in the named `study-data` volume, at `/data/local/submissions.sqlite3`; the database is created on the first submission. A legacy `/data/local/responses.sqlite3` store is moved and migrated on first use. Use `localhost` consistently because submission validation checks the exact origin.

## Run with user programs

User programs let you open one small C file of your own in **Explore**, write one in its editor, or edit a copy of a curated example or one of your files, and follow it through the same states, panels and comparison report as a curated example. They are for local use only and run in a separate Compose stack, on port 8001, beside the study stack above. Build the pinned toolchain image once (it downloads about 1.7 GB of LLVM), then start the stack:

```sh
docker compose --profile toolchain build toolchain
docker compose -f compose.user-programs.yaml up -d --build --wait
```

Open **http://localhost:8001**. A program that compiles with clang warnings lists them, collapsed, above its source, and marks their lines. A compiled edit of one of your files replaces it in **Your files**; a copy of a curated example or a new program is added, under a numbered name such as `program (2).c` if its name is already listed. **Restore original** in the editor puts back the curated example or the file first uploaded. Stop it with `docker compose -f compose.user-programs.yaml down`; add `--volumes` to remove its own local study store as well.

The stack runs the same application image with the user programs setting on, beside a compiler service holding the pinned LLVM toolchain and the C library headers. On Apple Silicon the compiler runs `linux/amd64` under emulation, so a program takes a few seconds. The compiler service has no published port and no internet access, reaches only the application over the stack's internal network, has a read-only root file system and wipes its temporary work directory after each program. The application never gets the Docker socket and never runs `clang` or `opt` itself.

With the stack up, `scripts/check_user_programs.sh` checks it against the real toolchain; CI runs the same check on amd64 when started by hand. See [tests/README.md](tests/README.md#real-compiler-smoke-check).

## Run with Python

Python 3.12 is the container runtime baseline. From the repository root:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install -r src/backend/requirements.lock
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000**. Stop the Docker application first if it already uses port 8000. The host runner uses the development release label and a separate preview study store by default; see [study operations](docs/evaluation-operations.md).

## Development and verification

- [Tests](tests/README.md): backend, browser, and study state checks, plus lint and type checks (install `src/backend/requirements-dev.txt` for these).
- [Compiler environment](docs/environment.md): pinned LLVM toolchain and intentional artefact regeneration.
- [API](src/backend/api/README.md): curated query interfaces; interactive API documentation and OpenAPI are not exposed.
- [Study operations](docs/evaluation-operations.md): configuration, export, backup, restore, and deletion.
- [Accessibility](docs/accessibility.md): interface behaviour and testing limitations.

`src/frontend/` contains the browser application. `src/backend/` contains compiler tooling, immutable models, comparison analysis, the HTTP API, and the separate study service. `examples/curated/` and `artefacts/curated/` are required application data and reproducible compiler fixtures.

## Release identity

The navigation displays the application version. `/api/release` exposes its source fingerprint, instrument versions, and artefact checksum, and beside them a runtime `config` object (whether user programs are on) that is not part of the release identity. Container builds verify all pinned compiler artefacts and generate `release.json` from the packaged inputs. Git checkouts identify as development builds even when a generated `release.json` remains from an earlier build.

For a new version:

```sh
export IREXPLORER_VERSION=0.6.0
scripts/check_dependency_advisories.sh
docker compose build app
docker compose up -d --no-build --pull never --wait
```

The advisory check uses the pinned `pip-audit` tool from `src/backend/requirements-dev.txt` to query published Python package advisories for the exact pins in `src/backend/requirements.lock`. It requires network access and deliberately stays outside the offline repository gate. Install the development requirements first if `.venv/bin/pip-audit` is unavailable.

Keep the version set when operating that image, or record it in a local `.env` file. An accepted release version should identify one source state. Application versions, instrument versions, and database schema versions are independent. `/docs` and `/openapi.json` are disabled in development checkouts and packaged releases.

## Licence

[MIT](LICENSE). Vendored frontend dependencies retain their own [licence notices](src/frontend/vendor/README.md).
