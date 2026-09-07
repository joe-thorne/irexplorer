# E0 baseline and private task-evidence audit

**7 September 2026 · Ready for review, not S1.8 completion.** App source/artefact baseline `cb794d3`; parent thesis baseline `afd21e1`. All captures show the current S3.5 workspace, not E1–E8 features. No application source, canonical artefact, or accepted instrument was changed. Synthetic checks only. This file and the answer evidence are researcher-only; the application serves only `src/frontend/`, not this directory. Repository visibility has not been verified, so do not distribute this pack to participants.

## Reproducible evidence

- [Task evidence JSON](e0-task-evidence.json): 60 source-backed participant fields, original instrument SHA-256 values, canonical source hashes, 42 state/function/mapping inventories, and T1–T5 assertions.
- [Browser observations](e0-browser-checks.json): Chrome 152.0.7977.82, desktop 1440×1000, narrow viewport 390×844, no JavaScript runtime exceptions; actual capture timestamp, Git revision, and frontend file SHA-256 values are recorded. The Browser runtime returned no available browser after its documented discovery check; an isolated local headless Chrome/CDP fallback produced the captures. No new packages were installed.
- [Score desktop](e0-score-desktop.png), [score narrow, full page](e0-score-narrow.png), [binary_search T3](e0-binary-search-t3.png), [binary_search T4](e0-binary-search-t4.png), [quick_sort T5](e0-quick-sort-t5.png). Images were visually inspected. They contain curated compiler data, no participant answers or identifiers.
- [Audit rejection probes](e0-audit-checks.txt): five in-memory mutations were rejected (missing field, leaked researcher property, unsourced wording, altered P1 requiredness, and task reordering); original 60-field content passes. No files were mutated by these probes.
- [Backend baseline transcript](e0-tests.txt): **52 tests passed** in 0.697 seconds. These include the aggregate checksum gate; they are not a fresh Docker generation.

Pinned aggregate: 135 generated files, SHA-256 `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`. Canonical LLVM remains 22.1.8 Linux/x86-64. Source bytes match the DIFile MD5 checksums embedded in each of the 42 textual IR states. This checks input consistency, not a cryptographic authenticity claim or fresh compilation. All state origin commands resolve to the recorded manifests. All function CFG queries and recorded source anchors resolve across the three examples. Source mappings remain compiler debug-location evidence only.

## Task evidence (never participant content)

| Task | Checked evidence | Result / restriction |
|---|---|---|
| T0 | score 0 O0 → 1 mem2reg, IR/CFG available | Orientation is feasible; no scored response |
| T1 | score 0 O0 has 41 instructions / 4 blocks; 12 final_cleanup has 5 instructions / 1 block | Stack traffic and wasted arithmetic disappear; branches flatten into a select. Final is ordinal 12, not 13 O3 |
| T2 | score C line 3: two `mul nsw` and a `sub nsw` remain in states 0 and 1. At 2 instcombine the arithmetic and addition disappear; actual IR inspected as well as debug locations | Existing key `instcombine` is supported. `mem2reg` does not eliminate the computation. No pipeline/key edit needed |
| T3 | binary_search 3 simplifycfg, function fn0, instruction fn0/bb1/i2: `%cmp = icmp slt i32 %lo.0, %hi.0`; C line 5 | Containing block fn0/bb1 = `while.cond`; true → `while.body`, false → `while.end`. IR click highlights that block in the current browser. Arrows need E3 repair before using T3b |
| T4 | binary_search 6 loop_canonical: 7 blocks / 9 edges; 7 loop_rotate: 8 blocks / 11 edges | `entry` gains a true/false guard; `while.body.lr.ph` leads into body; body's true edge loops to itself and false goes through `while.cond.while.end_crit_edge` to exit. Actual CFG supports rotation; renderer hides the self-loop |
| T5 | quick_sort function `quick_sort` (fn0), 0 O0 → 9 indvars. Select fn0/bb0/i9 `%cmp` (C line 25) | Counterpart fn0/bb0/i0, changed/approximate. Browser displays “linked counterpart in indvars (changed; approximate confidence)” and explains nine composed transitions, no single pass attributed. This is interpretation coding, not correctness |
| T6 | Three examples and independent state/view controls; quick_sort has quick_sort and partition functions in all states | Free exploration available. The five-minute guidance and task timing are not implemented |

All state IDs in order: 0 O0; 1 mem2reg; 2 instcombine; 3 simplifycfg; 4 gvn; 5 cleanup; 6 loop_canonical; 7 loop_rotate; 8 licm; 9 indvars; 10 loop_cleanup; 11 vectorize; 12 final_cleanup; 13 O3 (recompiled). Repeated cleanup identifiers remain distinct.

