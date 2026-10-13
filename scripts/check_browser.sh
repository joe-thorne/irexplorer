#!/usr/bin/env bash
# Run the browser acceptance (check_app, check_study_tasks, check_study_guidance, check_user_programs)
# end to end: start the host runner on a disposable preview store and an isolated headless Chrome, run
# every check open with user programs off, rerun check_app with collection closed, then start the
# compiler service on loopback over the fake toolchain (no Docker, no LLVM), restart the runner with
# user programs on and run check_user_programs, then the Study checks again unchanged (Study must not
# change with user programs on), then stop everything. Synthetic data only.
# Needs Node 22+, Chrome, and the Python environment from the README. CHROME overrides the browser.
# Ports: IREXPLORER_PORT (app), IREXPLORER_CDP_PORT (Chrome) and IREXPLORER_COMPILER_PORT (compiler service).
set -euo pipefail

APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON=${IRX_PYTHON:-"$APP_ROOT/.venv/bin/python"}
PORT=${IREXPLORER_PORT:-8000}
CDP_PORT=${IREXPLORER_CDP_PORT:-9239}
COMPILER_PORT=${IREXPLORER_COMPILER_PORT:-8090}
COMPILER_URL="http://127.0.0.1:$COMPILER_PORT"
export IREXPLORER_ORIGIN="http://127.0.0.1:$PORT"
export IREXPLORER_CDP_PORT=$CDP_PORT

if [[ -z "${CHROME:-}" ]]; then
  for candidate in google-chrome google-chrome-stable chromium \
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then CHROME=$candidate; break; fi
  done
fi
[[ -n "${CHROME:-}" ]] || { echo "check_browser: no Chrome found; set CHROME" >&2; exit 2; }

cd "$APP_ROOT"
work=$(mktemp -d "${TMPDIR:-/tmp}/irexplorer-browser.XXXXXX")
server_pid=''
compiler_pid=''
chrome_pid=''
# Something still answering on a port would be checked in place of the code under test.
answering() { curl -sS -o /dev/null "$1" >/dev/null 2>&1; }
stop_server() {
  [[ -n "$server_pid" ]] || return 0
  kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true
  server_pid=''
  if answering "$IREXPLORER_ORIGIN/"; then echo "check_browser: a server still answers on port $PORT after stopping" >&2; return 1; fi
}
stop_compiler() {
  [[ -n "$compiler_pid" ]] || return 0
  kill "$compiler_pid" 2>/dev/null || true; wait "$compiler_pid" 2>/dev/null || true
  compiler_pid=''
  if answering "$COMPILER_URL/"; then echo "check_browser: a compiler service still answers on port $COMPILER_PORT after stopping" >&2; return 1; fi
}
cleanup() {
  stop_server || true
  stop_compiler || true
  if [[ -n "$chrome_pid" ]]; then kill "$chrome_pid" 2>/dev/null || true; wait "$chrome_pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT

wait_for() {
  local url=$1
  for _ in $(seq 1 60); do
    answering "$url" && return 0
    sleep 1
  done
  echo "check_browser: $url did not respond" >&2
  return 1
}

# start_server <collection closed: 0|1> <user programs: 0|1>
start_server() {
  local log="$work/server-closed$1-programs$2.log"
  if answering "$IREXPLORER_ORIGIN/"; then echo "check_browser: port $PORT is already in use" >&2; return 1; fi
  # No subshell: $! must be the server itself, or stop_server kills only a wrapper and leaves it running.
  IREXPLORER_STUDY_DIR="$work/study" IREXPLORER_COLLECTION_MODE=preview \
    IREXPLORER_STUDY_ORIGIN="$IREXPLORER_ORIGIN" IREXPLORER_COLLECTION_CLOSED="$1" \
    IREXPLORER_USER_PROGRAMS="$2" IREXPLORER_COMPILER_URL="$COMPILER_URL" \
    "$PYTHON" -c "from src.backend.api.server import run_server; run_server(port=$PORT)" >"$log" 2>&1 &
  server_pid=$!
  wait_for "$IREXPLORER_ORIGIN/" || { cat "$log" >&2; return 1; }
}

# The compiler service's own code, pointed at the fake toolchain, which replays recorded artefacts.
start_compiler() {
  if answering "$COMPILER_URL/"; then echo "check_browser: port $COMPILER_PORT is already in use" >&2; return 1; fi
  mkdir -p "$work/compiler"
  "$PYTHON" -m src.backend.toolchain.compiler_service --host 127.0.0.1 --port "$COMPILER_PORT" \
    --toolchain tests/fake_toolchain --workspace "$work/compiler" \
    --compiler-image sha256:fake-compiler-image --libc-version fake >"$work/compiler.log" 2>&1 &
  compiler_pid=$!
  wait_for "$COMPILER_URL/" || { cat "$work/compiler.log" >&2; return 1; }
}

"$CHROME" --headless=new --no-first-run --no-default-browser-check --disable-background-networking \
  --user-data-dir="$work/chrome" --remote-debugging-address=127.0.0.1 \
  --remote-debugging-port="$CDP_PORT" about:blank >"$work/chrome.log" 2>&1 &
chrome_pid=$!
wait_for "http://127.0.0.1:$CDP_PORT/json/version"

start_server 0 0
node scripts/check_app.mjs
node scripts/check_study_tasks.mjs
node scripts/check_study_guidance.mjs
stop_server

start_server 1 0
node scripts/check_app.mjs
stop_server

start_compiler
start_server 0 1
node scripts/check_user_programs.mjs
node scripts/check_study_tasks.mjs
node scripts/check_study_guidance.mjs
stop_server
stop_compiler
echo "check_browser: green"
