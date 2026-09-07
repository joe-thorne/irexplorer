# E4 consent, survey, and recovery evidence

7 September 2026 · Ready for Joe’s review. E3 was reviewed with no amendments. E4 is synthetic-only; no E5 task implementation or E6 collection is enabled.

Preview: **http://127.0.0.1:8000/?revision=e4-forms-1#/study**. Start from the implementation repository with `.venv/bin/python -m src.backend.api.server`. The review server remains running. Parent [review checklist](../../../Docs/evaluation/e4-review.md) and [content mapping](../../../Docs/evaluation/e4-content-mapping.md) describe the exact scope and remaining decisions.

## Verification

- **63 backend tests pass:** [full output](e4-tests.txt). Four new tests cover the participant-only content boundary, consent/survey field inventory, required/optional values, not-applicable status, option ranges/types, exclusive and conditional values, raw Unicode/text bounds, unknown fields, private paths, and disabled submission. The static-cache and API-route contracts now include E4’s read-only content and versioned draft module.
- **12 draft/validation checks pass:** [results](e4-draft-checks.json), reproduced with `node scripts/check_e4_drafts.mjs`. Includes incompatible/corrupt state, consent/version/progress validation, required P1, optional post answers, locked P13 during incomplete corrections, Unicode, quota failure, stale-copy handling, failed discard, and explicit memory continuation.
- **78 Chrome assertions pass:** [results, actual browser version, and source hashes](e4-browser-checks.json), reproduced with `node scripts/capture_e4.mjs` against an isolated headless Chrome on port 9226 and the local server on 8000. Seven captures below were visually inspected. No JavaScript runtime exceptions. Recorded application requests were all GET; no synthetic answers or participant code appeared in request URLs. There is no answer-sending code, unload sender, or submission endpoint.
- **Content/model audit passes:** `scripts/build_e4_content.py --check` verifies the complete 42-field executable mapping and all four original instrument hashes. [Current model audit](e4-model-audit.json) verifies the original 60-field inventory, 42 states/source checksums/commands, model invariants and pinned aggregate, and T1–T5 feasibility. The E0 audit was adjusted only for the now-public participant-content GET and an explicit output path; E0 historical evidence is unchanged. This is not Docker regeneration.
- JavaScript syntax and separate parent/submodule whitespace checks pass. No new dependency was installed.

Browser checks exercise: unchecked consent and decline; no pre-consent storage/identifier; P1 errors/focus; exact question order; conditional detail clearing; both directions of None exclusivity; independent not-applicable/neutral/unanswered values; same-tab pre/post recovery; deep-link and Back gating; P13 lock and explicit corrections; incomplete P1 correction recovery; raw HTML-like/Unicode text; 4,000-code-point bounds without truncation; disabled submission review; storage denial with explicit memory continuation; mid-trial quota failure and retry; failed deletion without false success; damaged drafts; content load failure/retry; and unchanged source-aware direct exploration.

Native Chrome keyboard events exercise Space and arrow keys on radio ratings and Enter on a clear-answer button. Native labels, legends, described-by links, inline errors, and route focus are checked; the Chrome accessibility tree exposes named question groups and not-applicable options. A first keyboard replay omitted Chrome’s Enter text event and failed to activate the button; replay with the native carriage-return text event passes. This was a test-harness correction, not a custom application keyboard handler.

During verification, clearing P1 in a background correction exposed a draft-recovery edge case: a completed-stage flag could coexist with a newly unanswered required field. The corrected state retains P13’s lock independently, preserves incomplete corrections, and gates later screens until P1 is valid. Failed saves/deletes also preserve explicit uncertainty about an inaccessible older copy.

## Captures

| Capture | Visual check |
|---|---|
| [Information, desktop](e4-information-desktop.png) | Source prose and clearly separate synthetic/draft notice; local recovery notice |
| [P1 validation, desktop](e4-pre-validation-desktop.png) | Required versus optional labels, grouped choices, visible inline error |
| [Post survey, desktop](e4-post-desktop.png) | Original five labels, separate not-applicable row, selected-state distinction |
| [Post survey, 390px](e4-post-narrow.png) | Wrapped progress and page introduction; no page-wide overflow |
| [Narrow rating choices](e4-post-narrow-choices.png) | Full labels and distinct not-applicable/neutral values without compressed columns |
| [Local review](e4-review-desktop.png) | Editable background/post links, disabled submission, no simulated successful receipt |
| [Memory-only continuation](e4-memory-only.png) | Explicit refresh limitation and honest inaccessible-older-copy notice |

The in-app browser runtime reported no available browser, including after its documented discovery check. Verification therefore used a separate temporary Chrome profile under `/private/tmp/irexplorer-e4-chrome`, without reading or modifying Joe’s browser. Synthetic data only; the isolated browser is closed after capture.

Physical keyboard and spoken screen-reader testing, zoom/media/contrast coverage across the final journey, timed tasks, durable collection, and final S1.8 remain E5–E7 work. These checks do not claim full accessibility conformance or participant release readiness. D3–D5 and the proposed instrument/optionality/bounds decisions remain unresolved. Instrument v0.1, E0 mapping, compiler model and artefacts remain unchanged; E4 content/study/asset versions are preview versions only. No deployment, real responses, commits, or pushes occurred.
