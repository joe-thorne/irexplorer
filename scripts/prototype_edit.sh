#!/usr/bin/env bash
# PROTOTYPE ONLY (irexplorer#71): serve the Explore page with the three editing-flow variants and a
# stubbed /api/programs. No compiler runs; see src/frontend/prototype-edit/README.md.
set -euo pipefail

APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON=${IRX_PYTHON:-"$APP_ROOT/.venv/bin/python"}
PORT=${IREXPLORER_PORT:-8011}
echo "Open http://127.0.0.1:$PORT/?variant=A#/explore  (B and C too; ← and → switch variants)"
cd "$APP_ROOT"
exec "$PYTHON" -m uvicorn src.backend.api.app:app --host 127.0.0.1 --port "$PORT"
