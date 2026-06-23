# Toolchain Boundary

Owns canonical LLVM generation through the pinned Docker environment.
No upper layer should call `clang` or `opt` directly.
