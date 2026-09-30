# Study API contract

At startup, the service loads the installed public `participant-package-v2.json` and its `public-manifest.json` from the evaluation package directory. It checks the exact package-byte hash, schema and manifest keys, identity/version tuple, canonical public digest, and closed nested public-content schema before exposing content. The runtime does not read thesis source, YAML, or compiler output. The verified package is cached for the process lifetime; `GET /api/study/content` returns its participant-facing content through an explicit allowlist, with server-configured collection status. It includes information, consent, question types/options/scales, task instructions, and workspace defaults and metadata. Researcher mappings and expected answers are not served. The compiler's legacy participant-content JSON remains a separate compatibility artifact.

`POST /api/study/submissions` accepts the final JSON submission from the configured exact origin. The service validates content type, body size, supported versions, consent, field types and bounds, task completion/order, and identifiers before storage. Section and task membership comes from the package's explicit membership table and is checked against each declared section and field owner; field identifier prefixes do not determine membership. It commits the complete response transactionally before returning a receipt.

- First accepted submission: `201`.
- Identical retry with the same submission ID: `200`, with the original receipt.
- Conflicting reuse of that ID: `409`, without disclosing stored responses.

The browser freezes the submission before sending and retries that same submission after uncertain delivery. No draft is sent on unload. Compiler queries remain read-only and cannot invoke compilation or mutate study records.

See [study operations](evaluation-operations.md) for modes, data paths, and private researcher commands, and the runtime `/docs` endpoint for HTTP schemas.

## Instrument v0.11 preview 2

The installed preview package uses instrument `v0.11`, content `v0.11-preview-2`, and study `v0.11-synthetic-1`. The package's version tuple and canonical identity are included in release metadata and the content endpoint. Old drafts are incompatible and require explicit discard/restart. Historical stored responses are not rewritten.

Each submitted task includes `id`, `status`, `durationMs`, `interrupted`, and `answers`; `setupReached` is not collected. Completing, skipping, or reporting inability does not depend on reaching the requested comparison, and partial answers and elapsed duration can be retained. `durationMs` starts at task presentation and counts visible time, excluding hidden-tab time, explicit pauses, and reload downtime. Keep it separate from v0.5/v0.6 post-setup duration. Release metadata uses submitted JSON schema version 2; the SQLite submission-store schema is version 3. Status codes, request bounds, origin checks, receipt shape, and conflict responses are unchanged. The server links each new submission to the participant-content snapshot of its installed package in the same transaction as the insert; a snapshot integrity failure returns `503 storage_unavailable` without a receipt.

Field definitions returned by the content endpoint are authoritative. Presentation control hints (`radio`, `checkbox`, `checkboxes`, `select`, `textarea`, and `input`) guide the browser renderer without changing response meaning. Exported codebook definitions are labelled with their instrument version; do not apply them to older records.
