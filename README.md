# irexplorer

A system for exploring code transformations: curated LLVM IR and CFG states in two independently configurable browser panes.

From this directory:

```sh
.venv/bin/python -m src.backend.api.server
```

Open **http://127.0.0.1:8000/** and choose a curated file. If needed, create `.venv` with `python3 -m venv .venv` and install with `.venv/bin/python -m pip install -r src/backend/requirements.lock`.

**E4 ready for review (7 September 2026); E3 reviewed with no amendments.** The study now has participant-only information/consent, P1–P13 and Q1–Q20 forms, validation, tab-local recovery after consent, P13 locking and background corrections, and local response review. Open `http://127.0.0.1:8000/?revision=e4-forms-1#/study`; see [E4 checks and captures](docs/evaluation-captures/e4-forms.md). 63 backend tests, 12 draft checks and 78 browser assertions pass. Instruments and source-aware comparison controls remain unchanged. The task screen is still a labelled preview: E5 supplies T0–T6/timing and E6 supplies final submission, durable storage and release modes. Use invented answers only; no answers leave the browser. Refresh recovers compatible drafts in the same tab; unavailable storage requires explicit memory-only continuation.

In the parent thesis checkout, see [E0 review](../Docs/evaluation/e0-review.md) and the [E0–E8 implementation plan](../Docs/system-plan/web-evaluation-implementation-plan.md). Read [CLAUDE.md](CLAUDE.md) before implementation. Run `.venv/bin/python scripts/audit_e0.py` for the reproducible researcher audit (requires parent draft instruments), and `.venv/bin/python -m unittest discover -s tests -v` for the backend suite.


E3 source-loading amendment (7 Sep): versioned frontend assets and no-store preview static responses address the reproduced legacy-script/empty-C-panel failure. 59 backend tests and six cache-enabled recovery assertions pass. Retest at `http://127.0.0.1:8000/?revision=e3-source-fix-1#/explore`; Joe subsequently reviewed E3 with no amendments; E4 is now ready for review.
