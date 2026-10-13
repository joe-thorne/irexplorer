#!/usr/bin/env bash
# Real-compiler smoke check for user programs, run by hand before the demo and before merging; it is not
# part of CI. Needs Docker and the user-programs stack, started from the irexplorer root with
#   docker compose -f compose.user-programs.yaml up -d --build --wait
# and fails at once without them. It runs tests/test_user_programs_smoke.py against the stack, pointing it
# at the compiler service's container, so the module is never skipped: curated parity, each recording in
# tests/data/user-programs against the real toolchain (re-record with scripts/record_user_programs.py),
# and each corpus program's answer from the app, the realistic one within its time.
set -euo pipefail

APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PYTHON=${IRX_PYTHON:-"$APP_ROOT/.venv/bin/python"}
# compose.user-programs.yaml's project and services; scripts/record_user_programs.py's COMPILER_CONTAINER.
COMPILER=irexplorer-user-programs-compiler-1
APP=irexplorer-user-programs-app-1
UP="docker compose -f compose.user-programs.yaml up -d --build --wait"

fail() { echo "check_user_programs: $*" >&2; exit 1; }

docker info >/dev/null 2>&1 || fail "Docker is not running (or not reachable); start it, then: $UP"
for container in "$COMPILER" "$APP"; do
  health=$(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null) ||
    fail "$container does not exist: the user-programs stack is not up; start it with: $UP"
  [[ $health == healthy ]] || fail "$container is not healthy ($health); start the stack with: $UP"
done

cd "$APP_ROOT"
IREXPLORER_SMOKE_COMPILER=$COMPILER IREXPLORER_SMOKE_APP=http://127.0.0.1:8001 \
  "$PYTHON" -m unittest discover -s tests -p test_user_programs_smoke.py -v