## Observed baseline defects / owning step

- **C07, E3; affects T3/T4, FR7/NFR3.** `renderCfg` draws centre-to-centre lines before opaque blocks, covering arrowheads. Reciprocal edges overlap; T3 true/unconditional labels collide. T4 has one zero-length self-edge, so the body back-edge is invisible; long labels overflow fixed boxes. Acceptance: visible directed arrowheads, distinct reciprocal paths, a non-zero self-loop, readable labels, and model-consistent edge counts/targets in both T3/T4 captures. This is a presentation repair; do not alter compiler/model evidence or insert task hints.
- **C08, E1/E3; NFR1/NFR6.** Narrow score page is 3037px tall; the second pane begins far below the first. No document-wide horizontal overflow at 390px, but IR needs local horizontal scrolling. Use bounded readable panes/task controls and test the comparison at narrow widths. Long state labels truncate on desktop; explicit ordinals/source hierarchy remain planned.
- Source panel, summary outcomes, previous/next controls, task panel, and study journey are absent, as expected at E0. Current pass explanation is a general purpose, not recorded summary outcomes. Q2 cannot be meaningfully trialled until E3 supplies the summary.

These defects predate E0 and stay unchanged in baseline captures. E0 records the discrepancy; E3 owns the concrete renderer fix before participant pilot.

## S1.8 gap list

| Gate | Current evidence | Still required |
|---|---|---|
| Curated states, golden fixtures, invariants | 52 baseline tests; aggregate, 42 source/command/state/function checks; model loading validates records | Final release evidence after interface changes; do not use count alone as completion |
| Case-study faithfulness | T1–T5 researcher audit against pinned models and actual T2 IR | Final source/comparison walkthrough, provenance/summary evidence and uncertainty validation across same/reversed/adjacent/wider/recompiled/no-op cases |
| Faithful rendered CFG | T3 selection works; model topology checked | C07 arrow/self-loop/label repair, visible T3b/T4 acceptance |
| Source coordination / summaries | Underlying debug edges and summary functions exist | E2/E3 restore API/presentation and cover missing/multiple mappings and stale requests |
| End-to-end Must-have / requirements traceability | Working curated S3.5 workspace and current captures | Final E7 matrix against FR/NFR/DR claims; study-ready source/summary features also required by web plan |
| Accessibility / scale | Desktop/narrow observations; existing static semantics/contrast regressions | Physical Tab/Enter/Space, screen-reader forms, zoom, reduced motion, forced colours, failures, large fixture, independent sessions, and complete journey |
| Reproducibility | Existing 135-file aggregate matches; source debug checksums match | Fresh pinned Docker regeneration/review when claiming generation reproducibility; not run in E0 |
| Study/operations | Draft field/code/API/storage contracts; original instruments unchanged | E4–E8 forms/timing/validation/storage/retry/export/backup/deletion/logging tests and D3–D5 decisions |

## Run and reproduce

Preview at **http://127.0.0.1:8000/**, launched with `.venv/bin/python -m src.backend.api.server` from `irexplorer/`. The command emits a pre-existing Python runpy import warning but the server starts and responds. No hash study routes exist yet.

```sh
.venv/bin/python scripts/audit_e0.py
.venv/bin/python -m unittest discover -s tests -v
node --check src/frontend/app.js
node --check scripts/capture_e0.mjs
git diff --check
```

JavaScript syntax checks and both repository `git diff --check` checks passed. Review links were checked with no missing targets; Git diffs confirm instruments, application source, examples, and canonical artefacts are unchanged. The running `/api/health` returned `{"status":"ok"}` and `/api/examples` returned all three examples. Run parent `git diff --check` separately. The audit uses the parent `Docs/evaluation/` draft; it is not a production validator. It fails on source instrument drift, missing/unsourced fields, unexpected projection metadata, invalid IDs, or changed task evidence. New API shape/response validation is deferred to the owning E-step, not falsely tested as installed E0 functionality.

To reproduce captures on this Mac, with the preview already running, start a separate temporary Chrome profile (never use a personal profile), then the checked-in Node script (Node 22+ built-ins only):

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-first-run --no-default-browser-check --user-data-dir=/tmp/irexplorer-e0-cdp --disable-background-networking --remote-debugging-port=9223 about:blank
```

In another terminal, `node scripts/capture_e0.mjs`. Close this temporary headless process after capture. No physical-keyboard or full accessibility success is inferred from CDP clicks. Review [the parent E0 handover](../../../Docs/evaluation/e0-review.md) before proceeding to E1.
