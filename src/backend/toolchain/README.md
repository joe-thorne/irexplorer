# Toolchain Boundary

Owns canonical LLVM generation through the pinned Docker environment.
No upper layer should call `clang` or `opt` directly.

`compiler_service.py` is the compiler service: a standard-library HTTP server that compiles one user program at a time with exactly the curated pass sequence commands (`pass_sequence_commands`) and returns only text. It is the only way the application compiles anything. Run `python -m src.backend.toolchain.compiler_service --help` for its options; tests run it on loopback over the fake toolchain in `tests/fake_toolchain`.
