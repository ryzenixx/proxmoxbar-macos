#!/usr/bin/env bash

set -euo pipefail

PIPELINE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$PIPELINE_DIR/lib/common.sh"

APP_NAME="${APP_NAME:-ProxmoxBar}"
VERSION="${VERSION:-0.0.0}"

require_env SPARKLE_PUBLIC_KEY
require_env SPARKLE_PRIVATE_KEY
require_env TAG_NAME

log_info "Running release pipeline for $APP_NAME $VERSION"

"$PIPELINE_DIR/bundle.sh"
"$PIPELINE_DIR/sign.sh"
"$PIPELINE_DIR/package.sh"
"$PIPELINE_DIR/generate_appcast.sh"

require_file "$PROJECT_ROOT/${APP_NAME}.dmg"
require_file "$PROJECT_ROOT/release_assets/appcast.xml"

log_success "Release pipeline completed."
