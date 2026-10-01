# Model record format v3 migration evidence

Model records moved from format v2 to v3 to store the curated-pass-sequence
identity, use `unresolved` as the unresolved confidence value, and describe the
separately recompiled O3 comparison directly. Compiler artefacts, pass order,
and correspondence endpoints and relations were preserved.

Before updating the summary-response digest fixture, the v3 records and every
`QueryService.summary` response were compared with application revision
`afa93412c2e507c25f3edfe12a1b089b9fc038ae`. The checker applies only the declared
format, configuration ID, confidence, and recompiled-O3 wording mappings. The
normalised JSON structures must then match exactly. It reported 45 model records
and 315 comparison responses equivalent, with all 93 compiler artefacts
outside the model-record directories byte-identical.

The one-off equivalence checker used for this migration has been retired; the
comparison results above remain the record of that verification.

The expected result is `45 model records, 315 comparison responses,
93 compiler artefacts byte-identical`.
The expected-correspondence tests separately check fresh analysis, stored
correspondences, reviewed link tables, and complete endpoint coverage.
