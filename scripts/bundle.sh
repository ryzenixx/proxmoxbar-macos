#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.proxmoxbar.app}"
VERSION="${VERSION:-0.0.0}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-14.0}"
SPARKLE_PUBLIC_KEY="${SPARKLE_PUBLIC_KEY:-}"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://raw.githubusercontent.com/ryzenixx/proxmoxbar-macos/main/appcast.xml}"

BUILD_DIR="$PROJECT_ROOT/.build"
PRODUCTS_DIR="$BUILD_DIR/apple/Products/Release"
EXECUTABLE_PATH="$PRODUCTS_DIR/$APP_NAME"
APP_ROOT="$PROJECT_ROOT/$APP_BUNDLE/Contents"
MACOS_DIR="$APP_ROOT/MacOS"
RESOURCES_DIR="$APP_ROOT/Resources"
FRAMEWORKS_DIR="$APP_ROOT/Frameworks"

log_info "Bundling $APP_NAME..."

require_command swift
require_command install_name_tool
require_command plutil

cd "$PROJECT_ROOT"
rm -rf "$BUILD_DIR" "$PROJECT_ROOT/$APP_BUNDLE"

swift build -c release --arch arm64 --arch x86_64
require_file "$EXECUTABLE_PATH"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"
cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"

if ! otool -l "$MACOS_DIR/$APP_NAME" | grep -q "@executable_path/../Frameworks"; then
  install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/$APP_NAME"
fi

for asset in AppIcon.icns MenuBarIcon.png; do
  asset_path="$PROJECT_ROOT/Sources/Assets/$asset"
  if [ -f "$asset_path" ]; then
    cp "$asset_path" "$RESOURCES_DIR/"
  else
    log_error "Required asset missing: $asset_path"
    exit 1
  fi
done

sparkle_framework_source="$(find "$BUILD_DIR" -name "Sparkle.framework" -type d | head -n1 || true)"
if [ -z "$sparkle_framework_source" ]; then
  log_error "Sparkle.framework not found in build output."
  exit 1
fi
cp -R "$sparkle_framework_source" "$FRAMEWORKS_DIR/"

if [ -z "$SPARKLE_PUBLIC_KEY" ]; then
  log_info "SPARKLE_PUBLIC_KEY is empty. Auto-update checks will be unavailable for this build."
fi

cat > "$APP_ROOT/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_IDENTIFIER</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>SUEnableAutomaticChecks</key>
  <true/>
  <key>SUFeedURL</key>
  <string>$SPARKLE_FEED_URL</string>
  <key>SUPublicEDKey</key>
  <string>$SPARKLE_PUBLIC_KEY</string>
  <key>SUScheduledCheckInterval</key>
  <integer>3600</integer>
</dict>
</plist>
EOF

plutil -lint "$APP_ROOT/Info.plist" >/dev/null
log_success "App bundle created at $APP_BUNDLE"
