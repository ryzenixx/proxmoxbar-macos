#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME

dmg_path="${1:-${GITHUB_WORKSPACE}/${APP_NAME}.dmg}"
[ -f "$dmg_path" ] || die "DMG not found: $dmg_path"

require_env NOTARY_APPLE_ID
require_env NOTARY_APP_PASSWORD
require_env NOTARY_TEAM_ID

log "Submitting DMG for notarization using Apple ID credentials."
xcrun notarytool submit "$dmg_path" \
  --apple-id "$NOTARY_APPLE_ID" \
  --password "$NOTARY_APP_PASSWORD" \
  --team-id "$NOTARY_TEAM_ID" \
  --wait \
  --timeout 30m

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
spctl --assess --type open --verbose=4 "$dmg_path"

log "Notarization and stapling succeeded: $dmg_path"
