#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME

signed_app_tar="${1:-${GITHUB_WORKSPACE}/${APP_NAME}.app.tar.gz}"
dmg_path="${DMG_PATH:-${GITHUB_WORKSPACE}/${APP_NAME}.dmg}"

[ -f "$signed_app_tar" ] || die "Signed app artifact not found: $signed_app_tar"

extract_dir="$(mktemp -d "${RUNNER_TEMP}/${APP_NAME}-signed-app.XXXXXX")"
tar -xzf "$signed_app_tar" -C "$extract_dir"

app_path="${extract_dir}/${APP_NAME}.app"
[ -d "$app_path" ] || die "Extracted app not found: $app_path"

staging_dir="$(mktemp -d "${RUNNER_TEMP}/${APP_NAME}-dmg.XXXXXX")"
cp -R "$app_path" "$staging_dir/"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
  -volname "${APP_NAME} Installer" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  -fs HFS+ \
  "$dmg_path" >/dev/null

log "DMG created: $dmg_path"
