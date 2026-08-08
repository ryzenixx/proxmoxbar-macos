#!/usr/bin/env bash
set -euo pipefail

target="${1:?usage: notarize.sh <path>}"
: "${NOTARY_APPLE_ID:?missing NOTARY_APPLE_ID}"
: "${NOTARY_APP_PASSWORD:?missing NOTARY_APP_PASSWORD}"
: "${NOTARY_TEAM_ID:?missing NOTARY_TEAM_ID}"
timeout="${NOTARY_TIMEOUT:-45m}"

creds=(--apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_APP_PASSWORD" --team-id "$NOTARY_TEAM_ID")

case "$target" in
  *.app)
    payload="${TMPDIR:-/tmp}/$(basename "$target").zip"
    rm -f "$payload"
    ditto -c -k --keepParent "$target" "$payload"
    ;;
  *) payload="$target" ;;
esac

echo "submitting $(basename "$payload") to the notary service"
if ! xcrun notarytool submit "$payload" "${creds[@]}" --wait --timeout "$timeout"; then
  echo "notarization failed, fetching the log"
  id=$(xcrun notarytool history "${creds[@]}" --output-format json \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["history"][0]["id"])')
  xcrun notarytool log "$id" "${creds[@]}" || true
  exit 1
fi

xcrun stapler staple "$target"
xcrun stapler validate "$target"
echo "stapled $(basename "$target")"
