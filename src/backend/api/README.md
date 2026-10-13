# Query API boundary

FastAPI serves the static browser application and stateless queries over included compiler artefacts. Every query names its example; the browser owns panel and selection state. The immutable per-example cache contains no participant responses. The application never runs a compiler: user programs (below) are compiled by the separate compiler service.

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

`GET /api/health` reports service health. `GET /api/release` reports application identity, plus a runtime `config` object, `{"userPrograms": true|false}`, that is not part of it. Static responses use `Cache-Control: no-store` and serve the current body even when conditional validators match.

The [study API](../../../docs/evaluation-api-contract.md) supplies participant content and final submissions through a separate service. It does not mutate compiler queries. [Study operations](../../../docs/evaluation-operations.md) covers server configuration and private CLI commands.

## User programs setting

`IREXPLORER_USER_PROGRAMS` is read once at startup. Unset or `0` leaves user programs off, and the `/api/programs` routes are not mounted at all. `1` turns them on and requires `IREXPLORER_COMPILER_URL`, the compiler service's address; the address alone never turns them on. Any other value, `1` without an address, or `1` with `pilot` or `live` collection stops startup with an error that names the problem. `IREXPLORER_COMPILER_TIMEOUT` sets how many seconds the app waits for the compiler service to answer (default 40); it must be a positive number. The image, the study Compose file and the host runner all leave the setting off.

## User programs

With the setting on, a separate router serves user programs. It resolves ids only through its own in-memory store, and the curated routes never resolve a `programId`.

- `POST /api/programs` with `{"fileName": ..., "source": ...}` compiles the program through the compiler service and answers `201`, or `200` at once if the program is already held. The body, also returned by `GET /api/programs/{programId}`, is `{programId, fileName, sha256, manifest}`; the manifest records the `clang` and `opt` version lines, the target triple, the compiler image ID, the `libc6-dev` version and every command.
- `GET /api/programs/{programId}/states`, `/source`, `/states/{ordinal}/ir`, `/states/{ordinal}/cfg?functionId=...`, `/states/{ordinal}/source-mappings?functionId=...` and `/comparison-report?fromOrdinal=...&toOrdinal=...` answer exactly as the curated routes do, with `programId` in place of `exampleId`.

Before compiling, the file name must end in `.c` in any case. It is saved as a safe name with a lowercase `.c`: each run of characters in the stem outside `[A-Za-z0-9_-]` becomes `_`, the stem is cut to 64 characters, and an empty stem becomes `program`. The source is normalised: CRLF and lone CR become LF and a leading BOM is removed. It must then be non-empty, not only whitespace, valid UTF-8 without NUL characters, and at most 200 lines (a final newline does not start another) and 16 KiB; it is never truncated. Anything else is refused with `400 invalid_program`, a `reason` (`not_c_file`, `invalid_utf8`, `nul_character`, `empty`, `too_many_lines` or `too_large`, the first that applies in that order) and a `message` the browser shows as it is. The browser applies the same rules before sending; `tests/data/user-program-acceptance.json` holds the cases both are checked against.

`programId` is the SHA-256 of the safe file name, a NUL byte and the normalised source. About 16 programs are held, least recently used out first, and nothing is persisted. An id that is not held returns `404 unknown_program`; a failed compile returns `422 compile_failed` with the compiler's `output`. The compiler service compiles one program at a time: a compile requested during another is refused at once with `409 compiler_busy` (a held program still answers `200`), a compile that runs past the service's 30 s limit is stopped with `504 compile_timeout`, and a service that cannot be reached or does not answer within the compiler timeout returns `503 compiler_unavailable`. None of these holds the program.
