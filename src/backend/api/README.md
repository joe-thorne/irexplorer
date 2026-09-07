# Query API Boundary

Exposes stateless, read-only model queries to the browser frontend. The
frontend must not reach around this layer to compiler or model internals.

Run the local service from `irexplorer/` with:

```sh
.venv/bin/python -m src.backend.api.server
```

The service binds to `127.0.0.1:8000` by default. It serves only pre-baked
full teaching-pass timeline and adjacent correspondence records. Every query
names its curated example, so one browser cannot replace another browser's
selected example. The API supports:

- `GET /api/examples`;
- `GET /api/examples/{exampleId}/states`;
- `GET /api/examples/{exampleId}/states/{ordinal}/ir`;
- `GET /api/examples/{exampleId}/states/{ordinal}/cfg?functionId=...`; and
- `GET /api/examples/{exampleId}/states/{ordinal}/counterparts?nodeId=...&toOrdinal=...`.

The browser owns all pane and selection state. FastAPI exposes the API contract
at `http://127.0.0.1:8000/docs` during local development.

Unknown examples and model nodes return `404`, while invalid combinations of
otherwise valid query parameters return `422`. Missing or corrupt pre-baked
model data is logged with its internal cause and exposed as a sanitised `503`.

Open `http://127.0.0.1:8000/` in a browser to use the static frontend. It is
served from `src/frontend/` by this local service, so it makes same-origin
requests only to the query API; it does not read compiler artefacts or invoke
compiler tooling.

Arbitrary source submission is deliberately unavailable: there is no upload,
analysis, or session-mutation route. `docs/input-isolation.md` records the
required future worker boundary and activation gate; it does not enable that
capability.

Install direct development dependencies with
`.venv/bin/python -m pip install -r src/backend/requirements.txt`. For a
repeatable deployment environment, install the fully resolved
`src/backend/requirements.lock` instead.


## E3 comparison summary query

`GET /api/examples/{example_id}/summary?fromOrdinal=0&toOrdinal=9` exposes the existing `summarise_correspondence` results for the **whole example**, independent of the function selected in the panes. The required ordinals are validated; either pane order is accepted. `fromOrdinal` and `toOrdinal` in the response are sorted into timeline order. Same-state requests return no transformation claims, links or steps, but retain the state's provenance. Reversed panes use the same timeline-order evidence; the browser labels that direction explicitly.

`items` contain `text`, `linkIndices` into this response's `links`, and `remarkIndices` into the final entry of `steps`. `links` preserve original endpoint IDs, relation, confidence and evidence. Adjacent records are read directly; wider overlays are composed transiently. `states` includes every selected-span state with recorded command and transition metadata; `steps` includes every intervening command and original remarks. Remark records retain their model fields (`pass_name`, `name`, `function`, `location`, `raw`). The context distinguishes derived, composed and recompiled comparisons. API version remains 1.0.0; this is an additive preview query. No state mutation, compiler execution, study content, response storage or researcher answer key is involved.

The browser shows up to three existing outcome items, with the remainder and all provenance behind bounded disclosures. Selection confidence/evidence remains separate. New summary requests clear previous outcomes; generation guards prevent delayed responses from overwriting a newer comparison. A failed query hides stale panes and supports reloading the file. See `tests/test_summary_queries.py` and [E3 evidence](../../../docs/evaluation-captures/e3-comparisons.md).


E3 source-loading amendment: the preview shell references CSS/JS with `?v=e3-source-fix-1` to bypass legacy cached URLs. `PreviewStaticFiles` sends `Cache-Control: no-store` for successful static responses and serves current bodies even with matching conditional validators. This policy applies to preview static assets, not model queries. Future release caching needs its own asset-versioning decision; do not restore unversioned reusable scripts. See [cache regression evidence](../../../docs/evaluation-captures/e3-cache-fix.md).

## E4 participant content

`GET /api/study/content` is a separate read-only boundary from compiler queries. It returns the versioned participant-only definition from `src/backend/evaluation/participant-content.json`: draft information/consent, 42 survey/consent fields, labelled scales and original section order, plus fixed preview/submission-disabled metadata. Both the plain browser renderer and `evaluation.content.validate_answers` consume that definition. The validator checks raw survey types/ranges/statuses, required P1, conditional/exclusive choices, and text bounds; it does not implement the future submission envelope. No researcher annotation, answer key, response data, private path, or raw Markdown is exposed.

Content responses use `Cache-Control: no-store`; all current frontend assets use `?v=e4-forms-1`, including `study-draft.js`. Survey drafts and crypto-random participant codes are created only after consent and remain in browser `sessionStorage`, or explicit memory-only mode. No POST/submission route exists. See [E4 evidence](../../../docs/evaluation-captures/e4-forms.md). API version remains 1.0.0; tasks/timing and durable collection remain E5/E6.
