# Artefact-reviewed expected correspondences

These ten tables cover `score` and `binary_search` at mem2reg (0→1), instcombine
(1→2), simplifycfg (2→3), loop-rotate (6→7), and the separately recompiled
O3 state (12→13). They contain 353 expected correspondences and account for every
Function, BasicBlock, and Instruction in each pair exactly once at each
endpoint. Module and source-location nodes are outside correspondence coverage.

## Review method and limits

On 18 September 2026, Codex inspected the recorded `.ll` function bodies,
terminators, debug locations, and the documented/current matching evidence
tiers. Endpoint pairings and relation/confidence expectations were transcribed
explicitly and compared with the matcher. IR text, recorded source fields, and
file hashes were attached mechanically from ingestion; the tables were not
produced by serialising fresh or stored correspondence output. The labelled
CFG edge sets were transcribed from the terminators separately.

This is an AI-assisted manual artefact review. Independent human sign-off has
not occurred. The tables check the observable change story and the matcher’s
qualified identity claims; they do not prove semantic equivalence, identify
every possible semantic counterpart, or establish compiler intent.

`exact` describes correspondence evidence, and can accompany a `changed` or
`renamed` instruction. `approximate` source/position links remain qualified.
`unresolved` means an inspected identity could not be resolved: paired one-sided
removal/addition rows must not be read as proven semantic destruction/creation.
In particular, the source-only initial-hi-store→hi-phi link, the unresolved
`binary_search` moved `%add2`, rotated phis, and recompiled O3 controls are retained as
visible heuristic limitations. `score` loop-rotate is a genuine no-op. Line-zero
debug locations record no source line; a missing column on a positive source
line is recorded as column zero.

## Table format and assertions

Each UTF-8 TSV row records source/target state-scoped IDs, relation, confidence,
the recorded instruction text or node label, source location, and an explanatory
rationale. An empty endpoint denotes an addition/removal. Instruction text
omits only `!dbg`; other metadata references remain, matching the relation
policy. Source locations use `filename:line:column`; blank fields explicitly
denote no recorded location. All links here are one-to-one or one-sided.

`cases.json` pins both `.ll` paths and byte hashes, ordinals, state IDs,
step kind, full labelled CFG edge sets, the reviewed change story, and
summary claims. `tests/test_expected_correspondences.py` checks these records against
fresh ingestion/analysis and the model records consumed by the API. It
compares complete link sets without depending on link ordering or generated
evidence strings, and verifies summary claims and evidence references.

Run from the application root:

```sh
.venv/bin/python -m unittest discover -s tests -p test_expected_correspondences.py -v
```

Review these expectations against the `.ll` artefacts before changing them.
A failing matcher assertion requires investigation; copying matcher output into
the tables would remove their value as reviewed test data. Intentional compiler
or evidence-policy changes require a renewed artefact review, updated rationales
and hashes, and the full suite. These files are application test data and are
not included in the 138-file generated-artefact checksum.
