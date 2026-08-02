# Accessibility and scale check

This record closes S2.5 for the curated, pre-baked prototype. It covers the
browser presentation layer only; no live compiler or user-code path is
enabled.

## Scale and graceful degradation

- The browser requests IR and source for one selected state in parallel, then
  requests the CFG only for the selected function. It never invokes the
  toolchain at interaction time.
- Function selection is the overview. The IR view can then be limited to the
  selected block and filtered locally by opcode, value name, source location,
  or instruction text. The displayed result count states exactly how many
  blocks and instructions remain.
- The CFG starts as a selected-function overview. Its detail control retains
  the selected block plus only its direct predecessors and successors, with
  edges restricted to that neighbourhood.
- The exercised larger fixture is `quick_sort` at `-O0`: its `partition`
  function has 7 basic blocks and 93 instructions. The API test verifies both
  its function-scoped CFG and full structured IR response. The client-side
  detail controls bound what is rendered without altering that model data.

The model cost envelope remains the one recorded in
`../deliverables/5-system-plan/layer3-data-model.md` §8.4. The UI controls
avoid an additional whole-timeline or whole-program rendering path; they only
filter the currently selected function/state data already held by the view.

## Accessibility pass

| Check | Outcome |
|---|---|
| Keyboard operation | Native controls are focusable. IR lines and CFG blocks expose button roles and support Enter/Space; source lines are buttons; the stepper, scope controls, filter, and clear action use native controls. |
| Focus and navigation | A skip link targets the focusable main region. Visible 3px focus outlines apply to controls and CFG nodes. The filter result is a polite live region; state and selection changes use the existing status region. |
| Non-colour encoding | Selected IR blocks explicitly display “selected block”; controls expose `aria-current`/`aria-pressed`; no-op passes are dashed and labelled; mapped source lines show an arrow; exact/approximate/none mapping states include text labels. |
| Contrast | Calculated CSS foreground/background ratios: body text `#132238` on `#f6f8fb` 15.03:1; muted text 5.58:1; primary button text 7.27:1; warning text 10.69:1; error text 8.31:1. |
| User preferences | Reduced-motion settings remove animation/scroll effects. Forced-colours settings preserve visible borders and non-colour state cues. |
| Narrow screens | Existing single-column layout remains, and the display controls stack with full-width filtering below 700px. |

Automated checks cover the larger fixture, served accessibility controls, API
routes, JavaScript syntax, and CSS diff integrity. S3.4 adds rendered Chrome
captures and layout/media-preference checks in
`evaluation-captures/s3-4-walkthrough.md`. Its physical-keyboard row remains
explicitly outstanding because the host could not inject real keyboard input
into Chrome and did not expose a physical desktop display; complete that one
manual Tab/Enter pass before a public demonstration.
