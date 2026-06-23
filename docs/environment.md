# Environment Pin

Canonical generation for `irexplorer` uses one controlled Linux environment. Local host toolchains are convenience-only and must not produce golden artefacts.

## Canonical Toolchain

- Target: Linux/x86-64 from the start.
- Docker base image: Ubuntu 24.04.
- LLVM source: official LLVM 22.1.8 Linux x86_64 release tarball.
- Tools: `clang`, `opt`, and related LLVM tools from LLVM 22.1.8.
- Canonical artefacts: shipped pre-baked examples and golden fixtures.

## Local Workflow

- Local canonical generation runs through Docker, even on macOS.
- Homebrew LLVM 22.1.8 on macOS is acceptable for ad hoc exploration only.
- Existing seminar artefacts target `arm64-apple-macosx26.0.0`; they are examples, not canonical golden data.

## Record With Each Artefact

- LLVM/clang/opt version.
- Target triple and datalayout.
- Docker image/build identifier.
- Full `clang`/`opt` command line.
