# E5 amendment: task scrolling and CFG sizing

8 September 2026 · **Ready for Joe's retest; E5 remains open.** This addresses Joe's two reported layout problems. Preview: **http://127.0.0.1:8000/?revision=e5-layout-2#/study**. The existing local server remains running; refresh the page to load the amended assets. Compatible E5 drafts recover normally, with unchanged study/content/schema versions.

**Later C30 correction:** [Graph zoom amendment](e5-zoom-amendment.md) replaces the former shrink-only Fit width behaviour described below with true width fitting and explicit percentage scales. C28 remains unchanged.

## Task panel reset (C28)

The study renderer reset the page scroll and focused the new heading, but did not explicitly reset the independently scrolling desktop sidebar. The ordinary isolated Chrome replay scrolled to the heading automatically, so it did not reproduce Joe's exact browser behaviour. A controlled replay that retained focus while suppressing its automatic scrolling exposed that dependency: after T1 continued to T2, the sidebar retained **1,150 px** of scroll and hid the new heading. See [ordinary baseline](e5-layout-before.json), [controlled baseline](e5-layout-before-focus.json), and [controlled before capture](e5-layout-before-focus-task.png).

Route rendering now focuses the heading without implicit scrolling, sets the study panel's own vertical/horizontal scroll to zero, and resets the page. Continue, Skip, and read-only revisits therefore start at the task heading independently of browser focus behaviour. Response-entry and workspace interactions do not rerender the study route or reset its scroll. [After capture](e5-layout-after-task.png) and [regression results](e5-layout-after.json) show a zero sidebar scroll position under the same controlled condition. The normal E5 task progression/response locks are preserved.

## Compact fitted CFGs (C29)

At 1440 px page width with the task sidebar, the T4 right graph was **622 px wide** in a viewer approximately **504 px wide**; it was **1,240 px tall**. This reproduced the clipped graph and long vertical paths in the [before capture](e5-layout-before-cfg.png).

The layout now uses a 96 px row gap instead of 150 px, 20 px edge lanes instead of 24 px, and a smaller minimum block width while continuing to size long labels. Labels are slightly larger in the unscaled drawing. Each SVG defaults to **Fit width**, which responds to the available pane without enlarging a small graph. A labelled **Graph size → Actual size** option permits closer inspection and horizontal scrolling when useful; each pane retains its own choice through selection/state rendering.

In the same T4 setup, the right graph now fits at about **486 px × 670 px**; the left graph is **440 px × 712 px**. Topology, source/cross-state coordination, independent panes, arrowheads, self-loops, and the text edge disclosure remain intact. The layout also applies in direct exploration. Large graphs may have small labels when fitted to very narrow panes; Actual size preserves a readable inspection option.

## Verification and captures

- **75 browser assertions pass:** [results and current frontend hashes](e5-layout-after.json), reproduced with `node scripts/check_e5_layout.mjs --prevent-focus-scroll` against isolated Chrome on 9228 and the preview on 8000. The controlled baseline uses `--baseline --prevent-focus-scroll`; ordinary baseline uses `--baseline`.
- Coverage includes Continue/Skip/revisit scroll resets, retained answers/locks, T4 node/edge counts, non-zero self-loop and arrow paths, independent fit/actual sizing, native Enter selection with size preservation, responsive fit at 1440/1200/390 px, and all **56 curated state/function combinations** across the 42 recorded states. Each combination checks that block labels fit their rectangles and nodes/edge paths remain within the SVG bounds. No browser runtime exceptions occurred.
- **11 focused API tests pass:** [output](e5-layout-api-tests.txt), including the updated versioned static asset expectations. **20 draft/timing checks** and the 60-field content/original-instrument hash audit also pass. JavaScript syntax and both repository whitespace checks pass. The earlier E5 full backend/browser results remain historical evidence; no compiler/model code was changed in this amendment.
- Four final screenshots were visually inspected: [task heading](e5-layout-after-task.png), [desktop T4 graphs](e5-layout-after-cfg.png), [1200 px study layout](e5-layout-after-1200.png), and [390 px graph](e5-layout-after-390.png).

The browser plugin still reported no available browser. Checks used a separate temporary Chrome profile under `/private/tmp/irexplorer-e5-layout-chrome`, closed after verification. No user browser profile was read or changed. Original instruments, response/timing semantics, and release gates are unchanged. Asset revision is now `e5-layout-2`; API remains v1.0.0, content `e5-preview-1`, study `e5-synthetic-1`, and draft schema 2. No E6 implementation, response collection, deployment, commit, push, or artefact regeneration occurred.

For review: continue from a scrolled response form and check the next task's heading is visible; compare T4's two graphs with the task sidebar present; try Fit width and Actual size at your normal browser width. E5 remains at its review point.
