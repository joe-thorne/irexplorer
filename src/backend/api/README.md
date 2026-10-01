# Query API boundary

FastAPI serves the static browser application and stateless queries over included compiler artefacts. Every query names its example; the browser owns panel and selection state. The immutable per-example cache contains no participant responses. No runtime source upload or compiler execution is supported.

Run `.venv/bin/python -m src.backend.api.server` from the repository root and open `http://127.0.0.1:8000`. The interactive API docs and OpenAPI schema are not exposed by development or packaged releases; both `/docs` and `/openapi.json` return a controlled `404 not_found` response.

Every response carries a self-only Content Security Policy with `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, and `Referrer-Policy: no-referrer`. The policy allows same-origin resources only and prevents this application from being framed.

## Curated queries

- `GET /api/examples`
- `GET /api/examples/{exampleId}/states`
- `GET /api/examples/{exampleId}/source`
- `GET /api/examples/{exampleId}/states/{ordinal}/ir`
- `GET /api/examples/{exampleId}/states/{ordinal}/cfg?functionId=...`
- `GET /api/examples/{exampleId}/states/{ordinal}/source-mappings?functionId=...`
- `GET /api/examples/{exampleId}/comparison-report?fromOrdinal=...&toOrdinal=...`

Unknown examples and model nodes return `404`; invalid query combinations return `422`. Missing or corrupt model data produces a sanitised `503`.

Source bytes are checked against recorded compiler metadata. Source locations are distinct from cross-state correspondence confidence. Comparison reports cover the whole example in timeline order, independent of panel order or selected function. The route returns `steps`, `structuralClaims`, `links`, `optimisations`, and the compared `states`; each state exposes its producing `step`, and the browser resolves a selection's trace from `comparisonReport.links`. Wider comparisons compose stored correspondences transiently; the independently recompiled O3 state retains its own provenance.

## Application and study

`GET /api/health` reports service health. `GET /api/release` reports application identity. Static responses use `Cache-Control: no-store` and serve the current body even when conditional validators match.

The [study API](../../../docs/evaluation-api-contract.md) supplies participant content and final submissions through a separate service. It does not mutate compiler queries. [Study operations](../../../docs/evaluation-operations.md) covers server configuration and private CLI commands.
