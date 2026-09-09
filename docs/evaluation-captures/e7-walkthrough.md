# E7 complete synthetic walkthrough and S1.8 record

9 September 2026. This is a localhost-only, synthetic E7 rehearsal. The implementation HEAD was `fd6673757dd04bab1aefeff321e483fdcc9a5ce5` with the working E6/E7 review changes present. The trusted server release label and visible asset label are `e7-walkthrough-1`; the participant instrument remains v0.1, participant content remains `e5-preview-1`, the study remains `e5-synthetic-1`, and local draft schema remains 2. The pinned aggregate covers 135 artefacts and is `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`. It was verified against the checked-in fixtures; no Docker regeneration was run.

## E7 walkthrough results

An isolated Chrome 152 profile and a disposable local preview store completed 28 behavioural assertions with zero runtime exceptions. The complete list, current frontend hashes, implementation revision, and execution timestamp are in `e7-browser-checks.json`.

| Area | Observed evidence |
|---|---|
| Workspace and faithfulness | All three curated examples loaded. A `score` source line highlighted mapped IR in both panes, its absence after `instcombine` was explicit, Enter followed an IR correspondence, and a focused CFG route visibly isolated itself. |
| Failure recovery | An injected source request failure showed a controlled unavailable state; restoring the request and reselecting the example recovered canonical source data. A lost submission acknowledgement froze answers, then retry produced the durable receipt. |
| Study journey | Consent, P1/P13, T0–T6, post-survey, review, explicit final submission, uncertainty, retry, and receipt were exercised with invented values. Route headings received focus at every screen and task transition. |
| Accessibility and scale | CDP Space operated a consent checkbox, Enter operated an IR line, reduced-motion and forced-colours media queries were applied, and no page-width overflow occurred at a 390 px viewport with 200% emulated page scale. |
| Session isolation | A separately created browser tab began with neither the first tab's answer draft nor its receipt. |

The two captures were visually inspected: `e7-review-desktop.png` shows the explicit review/submission boundary, and `e7-receipt-narrow-zoom.png` shows wrapped receipt and participant codes at narrow/zoomed display. The retained private trial export at `/private/tmp/irexplorer-e7-final.PnBASM/trial-export/` contains one invented session, 67 long-format CSV rows, raw JSON, and its codebook. It is not in either repository.

## S1.8 acceptance matrix

| S1.8 requirement | Current evidence | Status |
|---|---|---|
| Curated MVP and -O0/-O3 comparison | Full suite covers three curated C examples, all 42 states, function-scoped IR/CFG, state navigation, and immutable query boundaries. The browser rehearsal loaded the current workspace. | Verified |
| Human-inspectable IR, structural CFG, interaction | Browser checks exercised source/IR/CFG coordination, keyboard IR selection and CFG route focus. The captures show the final review interface; historical S3.4 captures remain historical only. | Verified in automated browser; physical check pending |
| Case-study and faithfulness record | `e7-model-audit.json` validates source checksums, commands, state IDs, all source mappings, pinned aggregate, invariants, and T1–T5 evidence. It confirms `score` line-3 computation disappears at `instcombine`, the `binary_search` T3/T4 CFG facts, and the `quick_sort` approximate example without treating missing mappings as proof of removal. | Verified |
| Golden fixtures and reproducibility | The aggregate SHA-256 gate and the 73-test suite pass. These tests validate the stored fixtures, not a fresh Docker generation. | Verified fixture integrity; regeneration not performed |
| Controlled failure and separation | Tests cover malformed/unknown query paths, failed storage writes, private data boundaries, disabled pilot/live modes, and no compiler path from survey submission. The walkthrough recovered injected source and acknowledgement failures. | Verified |
| Accessibility/NFR11 evidence | Current desktop/narrow captures and the E7 browser record exist. A real physical Tab/Enter/Space walkthrough and spoken screen-reader assessment remain human checks. | Ready for Joe's review |

## Issues and release limits

E7-01 is resolved: the visible preview label, asset cache revision, and default trusted application revision now identify `e7-walkthrough-1`, while the E6 submission-envelope storage key remains stable for compatible retry recovery.

The following are deliberately deferred rather than treated as defects fixed by synthetic automation: Joe's physical keyboard and spoken screen-reader assessment; a timed human pilot and the approximately 35-minute estimate; D3–D5 consent/withdrawal, storage/access/retention, and ethics wording; D7/D8 timing and strata decisions; host/proxy logging, HTTPS, durable deployment, and release freeze in E8. Pilot and live submissions remain disabled. No participant, recruitment, deployment, instrument amendment, dependency, commit/push, or Docker regeneration occurred.
