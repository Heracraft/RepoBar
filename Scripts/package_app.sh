#!/usr/bin/env bash
set -euo pipefail
CONFIGURATION=${1:-debug}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="RepoBar"

log() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

log "==> Building ${APP_NAME} (${CONFIGURATION})"
swift build -c "${CONFIGURATION}"

APP_BUNDLE="${ROOT_DIR}/.build/${CONFIGURATION}/${APP_NAME}.app"
if [ -d "${APP_BUNDLE}" ]; then
  log "Built app at ${APP_BUNDLE}"
else
  fail "App bundle not found (SwiftPM may not have produced a bundle)."
fi
