#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env APP_NAME

export_path="${EXPORT_PATH:-${RUNNER_TEMP}/${APP_NAME}-export}"
app_path="${EXPORTED_APP_PATH:-${export_path}/${APP_NAME}.app}"
output_tar="${OUTPUT_TAR_PATH:-${GITHUB_WORKSPACE}/${APP_NAME}.app.tar.gz}"

[ -d "$app_path" ] || die "Signed app not found: $app_path"

tmp_dir="$(mktemp -d "${RUNNER_TEMP}/${APP_NAME}-signed-app.XXXXXX")"
cp -R "$app_path" "$tmp_dir/"
tar -czf "$output_tar" -C "$tmp_dir" "${APP_NAME}.app"

log "Signed app archived: $output_tar"
