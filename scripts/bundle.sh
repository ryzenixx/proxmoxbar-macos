#!/bin/bash
set -e

echo "📦 Bundling Application..."

# Cleanup
rm -rf .build
rm -rf ProxmoxBar.app

# Build
swift build -c release --arch arm64

# Define Paths
EXECUTABLE_PATH=".build/arm64-apple-macosx/release/ProxmoxBar"
BUNDLE_PATH="./ProxmoxBar.app"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
MACOS_PATH="$CONTENTS_PATH/MacOS"
FRAMEWORKS_PATH="$CONTENTS_PATH/Frameworks"

# Create Bundle Structure
mkdir -p "$MACOS_PATH"
mkdir -p "$RESOURCES_PATH"
mkdir -p "$FRAMEWORKS_PATH"

# Install Executable
cp "$EXECUTABLE_PATH" "$MACOS_PATH/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_PATH/ProxmoxBar"

# Install Resources (Check if they exist to avoid errors)
if [ -f "Sources/Assets/AppIcon.icns" ]; then
    cp "Sources/Assets/AppIcon.icns" "$RESOURCES_PATH/"
else
    echo "⚠️  Warning: AppIcon.icns not found in Sources/Assets/"
fi

if [ -f "Sources/Assets/MenuBarIcon.png" ]; then
    cp "Sources/Assets/MenuBarIcon.png" "$RESOURCES_PATH/"
else
    echo "⚠️  Warning: MenuBarIcon.png not found in Sources/Assets/"
fi

# Install Sparkle Framework
find .build -name "Sparkle.framework" -exec cp -R {} "$FRAMEWORKS_PATH/" \;
if [ ! -d "$FRAMEWORKS_PATH/Sparkle.framework" ]; then
    echo "❌ CRITICAL ERROR: Sparkle.framework not found. Ensure it is added as a dependency."
    # We exit 0 here for now if the user hasn't added it yet, to allow the script to be saved.
    # But strictly it should fail. The user asked to copy scripts, I assume they will add dep.
    exit 1
fi

# Generate Info.plist
VERSION=${VERSION:-"0.0.0"}

cat > "$CONTENTS_PATH/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ProxmoxBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.proxmoxbar.app</string>
    <key>CFBundleName</key>
    <string>ProxmoxBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/ryzenixx/proxmoxbar-macos/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>${SPARKLE_PUBLIC_KEY}</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>3600</integer>
</dict>
</plist>
EOF

echo "✅ App Bundled Successfully!"
