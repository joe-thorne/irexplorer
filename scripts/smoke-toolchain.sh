#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

cat > "${tmpdir}/smoke.c" <<'C'
int add_one(int x) {
  return x + 1;
}
C

echo "== clang =="
clang --version

echo "== opt =="
opt --version

clang -O0 \
  -g \
  -Xclang -disable-O0-optnone \
  -fno-discard-value-names \
  -S -emit-llvm \
  "${tmpdir}/smoke.c" \
  -o "${tmpdir}/smoke.ll"

echo "== target =="
grep -E '^(target datalayout|target triple)' "${tmpdir}/smoke.ll"

echo "== debug locations =="
grep -q '!dbg' "${tmpdir}/smoke.ll"
echo "debug metadata present"
