#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME
require_env TAG_NAME
require_env SPARKLE_TOOLS_VERSION
require_env SPARKLE_PRIVATE_KEY

dmg_path="${1:-${GITHUB_WORKSPACE}/${APP_NAME}.dmg}"
release_assets_dir="${RELEASE_ASSETS_DIR:-${GITHUB_WORKSPACE}/release_assets}"
tools_root="${RUNNER_TEMP}/sparkle-tools/${SPARKLE_TOOLS_VERSION}"
sparkle_archive="${RUNNER_TEMP}/Sparkle-${SPARKLE_TOOLS_VERSION}.tar.xz"
repo_slug="${GITHUB_REPOSITORY:-ryzenixx/proxmoxbar-macos}"
download_url_prefix="https://github.com/${repo_slug}/releases/download/${TAG_NAME}/"
release_notes_url="${RELEASE_NOTES_URL:-https://raw.githubusercontent.com/${repo_slug}/main/RELEASE_NOTES.md}"

[ -f "$dmg_path" ] || die "DMG not found: $dmg_path"

mkdir -p "$tools_root"
curl -fsSL -o "$sparkle_archive" \
  "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_TOOLS_VERSION}/Sparkle-${SPARKLE_TOOLS_VERSION}.tar.xz"
tar -xf "$sparkle_archive" -C "$tools_root"

generate_appcast_bin="$(find "$tools_root" -type f -path '*/bin/generate_appcast' | head -n1 || true)"
[ -n "$generate_appcast_bin" ] || die "Unable to locate generate_appcast binary."
[ -x "$generate_appcast_bin" ] || die "generate_appcast is not executable."

rm -rf "$release_assets_dir"
mkdir -p "$release_assets_dir"
cp "$dmg_path" "$release_assets_dir/"

if [ -f "${GITHUB_WORKSPACE}/RELEASE_NOTES.md" ]; then
  cp "${GITHUB_WORKSPACE}/RELEASE_NOTES.md" "$release_assets_dir/${APP_NAME}.md"
fi

printf '%s' "$SPARKLE_PRIVATE_KEY" | "$generate_appcast_bin" \
  --download-url-prefix "$download_url_prefix" \
  --ed-key-file - \
  "$release_assets_dir"

appcast_path="${release_assets_dir}/appcast.xml"
[ -f "$appcast_path" ] || die "Appcast file not found: $appcast_path"

# Keep a stable release-notes URL for all feed items.
escaped_url="${release_notes_url//\//\\/}"
perl -i -pe "s#<sparkle:releaseNotesLink>[^<]*</sparkle:releaseNotesLink>#<sparkle:releaseNotesLink>${escaped_url}</sparkle:releaseNotesLink>#g" "$appcast_path"

log "Appcast generated in ${release_assets_dir}"
