# E5 amendment: CFG zoom controls

8 September 2026 · **Ready for Joe's retest; E5 remains open.** Current preview: **http://127.0.0.1:8000/?revision=e5-zoom-3#/study**. Refresh to load the revised assets; compatible E5 drafts are retained.

## Reproduction and fix (C30)

Joe reported that the CFG width dropdown appeared to do nothing. The previous Fit width option only applied a maximum-width constraint, leaving the SVG's natural width in place. A graph already smaller than its pane therefore looked identical under Fit width and Actual size. The [baseline check](e5-zoom-before.json) reproduces this with `score`: both options render at **340 px**. The earlier C29 regression exercised an oversized graph and did not test this smaller-graph case.

The control is now labelled **Graph zoom**. Fit width sets the actual SVG width to the available pane width and follows resizing; **50%, 75%, 100% (actual size), 125%, and 150%** set explicit drawing scales. Percentages refer to the graph's unscaled drawing size. In the same `score` reproduction, Fit width now renders at approximately **638 px**, while 100% remains **340 px**. Each pane retains its independent choice across state changes and selections. Large zooms intentionally use the existing viewer scrollbars.

## Verification

**17 browser assertions pass**, including all percentage scales, small-graph fit versus actual size, responsive fit, independent study panes, retained task answers, state-change/keyboard-selection persistence, unchanged T4 topology, and fit without page/viewer overflow at 390 px. [Results and current frontend hashes](e5-zoom-after.json). Reproduce using `node scripts/check_e5_zoom.mjs` against the local server on 8000 and isolated Chrome on 9229; add `--baseline` only when checking the earlier implementation.

**11 focused API tests pass** ([output](e5-zoom-api-tests.txt)), including current versioned assets. The 60-field participant-content/original-instrument hash audit, JavaScript syntax, and both repository whitespace checks pass. Two screenshots were visually inspected: [75%](e5-zoom-after-75.png) and [150%](e5-zoom-after-150.png). There were no browser runtime exceptions. The prior C28/C29 geometry and scroll evidence remains historical; this amendment changes sizing semantics only.

Verification used a separate temporary Chrome profile at `/private/tmp/irexplorer-e5-zoom-chrome`, closed afterward. The preview server remains running. Assets are `e5-zoom-3`; instrument/content/study/draft versions and timing, task responses, graph topology, and compiler artefacts are unchanged. Both logs are updated. No E6 work, collection, deployment, commit, push, or artefact regeneration occurred.

For review, select 50% or 75% to make a graph smaller, 125% or 150% to enlarge it, and Fit width to fill its pane. E5 remains open for retest.
