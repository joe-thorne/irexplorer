# Study API contract

`GET /api/study/content` returns the packaged participant definition through an explicit allowlist, with server-configured collection status. It includes information, consent, question types/options/scales, task instructions, and manual workspace setup instructions and metadata. Researcher mappings and expected answers are not served.

`POST /api/study/submissions` accepts the final JSON envelope from the configured exact origin. The service validates content type, body size, supported versions, consent, field types and bounds, task completion/order, and identifiers before storage. It commits the complete response transactionally before returning a receipt.

- First accepted submission: `201`.
- Identical retry with the same submission ID: `200`, with the original receipt.
- Conflicting reuse of that ID: `409`, without disclosing stored responses.

The browser freezes the envelope before sending and retries that same envelope after uncertain delivery. No draft is sent on unload. Compiler queries remain read-only and cannot invoke compilation or mutate study records.

See [study operations](evaluation-operations.md) for modes, data paths, and private researcher commands, and the runtime `/docs` endpoint for HTTP schemas.

## Instrument v0.2

The current preview uses instrument `v0.2`, content `v0.2-preview-1`, and study `v0.2-synthetic-1`. Old drafts are incompatible and require explicit discard/restart. Historical stored responses are not rewritten.

Each submitted task includes `setupReached` (boolean) in addition to `id`, `status`, `durationMs`, `interrupted`, and `answers`. A completed task requires true. False is permitted for skipped/unable T1–T6 only, with zero duration, no interruption, and all answers unanswered. It means no usable comparison was reached, not that the task's requested configuration was checked. Release metadata uses response schema version 2; the SQLite storage schema remains 1 because payloads are stored as JSON.

T4c is single choice (CFG, IR, Both, Neither, Unsure); T5a is free text with an inability status; Q8 is multiple choice with exclusive Not sure. Field definitions returned by the content endpoint are authoritative. Exported codebook definitions are labelled with their instrument version; do not apply them to older records.
