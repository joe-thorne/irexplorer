#!/usr/bin/env bash
# Run the browser acceptance (check_app, check_study_tasks, check_study_guidance) end to end:
# start the host runner on a disposable preview store and an isolated headless Chrome, run every
# check open, rerun check_app with collection closed, then stop both. Synthetic data only.
# Needs Node 22+, Chrome, and the Python environment from the README. CHROME overrides the browser.
set -euo pipefail

APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON=${IRX_PYTHON:-"$APP_ROOT/.venv/bin/python"}
PORT=${IREXPLORER_PORT:-8000}
CDP_PORT=${IREXPLORER_CDP_PORT:-9239}
export IREXPLORER_ORIGIN="http://127.0.0.1:$PORT"
export IREXPLORER_CDP_PORT=$CDP_PORT

if [[ -z "${CHROME:-}" ]]; then
  for candidate in google-chrome google-chrome-stable chromium \
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then CHROME=$candidate; break; fi
  done
fi
[[ -n "${CHROME:-}" ]] || { echo "check_browser: no Chrome found; set CHROME" >&2; exit 2; }

work=$(mktemp -d "${TMPDIR:-/tmp}/irexplorer-browser.XXXXXX")
server_pid=''
chrome_pid=''
stop_server() {
  if [[ -n "$server_pid" ]]; then kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
  server_pid=''
}
cleanup() {
  stop_server
  if [[ -n "$chrome_pid" ]]; then kill "$chrome_pid" 2>/dev/null || true; wait "$chrome_pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT

wait_for() {
  local url=$1
  for _ in $(seq 1 60); do
    curl -fsS "$url" >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "check_browser: $url did not respond" >&2
  return 1
}

start_server() {
  (cd "$APP_ROOT" && IREXPLORER_STUDY_DIR="$work/study" IREXPLORER_COLLECTION_MODE=preview \
    IREXPLORER_STUDY_ORIGIN="$IREXPLORER_ORIGIN" IREXPLORER_COLLECTION_CLOSED="$1" \
    "$PYTHON" -c "from src.backend.api.server import run_server; run_server(port=$PORT)") \
    >"$work/server-$1.log" 2>&1 &
  server_pid=$!
  wait_for "$IREXPLORER_ORIGIN/" || { cat "$work/server-$1.log" >&2; return 1; }
}

"$CHROME" --headless=new --no-first-run --no-default-browser-check --disable-background-networking \
  --user-data-dir="$work/chrome" --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port="$CDP_PORT" about:blank >"$work/chrome.log" 2>&1 &
chrome_pid=$!
wait_for "http://127.0.0.1:$CDP_PORT/json/version"

cd "$APP_ROOT"
start_server 0
node scripts/check_app.mjs
node scripts/check_study_tasks.mjs
node scripts/check_study_guidance.mjs
stop_server

start_server 1
node scripts/check_app.mjs
echo "check_browser: green"
