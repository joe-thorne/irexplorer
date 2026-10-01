#!/usr/bin/env bash
set -euo pipefail

APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LOCK="$APP_ROOT/src/backend/requirements.lock"
AUDIT_TOOL=${PIP_AUDIT_BIN:-"$APP_ROOT/.venv/bin/pip-audit"}
AUDIT_CACHE_DIR=${PIP_AUDIT_CACHE_DIR:-"${TMPDIR:-/tmp}/irexplorer-pip-audit-cache"}

if [[ ! -f "$LOCK" ]]; then
  printf 'Advisory check failed: pinned dependency lock is missing: %s\n' "$LOCK" >&2
  exit 2
fi
if [[ ! -x "$AUDIT_TOOL" ]]; then
  printf 'Advisory check cannot run: pip-audit is not installed at %s.\n' "$AUDIT_TOOL" >&2
  printf 'Install the pinned development tools with: %s/.venv/bin/python -m pip install -r %s/src/backend/requirements-dev.txt\n' "$APP_ROOT" "$APP_ROOT" >&2
  exit 2
fi

printf 'Checking pinned runtime dependencies in %s for published security advisories. Network access is required.\n' "$LOCK"
mkdir -p "$AUDIT_CACHE_DIR"
if "$AUDIT_TOOL" --requirement "$LOCK" --strict --progress-spinner off --cache-dir "$AUDIT_CACHE_DIR"; then
  printf 'Advisory check passed: no known vulnerabilities were reported for the pinned runtime dependencies.\n'
else
  status=$?
  printf 'Advisory check failed with exit status %s. Review the findings above before packaging this release.\n' "$status" >&2
  exit "$status"
fi
