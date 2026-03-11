#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env TAG_NAME
require_env VERSION
require_env GITHUB_REPOSITORY
require_env GH_TOKEN

dmg_path="${1:-release_bundle/ProxmoxBar.dmg}"
sha_path="${2:-release_bundle/release_assets/ProxmoxBar.dmg.sha256}"

[ -f "$dmg_path" ] || die "Missing DMG artifact: $dmg_path"
[ -f "$sha_path" ] || die "Missing checksum artifact: $sha_path"

if gh release view "$TAG_NAME" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  gh release upload "$TAG_NAME" "$dmg_path" "$sha_path" --clobber --repo "$GITHUB_REPOSITORY"
else
  gh release create "$TAG_NAME" \
    "$dmg_path" \
    "$sha_path" \
    --repo "$GITHUB_REPOSITORY" \
    --title "ProxmoxBar $VERSION" \
    --verify-tag \
    --generate-notes
fi

log "GitHub release published for ${TAG_NAME}"
