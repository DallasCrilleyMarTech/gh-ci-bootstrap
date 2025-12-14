# gh-ci-bootstrap

Org-only GitHub CLI extension to scaffold Smart CI Router for self-hosted runners with one command.

## Usage

```bash
# publish this repo as DallasCrilleyMarTech/gh-ci-bootstrap, then:
gh extension install DallasCrilleyMarTech/gh-ci-bootstrap

# from a repo under DallasCrilleyMarTech
gh ci-bootstrap --repo /path/to/repo
```

What it does (idempotent unless `--force`):
- Writes `.github/ci-router.yml` with a starter image/commands
- Writes `.github/workflows/ci.yml` pointing to `DallasCrilleyMarTech/.github/.github/workflows/smart-ci.yml@v3`
- Verifies the repo owner is `DallasCrilleyMarTech` (fails otherwise)

Flags:
- `--repo <path>`: target repository (default: current dir)
- `--force`: overwrite existing files
- `--dry-run`: print actions without writing

## Files it creates

`.github/ci-router.yml` (edit to match your stack):
```yaml
environment: image
image: python:3.12-slim

commands:
  ci: |
    pip install -q uv
    uv pip install -r requirements.txt
    pytest -v
```

`.github/workflows/ci.yml`:
```yaml
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: DallasCrilleyMarTech/.github/.github/workflows/smart-ci.yml@v3
    with:
      command: ci
    secrets: inherit
```

## Scope guard

The script refuses to run if `gh repo view` shows the owner is not `DallasCrilleyMarTech`. This keeps it org-only even if someone installs the extension elsewhere.

## Publishing

This extension is developed in the `github-platform` monorepo and automatically published to `DallasCrilleyMarTech/gh-ci-bootstrap` via git subtree.

### Manual publish

```bash
cd packages/workflow-automation/gh-ci-bootstrap
./publish.sh
```

### Automatic publish

Changes to this folder on `main` branch automatically trigger a GitHub Action that publishes to the extension repo.

The workflow requires a PAT secret with write access to `DallasCrilleyMarTech/gh-ci-bootstrap`:
- Org/repo secret: `GH_CI_BOOTSTRAP_PAT`
- Scope: `repo` (or finer-grained equivalent) with permission to push to the target repo

Branch alignment:
- The subtree is pushed to the `main` branch of `DallasCrilleyMarTech/gh-ci-bootstrap`. Ensure that repo’s default branch is `main`.

### Testing after publish

```bash
gh extension install DallasCrilleyMarTech/gh-ci-bootstrap
gh ci-bootstrap --dry-run --repo /path/to/test-repo
```
