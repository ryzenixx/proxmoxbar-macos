#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
APP_BUNDLE_PATH="${APP_BUNDLE_PATH:-$PROJECT_ROOT/${APP_NAME}.app}"
DMG_PATH="${DMG_PATH:-$PROJECT_ROOT/${APP_NAME}.dmg}"
DMG_VOLNAME="${DMG_VOLNAME:-${APP_NAME} Installer}"
DMG_FORMAT="${DMG_FORMAT:-UDZO}"
DMG_FS="${DMG_FS:-HFS+}"

require_command hdiutil
require_command ln
require_directory "$APP_BUNDLE_PATH"

rm -f "$DMG_PATH"

staging_dir="$(mktemp -d "$PROJECT_ROOT/.dmg-staging.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT

cp -R "$APP_BUNDLE_PATH" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
  -volname "$DMG_VOLNAME" \
  -srcfolder "$staging_dir" \
  -ov \
  -format "$DMG_FORMAT" \
  -fs "$DMG_FS" \
  "$DMG_PATH" >/dev/null

require_file "$DMG_PATH"
log_success "DMG created at $DMG_PATH"
