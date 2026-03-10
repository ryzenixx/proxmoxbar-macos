#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
VERSION="${VERSION:-0.0.0}"

require_env SPARKLE_PUBLIC_KEY
require_env SPARKLE_PRIVATE_KEY
require_env TAG_NAME

log_info "Running release pipeline for $APP_NAME $VERSION"

"$SCRIPT_DIR/bundle.sh"
"$SCRIPT_DIR/sign.sh"
"$SCRIPT_DIR/package.sh"
"$SCRIPT_DIR/generate_appcast.sh"

require_file "$PROJECT_ROOT/${APP_NAME}.dmg"
require_file "$PROJECT_ROOT/release_assets/appcast.xml"

log_success "Release pipeline completed."
