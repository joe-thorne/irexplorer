# ADR 0004 — Controlled backfill of legacy participant-content provenance

**Status:** Accepted — 30 Sep 2026. Amends the provenance immutability recorded in [ADR 0002](0002-final-only-study-storage.md); the final-only decision is unchanged.

## Context

SQLite schema version 3 links each new submission to the participant-content snapshot it was validated against. Rows stored before that version are marked `legacy_unavailable`, and a trigger made every submission's provenance unconditionally immutable. That stopped legacy rows being relabelled with current content. It also stopped a researcher from linking a legacy row to its exact historical content, even when a frozen release shows which content the row used.

## Decision

- Schema version 4 replaces the unconditional trigger with one that permits exactly one provenance change. A row that is `legacy_unavailable`, with no digest and no backfill record, may become `snapshot`. The new digest must name a registered snapshot, and the new `provenance_backfill` column must record the evidence. Every other provenance change is rejected, whether to a linked row, a backfilled row, or a legacy row. So is any update of a row's submission ID, submission digest, submitted JSON, receipt, or release metadata. A new row cannot claim a backfill.
- Only the private `backfill-provenance` CLI operation makes this change. It takes explicit input: one or more frozen public package pairs (`--release`) and a links file naming each record, its stored submission digest, and its content digest. It links a record only when all of the following hold:
  - the release verifies like an installed package;
  - the submission digest matches the stored row and its stored JSON;
  - the record names that release's identities;
  - no other supplied release or stored snapshot carries those identities, so the link is unambiguous;
  - the stored JSON is admissible under that release's own rules.
- Version labels alone never select content, and the running package is never consulted.
- The operation writes a verified copy of the store and never modifies its source. A failed link, a conflicting existing link, or unusable input writes nothing. A record already linked to the named digest is left unchanged, so repeating a run is a no-op.
- Exports keep the `snapshot` status for a backfilled record, so its snapshot codebook applies. They add the stored `backfill` evidence, which shows the link was made after submission.

## Consequences

The triggers guard integrity rather than grant access. Anyone who can write the SQLite file directly can still drop them, so private storage permissions remain the access control. The permitted change is available to any connection, but only the CLI performs the verification that justifies it.

The tool checks that a record is consistent with the supplied frozen artefact. It cannot prove which release was deployed when the record was collected. The researcher remains responsible for deployment records that justify each link.

Records collected under an instrument with no frozen public package (currently any instrument before v0.11) cannot be verified, and stay unavailable.

First use by this release migrates each store to version 4, as version 3 was introduced. Earlier releases refuse a version-4 store, so a code-only rollback across this release is not supported. Take a backup before the update, and review compatibility before any rollback. Version-3 stores and backups remain readable and are migrated on first use.
