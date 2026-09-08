# E5 amendment: CFG layout and routing (C31)

8 September 2026. Ready for Joe's visual review; E5 remains open.

Preview: http://127.0.0.1:8000/?revision=e5-routing-4#/study

The old renderer put every block in one column and ran forward/backward edges through numbered side lanes. Zoom changed its size but could not improve this shape. The renderer now uses directed layered layout based on the existing typed CFG, independently of pane width. Branches separate horizontally where the topology permits; joins and loops have routed polylines with destination arrowheads. Edge labels are horizontal. Hovering an edge or reaching it with Tab dims other edges, making its direction easier to follow; the accessible label and existing textual edge list preserve exact endpoints and condition labels. Block selection, cross-pane correspondence, and independent zoom remain available.

Dagre 1.1.5 is vendored locally with graphlib and its MIT licence. [Source and integrity](../../src/frontend/vendor/README.md). It performs presentation layout only, with no LLVM parsing, correspondence computation, network dependency, or model/artefact changes.

## Verification

[78 passing browser assertions and source hashes](e5-routing-after.json), including all 56 curated state/function combinations, unchanged node/edge counts, contained paths and block labels, horizontal labels, multiple branch columns, self-loop and arrowheads, keyboard tracing/selection, zoom persistence, task scroll reset, retained responses, and 1200/390 px fitting. No runtime exceptions. Reproduce with `node scripts/check_e5_routing.mjs`, local server on 8000 and isolated test Chrome on 9230. This extends the prior layout regression; historical capture scripts remain untouched.

65 backend tests pass, including served/versioned vendor assets. `scripts/build_e5_content.py --check` confirms all 60 fields and four original instrument hashes unchanged. JavaScript syntax and repository whitespace checks pass.

Inspected study captures: [desktop CFG](e5-routing-after-cfg.png), [1200 px](e5-routing-after-1200.png), [390 px](e5-routing-after-390.png). The layout is no longer a fixed source-order column. Some cyclic graphs remain tall and require vertical scrolling; crossings are still possible. This change does not claim a crossing-free or minimum-height layout. Fit width retains its existing scaling semantics; percentages still offer closer inspection.

Both logs and the E5 review pack are updated. Instruments, participant content/study versions, draft schema, task timing/answers and compiler artefacts are unchanged. E6 has not started. Stop at E5's review point.
