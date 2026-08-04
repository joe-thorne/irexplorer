# ADR 0001 — FastAPI and stateless curated queries

**Status:** Accepted — 03 Aug 2026

## Context

The first browser boundary used Python's dependency-free `http.server`.  It
was suitable for a localhost, single-user prototype over pre-baked artefacts,
but it manually implemented routing, request parsing, error handling, JSON,
and static-file serving.  More importantly, `QueryService` held one selected
example for the whole process.  That is correct only while one browser uses
the local service; it would allow one participant to replace another
participant's selected example in a hosted study.

The project will continue to serve curated, pre-baked model records only.
This decision does not enable user-source submission, compiler invocation, a
database, persistent user sessions, or application-level authentication.

## Decision

- Use FastAPI, Pydantic, and Uvicorn at the Layer 3/4-to-5 model-query
  boundary.
- Retain the existing immutable dataclasses, validation, and plain-record
  serialisation as the domain model.  Pydantic describes HTTP requests and
  responses only.
- Make every model query stateless by including a validated curated
  `exampleId` in its path.  Remove the server-side `POST /api/session` route.
- Cache immutable curated timelines and correspondence overlays by example id
  inside `QueryService`; the cache never stores browser or participant state.
- Keep the browser frontend and API same-origin.  FastAPI serves the existing
  static assets in local development; deployment may delegate static files and
  TLS to nginx.

## Consequences

The new API contract is explicit, documented as OpenAPI, validates request
parameters and response records, and can be tested in-process without binding
a localhost socket.  Concurrent browsers can select different curated examples
without cross-user interference.

Routes change from a stateful session plus unscoped queries to:

- `GET /api/examples`;
- `GET /api/examples/{exampleId}/states`;
- `GET /api/examples/{exampleId}/states/{ordinal}/ir`;
- `GET /api/examples/{exampleId}/states/{ordinal}/cfg?functionId=...`; and
- `GET /api/examples/{exampleId}/states/{ordinal}/counterparts?nodeId=...`.

This is deliberately a boundary migration.  The separate worker, quota, and
confinement requirements in `docs/input-isolation.md` remain the activation
gate for any future user-supplied source capability.
