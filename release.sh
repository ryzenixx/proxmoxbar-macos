#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/common.sh"

VERSION_INPUT="${1:-}"

if [ "$(git branch --show-current)" != "main" ]; then
  log_error "Releases must be created from the main branch."
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  log_error "Working tree is not clean."
  exit 1
fi

if [ -z "$VERSION_INPUT" ]; then
  git fetch --tags
  latest_tag="$(git describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null || echo "none")"
  log_info "Latest tag: $latest_tag"
  read -r -p "Enter next version (e.g. 1.2.0 or v1.2.0): " VERSION_INPUT
fi

if [[ "$VERSION_INPUT" != v* ]]; then
  VERSION_INPUT="v$VERSION_INPUT"
fi

if git rev-parse "$VERSION_INPUT" >/dev/null 2>&1; then
  log_error "Tag already exists: $VERSION_INPUT"
  exit 1
fi

if [[ ! "$VERSION_INPUT" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9]+)?$ ]]; then
  log_error "Version format invalid: $VERSION_INPUT"
  log_info "Expected formats: v1.2.3 or v1.2.3-rc1"
  exit 1
fi

log_info "Creating release tag $VERSION_INPUT"
git tag "$VERSION_INPUT"
git push origin "$VERSION_INPUT"
log_success "Release trigger pushed: $VERSION_INPUT"
