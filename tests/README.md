# Tests

Run from the application repository root. All application tests use included fixtures and synthetic responses; no thesis checkout or external instruments are required.

## Backend

With the Python environment described in the application README:

```sh
.venv/bin/python -m unittest discover -s tests -v
```

Or run the same suite in the pinned application environment:

```sh
docker build --target test -t irexplorer-test .
docker run --rm --read-only --tmpfs /tmp --network none irexplorer-test
```

The suite covers compiler fixtures and invariants, ingestion, correspondence, source and summary queries, API boundaries, study validation, transactional submission retries, mixed-release export with snapshot codebooks and researcher-pack joins, verified legacy provenance backfill, and backup/restore. Compiler generation tests inspect the generation contract without regenerating the shipped fixtures.

[Artefact-reviewed expected-correspondence tables](data/expected_correspondences/README.md) additionally
check ten complete `score`/`binary_search` comparisons across mem2reg,
instcombine, simplifycfg, loop-rotate, and the recompiled O3 state. Their 353
explicit links, IR/source fields, labelled CFG edges, and summary expectations
are asserted against fresh analysis and served correspondences. This is AI-assisted
manual artefact evidence; independent human sign-off and fresh Docker
regeneration are separate verification steps.

User programs are tested without LLVM. `test_user_programs_api.py` drives the app in-process with user programs on, pointed at the real compiler service on a loopback port. The service runs the fake `clang` and `opt` in `fake_toolchain/`, which replay the committed curated artefacts of the three unedited curated sources, looked up by the SHA-256 of the source, and fail with "no recording" for any other source. A `// irx-fake: error` line makes the fake clang fail as the pinned clang does on a call to an undeclared `abss`, and `// irx-fake: crash` makes the fake opt crash; `test_user_program_compile_failures.py` covers both. `test_user_program_warnings.py` covers clang's warnings on a program that compiles, replayed from the recorded `clang_warnings.c`. `// irx-fake: hang` never finishes (in a child process that keeps writing, as clang's own `-cc1` child would), and `// irx-fake: slow` spends 2 s in its first command and then compiles as recorded, its marker line left out of the lookup. The timeout tests start a service with a 0.5 s timeout. The cancel tests drop a request mid-compile: `test_compiler_service.py` closes its socket to the service, and `CompileCancelTests` serves the app under a real uvicorn server on loopback, since the in-process test client cannot drop a request. The fake also replays the user programs in `data/user-programs`, recorded from the real toolchain (see below); `test_user_program_recordings.py` checks that each replays exactly as recorded and that the app answers each as `data/user-programs/corpus.json` says. What is accepted as a user program is checked on both sides against the shared cases in `data/user-program-acceptance.json`: by `test_accepted_programs.py` on the server and by `scripts/check_user_programs.mjs` in the browser.

## Real-compiler smoke check

