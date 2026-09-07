# irexplorer

A system for exploring code transformations: curated LLVM IR and CFG states in two independently configurable browser panes.

From this directory:

```sh
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000/** and choose a curated file. If needed, create `.venv` with `python3 -m venv .venv` and install with `.venv/bin/python -m pip install -r src/backend/requirements.lock`.

**E3 ready for review (7 September 2026); E2 reviewed with no amendments.** Verified C remains linked to independent IR/CFG panes. E3 adds state stepping, readable labels, recorded summaries with evidence/provenance, and repaired directed CFGs. Open `http://127.0.0.1:8000/#/explore` or `/#/study`; see [E3 commands, 71 browser checks, and captures](docs/evaluation-captures/e3-comparisons.md). 58 backend tests pass. Instruments remain unchanged; E4–E8 forms, drafts, timing, and collection are unimplemented. The synthetic journey resets on refresh. This is preview-only; server-controlled release modes remain E6 work.

In the parent thesis checkout, see [E0 review](../Docs/evaluation/e0-review.md) and the [E0–E8 implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md). Read [CLAUDE.md](CLAUDE.md) before implementation. Run `.venv/bin/python scripts/audit_e0.py` for the reproducible researcher audit (requires parent draft instruments), and `.venv/bin/python -m unittest discover -s tests -v` for the backend suite.


E3 source-loading amendment (7 Sep): versioned frontend assets and no-store preview static responses address the reproduced legacy-script/empty-C-panel failure. 59 backend tests and six cache-enabled recovery assertions pass. Retest at `http://127.0.0.1:8000/?revision=e3-source-fix-1#/explore`; E3 remains ready for review, E4 unstarted.
