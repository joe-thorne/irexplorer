# Environment Pin

Canonical generation for `irexplorer` uses one controlled Linux environment. Local host toolchains are convenience-only and must not produce golden artefacts.

## Canonical Toolchain

- Target: Linux/x86-64 from the start.
- Target triple: `x86_64-unknown-linux-gnu`.
- Datalayout: `e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128`.
- Docker base image: Ubuntu 24.04.
- LLVM source: official LLVM 22.1.8 Linux x86_64 release tarball.
- Tools: `clang` and `opt` from LLVM 22.1.8.
- Canonical artefacts: shipped pre-baked examples and golden fixtures.

## Docker Files

- `Dockerfile.toolchain`: multi-stage Ubuntu 24.04 image with a pruned LLVM 22.1.8 `clang`/`opt` toolchain.
- `docker-compose.yml`: `toolchain` service built for `linux/amd64`.
- `scripts/smoke-toolchain.sh`: prints tool versions, compiles a minimal C file to LLVM IR, and checks target/debug metadata.

Run from `irexplorer/`:

```sh
docker compose build toolchain
docker compose run --rm toolchain ./scripts/smoke-toolchain.sh
```

Verified local image size after pruning: about 880 MB. The retained LLVM release binaries and clang resource headers dominate the image.

## Local Workflow

- Local canonical generation runs through Docker, even on macOS.
- Homebrew LLVM 22.1.8 on macOS is acceptable for ad hoc exploration only.
- Existing seminar artefacts target `arm64-apple-macosx26.0.0`; they are examples, not canonical golden data.
- Local Python tools and modules must run inside a virtual environment and be reproducible from a requirements file. Backend Python dependencies belong in `src/backend/requirements.txt`.
- The toolchain container does not provide Python; it is only for canonical LLVM generation.

## Record With Each Artefact

- LLVM/clang/opt version.
- Target triple and datalayout.
- Docker image/build identifier.
- Full `clang`/`opt` command line.
