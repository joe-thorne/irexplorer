# CLAUDE.md — irexplorer (implementation)

Implementation of the thesis prototype: compiles curated C/C++ via `clang`/`opt` and presents LLVM IR artefacts (textual diffs, CFG views, pass timeline, change summaries) for students and non-expert developers.

For thesis context, aims, and process, see `../CLAUDE.md`. Design basis: `../deliverables/5-system-plan/` (system-design.md, layer3-data-model.md) and requirements in `../docs/application_requirements.md`.

## Status

Phase 3 in progress (S2.1–S2.6 and S3.1–S3.2 complete; the S1.8 verification gate remains to be documented). Architecture: Option C — a browser JavaScript single-page front-end (`src/frontend/`, static HTML/CSS/JS assets) served by a local Python backend (`src/backend/`) that owns artefact generation, the internal model, comparison, and a `localhost` model-query API (collapsible to a hosted web app later). Build order, decisions, and rules: `../deliverables/5-system-plan/implementation-plan.md`. Canonical generation environment: `docs/environment.md`.

Built and under green tests:

- **S0.1–S0.3** — Option C baseline, the pinned Docker LLVM 22.1.8 toolchain (`docs/environment.md`, `Dockerfile.toolchain`, `docker-compose.yml`, `scripts/smoke-toolchain.sh`), and the layered `src/backend/` package skeleton.
- **S1.1** — curated set (`score`, `binary_search`, `quick_sort`), the 12-step teaching pass chain, full `-g` debug info, and the exact `clang`/`opt` command templates.
- **S1.2** — toolchain wrapper (`toolchain/curated.py`) + pre-baked generator (`toolchain/generate_curated.py`); artefacts under `artefacts/curated/`; per-state `origin.command` resolvable from the manifest (`curated.origin_command`).
- **S1.3** — IR→`StateGraph` parser (`ingest/llvm_ir.py`) with within-state invariant validation (I1–I8), source-map and remark attachment, and controlled ingest failure.
- **S1.4** — immutable `OptimisationTimeline`/`PassStep` records with honest derived versus recompiled provenance, plain JSON-ready model serialisation that validates and rebuilds state indices on load, and endpoint/full curated timeline loading. S2.2 grows the offline cache to one full teaching-pass timeline per curated example. Canonical artefacts are protected by a checked-in aggregate SHA-256 snapshot verified in the test suite.
- **S1.5** — deterministic, coverage-complete correspondence overlays with exact/approximate confidence, audit evidence, and concise link-backed summaries; S2.2 persists only the adjacent overlays.
- **S1.6** — read-only `localhost` query API (`api/query.py`, `api/server.py`) over the pre-baked model records, with IR/CFG/navigation/counterpart/summary queries and in-session focus retention. S2.2 exposes the full timeline and transient composed comparisons.
- **S1.7** — dependency-free static browser front-end (`frontend/index.html`, `style.css`, `app.js`) served by the local API service. It loads curated comparisons, switches optimisation state, renders structured and syntax-highlighted IR with debug metadata hidden by default, navigates functions and basic blocks, renders a labelled API-derived SVG CFG, presents the recompiled-anchor summary, and surfaces controlled request failures. It contains no compiler, parsing, matching, or artefact logic.
- **S2.1** — eager `valueFlow` def-use edges and derived indices, plus a deterministic hybrid matcher. Exact instruction links require unique structural, source, and value-flow agreement; source-anchored and positional links are approximate; inspected but unresolved candidates surface as explicit `none` links.
- **S2.2** — full 14-state teaching-pass timelines, 13 persisted adjacent overlays per example, identity/no-op detection, transient relational composition for wider spans, and a conservative recompiled-anchor matcher. The browser shows no-op states compactly, separates the `-O3` anchor, and can request a composed baseline comparison. Full records and overlays were re-baked through the existing offline path and checksum-gated.
- **S2.3** — source-aware coordinated exploration. The API exposes curated source lines annotated only from `sourceMap` edges; the browser synchronises IR instruction, CFG block, source-line, and cross-state counterpart selection, including exact/approximate/none/absent status cues. It contains no compiler, parsing, matching, or artefact logic.
- **S2.4** — sequential previous/next and scrubber controls drive the complete pass timeline, retaining the anchor break and collapsing no-op passes until expanded. Correspondence summaries now distinguish additions, removals, relation classes, CFG stability, and uncertainty; every claim expands into its supporting link records. The generator captures a YAML remark record for every derived `opt` state; records attach by debug location to target instructions and are preserved on the corresponding immutable `PassStep` for summary evidence. The fully re-baked snapshot is checksum-gated.
- **S2.5** — function-selected views now add local IR filtering and a selected-block detail scope, while the CFG can collapse to the selected block's direct neighbourhood. The UI exposes result counts, keyboard semantics, non-colour selection cues, reduced-motion and forced-colour support, and responsive display controls. `docs/accessibility.md` records the scale fixture, contrast audit, and verification boundary.
- **S2.6** — `docs/input-isolation.md` fixes the design-only gate for future user-supplied C: strict admission, a fresh no-network resource-bounded worker, sanitised controlled failures, ephemeral retention, and preconditions for activation. The current service has no source-analysis route, does not invoke a live toolchain, and remains curated/pre-baked by default; a localhost test locks that boundary.
- **S3.1** — the learner-facing front end now has one labelled marker timeline with previous/next navigation, showing baseline and changing states by default while retaining no-op passes behind a full-pipeline disclosure. It leads with up to three link-backed outcomes and a clearly general pass role; full generated summaries and their evidence remain on demand. The `-O3` anchor remains marked and honestly framed as separately compiled output.
- **S3.2** — the default workspace centres selected-block IR with explicit before/after state context, a recorded source snippet, and a compact API-derived CFG result. Structural changes open the full artefact disclosure; unchanged CFGs do not compete by default. The full artefact retains navigation, display controls, debug metadata, full source/CFG, evidence, raw remarks, and baseline comparison; a selection inspector retains confidence-labelled source/CFG/counterpart navigation. The learner-facing controlled-failure button is removed, while its API route regression remains.

