# Tests

Test coverage grows with implementation risk.
Start with boundary smoke tests, then add model invariant, ingestion, analysis, and end-to-end fixture tests.

E4 adds `test_evaluation_content.py` for participant-only content and raw survey validation. From the implementation directory, `node scripts/check_e4_drafts.mjs` checks local recovery/state contracts; `.venv/bin/python scripts/build_e4_content.py --check` verifies exact source-backed survey/consent mapping and instrument hashes (requires parent checkout). `node scripts/capture_e4.mjs` runs the synthetic browser checks against isolated headless Chrome on port 9226 and the review server on 8000. Current evidence is in `docs/evaluation-captures/e4-forms.md`; older capture scripts retain their step-specific historical assumptions.
