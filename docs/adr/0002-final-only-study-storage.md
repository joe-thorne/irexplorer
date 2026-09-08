# ADR 0002 — Separate, final-only study collection

**Status:** Implemented for synthetic E6 review, 8 September 2026. Pilot/live collection remains disabled. Extends [ADR 0001](0001-fastapi-stateless-curated-api.md) only for the requested study boundary; compiler queries remain stateless.

## Context and decision

The entire evaluation will run in the prototype. Survey/task responses are mutable research records; the immutable compiler model and its per-example query cache must never store them. E6 adds a separate `src/backend/evaluation/` service/router. Plain browser study modules own navigation, forms, drafts, and timing; workspace modules own only view/selection state. The shared, reviewed participant definition supplies rendering and server validation. Researcher notes, expected answers, stratification, and reverse-scoring metadata stay out of served assets and public APIs.

After explicit consent, generate a cryptographically random participant code and keep a tab-scoped draft in `sessionStorage`. No answers or identifiers are created before consent. Refresh in the same tab is supported; closing the tab is not a supported recovery procedure. Browser session restoration can retain tab storage, so do not promise that closing always erases it. Provide an explicit Stop/discard action that removes the draft. When storage fails, explain the limitation and require explicit memory-only continuation. Do not send drafts on unload. Abandoned/incomplete sessions have no server response record; their exclusion is an analysis limitation.

Only the final Submit action sends responses. Generate a separate random submission ID once and preserve it across retries. SQLite commits the complete validated envelope transactionally before returning a receipt. A unique submission ID plus a canonical content hash gives the same receipt for an identical retry; different content under the same ID returns a controlled conflict without stored answers. Canonicalisation rules must be versioned in E6, including object key ordering and multi-choice set ordering. Failed or uncertain acknowledgement retains the original draft/ID for retry. In-flight/uncertain submission cannot be described as proof that nothing was saved. After acknowledgement, clear answers and retain only the receipt/participant code needed for the reviewed withdrawal policy.

SQLite lives outside public assets and Git on single-host durable storage. Preview uses only synthetic records and a separate temporary store; pilot and live each need separately configured stores. Mode and release metadata are server-controlled, never URL/client flags. Live collection stays off until D3–D5 and E7/E8 release checks pass. No public listing/export/researcher dashboard is introduced. A private CLI will export UTF-8 JSON/CSV plus the codebook, back up/restore the database, and delete records/database/exports/backups under the agreed retention policy. Escape spreadsheet-formula prefixes in CSV while preserving original free text in JSON; keep raw ratings separate from subsequent coding and reverse scoring.

## Validation and operations contract

Use the proposed [API contract](../evaluation-api-contract.md). Enforce allowed versions/IDs/types/ranges, consent/P1, task statuses/order/completion, bounded UTF-8 body/text lengths, JSON content type, and same-origin requests before storing. Query writes cannot invoke the compiler. Do not persist request bodies, IP addresses, or identifiers in application diagnostics. Infrastructure/proxy/access/error/backup logs need an actual E8 audit before any disclosure claims can be made; current Uvicorn access logging is not a verified live configuration.

Assign app revision, artefact checksum, schema version, and collection mode from trusted server release metadata. Validate supported study/instrument versions supplied by the client against that release. Separate pilot data from main data unless inclusion is explicitly justified. Require durable restart, identical/conflicting retries, lost acknowledgement, concurrent writes, disk failure, export fidelity, backup restore, and deletion tests in E6/E8.

## Consent and unresolved conditions

The proposed participant wording and withdrawal-code policy are in the parent [E0 review](../../../Docs/evaluation/e0-review.md). Keep the code available for withdrawal requests before an agreed cutoff; a random identifier does not make deletion technically impossible. Joe/Joel must confirm that cutoff, eligibility, contact details, use/sharing, and exact storage/access/retention arrangements. No promise of institutional approval is inferred from earlier advice. Update evaluation §6 and the consent instrument together only after review, then version them before participant use.

## Consequences and alternatives

Local drafts avoid collecting abandoned answers, but lose incomplete-session evidence and do not support cross-device recovery. SQLite fits a single host; multi-host collection would need a new storage decision. Continuous server autosave and an external survey platform were considered unnecessary for the authorised final-only workflow. Participant accounts, clickstream/keystrokes, audio/video/screen recording, and arbitrary source submission are outside scope. The mutable service is a bounded addition to the application, with no mutation of `QueryService`, `StateGraph`, or correspondence records.


## E6 implementation record

SQLite schema/canonicalisation version 1, exact request validation, final-only browser retry/receipt state, and researcher export/backup/restore/deletion are implemented. See [operations and release configuration](../evaluation-operations.md) and [verification](../evaluation-captures/e6-submission.md). The original participant definition and instruments remain unchanged; server configuration overlays collection mode/enabled status. E5 fractional durations round once at submission, to integer milliseconds within the proposed 24-hour bound. Preview is synthetic-only; recognised pilot/live modes cannot collect until the participant release is reviewed and versioned.