Run by hand before the demo and before merging; it is not part of CI. With Docker and the [user-programs stack](../README.md#run-with-user-programs) up:

```sh
scripts/check_user_programs.sh
```

It fails at once without Docker or a healthy stack. Otherwise it runs `test_user_programs_smoke.py` (skipped in the offline suite) against the stack: the three unedited curated sources must compile to their committed artefacts once `examples/curated` reads `user-programs` and the output directory `out`; each recording in `data/user-programs` must still match the real toolchain (ignoring the compiler image's identity); and the app must answer each corpus program as `corpus.json` says, under a fresh file name so it compiles afresh, the realistic 200-line program within 15 s. A program with `until` answers as its `currently` until that ticket lands.

The corpus sources are stored as the app sends them, each beside a directory of the same stem that holds its recording. To add a program or re-record after a deliberate toolchain change, list it in `corpus.json` and, with the stack up, run:

```sh
.venv/bin/python scripts/record_user_programs.py
```

It sends each program to the stack's compiler service (inside its container, so a program the app cannot show yet is recorded too) and rewrites its recording. Name file names after the command (`… record_user_programs.py clang_warnings.c`) to record only those programs. A recording keeps the `-O0` command's stderr (clang's warnings) as `<stem>_O0_stderr.txt` only when clang printed something; the fake `clang` replays a missing one as empty, so the curated artefacts never gain the file.

## Lint and type checks

Install the development tools over the runtime environment, then run both checks from the repository root. Their configuration is in `pyproject.toml`.

```sh
.venv/bin/python -m pip install -r src/backend/requirements-dev.txt
.venv/bin/ruff check .
.venv/bin/mypy
```

GitHub Actions (`.github/workflows/ci.yml`) runs these checks, the backend suite, the study state checks and the browser regression on Python 3.12 for every push to `main` and every pull request.

## Study state

With Node 22 or later, these standalone checks require no server or browser and write no evidence files:

```sh
node scripts/check_study_drafts.mjs
node scripts/check_study_submission.mjs
```

## Browser regression

To run the whole browser regression in one step, as CI does:

```sh
scripts/check_browser.sh
```

It starts the host runner on a disposable preview store and an isolated headless Chrome, runs the three checks below with collection open and user programs off, and reruns `check_app.mjs` with collection closed. It then starts the compiler service on loopback over the fake toolchain (no Docker or LLVM), restarts the host runner with user programs on, runs `check_user_programs.mjs`, reruns `check_study_tasks.mjs` and `check_study_guidance.mjs` unchanged (Study must not change with user programs on), and stops everything. It fails if a port it uses already answers, or still answers after it stops a server. `CHROME` names the browser executable if it is not found; `IRX_PYTHON` names the Python interpreter; `IREXPLORER_PORT` (default 8000), `IREXPLORER_CDP_PORT` (9239) and `IREXPLORER_COMPILER_PORT` (8090) name its ports. The steps below run each check by hand.

Start the application with Docker Compose, then start a separate headless Chrome instance with a temporary profile and remote debugging on port 9239. For example, on Linux:

```sh
google-chrome --headless --no-first-run --no-default-browser-check --disable-background-networking --user-data-dir="$(mktemp -d)" --remote-debugging-port=9239 about:blank
```

Use your platform's Chrome executable if named differently. In another terminal:

```sh
node scripts/check_app.mjs
```

On macOS, run the application bundle executable directly in a terminal that
remains open. The quoted command preserves the temporary profile path, so an
ordinary Chrome window is neither reused nor stopped by a profile lock:

```sh
task_profile="$(mktemp -d /private/tmp/irexplorer-devtools.XXXXXX)"
exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --no-first-run --no-default-browser-check \
  --disable-background-networking --user-data-dir="$task_profile" \
  --remote-debugging-address=127.0.0.1 --remote-debugging-port=9239 about:blank
```

Before running the regression, confirm that the isolated browser is available:

```sh
curl -fsS http://127.0.0.1:9239/json/version
```

The script requires Node 22 or later. It checks default Explore navigation, coordinated views at narrow, desktop and wide (2560 px) widths, study navigation, retry/receipt behaviour, and independent browser tabs. It submits synthetic data, so use a disposable local instance and study volume. `IREXPLORER_ORIGIN` overrides the default `http://localhost:8000`. Results go to stdout; optionally set `IREXPLORER_CHECK_OUTPUT` to a directory outside the repository for JSON and screenshots.

Run it again against an instance restarted with `IREXPLORER_COLLECTION_CLOSED=1` (and the same study store) to check closed collection. When the served content reports `submissionEnabled: false`, the script runs the same Explore checks, then, instead of the journey, checks the closed message before consent, a local draft's explicit discard, and a frozen submission that the server refuses with `410 collection_closed`, across a refresh and its discard. It also checks that a pending submission whose retry returns a receipt shows it. The closed instance stores nothing, so that receipt is supplied in the page.

With the same application and browser, check the task procedure:

```sh
node scripts/check_study_tasks.mjs
```

It runs T0–T6 from the packaged task declarations: each task's entry workspace against its target comparison, T6 inheritance and refresh, pause, hidden-tab and reload exclusions, P13 locking, read-only task responses, partial, skipped and inability answers, and background/post corrections. It then serves a synthetic content variant with different declared entry workspaces, inheritance and membership through the DevTools protocol. It sends no submission and discards each draft. It uses the same `IREXPLORER_ORIGIN` and writes results only to stdout.

Then check the journey guidance:

```sh
node scripts/check_study_guidance.mjs
```

It reads every expected sentence from the served message catalogue, glossary and introductions, and runs the journey at desktop and narrow widths. It covers normal guidance, T0 glossary help by keyboard focus and hover, validation, a failed local save, discard confirmation (including Escape and a failed discard), and review. It then covers uncertain delivery: an offline attempt, a reload, a 503, and a stored attempt whose response is lost. These must send identical content under one submission ID. The receipt appears only after the server confirms storage; cleanup failures are checked, as are incompatible and corrupt recovery. Closed collection is served as a content variant with scripted `410 collection_closed` refusals: the closed message, a local draft's discard (including a failed one), a refused submission across a refresh and its discard, and a pending retry that returns a receipt. The journey runs again with every message marked, then with markup in the prose, then with catalogues that break the key or placeholder contract or content without a boolean `submissionEnabled`. Each full journey submits one synthetic record, so use a disposable local or preview store.

To check user programs by hand, start the compiler service over the fake toolchain and an application with user programs on, with the same browser:

```sh
.venv/bin/python -m src.backend.toolchain.compiler_service --port 8090 --toolchain tests/fake_toolchain --workspace "$(mktemp -d)"
IREXPLORER_USER_PROGRAMS=1 IREXPLORER_COMPILER_URL=http://127.0.0.1:8090 IREXPLORER_COMPILER_TIMEOUT=5 .venv/bin/python -c "from src.backend.api.server import run_server; run_server()"
IREXPLORER_ORIGIN=http://127.0.0.1:8000 IREXPLORER_COMPILER_PID=<compiler service pid> node scripts/check_user_programs.mjs
```

It uploads the unedited curated sources, which the fake toolchain has recordings for, and checks the **Curated examples | Your files** switch, the compile card and a user program opening in the panels. It writes a new program with **New…**, whose starter function is recorded as `data/user-programs/program.c`, and checks the editor's line numbers, highlighting and locked file controls, its keys (Tab and Shift+Tab on a line and a selection, Enter keeping the indent, Esc then Tab leaving the editor, and the browser's undo stepping back through them), the margin marks and status line counting new or changed lines, the hint's line count against 200, compiling with **Compile** and with Ctrl+Enter under the name typed, and that **Discard edits** asks first and brings back what was open. It compiles an edit carrying the `error` marker and checks that the editor comes back with the edit as it was, its failing lines marked and clang's diagnostics listed above it and announced, that each diagnostic moves the caret to its line, that an edit carrying the `crash` marker comes back the same way with clang's output, and that discarding brings back the comparison the edit started from. It meets an edit's compile with a busy compiler, a timeout (answered in the page, as the fake toolchain cannot outlast the app's own wait), an unavailable compiler (the `hang` marker, until the app's 5 s compiler timeout) and **Cancel**, and checks that **Back to editing** leads each card and returns to the edit unchanged, that **Try again** compiles the edit, and that a file chosen from an edit's card replaces the edit as an upload does. It starts edits with **Edit a copy** on a curated example and **Edit** on an upload, and checks the heading, the copy's name and the compiled source beside the editor with its note. It compiles an edited copy of `quick_sort`, recorded as `data/user-programs/quick_sort.c` (partition kept, quick_sort renamed sort), and checks that both panels keep their states and views and the function stays chosen, or the default function is chosen when the chosen one is gone, with the source selection and trace cleared. It also checks that Study never has the upload controls, even after a compile started in Explore, and that a task inheriting its workspace opens the curated one rather than a user program on screen. It makes the compiler busy with a slow compile posted from outside the page, and unavailable by pausing the compiler service's process (`IREXPLORER_COMPILER_PID`) until the app's 5 s compiler timeout passes, then checks that **Try again** succeeds once the cause is gone. It cancels a hanging compile and checks that another file uploaded straight after compiles rather than finding the compiler busy. It also cancels the recompile of a program the server forgot, and checks that the upload stays listed and **Try again** opens it. It uploads the recorded `clang_warnings.c` and checks that its warnings are listed, collapsed, above the source, marked on their lines and announced. Each scenario starts from a freshly loaded Explore page. `check_app.mjs` checks that no upload control is built with user programs off.

All four scripts connect to the browser on port 9239 unless `IREXPLORER_CDP_PORT` names another. Close the temporary Chrome process after testing.

Automated checks do not establish complete accessibility conformance or replace physical keyboard and spoken screen-reader testing.

## Deployment checker contract

The repository gate runs the deployment checker’s public-origin assertions
against a local mock server without network access:

```sh
node --test tests/test_deployment_checker.mjs
```

The checks require controlled not-found responses for the packaged documentation and OpenAPI routes, verify the required response headers, and prove that reachable docs or missing study-response headers fail the deployment check. They also cover the `--expect-closed` expectation: a closed service passes in every mode, and the check fails when content reports open collection, the probe gets `422`, the service environment lacks `IREXPLORER_COLLECTION_CLOSED=1`, or the `410` lacks a security header or `no-store`. Without it, a service environment that sets `IREXPLORER_COLLECTION_CLOSED=1` fails.
