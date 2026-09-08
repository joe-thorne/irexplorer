# E6 final submission verification

8 September 2026. Assets/release label `e6-submission-1`; instrument v0.1; participant content `e5-preview-1`; synthetic study `e5-synthetic-1`; local draft schema 2; storage/canonicalisation schema 1. The pinned artefact aggregate is `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`. Frontend hashes and implementation HEAD at capture are in `e6-browser-checks.json`; the working changes are uncommitted.

## Results

| Verification | Observed result |
|---|---|
| Backend suite | 73 tests pass; `e6-tests.txt` |
| E5 draft/timing regression | 20 checks pass; no change to draft schema or task clock |
| E6 submission-state checks | 10 pass; `e6-submission-checks.json` |
| Focused browser journey | 43 assertions pass, zero runtime exceptions; `e6-browser-checks.json` |
| Instrument/content audit | 60 original fields, T0–T6 prompts/setups/scales match; all four original instrument hashes unchanged |
| Model/source audit | All 42 states, source checksums, task evidence, pinned aggregate and invariant validation pass; `e6-model-audit.json` |
| Syntax/whitespace | Changed JavaScript and both repository diff checks pass |

Browser runtime discovery returned no available connected browsers. Verification used the repository's existing standalone CDP approach with isolated headless Chrome on 9239 and a new temporary profile. The same-origin E6 preview ran on 8006, with an isolated synthetic database. Two complete sessions were exercised in each of two runs; **four unique synthetic sessions remain in the review database**, with no duplicate rows from retries. The final run's captures are retained. The earlier port-8000 server and an unrelated existing Chrome on 9228 were not changed.

The browser completed consent, P1/P13, all T0–T6, partial skipped T3, task-level T2 inability, post-survey not-applicable Q1, P13/Q14 text, and formula-like multiline Unicode Q18. First-session failure was injected at the fetch seam *after the server committed*, suppressing its acknowledgement. The second used Chrome's offline network setting before submission. Both cases displayed uncertainty, prevented Back edits/discard claims, recovered the frozen envelope on refresh, retried, and received a durable receipt. Local draft and pending answer copies were absent after acknowledgement; receipt recovery survived another reload. Submission unit checks additionally cover concurrent clicks and storage/cleanup failures, without claiming those failure injections were browser UI tests.

SQLite/API tests cover valid/minimal receipt, exact consent/P1/version/item validation, invalid statuses/durations, duplicate/conflicting reuse, concurrent participants and identical submissions, controlled write failure, missing/foreign origin, content type, malformed/deep/duplicate-key/non-finite JSON, body limits including streamed input, unknown schema, disabled pilot/live, GET-only compiler paths, and private HTTP file/export boundaries. Study code imports no compiler/query/model service. Existing compiler cache/isolation and canonical model tests remain green. No public researcher data endpoint was introduced.

## Export and operational evidence

The private directory `/private/tmp/irexplorer-e6-review/export-final/` contains the actual CLI output: raw JSON, CSV, and codebook. There are four raw sessions and **268 long-format CSV rows**. Readback verified distinct IDs, consent/content/study/instrument/release metadata, T2 inability, T3 skip, Q1 not-applicable, and protected multiline formula-like Q18. JSON retains original text. Raw ratings are unchanged; reverse scoring and missing-data handling are documented separately in the codebook. These private outputs are not copied into either Git repository or static assets.

`backup-final.sqlite3` and `restored-final.sqlite3` were produced by the CLI and verified with schema/integrity checks and a four-record count. A separately launched Python process retried a stored envelope and returned its exact original receipt without inserting a row. Participant deletion removed one of two records in an earlier disposable restored copy; purge then removed that copy, leaving the source database and backup intact. Existing destinations are not overwritten by backup/restore/export commands.

The E6 application runner has access logging disabled. Its observed output contained startup messages only; study write failures are sanitised without paths/answers, and final passing test output contains test names/results only. Browser request records contain method/path, with no answer/participant code in URLs. This does not establish the logging behaviour of the old server, UQ Cloud, a future HTTPS proxy, or host backups; that audit remains E8.

## Inspected captures

- `e6-review-desktop.png`: explicit final notice, background/post correction, task outcomes, and primary Submit action.
- `e6-retry-narrow.png`: honest uncertain status, retained participant code, Retry action, and disabled reset at 390px.
- `e6-receipt-1.png`: narrow receipt with wrapped codes and explicit local cleanup confirmation.
- `e6-receipt-2.png`: desktop receipt and new synthetic session action.

All four final captures were visually inspected. No horizontal narrow-page overflow was measured. Full physical keyboard/spoken screen-reader, complete zoom/media/contrast coverage, S1.8, participant pilot, and human duration validation remain E7. E5's CFG/zoom/routing implementation and task clock were not changed. No new dependency, deployment, participant collection, commit/push, or Docker regeneration occurred. **Ready for E6 review; do not begin E7.**
