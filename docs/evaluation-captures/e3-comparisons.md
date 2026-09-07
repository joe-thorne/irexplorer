# E3 comparison and CFG evidence

7 September 2026 · **Ready for Joe’s review, not S1.8 completion.** E2 was reviewed with no amendments. E3 adds state stepping, comparison summaries and CFG readability repairs. All evidence is synthetic/curated; task evidence and this directory remain outside the served frontend. E0–E2 captures retain their historical labels and bytes.

## Recorded verification

- [Backend transcript](e3-tests.txt): **58 tests pass**. New coverage resolves every summary item to existing links/remarks, verifies all adjacent transitions plus wider, reversed, same-state, no-op and recompiled comparisons on all three examples, and checks HTTP schemas and controlled failures. The original canonical checksum tests pass.
- [Browser checks](e3-browser-checks.json): **71 assertions pass**, zero runtime exceptions, GET-only requests, Chrome version, capture timestamp, implementation base revision and SHA-256 of all six frontend assets. The working implementation diff is additional to the recorded base revision. Native automated Tab/Enter/Space exercises the new step controls and IR/CFG selection. Checks include source retention, all 14 states, direction/scope/O3 wording, exact rendered edge/node counts, external arrow endpoints, non-zero self-loop, full label bounds, 390px overflow, bounded viewers, forced-colour/reduced-motion emulation, delayed summaries and failure/recovery.
- [Fresh task/instrument audit](e3-task-evidence.json): original 60 participant fields, unchanged instrument SHA-256 values, all 42 source/state/command identities, original T1–T5 evidence, unavailable researcher routes and no submission endpoint. The audit’s optional output path preserves E0’s original JSON. No study items, wording, choices, scales, keys or task order changed.
- Syntax checks for `app.js`, `source.js`, `comparison.js`, `preview.js` and `capture_e3.mjs`, plus separate parent/implementation `git diff --check`, pass.

Pinned aggregate remains 135 files, SHA-256 `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`. The unchanged artefact/source checks are **not** a fresh Docker regeneration. LLVM remains 22.1.8 Linux/x86-64.

## Visually inspected captures

| Capture | Observed result |
|---|---|
| [score IR/IR](e3-score-ir-ir.png) | Baseline and final teaching-chain IR, aligned pane content, full wrapped state labels, whole-example recorded outcomes and collapsed evidence |
| [binary_search IR/CFG](e3-binary-search-ir-cfg.png) | T3 source/IR/CFG coordination; visible boundary arrows and separately routed reciprocal edges with true/false/unconditional labels |
| [binary_search CFG/CFG](e3-binary-search-cfg-cfg.png) | T4 6→7 comparison, locally scrolled graphs, visible body self-loop and complete long block labels; graph topology is 7 blocks/9 edges → 8 blocks/11 edges |
| [quick_sort evidence](e3-quick-sort-evidence.png) | Wider comparison context, whole-example outcome disclosure and separate approximate selected-instruction confidence; original evidence and commands remain expandable |
| [quick_sort at 390px](e3-quick-sort-narrow.png) | Function selector and wrapped selected-state labels fit; each pane is bounded to 320px with local scrolling and no page-wide horizontal overflow |
| [synthetic task workspace](e3-task-desktop.png) | Task goal/actions remain beside source, summary and independent panes; no participant answers or real task hints are present |

The graphs use model-order vertical blocks and separate outside lanes for forward/backward edges, with self-loop curves and full-width labels. No compiler/model topology changed. Large graphs require local scrolling; the text-edge disclosure provides the same labelled source→target list. This repairs C07’s hidden/overlaid geometry but does not claim a globally optimal graph layout. Joe’s clarity review is pending.

## Reproduce

The old servers on ports 8000 and 8002 were confirmed as belonging to `irexplorer` and terminated before edits. A new server is left at **http://127.0.0.1:8000/#/explore** and **http://127.0.0.1:8000/#/study**. From `irexplorer/`:

```sh
.venv/bin/python -m src.backend.api.server
```

The runner emits a pre-existing runpy import warning, then serves normally. In another terminal:

```sh
.venv/bin/python -m unittest discover -s tests -v
.venv/bin/python -c 'from pathlib import Path; from scripts.audit_e0 import main; main(Path("docs/evaluation-captures/e3-task-evidence.json"))'
node --check src/frontend/app.js
node --check src/frontend/source.js
node --check src/frontend/comparison.js
node --check src/frontend/preview.js
node --check scripts/capture_e3.mjs
git diff --check
```

The Browser skill was read; its required browser execution tool was not callable in this session. The repository’s isolated Chrome/CDP fallback used Node built-ins without installing dependencies. To repeat the browser checks on this Mac:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --no-first-run --no-default-browser-check --user-data-dir=/tmp/irexplorer-e3-checks --disable-background-networking --remote-debugging-port=9225 about:blank
```

Then run `node scripts/capture_e3.mjs` from `irexplorer/`. It targets only the isolated page on 9225 and the local preview on 8000. Close that temporary Chrome process after capture; keep the review server running. This session’s isolated browser was closed after verification.

## Boundaries and next review

T1’s real baseline/final IR remains inspectable; T2’s specific wasted operations are checked in actual IR as well as debug mappings; T3’s condition selects the recorded block and labelled destinations; T4’s actual self-loop is visible; T5’s approximate match and wider-span limitation remain reachable. The browser test assertions and researcher audit contain these private checks, not the static workspace. Summary counts describe correspondence records, not runtime speed or semantic equivalence. Quick-sort summaries include both functions and explicitly say “whole example”.

Physical keyboard, screen-reader, zoom, fuller forced-colour/contrast review, final study rehearsals and S1.8 remain E7 gates. Native automated key events do not substitute for Joe’s physical-keyboard review. API version stays v1.0.0; E3 is a synthetic preview with no frozen release. No E4 work, participant collection, instrument amendment, new dependency, Docker regeneration, deployment, commit or push occurred. D3–D5 and earlier instrument proposals remain pending. Review [the E3 handover](../../../Docs/evaluation/e3-review.md) before starting E4.
