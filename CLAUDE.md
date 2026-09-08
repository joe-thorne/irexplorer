# CLAUDE.md — irexplorer (implementation)

Implementation of the thesis prototype: compiles curated C/C++ via `clang`/`opt` and presents LLVM IR artefacts (textual diffs, CFG views, pass timeline, change summaries) for students and non-expert developers.

For thesis context, aims, and process, see `../CLAUDE.md`. Design basis: `../Docs/system-plan/` (system-design.md, layer3-data-model.md) and requirements in `../Docs/application_requirements.md`.

## Status

Phase 3 in progress (S2.1–S2.6 and S3.5 are complete; E0 baseline captures exist, while final browser/accessibility and S1.8 verification remain). Architecture: Option C — a browser JavaScript single-page front-end (`src/frontend/`, static HTML/CSS/JS assets) served by a local Python backend (`src/backend/`) that owns artefact generation, the internal model, comparison, and a `localhost` model-query API (collapsible to a hosted web app later). Build order, decisions, and rules: `../Docs/system-plan/implementation-plan.md`. Canonical generation environment: `docs/environment.md`.

Built and under green tests:

- **S0.1–S0.3** — Option C baseline, the pinned Docker LLVM 22.1.8 toolchain (`docs/environment.md`, `Dockerfile.toolchain`, `docker-compose.yml`, `scripts/smoke-toolchain.sh`), and the layered `src/backend/` package skeleton.
- **S1.1** — curated set (`score`, `binary_search`, `quick_sort`), the 12-step teaching pass chain, full `-g` debug info, and the exact `clang`/`opt` command templates.
- **S1.2** — toolchain wrapper (`toolchain/curated.py`) + pre-baked generator (`toolchain/generate_curated.py`); artefacts under `artefacts/curated/`; per-state `origin.command` resolvable from the manifest (`curated.origin_command`).
- **S1.3** — IR→`StateGraph` parser (`ingest/llvm_ir.py`) with within-state invariant validation (I1–I8), source-map and remark attachment, and controlled ingest failure.
- **S1.4** — immutable `OptimisationTimeline`/`PassStep` records with honest derived versus recompiled provenance, plain JSON-ready model serialisation that validates and rebuilds state indices on load, and endpoint/full curated timeline loading. S2.2 grows the offline cache to one full teaching-pass timeline per curated example. Canonical artefacts are protected by a checked-in aggregate SHA-256 snapshot verified in the test suite.
- **S1.5** — deterministic, coverage-complete correspondence overlays with exact/approximate confidence, audit evidence, and concise link-backed summaries; S2.2 persists only the adjacent overlays.
- **S1.6** — FastAPI/Pydantic read-only query API (`api/query.py`, `api/app.py`, `api/server.py`) over the pre-baked model records. Each request names its curated example; a thread-safe cache of immutable records is keyed by example id, so the browser owns all selection state and concurrent browsers cannot replace each other's chosen example. S3.5 trims the runtime surface to file loading, structured IR, function-scoped CFG, and adjacent or transiently composed counterpart queries.
- **S1.7** — static browser front-end (now with vendored Dagre for CFG presentation) (`frontend/index.html`, `style.css`, `app.js`) served by the local API service. It contains no compiler, parsing, matching, or artefact logic.
- **S2.1** — eager `valueFlow` def-use edges and derived indices, plus a deterministic hybrid matcher. Exact instruction links require unique structural, source, and value-flow agreement; source-anchored and positional links are approximate; inspected but unresolved candidates surface as explicit `none` links.
- **S2.2** — full 14-state teaching-pass timelines, 13 persisted adjacent overlays per example, identity/no-op detection, transient relational composition for wider spans, and a conservative recompiled-anchor matcher. Full records and overlays were re-baked through the existing offline path and checksum-gated.
- **S2.3** — source-aware coordinated exploration. The `sourceMap` model and ingestion coverage remain available, S3.5 removed the runtime source route and browser display; E2 restores them with verified canonical input and typed function-scoped mappings.
- **S2.4** — full-timeline correspondence summaries and per-`opt` YAML remark capture, attached by debug location to immutable `PassStep` records. S3.5 does not retain summary or remark presentation code.
- **S2.5** — accessible interaction, responsive display controls, and scoped-view evaluation. S3.5 removes the unused filtering and neighbourhood controls while retaining keyboard, non-colour, reduced-motion, and forced-colour support.
- **S2.6** — `docs/input-isolation.md` fixes the design-only gate for future user-supplied C: strict admission, a fresh no-network resource-bounded worker, sanitised controlled failures, ephemeral retention, and preconditions for activation. The current service has no source-analysis route, does not invoke a live toolchain, and remains curated/pre-baked by default; a localhost test locks that boundary.
- **S3.5** — direct two-panel comparison workspace. One curated file and, when needed, a shared function are selected above two independently configurable IR/CFG and state panes. Selecting an IR instruction or basic block follows the correspondence in either direction, highlights the target line or block, and states the adjacent pass/action, recompiled anchor, or composed-comparison limitation. The former guided timeline, learning tasks, source view, summaries, disclosures, filters, and server-side focus state are removed rather than retained as dormant code.

