# Study API contract

`GET /api/study/content` returns the packaged participant content through an explicit allowlist, with server-configured collection status. It includes information, consent, question types/options/scales, task instructions, and workspace defaults and metadata. Researcher mappings and expected answers are not served.

`POST /api/study/submissions` accepts the final JSON submission from the configured exact origin. The service validates content type, body size, supported versions, consent, field types and bounds, task completion/order, and identifiers before storage. It commits the complete response transactionally before returning a receipt.

- First accepted submission: `201`.
- Identical retry with the same submission ID: `200`, with the original receipt.
- Conflicting reuse of that ID: `409`, without disclosing stored responses.

The browser freezes the submission before sending and retries that same submission after uncertain delivery. No draft is sent on unload. Compiler queries remain read-only and cannot invoke compilation or mutate study records.

See [study operations](evaluation-operations.md) for modes, data paths, and private researcher commands, and the runtime `/docs` endpoint for HTTP schemas.

## Instrument v0.7

The current preview collection uses instrument `v0.7`, content `v0.7-preview-1`, and study `v0.7-synthetic-1`. Old drafts are incompatible and require explicit discard/restart. Historical stored responses are not rewritten.

Each submitted task includes `id`, `status`, `durationMs`, `interrupted`, and `answers`; `setupReached` is not collected in v0.7. Completing, skipping, or reporting inability does not depend on reaching the requested comparison, and partial answers and elapsed duration can be retained. The v0.7 `durationMs` starts at task presentation and counts visible time, excluding hidden-tab time, explicit pauses, and reload downtime. Keep it separate from v0.5/v0.6 post-setup duration. Release metadata uses submitted JSON schema version 2; the SQLite submission-store schema is version 2.

T4c is single choice (CFG, IR, Both, Neither, Unsure); T5a is free text with an inability status; Q8 is multiple choice with exclusive Not sure. Field definitions returned by the content endpoint are authoritative. Exported codebook definitions are labelled with their instrument version; do not apply them to older records.
