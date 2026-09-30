# ADR 0002 — Separate, final-only study collection

## Decision

Keep mutable study responses separate from the immutable compiler model and its query cache. The study service lives in `src/backend/evaluation/`; browser study modules own forms, navigation, drafts, and timing. The packaged participant definition supplies rendering and validation without requiring external instruments at runtime.

Create a tab-scoped draft only after consent. Only the final Submit action sends answers. Preserve a frozen envelope and submission ID across uncertain delivery and retries. SQLite commits before acknowledgement; identical retries return the original receipt and conflicting reuse is rejected. After acknowledgement, replace the stored envelope with the minimal receipt and clear the answer draft.

A retry is matched against its stored record before current-instrument validation: the same instrument identities and the same digest under the stored canonicalisation version return the original receipt, so receipts survive application and package upgrades. First deliveries are still validated against the installed release.

Store SQLite outside the source tree and public assets. Schema version 3 uses a `submissions` table and `submissions.sqlite3`, plus an immutable participant-content snapshot registry keyed by canonical public digest. Each new submission links to the snapshot it was validated against, and both rows commit together before the receipt. First use moves and migrates version-1 `responses` and version-2 `submissions` stores without changing submitted JSON; their rows record unavailable participant-content provenance explicitly rather than inheriting current content. Export, backup, restore, and deletion are CLI operations, with no public listing or export endpoint. Exports include every referenced snapshot and a codebook per snapshot read from the store, never the running package; verified researcher packs are supplied only as arguments to the private export. Collection mode and release metadata come from server configuration. Local and preview collection are supported; pilot and live collection remain disabled.

## Consequences

The application remains a single-host service with explicit persistent storage. Drafts do not support cross-device recovery; closing the tab is not a supported recovery workflow. Abandoned drafts produce no server response record. Multi-host collection would require a separate storage decision.

See [operations](../evaluation-operations.md) and [submission contract](../evaluation-api-contract.md). Tests cover validation, retry behaviour, durable receipts, export fidelity, and backup/restore. Infrastructure logging and external deployment configuration are the responsibility of the hosting environment.
