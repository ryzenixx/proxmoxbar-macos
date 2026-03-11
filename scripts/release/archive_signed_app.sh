#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME
require_env VERSION
require_env SPARKLE_PUBLIC_KEY
require_env CODESIGN_IDENTITY

archive_path="${ARCHIVE_PATH:-${RUNNER_TEMP}/${APP_NAME}.xcarchive}"
app_path="${archive_path}/Products/Applications/${APP_NAME}.app"

xcodebuild \
  -project ProxmoxBar.xcodeproj \
  -scheme ProxmoxBar \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$archive_path" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$VERSION" \
  SPARKLE_PUBLIC_ED_KEY="$SPARKLE_PUBLIC_KEY" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY" \
  archive

[ -d "$app_path" ] || die "Archived app not found: $app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"

sig_details="$(codesign --display --verbose=4 "$app_path/Contents/MacOS/$APP_NAME" 2>&1 || true)"
if ! printf '%s' "$sig_details" | grep -qi "Timestamp"; then
  die "Missing trusted timestamp on app signature."
fi
if ! printf '%s' "$sig_details" | grep -qi "runtime"; then
  die "Missing hardened runtime on app signature."
fi

log "Archive created: ${archive_path}"
