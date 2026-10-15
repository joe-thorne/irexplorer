# ADR 0005 — User programs compile on request

**Status:** Accepted — 13 Oct 2026. Partly supersedes [ADR 0001](0001-fastapi-stateless-curated-api.md) and [ADR 0003](0003-curated-examples-pre-baked-only.md) for user programs. <!-- terminology: allow pre-baked -->

## Context

ADR 0001 ruled out compiling user-supplied source, and ADR 0003 made the curated examples the only input. Both left the door open: live compiling would need a separately designed isolated worker with resource limits, and would have to enter as a new adapter with its own entry point, never as a second mode of the curated loaders.

Milestone M1 of the user-programs effort (irexplorer #41, specified in #51) lets someone upload one small C file in Explore and explore it exactly as a curated example is explored. It is for local use only, and the study build must stay unchanged while live collection runs.

## Decision

- **Compile on request, in a compiler service.** A user program is compiled by a separate long-running container: the exact LLVM 22.1.8 Linux X64 binary of the pinned toolchain, with `libc6-dev` added so standard headers compile for `x86_64-unknown-linux-gnu`. On Apple Silicon it runs `linux/amd64` under emulation, at about 4 s per program. A native arm64 compiler, or Linux-target IR from a macOS host, was rejected because its IR identity with the curated artefacts is untested, and the host has no Linux libc headers. (#42, #43)
- **Contained locally, not hardened.** The compiler service has no published port, no internet access, a read-only root filesystem and a tmpfs work directory wiped after each program. It runs one compile at a time and stops a compile after 30 s. It returns only text: IR, remarks, the optimisation record and a manifest. The app never runs `clang` or `opt` and never gets the Docker socket. Hosted use is out of scope. (#43, #46)
- **A separate stack.** User programs exist only in their own Compose stack, which serves on `127.0.0.1:8001` and runs the same app image as the study stack. The User programs setting turns the feature on at runtime. It is off by default, requires a compiler address, and cannot be combined with pilot or live collection, so Study and research data never meet user code. The setting is not part of the release identity. (#45)
- **Addressed by content, held in memory.** A user program's `programId` is the SHA-256 of its safe file name and normalised source. That keeps ADR 0001's per-browser statelessness: a program is addressed by its content, never by a browser session. Model records are derived when the program is compiled and kept in a small least-recently-used store, which is lost on restart. The browser keeps the source and posts it again when the server has forgotten it. (#44)
- **A separate adapter.** A separate `/api/programs` router has its own resolver, which calls the compiler service and then a pure timeline builder shared with the curated loader. The curated loader now reads the files and then calls the same builder. The curated routes never fall back to the user-program store, which keeps ADR 0003's rule against a second mode of the curated loaders. A user program's records pass once through model-record serialisation in memory, so they are validated as a curated model record is. (#44)

This replaces ADR 0001's closing line, "User-supplied source compilation is not supported by the runtime", and ADR 0003's bullet "The curated examples are the only input", for user programs. Curated examples remain derived offline, checked against `docs/curated-artefacts.sha256` and unchanged.

## Consequences

- **Naming debt.** A user program's timeline keeps its id in `OptimisationTimeline.example_id` and the record key `exampleId`. Renaming them would change the model-record format and every committed curated record.
- **Reproducibility.** A user program's output is traceable but not checksummed. Its manifest records the tool versions, target, every command, the compiler image ID and the `libc6-dev` version, because the headers come from Ubuntu's archive and are not pinned by digest. An unedited curated source compiled as a user program matches the committed curated IR once paths are normalised. A by-hand smoke check confirms that.
- **Fingerprint.** The release fingerprint covers the user-programs stack and the compiler service's sources, and the artefact checksum stays the curated pin.
