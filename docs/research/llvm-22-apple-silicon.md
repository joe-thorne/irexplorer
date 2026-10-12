# Running LLVM 22.1.8 locally on Apple Silicon

Findings for the research ticket [Options for running LLVM 22.1.8 locally on Apple Silicon](https://github.com/joe-thorne/irexplorer/issues/42), part of the map [User programs: upload, edit and recompile C in a local irexplorer](https://github.com/joe-thorne/irexplorer/issues/41). This file reports facts only. The choice between options belongs to the ticket "Toolchain source and run mode for user programs".

**Date:** 12 Oct 26.

**Machine:** Apple M4 Pro (12 cores, 24 GiB), macOS 26.6.2 (25G83), `arm64`. Docker Desktop 4.90.0 (client 29.7.2) is installed. Homebrew LLVM 23.1.2 is installed at `/opt/homebrew/opt/llvm`. Rosetta is installed: `oahd` is running and `/Library/Apple/usr/libexec/oah/RosettaLinux` exists.

**Pinned baseline:** [`Dockerfile.toolchain`](../../Dockerfile.toolchain) and [`docs/environment.md`](../environment.md). The image is Ubuntu 24.04 `linux/amd64` with the official `LLVM-22.1.8-Linux-X64.tar.xz`, checked against SHA-256 `df0e1ecf16caf3489a272a5eea4eec9b0d82878f6477fa309504f918a0006384`. It writes IR with triple `x86_64-unknown-linux-gnu`. [`generate_curated.py`](../../src/backend/toolchain/generate_curated.py) runs each tool command in its own `docker compose run --rm` container. Per example that is 16 tool invocations (2 `clang -O0`, 12 `opt`, 2 `clang -O3`) for the 14 pass states, plus 2 version probes.

## Summary

| Option | Exactly 22.1.8? | Runs natively here? | Emits `x86_64-unknown-linux-gnu` IR | `#include <stdio.h>` with that target | Measured cost |
|---|---|---|---|---|---|
| 1. Official `LLVM-22.1.8-Linux-ARM64.tar.xz` in an `arm64` image stage | Yes, the upstream release binary | Yes, inside Docker's `arm64` Linux VM | With `--target=x86_64-unknown-linux-gnu`. The X86 backend is inferred present but was not run | Needs x86-64 glibc headers added to the image | Not measured. Download is 1,771,004,928 bytes |
| 2. Existing `amd64` toolchain image under emulation | Yes, the pinned image | No, emulated (Rosetta or QEMU, depending on the Docker VMM) | Yes, the default target | Not as built today: the image has no libc headers | Not measured: the Docker daemon was not running |
| 3. Homebrew `llvm@22` on the macOS host | Version 22.1.8, but a patched Homebrew build | Yes | With `--target=x86_64-unknown-linux-gnu` | No: `'stdio.h' file not found` (tested with Homebrew 23.1.2) | Native baseline about 0.3 s for the 16 invocations (Homebrew 23.1.2) |
| (Also found) official `LLVM-22.1.8-macOS-ARM64.tar.xz` on the host | Yes, the upstream release binary | Yes | Expected, as option 3. Not tested | Same limitation as option 3. Not tested | Not measured. Download is 1,479,903,744 bytes |

## 1. Official Linux ARM64 release archive

**It exists.** The [LLVM 22.1.8 release](https://github.com/llvm/llvm-project/releases/tag/llvmorg-22.1.8) (published 16 Jun 26) includes the asset below. Sizes and digests come from the GitHub release API (`gh release view llvmorg-22.1.8 -R llvm/llvm-project --json assets`).

| Asset | Bytes | SHA-256 (GitHub asset digest) |
|---|---|---|
| [`LLVM-22.1.8-Linux-ARM64.tar.xz`](https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-ARM64.tar.xz) | 1,771,004,928 | `805efad2bb91cb4967fa569e0881d10c0f69c04461cf671cccbae19f547acc34` |
| [`LLVM-22.1.8-Linux-ARM64.tar.xz.jsonl`](https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-ARM64.tar.xz.jsonl) | 10,741 | attestation bundle |
| [`LLVM-22.1.8-Linux-ARM64.tar.xz.sig`](https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-ARM64.tar.xz.sig) | 119 | GPG signature |
| `LLVM-22.1.8-Linux-X64.tar.xz` (pinned, for comparison) | 1,938,859,476 | `df0e1ecf…0006384`, the pinned value |

**Where its checksum and signature are published.** The release has no separate checksum text file. The SHA-256 appears in three places:

- **GitHub's per-asset `digest` field**, in the release API and on the release page. For the X64 archive this field gives the same value the image pins.
- **A SLSA v1 build-provenance attestation**, the `.jsonl` file. The release notes link it as the "signature" for each binary and say to verify with `gh attestation verify --repo llvm/llvm-project <file>`, or with `--bundle <file>.jsonl` when offline. The same attestation can be read from the GitHub attestations API by digest (`gh api repos/llvm/llvm-project/attestations/sha256:805efad2…`). Its subject is `LLVM-22.1.8-Linux-ARM64.tar.xz` with the digest above. Its builder is `.github/workflows/release-binaries.yml@refs/tags/llvmorg-22.1.8`, run [27622225277](https://github.com/llvm/llvm-project/actions/runs/27622225277/attempts/1).
- **A `.sig` file**: per the release notes, a GPG signature by the release managers, checked against [`release-keys.asc`](https://releases.llvm.org/release-keys.asc).

The archive was not downloaded, so neither the digest nor the signature was checked locally.

**Build host and glibc.** The release matrix in [`release-binaries-all.yml`](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/.github/workflows/release-binaries-all.yml) builds Linux ARM64 on `ubuntu-22.04-arm`. The workflow's comment says it uses 22.04 "to make the built binaries more portable (eg functional aginast [sic] older glibc)". Ubuntu 24.04 ships glibc 2.39 and 22.04 ships 2.35, so the binary should run on a 24.04 `arm64` base. That is an inference and was not run.

**Can it emit x86-64 IR?** Inferred yes, not run:

- [`clang/cmake/caches/Release.cmake`](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/clang/cmake/caches/Release.cmake) sets `LLVM_TARGETS_TO_BUILD Native` for stage 1 only.
- That variable is not in clang's bootstrap pass-through list ([`clang/CMakeLists.txt`](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/clang/CMakeLists.txt), `_BOOTSTRAP_DEFAULT_PASSTHROUGH`).
- The final stage therefore keeps LLVM's default, `set(LLVM_TARGETS_TO_BUILD "all" …)` in [`llvm/CMakeLists.txt`](https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/llvm/CMakeLists.txt).

Running `llc --version` in the extracted archive would confirm it.

**What an ARM64 stage changes:**

- The default triple becomes `aarch64-unknown-linux-gnu`, so every command needs `--target=x86_64-unknown-linux-gnu` to keep the pinned triple and datalayout.
- Whether the IR is then byte-identical to the X64-hosted artefacts is untested. Regenerating the curated artefacts and checking [`docs/curated-artefacts.sha256`](../curated-artefacts.sha256) would show it.
- `<stdio.h>` needs x86-64 glibc headers (see section 4). Ubuntu 24.04 has [`libc6-dev-amd64-cross`](https://packages.ubuntu.com/noble/libc6-dev-amd64-cross) (2.39-0ubuntu8cross1, universe), described as "GNU C Library: Development Libraries and Header Files (for cross-compiling)". Whether clang finds those headers without extra flags was not tested.

**Cost:**

- A one-off download of about 1.65 GiB, then an image build. Only `clang`, `clang-22`, `opt` and `lib/clang` would be kept, as today.
- Native `arm64` speed inside Docker's Linux VM.
- Per-request container start-up if the request path keeps the one-container-per-command shape of `generate_curated.py`.

## 2. Existing amd64 image under emulation

**Not measured.** `docker image ls` failed with `Cannot connect to the Docker daemon at unix:///Users/josephthorne/.docker/run/docker.sock`: Docker Desktop is installed but its daemon was not running. So it is unknown whether `irexplorer-toolchain:llvm-22.1.8-ubuntu24.04` exists locally. The image was not built or pulled.

**Native baseline on this machine, for comparison.** Homebrew `clang`/`opt` 23.1.2 ran the same 16 invocations with the same flags, directly on the host with no container. Times are the median of 5 runs ([script used](#method-for-the-timings)):

| Program | `--target=x86_64-unknown-linux-gnu` | Host target |
|---|---|---|
| `score.c` (11 lines) | 0.305 s | 0.324 s |
| `binary_search.c` (20 lines) | 0.316 s | not run |
| `quick_sort.c` (31 lines) | 0.332 s | 0.330 s |
| 22-line test using `stdio.h`, `math.h`, `ctype.h` | n/a (headers missing) | 0.363 s |

Under emulation, the emulator's slowdown applies to these times. In the current generator's shape, so does the start-up of 16 separate containers.

**Which emulator Docker Desktop uses:**

- Docker's [settings reference](https://docs.docker.com/desktop/settings-and-maintenance/settings/) lists "Use Rosetta for x86_64/amd64 emulation on Apple Silicon", available with the Apple Virtualization framework VMM. It describes the setting as "Accelerate x86/AMD64 binary emulation on Apple Silicon".
- The [Docker VMM page](https://docs.docker.com/desktop/features/vmm/) says "Docker VMM does not currently support Rosetta, so emulation of amd64 architectures is slow." The same page says the Docker VMM option ran on `libkrun` in Docker Desktop 4.35 to 4.85 and on Docker's own VMM from 4.86. It describes the Apple Virtualization framework as a stable option that is still available.
- This machine's `settings-store.json` sets no VMM or Rosetta key, so Docker Desktop's defaults apply. Which VMM is active was not confirmed with the daemon down.

**Rosetta's horizon:**

- Apple's [Running Intel Binaries in Linux VMs](https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms) says x86-64 translation for Linux VMs has been available since macOS 13 and that "macOS 27 directly integrates support for Intel binary translation".
- In an [Apple developer forums thread](https://developer.apple.com/forums/thread/787530), Apple staff quote the plan to keep Rosetta as a general-purpose tool through macOS 27. They give no guidance on Linux VMs beyond that.

**Published figures.** I found no primary or controlled benchmark of clang under Rosetta or QEMU. The closest reports are user anecdotes:

- [OrbStack issue #792](https://github.com/orbstack/orbstack/issues/792) (M2 Max, macOS 14.1, a "CPU-bound" image build): 28 s native `arm64`, 142 s `amd64` under QEMU, and 190 s `amd64` under Rosetta. After the maintainer's fix in OrbStack 1.1.0, the Rosetta build took 44 s. That is about 1.6× native under Rosetta and about 5× native under QEMU, for that workload only.
- [Nixcademy](https://nixcademy.com/posts/rosetta-linux-builder-macos/) reports `x86_64-linux` Nix builds 2.54× faster with Rosetta than with QEMU. It gives no absolute times and does not name the machine.

## 3. Homebrew

**`llvm@22` exists and ships exactly 22.1.8.** The [formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/l/llvm@22.rb) builds from `llvm-project-22.1.8.src.tar.xz`. Its source SHA-256 is `922f1817a0df7b1489272d18134ee0087a8b068828f87ac63b9861b1a9965888`, the same digest GitHub reports for that release asset.

- It is keg-only (`keg_only :versioned_formula`), so it installs under `/opt/homebrew/opt/llvm@22`, beside the existing `llvm` (23.1.2).
- It has bottles for `arm64_golden_gate`, `arm64_tahoe` (macOS 26, this machine), `arm64_sequoia`, `arm64_linux` and `x86_64_linux`.
- Locally, `brew info llvm@22` reports `stable 22.1.8 (bottled) [keg-only]`, not installed.
- The installed `llvm` 23.1.2 keg takes 1.9 GB in 9,384 files. The size of `llvm@22` was not measured.

**It is not the upstream binary:**

- The formula applies four patches to 22.1.8:
  - a Homebrew-local `Patches/llvm/pull-111397.diff` (clang-cl triple config loading, marked `:unofficial`);
  - three backports for macOS 27, from llvm-project PRs [203680](https://github.com/llvm/llvm-project/pull/203680), [205044](https://github.com/llvm/llvm-project/pull/205044) and [222721](https://github.com/llvm/llvm-project/pull/222721).
- Its CMake configuration differs from the release build. For example, it sets `LLVM_LINK_LLVM_DYLIB=ON` and `LLVM_POLLY_LINK_INTO_TOOLS=ON`, and writes clang config files that point at the macOS SDK.
- It identifies itself differently. Observed with Homebrew 23.1.2, both `clang --version` and the IR (`!llvm.ident` and the `DICompileUnit` producer) say `Homebrew clang version 23.1.2`. The pinned artefacts say `clang version 22.1.8 (https://github.com/llvm/llvm-project ca7933e47d3a3451d81e72ac174dcb5aa28b59d1)`.

**The bottle changes while the version stays at 22.1.8.** The [formula history](https://github.com/Homebrew/homebrew-core/commits/HEAD/Formula/l/llvm@22.rb) shows the macOS 27 backports and three bottle updates on 10–11 Sep 26, and "move to local patch for better stability" on 3 Oct 26. The formula is now at `rebuild 2`. Homebrew installs one version per formula. Per Homebrew's [Versions policy](https://docs.brew.sh/Versions), versioned formulae differ in major or minor version, not patch, and may be removed when usage falls.

22.1.8 is the last 22.x release published so far: LLVM 23.1.0 followed on 25 Aug 26, and 23.1.3 is current (6 Oct 26). The formula therefore stays at 22.1.8 unless upstream ships a 22.1.9.

## 4. macOS host toolchain targeting `x86_64-unknown-linux-gnu`

**What the pinned build compiles today.**

- The curated sources include only `<stddef.h>` (`quick_sort.c`), a header from clang's own resource directory.
- The pinned image's final stage installs only `ca-certificates` on `ubuntu:24.04`.
- Docker's [package listing for `ubuntu:24.04`](https://github.com/docker-library/repo-info/blob/master/repos/ubuntu/local/24.04.md) shows glibc as `libc-bin` and `libc6` only, with no `-dev` packages. That listing is for the current tag, built 18 Sep 26, not the pinned digest.
- So the pinned image, as built, also has no `stdio.h`. This is inferred from the Dockerfile and the package list, and was not run.

**Tested with Homebrew clang 23.1.2.** Flags were `-O0 -g -Xclang -disable-O0-optnone -fno-discard-value-names -S -emit-llvm`, in a scratch directory:

| Case | Result |
|---|---|
| Host target, `#include <stdio.h>` | Compiles. Triple `arm64-apple-macosx26.0.0`, datalayout `e-m:o-…-n32:64-S128-Fn32` |
| `--target=x86_64-unknown-linux-gnu`, `#include <stdio.h>` | `fatal error: 'stdio.h' file not found`. The include search list is only clang's resource directory and `/usr/local/include`; Homebrew's SDK config file (`arm64-apple-darwin25.cfg`) is not loaded for this triple |
| `--target=x86_64-unknown-linux-gnu`, only `<stddef.h>`, `<stdint.h>`, `<stdbool.h>`, `<limits.h>`, `<stdarg.h>`, `<float.h>` | Compiles. Triple and datalayout are identical to the pinned artefacts (`e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128`) |
| `--target=x86_64-unknown-linux-gnu -isystem <macOS SDK>/usr/include`, with `assert`, `isdigit`, `errno`, `fputs(…, stderr)`, `exit`, `sqrt` | Compiles, but the IR uses Darwin libc names under a Linux triple: `@__stderrp`, `@__assert_rtn`, `@__error` for `errno`, and `@_fputs` (Darwin's symbol prefix leaked into the name). glibc's headers use other names, for example `__errno_location` for `errno` and `__assert_fail` for `assert` |

Host-target IR also differs from the pinned target's IR on code that does not involve libc names. The same `sqrt` call becomes `@llvm.sqrt.f64` on the host target but stays a `@sqrt` library call on `x86_64-unknown-linux-gnu`.

**Implication, stated as fact.** A macOS host toolchain can target `x86_64-unknown-linux-gnu`; Homebrew's build lists the `x86` and `x86-64` backends. Without a Linux sysroot, though, only clang's freestanding headers work. Clang's [cross-compilation guide](https://clang.llvm.org/docs/CrossCompilation.html) says the host's libraries are not enough and target headers must be supplied, via `--sysroot` or `-I`/`-L`.

Options for supplying them, none tested here:

- an x86-64 glibc sysroot on the Mac, for example headers taken from Ubuntu's `libc6-dev` and `linux-libc-dev` for amd64;
- the host target with the macOS SDK. This changes the triple, the datalayout and the libc calls in the IR relative to the curated examples.

## Trade-offs (no recommendation)

| | Fidelity to pinned toolchain | Speed on this Mac | Set-up and offline use | Standard headers |
|---|---|---|---|---|
| ARM64 Linux image | Same upstream release. Triple matches with `--target`; byte identity untested | Native in the VM, plus container start-up | One about 1.65 GiB download and an image build; then offline | Add `libc6-dev-amd64-cross` (untested) |
| amd64 image, emulated | Identical binary and image | Unknown here. Anecdotes: about 1.6× native (Rosetta), about 5× (QEMU) | Image already defined; Docker VMM lacks Rosetta | Add `libc6-dev` (absent today) |
| Homebrew `llvm@22` | Same version, patched, different build and producer string | About 0.3 s per program (measured with 23.1.2) | `brew install llvm@22` (bottle), no Docker; bottle can change | Needs a Linux sysroot, or the host target |
| Official macOS ARM64 archive | Same upstream release | Native (not measured) | About 1.4 GiB download, no Docker | Same as Homebrew (not tested) |

## Method for the timings

The timing script ran each of the 16 commands in sequence with `subprocess.run`, in the order and with the flags of `generate_curated.py`. It used `opt -passes=<p>` for `mem2reg`, `instcombine`, `simplifycfg`, `gvn`, `instcombine,simplifycfg`, `loop-simplify,lcssa`, `loop-rotate`, `licm`, `indvars`, `instcombine,simplifycfg`, `loop-vectorize` and `instcombine,simplifycfg`. Each run was timed by wall clock with `time.perf_counter`; other work on the machine was not controlled. Nothing from the script or its outputs was committed.

## Sources

- LLVM 22.1.8 release page and notes: <https://github.com/llvm/llvm-project/releases/tag/llvmorg-22.1.8>
- LLVM release keys: <https://releases.llvm.org/release-keys.asc>
- GitHub `gh attestation verify`: <https://cli.github.com/manual/gh_attestation_verify>
- Release workflows at the tag: <https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/.github/workflows/release-binaries-all.yml>, <https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/.github/workflows/release-binaries.yml>
- Release build cache and bootstrap: <https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/clang/cmake/caches/Release.cmake>, <https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/clang/CMakeLists.txt>, <https://github.com/llvm/llvm-project/blob/llvmorg-22.1.8/llvm/CMakeLists.txt>
- Homebrew `llvm@22` formula and history: <https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/l/llvm@22.rb>, <https://github.com/Homebrew/homebrew-core/commits/HEAD/Formula/l/llvm@22.rb>
- Homebrew versions policy: <https://docs.brew.sh/Versions>
- Docker Desktop settings and VMM: <https://docs.docker.com/desktop/settings-and-maintenance/settings/>, <https://docs.docker.com/desktop/features/vmm/>
- Apple, Running Intel Binaries in Linux VMs: <https://developer.apple.com/documentation/virtualization/running-intel-binaries-in-linux-vms>
- Apple developer forums, Rosetta after macOS 27: <https://developer.apple.com/forums/thread/787530>
- `ubuntu:24.04` package listing: <https://github.com/docker-library/repo-info/blob/master/repos/ubuntu/local/24.04.md>
- Ubuntu `libc6-dev-amd64-cross` (noble): <https://packages.ubuntu.com/noble/libc6-dev-amd64-cross>
- Clang cross-compilation guide: <https://clang.llvm.org/docs/CrossCompilation.html>
- Anecdotal emulation figures: <https://github.com/orbstack/orbstack/issues/792>, <https://nixcademy.com/posts/rosetta-linux-builder-macos/>
