# irexplorer

A system for exploring code transformations: curated LLVM IR and CFG states in two independently configurable browser panes.

From this directory:

```sh
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000/** and choose a curated file. If needed, create `.venv` with `python3 -m venv .venv` and install with `.venv/bin/python -m pip install -r src/backend/requirements.lock`.

**E6 ready for review (8 September 2026).** E5 is complete with Joe’s recorded follow-ups C28–C31 preserved. E6 is ready for review: final-only synthetic submission, durable SQLite receipts and idempotent retries, private JSON/CSV/codebook export, backup/restore, and retention commands. Preview: `http://127.0.0.1:8006/?revision=e6-submission-1#/study`. All four original instruments, E5 participant content/draft schema, task timing, CFG amendments, and canonical artefacts are preserved. Verification: 73 backend tests, 20 draft/timing checks, 10 submission checks, and 43 browser assertions. Pilot/live collection is disabled; E7–E8 have not started. See [E6 operations](docs/evaluation-operations.md) and [verification](docs/evaluation-captures/e6-submission.md). Use invented answers only. Earlier amendment entries below are historical.


In the parent thesis checkout, see [E0 review](../Docs/evaluation/e0-review.md) and the [E0–E8 implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md). Read [CLAUDE.md](CLAUDE.md) before implementation. Run `.venv/bin/python scripts/audit_e0.py` for the reproducible researcher audit (requires parent draft instruments), and `.venv/bin/python -m unittest discover -s tests -v` for the backend suite.


E3 source-loading amendment (7 Sep): versioned frontend assets and no-store preview static responses address the reproduced legacy-script/empty-C-panel failure. 59 backend tests and six cache-enabled recovery assertions pass. Retest at `http://127.0.0.1:8000/?revision=e3-source-fix-1#/explore`; Joe subsequently reviewed E3 with no amendments; E4 was subsequently reviewed with no amendments; E5 is now ready for review.


E5 layout amendment (8 Sep): task transitions explicitly reset the independent sidebar scroll. Compact CFGs fit their pane by default, with separate Actual size controls. The amendment passes 75 browser assertions, 11 focused API tests, and 20 draft/timing checks; four captures were inspected. E5 remains open for Joe's retest at `http://127.0.0.1:8000/?revision=e5-routing-4#/study`. See `docs/evaluation-captures/e5-layout-amendment.md`.


E5 C30 follow-up (8 Sep): Graph zoom now provides true Fit width and 50–150% choices; the earlier Fit/Actual pair could look identical for graphs already fitting their pane. Seventeen browser assertions and eleven focused API tests pass; two captures inspected. Current revision `e5-routing-4`; E5 remains open for retest.


E5 C31 (8 Sep): replaced the single-column CFG renderer with topology-based layered layout using pinned, locally served Dagre 1.1.5 (MIT). Branches separate spatially; edge labels are horizontal and hover/keyboard focus isolates a directed route. Pane width only scales the completed layout. See `docs/evaluation-captures/e5-routing-amendment.md`. E5 remains open for visual retest; E6 has not started.
