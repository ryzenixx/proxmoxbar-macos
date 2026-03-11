#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME

dmg_path="${1:-${GITHUB_WORKSPACE}/${APP_NAME}.dmg}"
release_assets_dir="${RELEASE_ASSETS_DIR:-${GITHUB_WORKSPACE}/release_assets}"

[ -f "$dmg_path" ] || die "DMG not found: $dmg_path"
mkdir -p "$release_assets_dir"

shasum -a 256 "$dmg_path" > "${release_assets_dir}/${APP_NAME}.dmg.sha256"

log "Checksum generated: ${release_assets_dir}/${APP_NAME}.dmg.sha256"
