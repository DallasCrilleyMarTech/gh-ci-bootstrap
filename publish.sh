#!/usr/bin/env bash
set -euo pipefail

# Publish script for gh-ci-bootstrap extension
# Mirrors packages/workflow-automation/gh-ci-bootstrap/ to DallasCrilleyMarTech/gh-ci-bootstrap

REPO_ROOT="$(git rev-parse --show-toplevel)"
SUBDIR="packages/workflow-automation/gh-ci-bootstrap"
# Allow override via env var (useful for CI with HTTPS token)
TARGET_REPO="${TARGET_REPO:-git@github.com:DallasCrilleyMarTech/gh-ci-bootstrap.git}"
BRANCH="gh-ci-bootstrap-publish"
TARGET_BRANCH="main"

cd "$REPO_ROOT"

# Verify we're in the right repo
if ! git remote get-url origin | grep -q "github-platform"; then
  echo "error: not in github-platform repo" >&2
  exit 1
fi

# Verify subdir exists
if [[ ! -d "$SUBDIR" ]]; then
  echo "error: subdir not found: $SUBDIR" >&2
  exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- "$SUBDIR"; then
  echo "warning: uncommitted changes in $SUBDIR" >&2
  echo "commit changes before publishing" >&2
  exit 1
fi

# Avoid printing tokenized URLs when using HTTPS
if [[ "$TARGET_REPO" == https://* ]]; then
  echo "Publishing $SUBDIR to remote (HTTPS, redacted)..."
else
  echo "Publishing $SUBDIR to $TARGET_REPO..."
fi

sanitize_remote() {
  echo "$1" | sed 's#https://[^@]*@github.com#https://***@github.com#g'
}

# Split subtree into temporary branch
git subtree split --prefix="$SUBDIR" -b "$BRANCH" || {
  echo "error: git subtree split failed" >&2
  exit 1
}

# Push to target repo (sanitize output to avoid leaking tokens)
push_output=$(git -c http.extraheader= -c http.https://github.com/.extraheader= \
  push "$TARGET_REPO" "$BRANCH:$TARGET_BRANCH" --force 2>&1) || {
  echo "error: git push failed" >&2
  echo "$(sanitize_remote "$push_output")" >&2
  git branch -D "$BRANCH" 2>/dev/null || true
  exit 1
}

# Clean up local branch
git branch -D "$BRANCH" 2>/dev/null || true

echo "✓ Published to $(sanitize_remote "$TARGET_REPO") (branch: $TARGET_BRANCH)"
