#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

tag_name="${INPUT_TAG:-}"
if [ -z "$tag_name" ]; then
  tag_name="${GITHUB_REF_NAME:-}"
fi
[ -n "$tag_name" ] || die "Unable to resolve release tag."

if [[ ! "$tag_name" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "Tag '$tag_name' is not supported (expected vX.Y.Z)."
fi

git fetch origin main --tags --force

if ! git rev-parse "refs/tags/$tag_name" >/dev/null 2>&1; then
  die "Tag '$tag_name' does not exist in this repository."
fi

tag_sha="$(git rev-list -n 1 "refs/tags/$tag_name")"
if ! git merge-base --is-ancestor "$tag_sha" "origin/main"; then
  die "Tag '$tag_name' is not on origin/main history."
fi

version="${tag_name#v}"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "tag_name=$tag_name"
    echo "version=$version"
  } >> "$GITHUB_OUTPUT"
fi

log "Resolved tag: $tag_name"
log "Resolved version: $version"
