# Query API Boundary

Exposes read-only model and analysis queries to the browser frontend over
`localhost`. The frontend should not reach around this layer to compiler or
model internals.

Run the local service from `irexplorer/` with:

```sh
.venv/bin/python -m src.backend.api.server
```

The service binds to `127.0.0.1:8000` by default. It serves only pre-baked
timeline and correspondence records. The current endpoint API supports:

- `GET /api/examples`, then `POST /api/session` with `{"exampleId":"score"}`;
- state metadata, structured IR, CFG, containment navigation, counterparts,
  step provenance, and the link-backed summary;
- `POST /api/focus` to retain the current state/node focus during a session.

Open `http://127.0.0.1:8000/` in a browser to use the static frontend. It is
served from `src/frontend/` by this local service, so it makes same-origin
requests only to the query API; it does not read compiler artefacts or invoke
compiler tooling.
