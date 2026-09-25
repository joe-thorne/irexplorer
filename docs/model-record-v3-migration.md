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

To repeat the check, extract the baseline application and make its Python
environment available through the same `.venv` path:

```sh
git archive afa93410bd302d99bf93bcb527758ad186c4d | tar -x -C /private/tmp/irexplorer-v2
ln -s "$PWD/.venv" /private/tmp/irexplorer-v2/.venv
.venv/bin/python -m scripts.check_model_v3_equivalence /private/tmp/irexplorer-v2
```

The expected result is `45 model records, 315 comparison responses,
93 compiler artefacts byte-identical`.
The expected-correspondence tests separately check fresh analysis, stored
correspondences, reviewed link tables, and complete endpoint coverage.
