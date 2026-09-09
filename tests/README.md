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

The script requires Node 22 or later. It checks default Explore navigation, coordinated views, study navigation, retry/receipt behaviour, and independent browser tabs. It submits synthetic data, so use a disposable local instance and study volume. `IREXPLORER_ORIGIN` overrides the default `http://localhost:8000`. Results go to stdout; optionally set `IREXPLORER_CHECK_OUTPUT` to a directory outside the repository for JSON and screenshots. Close the temporary Chrome process after testing.

Automated checks do not establish complete accessibility conformance or replace physical keyboard and spoken screen-reader testing.
