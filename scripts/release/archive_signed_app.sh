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
export_path="${EXPORT_PATH:-${RUNNER_TEMP}/${APP_NAME}-export}"
export_options_plist="${EXPORT_OPTIONS_PLIST:-${RUNNER_TEMP}/${APP_NAME}-ExportOptions.plist}"
app_path="${export_path}/${APP_NAME}.app"

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

rm -f "$export_options_plist"
/usr/bin/plutil -create xml1 "$export_options_plist"
/usr/bin/plutil -insert method -string developer-id "$export_options_plist"
/usr/bin/plutil -insert signingStyle -string manual "$export_options_plist"
/usr/bin/plutil -insert signingCertificate -string "$CODESIGN_IDENTITY" "$export_options_plist"
if [ -n "${CODESIGN_TEAM_ID:-}" ]; then
  /usr/bin/plutil -insert teamID -string "$CODESIGN_TEAM_ID" "$export_options_plist"
fi

rm -rf "$export_path"
xcodebuild -exportArchive \
  -archivePath "$archive_path" \
  -exportPath "$export_path" \
  -exportOptionsPlist "$export_options_plist"

[ -d "$app_path" ] || die "Exported app not found: $app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"

check_signed_and_timestamped() {
  local signed_item="$1"
  local details

  details="$(codesign --display --verbose=4 "$signed_item" 2>&1 || true)"
  if ! printf '%s' "$details" | grep -qi "Authority=Developer ID Application"; then
    die "Item is not signed with a Developer ID Application certificate: $signed_item"
  fi
  if ! printf '%s' "$details" | grep -qi "Timestamp"; then
    die "Missing trusted timestamp on signature: $signed_item"
  fi
}

check_signed_and_timestamped "$app_path/Contents/MacOS/$APP_NAME"

sparkle_base="$app_path/Contents/Frameworks/Sparkle.framework/Versions/Current"
sparkle_signed_paths=(
  "$sparkle_base/Autoupdate"
  "$sparkle_base/Updater.app/Contents/MacOS/Updater"
  "$sparkle_base/XPCServices/Downloader.xpc/Contents/MacOS/Downloader"
  "$sparkle_base/XPCServices/Installer.xpc/Contents/MacOS/Installer"
)

for signed_path in "${sparkle_signed_paths[@]}"; do
  if [ -e "$signed_path" ]; then
    check_signed_and_timestamped "$signed_path"
  fi
done

log "Archive created: ${archive_path}"
log "Exported app ready: ${app_path}"
