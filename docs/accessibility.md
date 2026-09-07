# Accessibility and scale check

This record covers the current S3.5 two-panel interface for the curated,
pre-baked prototype. It supersedes the earlier S2.5 description of source,
filter, neighbourhood, stepper, and clear controls, which are no longer part
of the lean workspace. No live compiler or user-code path is enabled.

## Scale and graceful degradation

- The browser requests structured IR for the two selected states in parallel
  and requests a CFG only when that pane is configured to show one. It never
  invokes the toolchain at interaction time.
- A shared function selector bounds both panes to one comparable function.
  Each pane then renders either that function's complete IR or its
  function-scoped CFG inside a scrolling viewer.
- The exercised larger fixture is `quick_sort` at `-O0`: its `partition`
  function has 7 basic blocks and 93 instructions. The API test verifies both
  its function-scoped CFG and full structured IR response.

The model cost envelope remains the one recorded in
`../../Docs/system-plan/layer3-data-model.md` §8.4. The interface avoids
an additional whole-timeline or whole-program rendering path: it holds two
selected state responses and renders one shared function per pane. Below
900px, the panels stack into one column.

## Accessibility pass

| Check | Outcome |
|---|---|
| Keyboard operation | File, function, state, and view selectors are native controls. IR block headings are buttons; IR instructions and CFG blocks expose button roles and support Enter/Space. |
| Focus and navigation | A skip link targets the comparison workspace. Visible 3px focus outlines apply to native controls, IR instructions, and CFG blocks. Loading and selection changes are announced through polite status regions. |
| Semantics and non-colour encoding | IR and CFG selections expose `aria-pressed`; the status text identifies the relation, confidence, absence, or unresolved result. No-op states are labelled “no recorded change”. CFG blocks sit in a labelled `group`, preserving their interactive button roles; linked CFG blocks also use a dashed outline. |
| Contrast | Calculated CSS foreground/background ratios: body text `#132238` on `#f6f8fb` 15.03:1; muted text 5.58:1; header eyebrow `#67e8f9` on `#102a43` 10.10:1; line numbers 4.55:1; instruction tokens 6.04:1; number tokens 4.80:1; unresolved text 9.37:1; error text 8.15:1. |
| User preferences | Reduced-motion settings remove animation/scroll effects. Forced-colours settings preserve visible borders and non-colour state cues. |
| Narrow screens | The two panels form one column below 900px. Header and viewer controls stack, with full-width selectors below 700px. |

Automated checks cover the larger fixture, served interaction semantics,
focus and contrast rules, API routes, JavaScript syntax, and CSS diff
integrity. `evaluation-captures/s3-4-walkthrough.md` records the earlier
rendered Chrome checks, but it predates S3.5. Complete a fresh physical
Tab/Enter/Space walkthrough of the current workspace before a public
demonstration.

## E0 baseline, 7 September 2026

Current [desktop/narrow captures and observations](evaluation-captures/e0-baseline.md) now exist. Headless browser checks confirm T3 selected-block coordination and T5 approximate-confidence text, with no page-wide horizontal overflow at 390px. They also expose hidden arrowheads, overlapping edges/labels, and a zero-length self-loop in the current CFG renderer (C07, E3). These affect T3/T4 interpretation and must be fixed before pilot use. Long stacked panes remain C08. This is baseline evidence only; physical keyboard, screen-reader, media preferences, zoom, and complete E7 checks remain outstanding.


## E1 layout and navigation, 7 September 2026

The preview route shell focuses the new screen heading on navigation, updates the document title, labels progress with `aria-current="step"`, and uses native labelled inputs, buttons, links, and disclosures. In-page skip/comparison links move focus without changing the study route. Synthetic response placeholders are read-only and labelled. Desktop task content is bounded and scrollable; narrow task details collapse initially on route entry and can expand, while the goal and primary action remain visible outside the disclosure. Each narrow viewer is bounded to 320px with local scrolling.

[Current evidence](evaluation-captures/e1-preview.md): 33 browser assertions, including native automated Tab/Enter events, heading focus, narrow disclosure expansion, and no page-wide overflow at 390px. All seven screenshots were visually inspected. This was isolated headless Chrome because the in-app runtime had no browser available. Physical keyboard, screen-reader, zoom/media variations, and complete S1.8 remain E7 checks; no broader accessibility conformance is claimed. C07 CFG defects remain E3 work. E1 layout is ready for Joe's review.
