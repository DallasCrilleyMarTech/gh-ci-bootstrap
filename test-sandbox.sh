#!/usr/bin/env bash
set -euo pipefail

# Create a temporary org repo, apply gh-ci-bootstrap, push, then delete the repo.
# Usage: KEEP=1 ./test-sandbox.sh   # keep repo for inspection

ORG="DallasCrilleyMarTech"
REPO_NAME="${REPO_NAME:-ci-bootstrap-sandbox-$(date +%s)}"
KEEP="${KEEP:-0}"
DELETE="${DELETE:-1}"

die() { echo "error: $*" >&2; exit 1; }
log() { printf '%s\n' "$*"; }

command -v gh >/dev/null 2>&1 || die "gh CLI required"
gh auth status >/dev/null 2>&1 || die "gh auth required"
if ! gh ci-bootstrap --help >/dev/null 2>&1; then
  die "gh extension install DallasCrilleyMarTech/gh-ci-bootstrap first"
fi

TMPDIR="$(mktemp -d)"
cleanup() {
  if [[ "$KEEP" -ne 1 ]]; then
    rm -rf "$TMPDIR"
  else
    log "keeping workdir: $TMPDIR"
  fi
}
trap cleanup EXIT

log "creating temp repo at $TMPDIR"
cd "$TMPDIR"

git init >/dev/null
git config user.name "gh-ci-bootstrap-sandbox"
git config user.email "gh-ci-bootstrap-sandbox@users.noreply.github.com"

cat >README.md <<EOF
# Sandbox for gh-ci-bootstrap
EOF
git add README.md
git commit -m "chore: initial commit" >/dev/null

log "creating remote repo $ORG/$REPO_NAME"
gh repo create "$ORG/$REPO_NAME" --private --source . --push --confirm >/dev/null

log "running gh ci-bootstrap..."
gh ci-bootstrap --repo "$TMPDIR"
git add .github
git commit -m "chore: add ci bootstrap" >/dev/null
git push origin main >/dev/null
log "pushed bootstrap to $ORG/$REPO_NAME"

if [[ "$KEEP" -ne 1 ]]; then
  if [[ "$DELETE" -eq 1 ]]; then
    log "deleting remote repo $ORG/$REPO_NAME (requires delete_repo scope)"
    if ! gh repo delete "$ORG/$REPO_NAME" --yes >/dev/null 2>&1; then
      log "warning: failed to delete repo (likely missing delete_repo scope). Set KEEP=1 to retain."
    fi
  else
    log "deletion skipped (DELETE=0)"
  fi
else
  log "repo retained: https://github.com/$ORG/$REPO_NAME"
fi
