#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
APP_BUNDLE_PATH="${APP_BUNDLE_PATH:-$PROJECT_ROOT/${APP_NAME}.app}"
FRAMEWORKS_PATH="$APP_BUNDLE_PATH/Contents/Frameworks"
SPARKLE_FRAMEWORK="$FRAMEWORKS_PATH/Sparkle.framework"

require_command security
require_command codesign
require_directory "$APP_BUNDLE_PATH"
require_directory "$SPARKLE_FRAMEWORK"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  SIGNING_IDENTITY="$CODESIGN_IDENTITY"
else
  SIGNING_IDENTITY="$(security find-identity -v -p codesigning | grep 'Developer ID Application' | head -n1 | sed -E 's/.*"(.+)".*/\1/' || true)"
  if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY="$(security find-identity -v -p codesigning | head -n1 | sed -E 's/.*"(.+)".*/\1/' || true)"
  fi
fi

if [ -z "$SIGNING_IDENTITY" ]; then
  log_error "No signing identity found."
  security find-identity -v -p codesigning || true
  exit 1
fi

log_info "Signing with identity: $SIGNING_IDENTITY"

sign_item() {
  local item="$1"
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$item"
}

autoupdate_binary="$(find "$SPARKLE_FRAMEWORK" -name Autoupdate -type f | head -n1 || true)"
if [ -z "$autoupdate_binary" ]; then
  log_error "Sparkle Autoupdate binary not found."
  exit 1
fi
sign_item "$autoupdate_binary"

updater_app="$(find "$SPARKLE_FRAMEWORK" -name Updater.app -type d | head -n1 || true)"
if [ -n "$updater_app" ]; then
  sign_item "$updater_app/Contents/MacOS/Updater"
  sign_item "$updater_app"
fi

while IFS= read -r xpc; do
  [ -z "$xpc" ] && continue
  sign_item "$xpc"
done < <(find "$SPARKLE_FRAMEWORK" -name '*.xpc' -type d 2>/dev/null)

sign_item "$SPARKLE_FRAMEWORK"
sign_item "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME"
sign_item "$APP_BUNDLE_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE_PATH"

signature_details="$(codesign --display --verbose=4 "$APP_BUNDLE_PATH/Contents/MacOS/$APP_NAME" 2>&1 || true)"
if ! printf '%s' "$signature_details" | grep -qi "Timestamp"; then
  log_error "Code signature is missing a trusted timestamp."
  exit 1
fi
if ! printf '%s' "$signature_details" | grep -qi "runtime"; then
  log_error "Hardened runtime flag is missing from main executable signature."
  exit 1
fi

log_success "Signing completed for $APP_BUNDLE_PATH"
