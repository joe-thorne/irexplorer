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
