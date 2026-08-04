# Guarded user-supplied input isolation design

**Status:** S2.6 design gate complete; not implemented or enabled.  This is the
required design boundary for future FR1 work, not permission to compile
arbitrary source in the thesis prototype.

## Current, deliberately disabled posture

The running service reads only pre-baked records for a curated `exampleId`
named in every query.  It has no source-upload or analysis route, does not
invoke `clang` or `opt` at runtime, and never runs compiled programs.
`POST /api/analysis` is deliberately unavailable and receives a controlled
unknown-route or method-not-allowed response; the API test keeps that property
explicit.

There is no dormant feature flag to turn on.  Enabling FR1 is a Phase 4 change
only after the gates in [Activation gate](#activation-gate) have been met.  The
curated, pre-baked route remains the default for demonstrations and evaluation.

## Scope and threat model

Future input is untrusted text, not a project checkout.  The design protects
the host, other requests, the local network, and persisted data from malformed
or deliberately expensive C source, preprocessor abuse, unexpected compiler
output, and compiler/toolchain defects.  It does not claim to make a compiler
bug harmless by itself: the compiler must run in a separate, strongly
restricted worker.

The first supported input shape is one UTF-8 **C** translation unit.  C++,
multiple files, archives, generated headers, modules, precompiled headers,
plugins, assembler/linker options, response files, and user-selected compiler
or pass arguments are out of scope.  The service owns a fixed, version-pinned
command template and pass chain; source text can never add flags or paths to
it.  The worker emits LLVM IR and model records only: it neither links nor
executes the submitted program.

## Proposed future boundary

```
browser
  -> request/schema and quota gate
  -> bounded job queue
  -> fresh untrusted-analysis worker
       -> fixed clang/opt commands
       -> parse + model validation
  -> short-lived in-memory session record
  -> existing read-only model-query API and browser views
```

The browser never receives a filesystem path, container identifier, raw
compiler command, or raw worker log.  The existing generation boundary stays
intact: only a validated internal model crosses upward.  The API process must
not run the compiler, share its process, or mount its working directory.

### Admission and validation

Before a job enters the queue, a dedicated input component must:

- accept one JSON field containing UTF-8 source and an explicit `c` language
  tag; reject unknown fields rather than silently interpreting them;
- bound source to 64 KiB, 2,000 lines, and 8 KiB per line; reject NUL bytes,
  invalid UTF-8, and binary payloads;
- assign a server-generated request id and a fixed internal filename
  (`input.c`); never use a supplied filename as a path;
- reject user headers, archives, modules, plugins, response files, and compiler
  options.  The initial command uses no user include directory and forbids
  source-controlled dependencies; an administrator-owned, read-only header
  allow-list would require a later design review;
- apply a small per-user/local-process rate limit and bounded queue before a
  worker is created.  Queue saturation is a controlled rejection, not
  unbounded waiting.

These limits are deliberately conservative for the teaching-scale prototype.
They may be revised only with representative measurements and corresponding
resource-limit tests.

### Fresh worker confinement

Each accepted job creates a new worker from the pinned LLVM image.  It is not
the present Docker Compose development service, which binds the repository for
offline curated generation and therefore is unsuitable for untrusted input.
The future worker runner must enforce all of the following and refuse to start
the feature if it cannot verify them:

- rootless execution, or an equivalently user-namespaced non-root worker; no
  Docker socket, host PID/network namespace, devices, privileged mode, or host
  bind mounts;
- no network (`--network none`) and no published port;
- read-only image root, all Linux capabilities dropped, `no-new-privileges`,
  and the deployment's restrictive seccomp and mandatory-access-control
  profile; the only writable locations are sized `tmpfs` work and temporary
  directories;
- a dedicated non-root uid, fixed `PATH`/locale, empty secrets environment,
  and no writable compiler cache or home directory;
- cgroup-backed limits of one CPU, 512 MiB memory and swap, at most 64
  processes, a 64 MiB temporary filesystem, and explicit file-descriptor and
  file-size limits;
- a five-second timeout for each compiler invocation and a 15-second wall-clock
  deadline for the whole request.  A supervisor kills the complete worker
  process group on any timeout, output cap, or cancellation;
- output caps of 2 MiB per IR state, 256 KiB of diagnostics, and 32 MiB for the
  complete job.  The worker accepts only the named expected IR/remark outputs,
  parses them, runs the normal model validation, and discards every other file.

Container configuration is not accepted on a best-effort basis.  In particular,
a rootless runtime whose cgroup configuration cannot enforce CPU, memory, and
process limits fails the startup self-check and leaves arbitrary input disabled.
The worker image, runtime version, and the effective limits are recorded as
operational metadata, not in the user-visible model.

## Results, failure, and retention

The worker returns either a validated internal model or a typed failure.  Its
temporary filesystem and container are removed after every outcome; no source,
raw IR, remarks, object file, executable, or worker log is written to a
persistent volume by default.  A session may retain the validated model only
for the active browser session and expires after 15 minutes of inactivity.

Client failures are deliberately useful but non-sensitive:

| Condition | Client response |
|---|---|
| Invalid JSON, encoding, schema, or language | `400` / `415` with a short validation message |
| Input or diagnostic/output limit | `413` with the exceeded public limit |
| Unsupported but well-formed source | `422` with a sanitised compiler location/message where available |
| Queue/rate limit | `429` with retry guidance |
| Worker unavailable or failed confinement self-check | `503`; analysis stays disabled rather than falling back to the API process |
| Compiler or whole-job deadline | `504` with a timeout message |
| Invalid generated model | controlled `422`/`500` without exposing implementation details |

Responses and logs must not reveal host paths, container ids, commands,
environment variables, stack traces, or raw stderr.  Minimal operational logs
contain request id, timestamp, byte count, configured toolchain id, duration,
and failure class; they do not contain source text or a source hash.  The
operator may opt into a separate, access-controlled diagnostic capture only for
an explicitly reported failure.

## Activation gate

Implementing a request route is not sufficient to enable FR1.  A maintainer
may enable it only when all of the following are complete:

1. S1.8 has verified the curated MVP, and the route has a strict request schema,
   C-only fixed command template, output allow-list, quotas, and the failure
   responses above.
2. The worker is separate from the API process and automated inspection proves
   no host mounts, network, capabilities, privileges, devices, or writable root
   filesystem.  Startup fails closed when rootless/user-namespace or cgroup
   enforcement is unavailable.
3. Automated adversarial fixtures cover malformed text, include/path attempts,
   macro expansion and other resource-pressure cases, excessive output,
   compiler timeout, cancellation, invalid IR, queue exhaustion, and cleanup.
   They prove bounded resource use and controlled responses without executing
   submitted code.
4. A security review approves the concrete runtime, its patched pinned image,
   the effective sandbox inspection, and the deployment-specific authentication
   and rate limits.  A hosted deployment additionally needs per-user isolation;
   localhost-only use does not waive the worker boundary.
5. The route is documented as an optional on-demand mode while curated,
   pre-baked examples remain available as the safe, reproducible default.

This gate satisfies the thesis requirement to leave a safe, implementable path
for FR1 without widening the current runtime attack surface.
