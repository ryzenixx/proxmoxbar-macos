#!/usr/bin/env bash

set -euo pipefail

COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$COMMON_LIB_DIR/../.." && pwd)"

log_info() {
  printf 'ℹ️  %s\n' "$*"
}

log_success() {
  printf '✅ %s\n' "$*"
}

log_error() {
  printf '❌ %s\n' "$*" >&2
}

require_command() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    log_error "Required command not found: $command_name"
    exit 1
  fi
}

require_env() {
  local env_name="$1"
  if [ -z "${!env_name:-}" ]; then
    log_error "Required environment variable is missing: $env_name"
    exit 1
  fi
}

require_file() {
  local path="$1"
  if [ ! -e "$path" ]; then
    log_error "Required file not found: $path"
    exit 1
  fi
}

require_directory() {
  local path="$1"
  if [ ! -d "$path" ]; then
    log_error "Required directory not found: $path"
    exit 1
  fi
}
