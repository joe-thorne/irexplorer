# irexplorer

A system for exploring code transformations: curated LLVM IR and CFG states in two independently configurable browser panes.

From this directory:

```sh
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000/** and choose a curated file. If needed, create `.venv` with `python3 -m venv .venv` and install with `.venv/bin/python -m pip install -r src/backend/requirements.lock`.

**E1 ready for review (7 September 2026); E0 reviewed with no amendments.** [Baseline captures/task audit](docs/evaluation-captures/e0-baseline.md), [proposed API contracts](docs/evaluation-api-contract.md), and [storage ADR](docs/adr/0002-final-only-study-storage.md) are prepared. Open `http://127.0.0.1:8000/#/study` for the five-screen synthetic journey or `/#/explore` for direct exploration. E1 adds the task/layout shell and placeholders; source data, actual instruments, drafts, timing, and response collection remain E2–E6 work. Refresh intentionally resets preview progress. [E1 checks and captures](docs/evaluation-captures/e1-preview.md) record 33 passing browser assertions and 52 backend tests. Known baseline CFG rendering defects are recorded for E3. No participant data or database is used in E0/E1. This build is preview-only; server-controlled release modes remain E6 work.

In the parent thesis checkout, see [E0 review](../Docs/evaluation/e0-review.md) and the [E0–E8 implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md). Read [CLAUDE.md](CLAUDE.md) before implementation. Run `.venv/bin/python scripts/audit_e0.py` for the reproducible researcher audit (requires parent draft instruments), and `.venv/bin/python -m unittest discover -s tests -v` for the backend suite.
