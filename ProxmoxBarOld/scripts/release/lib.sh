#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[release] %s\n' "$*"
}

die() {
  printf '[release] ERROR: %s\n' "$*" >&2
  exit 1
}

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    die "Missing required environment variable: ${name}"
  fi
}
