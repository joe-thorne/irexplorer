# S3.4 browser walkthrough and capture record

**Run:** 30 Jul 2026, local Google Chrome 150.0.7871.187, serving the
read-only application at `127.0.0.1:8000`. The application used only its
pre-baked curated records. Desktop capture viewport was 1440 × 1100; the
narrow-screen check used 600 × 900.

The machine-readable observations and capture checksums are in
`s3-4-browser-checks.json`. The captures below are rendered browser output,
not reconstructed illustrations.

| Capture | State and evidence | Observation |
|---|---|---|
| `score-simplifycfg-story.png` | `score`, `instcombine` ordinal 2 → `simplifycfg` ordinal 3; adjacent correspondence links and API CFG records | The story reports three removed blocks, four removed instructions, and one addition. The structural result states 4 → 1 blocks and 4 → 0 edges. The contextual task is “Explain the block collapse”. |
| `binary-search-simplifycfg-cfg.png` | `binary_search`, `instcombine` ordinal 2 → `simplifycfg` ordinal 3; adjacent correspondence links and API CFG records | The story records four removed blocks, six removed instructions, and two additions. The rendered CFG contains seven nodes and the structural result states 11 → 7 blocks and 14 → 9 edges. |

## Walkthrough outcomes

| Scenario | Result |
|---|---|
| Default `score` screen | Passed. It presents the pass story, one learning task, compact six-marker guided timeline, and closed pipeline, artefact, and selection disclosures. |
| Source-to-IR task | Passed. Opening the first `score` task moved to `mem2reg`; stepping to `instcombine` opened the observation after inspection and the selection inspector. |
| No-op and anchor framing | Passed. Expanding the full pipeline rendered eight no-op markers; the `O3` state retained the anchor marker and explicitly stated that the comparison is not a single pass effect. |
| `score` CFG change | Passed. `simplifycfg` opened the full artefact and reported 4 → 1 blocks and 4 → 0 edges. A browser observation led to the contextual-task adjustment, so its matching CFG task now replaces the earlier source task at this state. |
| `binary_search` CFG change | Passed. The full artefact exposed the seven-node CFG and its API-derived 11 → 7 block, 14 → 9 edge result. |
| `quick_sort` scoped navigation | Passed. Its task selected `partition`, opened the full artefact, and showed the seven-block function-scoped CFG. |
| Narrow layout | Passed. At 600 px, the header and state panel use a column layout and the timeline controls use two columns. |
| Reduced motion and forced colours | Passed. Browser media emulation matched both preferences; the selected CFG remained dashed and non-colour state cues remained visible. |
| Physical keyboard-only walkthrough | Outstanding. The live page exposes and retains the tested keyboard handlers, but this host's Chrome debugging input channel did not return after key injection and macOS denied the fallback System Events keystroke (`error 1002`). No physical desktop display was available. Perform one manual Tab/Enter pass before public demonstration; do not treat this row as completed evidence. |

The controlled-failure and API boundaries remain covered by the localhost test
suite. This record intentionally distinguishes the completed browser capture
and media/layout checks from the remaining physical-keyboard confirmation.
