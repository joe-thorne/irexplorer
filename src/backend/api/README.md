# Query API Boundary

Exposes read-only model and analysis queries to the browser frontend over
`localhost`. The frontend should not reach around this layer to compiler or
model internals.

Run the local service from `irexplorer/` with:

```sh
.venv/bin/python -m src.backend.api.server
```

The service binds to `127.0.0.1:8000` by default. It serves only pre-baked
full teaching-pass timeline and adjacent correspondence records. The API supports:

- `GET /api/examples`, then `POST /api/session` with `{"exampleId":"score"}`;
- the selected file's state metadata, structured IR, function CFG, and adjacent
  or composed counterpart records. The browser owns all pane and selection state.

Open `http://127.0.0.1:8000/` in a browser to use the static frontend. It is
served from `src/frontend/` by this local service, so it makes same-origin
requests only to the query API; it does not read compiler artefacts or invoke
compiler tooling.

Arbitrary source submission is deliberately unavailable: there is no upload or
analysis route, and the only `POST` route loads a named curated example.
`docs/input-isolation.md` records the required future worker boundary and
activation gate; it does not enable that capability.