Next: review E5 in `../Docs/evaluation/e5-review.md` before E6. Joe reviewed E0–E4 with no amendments, including E3's source-loading fix. E5 adds the full local T0–T6 journey, participant-only task content and original response structures, fixed-order locking, prompt-limited workspace setup, monotonic active durations, and pause/hide/refresh recovery. The separate evaluation validator/content GET still collects no responses. Preview: `http://127.0.0.1:8000/?revision=e5-routing-4#/study` or `/#/explore`. Verification: 65 backend tests, 20 draft/timing checks, 89 browser assertions, and eight inspected captures; see `docs/evaluation-captures/e5-tasks.md`. Instrument v0.1, E0 mapping, model and canonical artefacts are unchanged. No original instrument correction was explicitly accepted; the task contract documents preview clarifications and release decisions. E6 owns submission/storage/export. Physical keyboard/spoken screen-reader, final accessibility and S1.8 remain E7. Live arbitrary input remains Phase 5 after the S2.6 activation gate.

Run the backend tests from this directory with the project virtual environment: `.venv/bin/python -m unittest discover -s tests -v`.

## Repo & submodule routing

- `irexplorer/` is a **git submodule** of the thesis repo, with its own remote: `https://github.com/joe-thorne/irexplorer.git`. It is a separate repository — code here is versioned in the irexplorer repo, while the parent thesis repo (`../`) only tracks a pinned commit pointer.
- **Workflow:** commit and push code changes from inside this directory (they go to the irexplorer repo). Then, in the parent repo, stage and commit the updated submodule pointer (`git add irexplorer && git commit`) so the thesis repo references the new commit.
- This submodule has **no nested submodules** of its own.
- Planning, writing, and process work belongs in the parent — use `../CLAUDE.md`, not this file.

## Conventions

Environment pin: canonical artefacts and tests are generated through Docker on Ubuntu 24.04 with LLVM/clang/opt 22.1.8 from the official Linux x86_64 release tarball; see `docs/environment.md`.

Local Python tooling: any Python tools/modules used outside Docker for implementation, scripts, tests, or backend work must run inside a virtual environment and be reproducible from a requirements file. Direct backend dependencies belong in `src/backend/requirements.txt`; deployment installs the fully resolved `src/backend/requirements.lock`. Do not install Python packages globally or rely on undeclared local packages. The toolchain container is LLVM-only and does not need Python.

Backend package layout mirrors the system layers:

- `src/backend/toolchain/` — Layer 2 canonical `clang`/`opt` invocation boundary.
- `src/backend/ingest/` — Layer 2 parsing compiler artefacts into model records.
- `src/backend/model/` — Layer 3 immutable internal model and serialisation.
- `src/backend/analysis/` — Layer 4 pure comparison and summaries.
- `src/backend/api/` — read-only query boundary for the browser frontend.
- `src/backend/evaluation/` — participant-only consent/survey/task definition and validation; response collection remains E6.

