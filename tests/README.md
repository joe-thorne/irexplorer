# Tests

Test coverage grows with implementation risk.
Start with boundary smoke tests, then add model invariant, ingestion, analysis, and end-to-end fixture tests.

E5 extends `test_evaluation_content.py` to tasks and shared answer validation. Current commands: `node scripts/check_e5_drafts.mjs` for local draft/timing contracts, `.venv/bin/python scripts/build_e5_content.py --check` for source-backed participant content and unchanged instrument hashes (requires parent checkout), and `node scripts/capture_e5.mjs` for synthetic browser checks against isolated headless Chrome on port 9227 and the review server on 8000. Current evidence is `docs/evaluation-captures/e5-tasks.md`. The E5 builder extends the E4 survey builder; older build/check/capture scripts retain their step-specific historical assumptions and evidence.
