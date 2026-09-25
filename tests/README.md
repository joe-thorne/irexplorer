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

The suite covers compiler fixtures and invariants, ingestion, correspondence, source and summary queries, API boundaries, study validation, transactional submission retries, export, and backup/restore. Compiler generation tests inspect the generation contract without regenerating the shipped fixtures.

[Artefact-reviewed expected-link tables](data/expected_links/README.md) additionally
check ten complete `score`/`binary_search` comparisons across mem2reg,
instcombine, simplifycfg, loop-rotate, and the recompiled O3 state. Their 353
explicit links, IR/source fields, labelled CFG edges, and summary expectations
are asserted against fresh analysis and served correspondences. This is AI-assisted
manual artefact evidence; independent human sign-off and fresh Docker
regeneration are separate verification steps.

## Lint and type checks

Install the development tools over the runtime environment, then run both checks from the repository root. Their configuration is in `pyproject.toml`.

```sh
.venv/bin/python -m pip install -r src/backend/requirements-dev.txt
.venv/bin/ruff check .
.venv/bin/mypy
```

GitHub Actions (`.github/workflows/ci.yml`) runs these checks, the backend suite, and the study state checks on Python 3.12 for every push to `main` and every pull request.

## Study state

With Node 22 or later, these standalone checks require no server or browser and write no evidence files:

```sh
node scripts/check_study_drafts.mjs
node scripts/check_study_submission.mjs
```

## Browser regression

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

The script requires Node 22 or later. It checks default Explore navigation, coordinated views, study navigation, retry/receipt behaviour, and independent browser tabs. It submits synthetic data, so use a disposable local instance and study volume. `IREXPLORER_ORIGIN` overrides the default `http://localhost:8000`. Results go to stdout; optionally set `IREXPLORER_CHECK_OUTPUT` to a directory outside the repository for JSON and screenshots. Close the temporary Chrome process after testing.

Automated checks do not establish complete accessibility conformance or replace physical keyboard and spoken screen-reader testing.
