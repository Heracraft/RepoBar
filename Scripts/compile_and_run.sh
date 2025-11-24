#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="RepoBar"
APP_PROCESS_PATTERN="${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

kill_existing() {
  for _ in {1..10}; do
    pkill -f "${APP_PROCESS_PATTERN}" 2>/dev/null || true
    pkill -x "${APP_NAME}" 2>/dev/null || true
    pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null || pgrep -x "${APP_NAME}" >/dev/null || return 0
    sleep 0.2
  done
}

log "==> Killing existing ${APP_NAME} instances"
kill_existing

log "==> swift build"
swift build -q

log "==> swift test"
swift test -q

log "==> Launching debug build"
"${ROOT_DIR}/.build/debug/${APP_NAME}" &

sleep 1
if pgrep -f "${APP_PROCESS_PATTERN}" >/dev/null 2>&1 || pgrep -x "${APP_NAME}" >/dev/null 2>&1; then
  log "OK: ${APP_NAME} is running."
else
  fail "App exited immediately."
fi
