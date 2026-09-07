# E1 synthetic journey and layout evidence

**7 September 2026 · Ready for review.** E1 frontend working-tree changes over implementation revision `cb794d335476643eeeb1cab5ff0f07babb6647ed`. The exact four frontend file hashes, capture timestamp, browser version, 33 passing assertions, pane dimensions, network requests, and empty runtime-error list are in [e1-browser-checks.json](e1-browser-checks.json). This is current E1 evidence; the E0 captures remain historical baseline evidence.

## Captures

All seven were visually inspected; text is readable, task/source placeholders are explicit, and no page-wide overflow was measured at 390px. Only curated compiler artefacts and fixed synthetic placeholder text are shown.

- [Information, desktop](e1-information-desktop.png)
- [Pre-survey, desktop](e1-pre-desktop.png)
- [Task with live IR/CFG, desktop](e1-task-desktop.png)
- [Task, narrow full page](e1-task-narrow.png)
- [Post-survey, narrow](e1-post-narrow.png)
- [Simulated receipt, narrow](e1-receipt-narrow.png)
- [Independent exploration, desktop](e1-explore-desktop.png)

Desktop: 1440×1000. Narrow viewport: 390×844. Pane contents have local scrolling (maximum 512px desktop, 320px narrow). Narrow task instructions initially collapse on route entry and can expand; the goal and continue action remain outside that disclosure. The task sidebar scrolls independently on desktop. Source initially opens and can collapse, without implying actual source data or mapping.

## Reproduce

From `irexplorer/`, start `.venv/bin/python -m src.backend.api.server`, then open `http://127.0.0.1:8000/#/study`. The existing server was verified during E1. For automated captures use Node 22+ and an isolated local headless Chrome:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --remote-debugging-port=9223 --user-data-dir=/tmp/irexplorer-e1-chrome about:blank
```

In another terminal, from `irexplorer/`:

```sh
node scripts/capture_e1.mjs
.venv/bin/python -m unittest discover -s tests -v
node --check src/frontend/app.js
node --check src/frontend/preview.js
node --check scripts/capture_e1.mjs
git diff --check
```

The capture script deliberately navigates a local test tab; use only the isolated Chrome profile above. No new packages are required. Browser-plugin bootstrap/discovery returned no browsers; CDP was the fallback, not an in-app-browser verification claim.

## Results and scope

[Backend transcript](e1-tests.txt): **52 tests pass**. Canonical aggregate checksum remains `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`; the suite checks it, with no fresh Docker generation. Instrument files and `app.js` are unchanged. Instrument version remains draft v0.1, E0 mapping remains `e0-draft-1`, and the preview iteration is labelled E1; no release version was frozen.

Browser checks: **33 assertions pass**, including heading focus, native keyboard Tab/Enter events, full route sequence, Back/Forward, deep-link gating, refresh reset, decline/stop/reset, narrow disclosure and overflow, live curated selection/CFG, 14 state options, direct exploration, empty browser storage, non-preview guard, and absence of write requests. The simulated receipt sends nothing; no response store or submission endpoint exists. A test-only pre-script mode override exercises the non-preview guard. Server-controlled preview/pilot/live configuration remains E6 work.

Known C07 CFG defects remain E3 work. Physical keyboard/screen-reader verification, wider accessibility cases, and S1.8 remain E7. These captures verify E1 layout and synthetic navigation, not real consent, full instruments, task timing, draft recovery, source coordination, submission durability, or release readiness. Parent handover: [E1 review](../../../Docs/evaluation/e1-review.md).
