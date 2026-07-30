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
- state metadata, structured IR, CFG, containment navigation, adjacent or
  composed counterparts, step provenance/no-op status plus its captured pass
  remarks, and summaries for adjacent or wider spans; each summary claim
  carries expandable link and, where emitted, pass-remark evidence;
- `GET /api/source?ordinal=N` returns the curated C source annotated with only
  the debug-location-backed instruction mappings recorded for that state;
- `POST /api/focus` to retain the current state/node focus during a session.

Open `http://127.0.0.1:8000/` in a browser to use the static frontend. It is
served from `src/frontend/` by this local service, so it makes same-origin
requests only to the query API; it does not read compiler artefacts or invoke
compiler tooling.

Arbitrary source submission is deliberately unavailable: there is no upload or
analysis route, and the only `POST` routes load a named curated example or
retain focus. `docs/input-isolation.md` records the required future worker
boundary and activation gate; it does not enable that capability.
