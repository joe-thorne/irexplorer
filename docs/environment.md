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

## Phase 1 Curated Examples

- `score.c`: compact arithmetic and branch example.
- `binary_search`: single-function loop and CFG example.
- `quick_sort`: recursive, multi-function example.

## Default Teaching Pass Chain

The default configurable pass sequence is:

1. `mem2reg` - promote stack variables to SSA.
2. `instcombine` - simplify algebraic instruction forms.
3. `simplifycfg` - simplify CFG shape.
4. `gvn` - remove redundant equivalent computations.
5. `instcombine,simplifycfg` - clean up newly exposed simplifications.
6. `loop-simplify,lcssa` - canonicalise loop form.
7. `loop-rotate` - rotate loop control flow.
8. `licm` - hoist loop-invariant work.
9. `indvars` - simplify induction variables.
10. `instcombine,simplifycfg` - clean up after loop optimisations.
11. `loop-vectorize` - attempt safe loop vectorisation.
12. `instcombine,simplifycfg` - perform final instruction and CFG cleanup.

No-op states remain in the model and are rendered compactly.

## Command Templates

The generator records the exact command line with each generated artefact. These templates define the canonical shape; S1.2 owns the concrete invocation code.

Run the canonical generator from `irexplorer/` inside the local Python virtual environment:

```sh
.venv/bin/python -m src.backend.toolchain.generate_curated
```

Generated artefacts are written to `artefacts/curated/<example>/`. Each example directory contains the `-O0` IR/bitcode, the 12 teaching-pass IR states, the recompiled `clang -O3` anchor, captured `-Rpass` remarks, the `.opt.yaml` optimisation record, and a command manifest.

```sh
clang -O0 -g \
  -Xclang -disable-O0-optnone \
  -fno-discard-value-names \
  -S -emit-llvm \
  <example>.c \
  -o <example>_O0.ll

clang -O0 -g \
  -Xclang -disable-O0-optnone \
  -fno-discard-value-names \
  -emit-llvm -c \
  <example>.c \
  -o <example>_O0.bc

opt -passes='<pass-list>' \
  <input> \
  -S \
  -o <output>.ll

clang -O3 -g \
  -fno-discard-value-names \
  -S -emit-llvm \
  <example>.c \
  -o <example>_O3.ll

clang -O3 -g \
  -fno-discard-value-names \
  '-Rpass=.*' \
  '-Rpass-missed=.*' \
  '-Rpass-analysis=.*' \
  -fsave-optimization-record \
  <example>.c \
  -c \
  -o <example>.o
```

## Record With Each Artefact

- LLVM/clang/opt version.
- Target triple and datalayout.
- Docker image/build identifier.
- Full `clang`/`opt` command line.
