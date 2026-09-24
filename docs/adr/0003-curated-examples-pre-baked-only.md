# ADR 0003 — Curated examples are pre-baked only

**Status:** Accepted — 25 Sep 2026. Records the generation strategy the application has followed since [ADR 0001](0001-fastapi-stateless-curated-api.md); no runtime behaviour changes.

## Context

The original system design planned for two interchangeable ways of producing
a state: reading it from a cache, or invoking `clang`/`opt` on request.  The
pre-baked dataset was to be "the on-demand path, run early and cached", so
that live compiling could be switched on later without rework.

Only the offline path was built.  `bake.py` runs the pinned toolchain in a
staged snapshot, turns the compiler artefacts into model records (optimisation
timelines, source records and stored correspondences) and replaces the
committed tree in one step.  The running application reads nothing else.
There is no on-demand implementation behind a shared interface, and no
runtime code path invokes the toolchain.

## Decision

- The runtime reads only serialised model records, never raw IR, CFG or remark
  files.  `api/` loads records through the `load_prebaked_*` functions, uses
  `toolchain/curated` only to list the curated examples, and composes
  correspondences for non-adjacent spans in memory.
- Compiler artefacts are produced and turned into model records offline, by
  `bake.py`, under the pinned toolchain.  The committed tree is checked
  against `docs/curated-artefacts.sha256`.
- The curated examples are the only input.  There is no source submission and
  no runtime compiler invocation.
- Any future live compiling enters as a new adapter with its own entry point.
  It must not be added as a second mode of the curated loaders.  It can reuse
  the analysis and parsing modules that do not touch disk (`ingest/llvm_ir`,
  `analysis/compare`, `analysis/summary`, `analysis/cfg_diff`,
  `analysis/optimisations`, `analysis/report`), which take states and
  timelines rather than paths.

## Consequences

Every response is derived from a reproducible, checksummed snapshot, so what a
participant sees can be traced to a pinned compiler command.  The runtime
needs no toolchain, worker isolation or resource limits.

The design's "same code path" claim does not hold.  The curated loaders in
`ingest/curated.py` and `analysis/curated.py` are offline file readers, not
one of two interchangeable implementations.  A live adapter would need its
own input validation, isolated worker, resource bounds and controlled failures
before it could be enabled, as ADR 0001 already notes.
