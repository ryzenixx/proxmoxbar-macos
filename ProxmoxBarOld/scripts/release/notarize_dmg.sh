#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME

dmg_path="${1:-${GITHUB_WORKSPACE}/${APP_NAME}.dmg}"
[ -f "$dmg_path" ] || die "DMG not found: $dmg_path"

require_env CODESIGN_IDENTITY
require_env NOTARY_APPLE_ID
require_env NOTARY_APP_PASSWORD
require_env NOTARY_TEAM_ID

if ! security find-identity -v -p codesigning | grep -F "\"${CODESIGN_IDENTITY}\"" >/dev/null 2>&1; then
  log "Available code-signing identities:"
  security find-identity -v -p codesigning || true
  die "Configured MACOS_CODESIGN_IDENTITY was not found after certificate import."
fi

log "Signing DMG with Developer ID Application identity."
codesign --force --sign "$CODESIGN_IDENTITY" --timestamp --verbose=2 "$dmg_path"
codesign --verify --verbose=2 "$dmg_path"

log "Submitting DMG for notarization using Apple ID credentials."
submit_json="$(xcrun notarytool submit "$dmg_path" \
  --apple-id "$NOTARY_APPLE_ID" \
  --password "$NOTARY_APP_PASSWORD" \
  --team-id "$NOTARY_TEAM_ID" \
  --wait \
  --timeout 30m \
  --output-format json)"

submission_id="$(printf '%s' "$submit_json" | plutil -extract id raw - 2>/dev/null || true)"
status="$(printf '%s' "$submit_json" | plutil -extract status raw - 2>/dev/null || true)"

[ -n "$submission_id" ] || die "Unable to parse notarization submission ID from notarytool output."
[ -n "$status" ] || die "Unable to parse notarization status from notarytool output."

log "Notarization submission: ${submission_id} (status: ${status})"
if [ "$status" != "Accepted" ]; then
  log "Notarization failed with status '${status}'. Fetching detailed notary log..."
  xcrun notarytool log "$submission_id" \
    --apple-id "$NOTARY_APPLE_ID" \
    --password "$NOTARY_APP_PASSWORD" \
    --team-id "$NOTARY_TEAM_ID" || true
  die "Notarization was not accepted. See log above."
fi

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"

spctl_output="$(
  spctl --assess --type open --context context:primary-signature --verbose=4 "$dmg_path" 2>&1
)" || spctl_exit=$?
spctl_exit="${spctl_exit:-0}"
printf '%s\n' "$spctl_output"

if [ "$spctl_exit" -ne 0 ]; then
  if printf '%s' "$spctl_output" | grep -Eqi "Insufficient Context|no usable signature"; then
    log "spctl returned a non-blocking DMG assessment result on this runner; notarization and stapling already succeeded."
  else
    die "spctl assessment failed for ${dmg_path}"
  fi
fi

mount_point="$(mktemp -d "${RUNNER_TEMP}/${APP_NAME}-mount.XXXXXX")"
mounted=0
cleanup_mount() {
  if [ "$mounted" -eq 1 ]; then
    hdiutil detach "$mount_point" -quiet || true
  fi
  rmdir "$mount_point" 2>/dev/null || true
}
trap cleanup_mount EXIT

hdiutil attach "$dmg_path" -nobrowse -readonly -mountpoint "$mount_point" >/dev/null
mounted=1

mounted_app="${mount_point}/${APP_NAME}.app"
[ -d "$mounted_app" ] || die "Expected app not found in mounted DMG: $mounted_app"

app_spctl_output="$(
  spctl --assess --type execute --verbose=4 "$mounted_app" 2>&1
)" || app_spctl_exit=$?
app_spctl_exit="${app_spctl_exit:-0}"
printf '%s\n' "$app_spctl_output"

if [ "$app_spctl_exit" -ne 0 ]; then
  die "spctl assessment failed for app inside DMG: ${mounted_app}"
fi

log "Notarization and stapling succeeded: $dmg_path"
