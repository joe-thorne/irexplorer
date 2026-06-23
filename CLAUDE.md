# CLAUDE.md — irexplorer (implementation)

Implementation of the thesis prototype: compiles curated C/C++ via `clang`/`opt` and presents LLVM IR artefacts (textual diffs, CFG views, pass timeline, change summaries) for students and non-expert developers.

For thesis context, aims, and process, see `../CLAUDE.md`. Design basis: `../deliverables/5-system-plan/` (system-design.md, layer3-data-model.md) and requirements in `../docs/application_requirements.md`.

## Status

Phase 1 underway. Architecture: Option C — a browser JavaScript single-page front-end (`src/frontend/`, static HTML/CSS/JS assets, not yet started) served by a local Python backend (`src/backend/`) that owns artefact generation, the internal model, comparison, and a `localhost` model-query API (collapsible to a hosted web app later). Build order, decisions, and rules: `../deliverables/5-system-plan/implementation-plan.md`. Canonical generation environment: `docs/environment.md`.

Built and under green tests:

- **S0.1–S0.3** — Option C baseline, the pinned Docker LLVM 22.1.8 toolchain (`docs/environment.md`, `Dockerfile.toolchain`, `docker-compose.yml`, `scripts/smoke-toolchain.sh`), and the layered `src/backend/` package skeleton.
- **S1.1** — curated set (`score`, `binary_search`, `quick_sort`), the 12-step teaching pass chain, full `-g` debug info, and the exact `clang`/`opt` command templates.
- **S1.2** — toolchain wrapper (`toolchain/curated.py`) + pre-baked generator (`toolchain/generate_curated.py`); artefacts under `artefacts/curated/`; per-state `origin.command` resolvable from the manifest (`curated.origin_command`).
- **S1.3** — IR→`StateGraph` parser (`ingest/llvm_ir.py`) with within-state invariant validation (I1–I8), source-map and remark attachment, and controlled ingest failure.

Next: S1.4 (model serialisation, timeline/`PassStep`, indices built once at load), S1.5 (two-state `Correspondence`), S1.6 (query API), S1.7 (front-end). Outstanding issues are tracked inline in the implementation plan.

Run the backend tests from this directory with the project virtual environment: `python -m unittest tests.test_ingest_llvm_ir tests.test_toolchain_curated`.

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
