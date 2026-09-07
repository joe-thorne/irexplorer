# irexplorer

A system for exploring code transformations: curated LLVM IR and CFG states in two independently configurable browser panes.

From this directory:

```sh
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000/** and choose a curated file. If needed, create `.venv` with `python3 -m venv .venv` and install with `.venv/bin/python -m pip install -r src/backend/requirements.lock`.

**E2 ready for review (7 September 2026); E1 reviewed with no amendments.** Verified canonical C now links bidirectionally with both IR/CFG panes through recorded debug locations. Open `http://127.0.0.1:8002/#/explore` or `/#/study` on the same port; see [E2 commands, 31 browser checks, and captures](docs/evaluation-captures/e2-source.md). 55 backend tests pass. Instruments remain unchanged; actual forms, drafts, timing, and collection remain later work. The synthetic journey resets on refresh. Known CFG defects remain E3. This is preview-only; server-controlled release modes remain E6 work.

In the parent thesis checkout, see [E0 review](../Docs/evaluation/e0-review.md) and the [E0–E8 implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md). Read [CLAUDE.md](CLAUDE.md) before implementation. Run `.venv/bin/python scripts/audit_e0.py` for the reproducible researcher audit (requires parent draft instruments), and `.venv/bin/python -m unittest discover -s tests -v` for the backend suite.
