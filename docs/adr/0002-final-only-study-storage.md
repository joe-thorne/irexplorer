# ADR 0002 — Separate, final-only study collection

## Decision

Keep mutable study responses separate from the immutable compiler model and its query cache. The study service lives in `src/backend/evaluation/`; browser study modules own forms, navigation, drafts, and timing. The packaged participant definition supplies rendering and validation without requiring external instruments at runtime.

Create a tab-scoped draft only after consent. Only the final Submit action sends answers. Preserve a frozen envelope and submission ID across uncertain delivery and retries. SQLite commits before acknowledgement; identical retries return the original receipt and conflicting reuse is rejected. After acknowledgement, replace the stored envelope with the minimal receipt and clear the answer draft.

Store SQLite outside the source tree and public assets. Export, backup, restore, and deletion are CLI operations, with no public listing or export endpoint. Collection mode and release metadata come from server configuration. Local and preview collection are supported; pilot and live collection remain disabled.

## Consequences

The application remains a single-host service with explicit persistent storage. Drafts do not support cross-device recovery; closing the tab is not a supported recovery workflow. Abandoned drafts produce no server response record. Multi-host collection would require a separate storage decision.

See [operations](../evaluation-operations.md) and [submission contract](../evaluation-api-contract.md). Tests cover validation, retry behaviour, durable receipts, export fidelity, and backup/restore. Infrastructure logging and external deployment configuration are the responsibility of the hosting environment.