Next: S3.3 guided prompts, then S3.4 browser walkthroughs. S1.8 MVP verification documentation also remains outstanding; live arbitrary input is Phase 5 only after the S2.6 activation gate.

Run the backend tests from this directory with the project virtual environment: `.venv/bin/python -m unittest discover -s tests -v`.

## Repo & submodule routing

- `irexplorer/` is a **git submodule** of the thesis repo, with its own remote: `https://github.com/joe-thorne/irexplorer.git`. It is a separate repository — code here is versioned in the irexplorer repo, while the parent thesis repo (`../`) only tracks a pinned commit pointer.
- **Workflow:** commit and push code changes from inside this directory (they go to the irexplorer repo). Then, in the parent repo, stage and commit the updated submodule pointer (`git add irexplorer && git commit`) so the thesis repo references the new commit.
- This submodule has **no nested submodules** of its own.
- Planning, writing, and process work belongs in the parent — use `../CLAUDE.md`, not this file.

## Conventions

Environment pin: canonical artefacts and tests are generated through Docker on Ubuntu 24.04 with LLVM/clang/opt 22.1.8 from the official Linux x86_64 release tarball; see `docs/environment.md`.

Local Python tooling: any Python tools/modules used outside Docker for implementation, scripts, tests, or backend work must run inside a virtual environment and be reproducible from a requirements file. Backend dependencies belong in `src/backend/requirements.txt`; do not install Python packages globally or rely on undeclared local packages. The toolchain container is LLVM-only and does not need Python.

Backend package layout mirrors the system layers:

- `src/backend/toolchain/` — Layer 2 canonical `clang`/`opt` invocation boundary.
- `src/backend/ingest/` — Layer 2 parsing compiler artefacts into model records.
- `src/backend/model/` — Layer 3 immutable internal model and serialisation.
- `src/backend/analysis/` — Layer 4 pure comparison and summaries.
- `src/backend/api/` — read-only query boundary for the browser frontend.

Spelling (R13): prose, docstrings, identifiers, paths, and user-facing strings use UK/Australian spelling — *artefact*, *optimisation*, *faithfulness*. The generated artefact tree is `artefacts/curated/` (constant `ARTEFACTS_ROOT`). The only retained US spellings are upstream LLVM tokens that cannot be changed: the `-fsave-optimization-record` flag and the `.opt.yaml` records it emits.

_Other conventions TBD as implementation begins — fill in run/build/test commands and exact generation flags._

## Engineering guidelines

Adapted from the Karpathy-skills `CLAUDE.md` (https://github.com/multica-ai/andrej-karpathy-skills). Bias toward caution over speed; use judgment on trivial tasks.

1. **Think before coding.** State assumptions explicitly; if uncertain, ask. If multiple interpretations exist, surface them rather than silently picking one. If a simpler approach exists, say so and push back when warranted. If something is unclear, stop and name it.
2. **Simplicity first.** Write the minimum code that solves the problem — nothing speculative. No unrequested features, abstractions for single-use code, "flexibility", or error handling for impossible cases. If 200 lines could be 50, rewrite it.
3. **Surgical changes.** Touch only what the request requires. Don't "improve", refactor, or reformat adjacent working code; match existing style. Remove only the imports/variables your own changes orphaned; flag pre-existing dead code rather than deleting it. Every changed line should trace to the request.
4. **Goal-driven execution.** Turn tasks into verifiable goals ("fix the bug" → "write a test that reproduces it, then make it pass"). For multi-step work, state a brief plan with a verification check per step, and loop until verified.

## AI disclosure (required — Joe's rule)

Every session that gives meaningful assistance **must** be logged in `../docs/AI_reference.md` (the log lives in the parent thesis repo). Add the entry yourself or remind Joe before finishing. Format:

```
- DD MMM YY
    - [Category] What was done (Model name and version)
```

Similar work may be consolidated into one line, provided the real date (or date range) and model are preserved. **Categories** (one per entry): `Language Translation` · `Grammar/Style/Spelling` · `Topic Exploration` · `Research Question` · `Content Creation Visual` (formatting) · `Content Creation` (e.g. code, text) · `Feedback` · `Other`.