Spelling (R13): prose, docstrings, identifiers, paths, and user-facing strings use UK/Australian spelling — *artefact*, *optimisation*, *faithfulness*. The generated artefact tree is `artefacts/curated/` (constant `ARTEFACTS_ROOT`). The only retained US spellings are upstream LLVM tokens that cannot be changed: the `-fsave-optimization-record` flag and the `.opt.yaml` records it emits.

_Other conventions TBD as implementation begins — fill in run/build/test commands and exact generation flags._

## Engineering guidelines

Adapted from the Karpathy-skills `CLAUDE.md` (https://github.com/multica-ai/andrej-karpathy-skills). Bias toward caution over speed; use judgment on trivial tasks.

1. **Think before coding.** State assumptions explicitly; if uncertain, ask. If multiple interpretations exist, surface them rather than silently picking one. If a simpler approach exists, say so and push back when warranted. If something is unclear, stop and name it.
2. **Simplicity first.** Write the minimum code that solves the problem — nothing speculative. No unrequested features, abstractions for single-use code, "flexibility", or error handling for impossible cases. If 200 lines could be 50, rewrite it.
3. **Surgical changes.** Touch only what the request requires. Don't "improve", refactor, or reformat adjacent working code; match existing style. Remove only the imports/variables your own changes orphaned; flag pre-existing dead code rather than deleting it. Every changed line should trace to the request.
4. **Goal-driven execution.** Turn tasks into verifiable goals ("fix the bug" → "write a test that reproduces it, then make it pass"). For multi-step work, state a brief plan with a verification check per step, and loop until verified.

## AI disclosure (required — Joe's rule)

Every session that gives meaningful assistance **must** be logged in `../Docs/AI_reference.md` (the log lives in the parent thesis repo). Add the entry yourself or remind Joe before finishing. Format:

```
- DD MMM YY
    - [Category] What was done (Model name and version)
```

Similar work may be consolidated into one line, provided the real date (or date range) and model are preserved. **Categories** (one per entry): `Language Translation` · `Grammar/Style/Spelling` · `Topic Exploration` · `Research Question` · `Content Creation Visual` (formatting) · `Content Creation` (e.g. code, text) · `Feedback` · `Other`.


E3 source-loading amendment (7 Sep): versioned frontend assets and no-store preview static responses address the reproduced legacy-script/empty-C-panel failure. 59 backend tests and six cache-enabled recovery assertions pass. Retest at `http://127.0.0.1:8000/?revision=e3-source-fix-1#/explore`; Joe subsequently reviewed E3 with no amendments; E4 was subsequently reviewed with no amendments; E5 is now ready for review (see the current status above).


E5 layout amendment (8 Sep): task transitions explicitly reset the independent sidebar scroll. Compact CFGs fit their pane by default, with separate Actual size controls. The amendment passes 75 browser assertions, 11 focused API tests, and 20 draft/timing checks; four captures were inspected. E5 remains open for Joe's retest at `http://127.0.0.1:8000/?revision=e5-routing-4#/study`. See `docs/evaluation-captures/e5-layout-amendment.md`.


E5 C30 follow-up (8 Sep): Graph zoom now provides true Fit width and 50–150% choices; the earlier Fit/Actual pair could look identical for graphs already fitting their pane. Seventeen browser assertions and eleven focused API tests pass; two captures inspected. Current revision `e5-routing-4`; E5 remains open for retest.


E5 C31 (8 Sep): replaced the single-column CFG renderer with topology-based layered layout using pinned, locally served Dagre 1.1.5 (MIT). Branches separate spatially; edge labels are horizontal and hover/keyboard focus isolates a directed route. Pane width only scales the completed layout. See `docs/evaluation-captures/e5-routing-amendment.md`. E5 remains open for visual retest; E6 has not started.
