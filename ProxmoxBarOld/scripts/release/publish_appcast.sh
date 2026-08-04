#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/release/lib.sh
source "${SCRIPT_DIR}/lib.sh"

require_env TAG_NAME

appcast_path="${1:-release_bundle/release_assets/appcast.xml}"
[ -f "$appcast_path" ] || die "appcast.xml missing from artifact bundle."

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git fetch origin main develop

main_worktree="$(mktemp -d)"
develop_worktree="$(mktemp -d)"
cleanup() {
  git worktree remove "$main_worktree" --force >/dev/null 2>&1 || true
  git worktree remove "$develop_worktree" --force >/dev/null 2>&1 || true
}
trap cleanup EXIT

git worktree add "$main_worktree" origin/main
cp "$appcast_path" "$main_worktree/appcast.xml"

(
  cd "$main_worktree"
  git add appcast.xml
  if git diff --quiet --cached; then
    log "No appcast changes to publish on main."
  else
    git commit -m "chore(release): update appcast for ${TAG_NAME}"
    git push origin HEAD:main
  fi
)

git worktree add "$develop_worktree" origin/develop
(
  cd "$develop_worktree"
  git fetch origin main develop
  if git merge-base --is-ancestor origin/main HEAD; then
    log "develop already contains origin/main."
  else
    git merge --no-edit origin/main
    git push origin HEAD:develop
  fi
)

log "appcast.xml synced to main and develop"
