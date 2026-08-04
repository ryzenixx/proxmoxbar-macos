#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env SPARKLE_PUBLIC_KEY

xcodebuild -version
swift --version

xcodebuild \
  -project ProxmoxBar.xcodeproj \
  -scheme ProxmoxBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_KEY}" \
  build test
