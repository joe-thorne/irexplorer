# E5 task journey, recovery, and timing evidence

8 September 2026 · **Ready for Joe's review.** Joe reviewed E4 with no amendments. E5 adds the full local T0–T6 journey and stops before E6 submission/storage. The four original instruments remain byte-for-byte v0.1.

Preview: **http://127.0.0.1:8000/?revision=e5-tasks-1#/study**. Run `.venv/bin/python -m src.backend.api.server` from `irexplorer/`; the local review server remains running. See the parent [review pack](../../../Docs/evaluation/e5-review.md) and [task/content/duration contract](../../../Docs/evaluation/e5-task-contract.md).

**Later E5 amendment:** [C28/C29 task scrolling and CFG sizing](e5-layout-amendment.md) supersede the original asset revision below. The original counts/captures remain historical; current assets are `e5-layout-2`.

## Verification

- **65 backend tests pass:** [full output](e5-tests.txt). The two E5 tests cover task inventory, declared setup boundaries, actual confidence/response structures, optional partial responses, item-level inability/not-applicable distinctions, unknown items, type/range errors, and Unicode text bounds. Existing API tests cover the added static clock module and E5 asset revision; compiler queries and public HTTP methods remain read-only.
- **20 draft/validation/timing checks pass:** [results](e5-draft-checks.json), reproduced with `node scripts/check_e5_drafts.mjs`. Includes E4 consent/storage/version/requiredness regressions plus task order, partial skipped/inability answers, corrupt progress/time rejection, Unicode recovery, deterministic monotonic accumulation, repeated resume/checkpoint, hidden/paused/refresh downtime, and frozen completed-task duration/interruption state.
- **89 isolated Chrome assertions pass:** [results, actual browser version, implementation HEAD, and frontend source hashes](e5-browser-checks.json), reproduced with `node scripts/capture_e5.mjs` against isolated Chrome on port 9227 and the local server on 8000. Eight final screenshots were visually inspected. No JavaScript runtime exceptions occurred. All observed application requests were GET; no synthetic response text or participant code appeared in request URLs.
- **Content fidelity passes:** `.venv/bin/python scripts/build_e5_content.py --check` verifies the 60 source-backed fields, T0–T6 goals/instructions/setups, original scales/options, and four original instrument hashes. The executable definition is `e5-preview-1`; study `e5-synthetic-1`; draft schema 2; assets `e5-tasks-1`. No instrument freeze or release revision is claimed.
- **Model/artefact audit passes:** [current audit](e5-model-audit.json), reproduced with `.venv/bin/python scripts/audit_e0.py --output docs/evaluation-captures/e5-model-audit.json`. Confirms all 42 source/state identities, source checksums, provenance commands, model invariants, pinned artefact snapshot, T1–T5 feasibility, and private-file boundaries. This is not Docker regeneration.
- JavaScript syntax and separate parent/submodule whitespace checks pass. No dependency was installed.

The browser rehearsal completes consent → pre → T0–T6 → post → local review using invented answers. It covers exact setup endpoints, no preselected T2 answer/node, real P13 locking, state/view changes, explicit pause and paused refresh, hidden/visible transitions, active refresh without double counting, future-task and P1-correction gating, read-only saved tasks, partial inability/skip outcomes, all T5/T6 fields, rapid example/function changes, delayed stale setup responses, T6 refresh awaiting a chosen workspace, and complete-draft recovery. Required-workspace failures cannot start timing; retries restore readiness. Failed discard and local task-save failures remain explicit and recoverable. No marking key, expected-observation payload, scoring, stratification, or facilitator notes are served; instrument/researcher evidence URLs return 404.

Chrome's lifecycle/focus emulation exercises the document's actual hidden/visible state and visibility events; deterministic clock tests independently check arithmetic. These are controlled browser tests, not a human timed rehearsal. Native Enter moves focus through the task/workspace links, and Chrome's accessibility tree exposes named task question groups. The narrow response jump opens its disclosure without replacing the task route. The checks do not establish spoken screen-reader behaviour or full accessibility conformance.

The browser plugin reported no available browser after its documented discovery check. A separate temporary Chrome profile under `/private/tmp/irexplorer-e5-chrome` was used instead, without reading or modifying Joe's browser. The first launch was interrupted by automatic approval review's account-usage-limit rejection on 7 September; the authorised continuation succeeded on 8 September. The isolated browser is closed after final capture.

During verification, the headless harness needed explicit visible-state restoration after lifecycle freezing; synthetic non-cancellable click events were also replaced with browser `.click()` activation so prevented in-page navigation was tested accurately. Application fixes retained the clock after failed discard, exposed the next stage after a retried terminal save, and kept function preservation within the guarded example load so an obsolete task setup could not overwrite a newer workspace. A compact normal-save notice, Back to goal link, independent narrow disclosures, and human-readable outcome labels support task review.

## Captures

| Capture | Visual check |
|---|---|
| [T0 desktop](e5-t0-desktop.png) | Original orientation goal/instructions beside verified C; compact tab-save notice |
| [T1 desktop](e5-t1-desktop.png) | Teaching-chain end clarification and active timing/pause control |
| [T2 narrow overview](e5-t2-narrow.png) | Goal, focus links, and independently collapsed task sections; no page-wide overflow at 390px |
| [T2 narrow responses](e5-t2-narrow-responses.png) | Full original choice labels and explicit inability selection; visible keyboard focus |
| [T3 desktop responses](e5-t3-desktop.png) | Short text/inability alternatives, 256-character bound, and retained partial graph description |
| [T4 responses beside CFG](e5-t4-desktop.png) | Readable response controls beside the real canonical/rotated graphs; existing graph viewers scroll independently |
| [T5 desktop](e5-t5-desktop.png) | Original confidence-signal goal, both functions, unrestricted comparison controls |
| [Local review](e5-review-desktop.png) | Human-readable task outcomes, active durations/interruption flags, and disabled E6 submission |

## Remaining review and release gates

Joe's full timed rehearsal and task-area ergonomics review remain the E5 review point. For a supervised rehearsal, keep a separate private interface-assistance note by participant code/task; no content hints or browser assistance log is added. D3–D5 still gate any participant pilot. Original instrument corrections, partial-answer/text limits, timing-budget interpretation, and analysis ambiguities remain explicit review/freeze decisions.

Full physical keyboard/spoken screen-reader, final zoom/media/contrast testing, and S1.8 remain E7. Durations include interface use/answering and are not pure comprehension times. T6 refresh retains responses/time but deliberately requires choosing a workspace again; no workspace interaction history is persisted. The duration contract documents checkpoint/crash limits and the E6 export handover. No E6 collection/storage/export, real responses, deployment, recruitment, commits, pushes, or Docker regeneration occurred.
