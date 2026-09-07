# E2 source coordination evidence

7 September 2026 · **Ready for review.** Working-tree E2 changes over implementation revision `421a21931234e67904f6411e10e4a0bc313895c5`. [Machine-readable evidence](e2-browser-checks.json) records the five frontend file hashes, revision, timestamp, Chrome version, 31 passing assertions, requests, and zero runtime errors. No participant content or responses appear in the captures.

- [Score source and both IR states](e2-score-desktop.png)
- [Binary-search source, IR, and CFG](e2-binary-search-desktop.png)
- [Quick-sort partition at 390px](e2-quick-sort-narrow.png)
- [Source within the synthetic task](e2-task-desktop.png)

All four captures were visually inspected. Desktop viewport: 1440×1000; narrow: 390×844. Full-page captures retain the locally bounded source and code viewers. Source height is capped at 240px desktop and 180px narrow; source highlights use a dashed outline as well as colour. All matches remain available through local scrolling. The existing C07 CFG defects are visible and remain assigned to E3.

## Reproduce

From `irexplorer/`, start the server (8000 was occupied in this session):

```sh
.venv/bin/python -c 'from src.backend.api.server import run_server; run_server(port=8002)'
```

Start an isolated Chrome profile in another terminal:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --remote-debugging-port=9224 --user-data-dir=/tmp/irexplorer-e2-checks about:blank
```

Then, from `irexplorer/`:

```sh
node scripts/capture_e2.mjs
.venv/bin/python -m unittest discover -s tests -v
node --check src/frontend/app.js
node --check src/frontend/source.js
node --check src/frontend/preview.js
node --check scripts/capture_e2.mjs
git diff --check
```

The script uses Node built-ins, disables caching, and starts with a fresh document to isolate test-only delayed/failing network responses. It targets only this local test tab. Browser runtime discovery returned no browsers; no in-app-browser verification is claimed. The local server/Chrome required sandbox escalation; both were permitted.

## Results and limits

[55 backend tests pass](e2-tests.txt), including all-source checksum verification and exact function/containment agreement with recorded mappings across 42 states. Existing immutable-model and aggregate artefact checksum tests pass; digest remains `5df7d29081f47cedc5514b971e96f62b4ccdc67af3ef126bfd968f0e6cfa2b7f`. This is not a fresh Docker regeneration.

31 browser assertions cover score source selection through baseline, mem2reg, instcombine, licm, final_cleanup, and separate O3; all early matches and honest absence; same-state IR/CFG; reverse order; CFG-to-source and unmapped instruction; binary-search loop test; both quick-sort functions; collapse labels; narrow bounds; native Enter; delayed state/example responses; mapping-error recovery; and synthetic-task integration. Runtime errors: zero. Browser network requests: GET only. The E1 harness's non-preview source assertion was updated for the now-functional source panel; historical E1 captures/results are retained and were not regenerated.

Physical keyboard/Space, screen-reader, wider media/zoom cases, complete study behaviour, and S1.8 remain E7 verification. Source is available independently of study mode. No instruments, compiler artefacts, response storage, or methodological decisions changed. See the [parent review pack](../../../Docs/evaluation/e2-review.md) for coverage gaps, review actions, and next prompt.
