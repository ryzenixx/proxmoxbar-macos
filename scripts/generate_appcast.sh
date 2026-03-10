#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
DMG_PATH="${DMG_PATH:-$PROJECT_ROOT/${APP_NAME}.dmg}"
RELEASE_ASSETS_DIR="${RELEASE_ASSETS_DIR:-$PROJECT_ROOT/release_assets}"
SPARKLE_TOOLS_VERSION="${SPARKLE_TOOLS_VERSION:-2.9.0}"

require_env SPARKLE_PRIVATE_KEY
require_env TAG_NAME
require_file "$DMG_PATH"

DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:-https://github.com/ryzenixx/proxmoxbar-macos/releases/download/${TAG_NAME}/}"

resolve_sparkle_bin() {
  local candidates=(
    "$PROJECT_ROOT/.build/artifacts/sparkle/Sparkle/bin"
    "$PROJECT_ROOT/.build/checkouts/Sparkle/bin"
  )

  for candidate in "${candidates[@]}"; do
    if [ -x "$candidate/generate_appcast" ]; then
      echo "$candidate"
      return
    fi
  done

  local tools_dir="$PROJECT_ROOT/sparkle_tools"
  if [ ! -x "$tools_dir/bin/generate_appcast" ]; then
    log_info "Downloading Sparkle tools v$SPARKLE_TOOLS_VERSION..."
    rm -rf "$tools_dir" "$PROJECT_ROOT/sparkle.tar.xz"
    curl -fsSL -o "$PROJECT_ROOT/sparkle.tar.xz" "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_TOOLS_VERSION/Sparkle-$SPARKLE_TOOLS_VERSION.tar.xz"
    mkdir -p "$tools_dir"
    tar -xf "$PROJECT_ROOT/sparkle.tar.xz" -C "$tools_dir"
  fi

  echo "$tools_dir/bin"
}

SPARKLE_BIN="$(resolve_sparkle_bin)"
GENERATE_APPCAST="$SPARKLE_BIN/generate_appcast"

if [ ! -x "$GENERATE_APPCAST" ]; then
  log_error "Sparkle tools not found or not executable."
  exit 1
fi

rm -rf "$RELEASE_ASSETS_DIR"
mkdir -p "$RELEASE_ASSETS_DIR"
cp "$DMG_PATH" "$RELEASE_ASSETS_DIR/"

release_notes_source="$PROJECT_ROOT/RELEASE_NOTES.md"
if [ -f "$release_notes_source" ]; then
  archive_name="$(basename "$DMG_PATH")"
  archive_base="${archive_name%.*}"
  cp "$release_notes_source" "$RELEASE_ASSETS_DIR/$archive_base.md"
fi

log_info "Generating appcast..."
printf '%s' "$SPARKLE_PRIVATE_KEY" | "$GENERATE_APPCAST" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --ed-key-file - \
  "$RELEASE_ASSETS_DIR"

log_success "Appcast generated at $RELEASE_ASSETS_DIR/appcast.xml"
