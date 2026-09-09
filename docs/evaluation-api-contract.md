# Study API contract

`GET /api/study/content` returns the packaged participant definition through an explicit allowlist, with server-configured collection status. It includes information, consent, question types/options/scales, task instructions, and initial workspace selections. Researcher mappings and expected answers are not served.

`POST /api/study/submissions` accepts the final JSON envelope from the configured exact origin. The service validates content type, body size, supported versions, consent, field types and bounds, task completion/order, and identifiers before storage. It commits the complete response transactionally before returning a receipt.

- First accepted submission: `201`.
- Identical retry with the same submission ID: `200`, with the original receipt.
- Conflicting reuse of that ID: `409`, without disclosing stored responses.

The browser freezes the envelope before sending and retries that same envelope after uncertain delivery. No draft is sent on unload. Compiler queries remain read-only and cannot invoke compilation or mutate study records.

See [study operations](evaluation-operations.md) for modes, data paths, and private researcher commands, and the runtime `/docs` endpoint for HTTP schemas.
