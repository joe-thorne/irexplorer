# E0 proposed source and study API contracts

7 September 2026 · **Source routes implemented in E2; study/summary interfaces remain drafts.** E0's executable audit is `scripts/audit_e0.py`: it verifies the draft field projection, 42 source/state identities, task evidence, and the private/public boundary. Existing runtime OpenAPI remains v1.0.0. E2 has implemented source queries; E3 summaries; E4/E5 forms/tasks; E6 submission. No new dependency or framework is needed in E0.

## Source (E2)

E2 retains existing example/state/IR/CFG/counterpart routes and implements:

- `GET /api/examples/{example_id}/source`: `{exampleId, file, text, sha256, inputVerified}`. `file` is the canonical logical file name, not a client filesystem path. Read via `curated.read_source`; verify bytes against the pinned IR's DIFile checksum before returning `inputVerified: true`. E0 verifies all 14 states per example. A mismatch is a sanitised `503`, never a false source claim.
- `GET /api/examples/{example_id}/states/{ordinal}/source-mappings?functionId=...`: `{exampleId, ordinal, stateId, functionId, mappings: [{instructionId, blockId, location: {file, line, column}, evidence: "debugLoc"}]}`. Return the selected function's full, bounded mapping set, allowing both directions without another selection route. The backend resolves containing blocks and anchors. Do not attach cross-state confidence to a source location or add source nodes to the model.

Use the existing controlled `404` for unknown examples/states/functions, `422` for invalid combinations, and `503` for missing/corrupt data. A valid function with no source edges returns an empty mappings array. All IDs are scoped by example and ordinal. Resolve the source anchor independently in each pane/state, preserve multiple mapped instructions, and show “No recorded source mapping” for absence. Existing correspondence routes track instructions across states; same-state coordination uses containment. Never infer deletion from a missing location. No uploaded source, user file path, compiler invocation, or new server selection state is accepted.

## Summary (E3)

Propose `GET /api/examples/{example_id}/comparison?fromOrdinal=...&toOrdinal=...` only when consumed by E3. Return scoped endpoints, comparison kind (`same_state`, `adjacent`, `composed`, `recompiled`), recorded summary items with their existing evidence, and separate general pass purpose. Preserve caller direction. A wider comparison has no single responsible pass; ordinal 13 is a separate compilation. Use the existing Layer 4 summary/composition functions. Do not turn task answers into summaries or add an answer-specific route.

## Participant definition and workspace setup (E4/E5)

`GET /api/study/content` will return only an explicit allowlist projection of the supported version: participant information, consent, prompts, labelled scales/options, answer types, task goals/setup, and public submission notice. No raw Markdown instrument is served. E0's parent `e0-participant-content.json` is a **field-only draft**, not complete page content; researcher hashes/coding are in a separate file. E4 must assemble full reviewed prose and reconcile D3–D8, then use the same versioned definition for form rendering and backend validation. Do not promote the inherited draft consent wording to release content.

Workspace module contract: `applySetup({exampleId, functionName?, left:{ordinal,view}, right:{ordinal,view}})` returns a promise resolved only when those views are ready. The study controller starts timing after that promise and prompt rendering. Setup never includes a selected instruction/block, an expected answer, or a responsible-pass hint. Reject stale setup completion after navigation. T2 has only the permitted starting setup, never an automatic jump to the answer. Direct exploration retains independent controls.

## Final submission (E6)

Propose `POST /api/study/submissions`, `Content-Type: application/json`, intended same origin; reject cross-origin requests and validate a configured origin in deployments. No permissive CORS. Same-origin defence does not assert participant identity. Enforce body size while reading, including chunked requests, before parsing JSON.

Envelope (proposed schema version 1):

```text
submissionId: UUID (crypto random, stable across retries)
participantCode: UUID (separate crypto random)
studyVersion, instrumentVersion: supported strings
consent: {version, acknowledgements: {C1:true, …, C6:true}}
pre: {P1: Answer, …, P13: Answer, existing conditional detail fields}
tasks: [{id:T0…T6, status, durationMs, interrupted, answers:{itemId:Answer}}]
post: {Q1:Answer, …, Q20:Answer}
Answer = {status: answered|unanswered|skipped|could_not_work_out|not_applicable,
          value: allowed scalar/array for answered, null otherwise}
```

Use the codebook's item-specific allowed statuses: required consent/P1 cannot be skipped; ordinary ratings cannot acquire not-applicable except where specified. T2a inability and P2 not-applicable are status values, not numeric answers. T1c is represented by T1.durationMs; T0 has no answer map. The private supervisor assistance record is outside this client envelope. All tasks must have their fixed-order terminal status; partial answers remain distinguishable from skipped/inability tasks. No invented confidence fields for T5/T6.

Proposed bounds for review: 128 KiB UTF-8 request, 4,000 Unicode code points per free-text field (256 for short text), UUID syntax for codes, version strings ≤64 characters, finite non-negative integer durations ≤86,400,000 ms per task, exactly T0–T6 without duplicates, unique multi-choice codes, and no unknown keys or extra items. These are implementation limits, not task time limits: no countdown or auto-fail is introduced. E4 should show text bounds and E6 should provide actionable validation without silently truncating answers. Review duration/text bounds before freeze if a pilot needs more.

Server attaches app revision, artefact SHA-256, collection mode, schema version, and durable receipt metadata. Reject these properties if sent by the client, including any `test`/`mode` override. Success `201` after first commit and `200` for identical retry returns the same minimal `{receiptId, participantCode, submissionId, studyVersion}`; no answers are echoed. Use controlled `409` for conflicting reuse, `413` body limit, `415` content type, `422` validation/version, `403` origin, and `503` unavailable collection/storage. Sanitised errors must not log or echo answers. An uncertain network result retains the exact envelope and ID for retry.

CLI export/backup/restore/delete are researcher operations, never HTTP endpoints. Final acknowledgement clears draft answers; minimal receipt/code stays accessible under the reviewed withdrawal policy. Stopping while no submission has been attempted discards only the local draft. In-flight or uncertain submission has explicit retry/receipt guidance, not a claim of erasure.

## Verification ownership

E0 verifies source bytes and all IDs against current models and preserves source-instrument hashes. E2 tests actual endpoint shapes, missing/one-to-many mappings, stale requests, and no user-source route. E4 verifies optionality and status behaviour in the browser. E5 verifies setup readiness, order/locking, timing, and public payloads. E6 tests validation, concurrency, idempotency, persistence, failure, and export/restore. E7/E8 verify full accessibility, live configuration, infrastructure logging, and release wording. Draft interfaces above are not evidence those later behaviours work.
