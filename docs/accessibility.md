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


## E2 source coordination, 7 September 2026

Source uses native line buttons with file/line/text accessible names, pressed state, a native details disclosure, and a live status. Dashed gold debug-location outlines remain separate from existing correspondence selection; CFG source marks use dashed strokes with forced-colour support. Source and pane scroll operations stay inside their bounded viewers. The source summary retains file/line/column anchors when collapsed. All recorded matches remain highlighted, and missing mappings are explicit.

[E2 evidence](evaluation-captures/e2-source.md): 31 browser assertions pass, including native Enter selection, 390px bounds, reverse navigation, and synthetic task integration; four captures were visually inspected. Physical keyboard/Space, screen-reader, zoom, and broader media checks remain E7. E2 is ready for source-panel review; no broader conformance claim is made.


## E3 state controls and CFG readability, 7 September 2026

Both panes now have labelled native previous/next buttons, boundary disabling, and full wrapped selected-state descriptions associated with their native selectors. All 14 states remain reachable, with ordinal/no-op labels and an explicit teaching-chain versus separately compiled -O3 boundary. Code viewer headings reserve label space so desktop panes align. Comparison outcomes, general pass purpose, and selection confidence are separate; native evidence disclosures are bounded and locally scrollable.

CFG edges use separate outside lanes for forward/backward directions and visible boundary arrowheads; self-loops have non-zero curves. Node widths accommodate the complete block labels. An expandable text edge list presents the same source, target and branch label without requiring graph interpretation. Forced-colour rules explicitly style paths, arrowheads, labels and nodes. Larger graphs retain natural readable dimensions and local scrolling, rather than shrinking text to fit the whole graph.

[E3 evidence](evaluation-captures/e3-comparisons.md): 71 browser assertions pass, including native automated Tab/Enter/Space on the new buttons and IR/CFG controls, source-anchor retention, topology/endpoint checks, 390px overflow/bounds, media emulation, summary failure/recovery and task context. Six screenshots were visually inspected. C07’s rendering repair and C08’s label/layout changes are ready for Joe’s review. Physical keyboard, screen-reader, zoom, broader media/contrast and final S1.8 checks remain E7; this is not a full accessibility conformance claim. Earlier E0–E2 paragraphs describe historical evidence and pending states.

## E4 forms and recovery, 7 September 2026

Consent uses six initially unchecked native labelled checkboxes. Each survey question has a fieldset/legend; every input has a native label and described-by notes/errors. Radio groups use the instrument's complete scale labels. Not-applicable is a separate labelled row outside the five rating choices; clearing a selection returns it to unanswered. Conditional details are hidden from layout and accessibility when irrelevant. Validation identifies errors in text, sets `aria-invalid`, and focuses the first invalid control. Text areas show their limits, retain excessive text for correction, and render answers as text rather than HTML. Locked P13 stays readable.

Recovery/failed-save notices appear at the top of each study screen; memory-only continuation is explicit. Errors do not claim successful persistence or deletion. The route heading and progress remain labelled, with an independently usable direct workspace.

[E4 evidence](evaluation-captures/e4-forms.md): 78 browser assertions pass, including Chrome's accessibility-tree question/option names, native Space/arrow/Enter operation, labels/legends/notes/errors, and no page-wide overflow at 390px. Seven captures were visually inspected. Narrow scale choices stack with full labels. This verifies browser semantics, not spoken screen-reader output; physical keyboard/spoken screen-reader, zoom/media/contrast and the complete final journey remain E7 checks. E4 is ready for Joe's form/recovery review; E0–E3 paragraphs above preserve historical states.
