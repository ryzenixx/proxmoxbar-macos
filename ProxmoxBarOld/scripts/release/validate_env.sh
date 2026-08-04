#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME
require_env VERSION
require_env SPARKLE_PUBLIC_KEY
require_env CODESIGN_IDENTITY

if ! security find-identity -v -p codesigning | grep -F "\"${CODESIGN_IDENTITY}\"" >/dev/null 2>&1; then
  log "Available code-signing identities:"
  security find-identity -v -p codesigning || true
  die "Configured MACOS_CODESIGN_IDENTITY was not found after certificate import."
fi

log "Using signing identity: ${CODESIGN_IDENTITY}"
