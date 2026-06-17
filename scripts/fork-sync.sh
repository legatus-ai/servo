#!/usr/bin/env bash
# fork-sync.sh — manual helper that mirrors what fork-upstream-sync.yml does in CI.
#
# Usage:
#   ./scripts/fork-sync.sh                    # merge upstream master into legatus-svg
#   ./scripts/fork-sync.sh --branch NAME      # use a custom sync branch name
#   ./scripts/fork-sync.sh --dry-run          # attempt merge, don't push or PR
#
# Requires: git, gh (GitHub CLI) authenticated with repo access.
#
# What it does:
#   1. Switches to legatus-svg.
#   2. Adds upstream servo/servo remote (idempotent).
#   3. Fetches upstream master.
#   4. Creates a dated sync/auto-YYYY-MM-DD branch off legatus-svg.
#   5. Merges upstream/master.
#   6. Auto-resolves Cargo.lock conflicts by taking upstream's lock (servo's
#      own Cargo.lock doesn't propagate when servo is consumed as a git dep).
#   7. On success: pushes the branch and opens a PR against legatus-svg.
#   8. On other conflicts: stops, prints conflict list, leaves the branch for
#      manual resolution.
#
# Why this exists: the SVG CSS work in legatus-svg is small (3 commits) but
# upstream servo moves fast (~20 commits/day). Weekly sync keeps the merge
# trivial; letting it slide turns a 5-minute job into a multi-hour conflict
# session. The CI workflow automates the weekly run; this script is for ad-hoc
# local syncs.

set -euo pipefail

UPSTREAM_REMOTE="${SERVO_UPSTREAM_REMOTE:-https://github.com/servo/servo.git}"
UPSTREAM_BRANCH="${SERVO_UPSTREAM_BRANCH:-master}"
PATCH_BRANCH="${SERVO_PATCH_BRANCH:-legatus-svg}"
DATE="$(date -u +%Y-%m-%d)"
SYNC_BRANCH="${SERVO_SYNC_BRANCH:-sync/auto-$DATE"}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) SYNC_BRANCH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

echo "==> fork-sync: $UPSTREAM_REMOTE ($UPSTREAM_BRANCH) -> $PATCH_BRANCH as $SYNC_BRANCH"

# Ensure we're on the patch branch and up to date.
git fetch origin "$PATCH_BRANCH"
git checkout -B "$PATCH_BRANCH" "origin/$PATCH_BRANCH"

# Ensure upstream remote is configured.
if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_REMOTE"
fi
git fetch upstream "$UPSTREAM_BRANCH"

# Create the sync branch.
git checkout -B "$SYNC_BRANCH" "$PATCH_BRANCH"

# Attempt the merge.
if ! git merge "upstream/$UPSTREAM_BRANCH" --no-edit; then
  echo "==> merge produced conflicts:"
  git diff --name-only --diff-filter=U | sed 's/^/    /'

  # Auto-resolve Cargo.lock by taking upstream's version. Rationale: servo's
  # own Cargo.lock does not propagate when servo is consumed as a git dep by
  # versoview-shim (each consumer generates its own lock), so this lock only
  # matters for standalone servo development. The [patch."...servo/stylo"]
  # block in Cargo.toml (which redirects stylo crates to ../stylo-fork for
  # local dev) still wins at build time.
  if git diff --name-only --diff-filter=U | grep -q '^Cargo.lock$'; then
    echo "==> auto-resolving Cargo.lock (taking upstream's)"
    git checkout --theirs Cargo.lock
    git add Cargo.lock
  fi

  # If only Cargo.lock was conflicting, the merge is now resolvable; commit it.
  # Otherwise surface and bail.
  if git diff --name-only --diff-filter=U | grep -q .; then
    echo "==> non-trivial conflicts remain; resolve manually, then:" >&2
    echo "    git commit --no-edit && git push -u origin $SYNC_BRANCH" >&2
    exit 1
  fi
  git commit --no-edit
fi

# Compose a short PR body.
UPSTREAM_SHA="$(git rev-parse --short "upstream/$UPSTREAM_BRANCH")"
AHEAD_BEHIND="$(git rev-list --left-right --count "$PATCH_BRANCH"..."upstream/$UPSTREAM_BRANCH")"
AHEAD="${AHEAD_BEHIND%% *}"
BEHIND="${AHEAD_BEHIND##* }"

echo "==> merge OK: $BEHIND upstream commits behind, $AHEAD local commits preserved"
echo "==> upstream HEAD: $UPSTREAM_SHA"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> --dry-run: skipping push + PR"
  exit 0
fi

git push -u origin "$SYNC_BRANCH"

gh pr create \
  --repo legatus-ai/servo \
  --base "$PATCH_BRANCH" \
  --head "$SYNC_BRANCH" \
  --title "sync: merge upstream servo/servo@$UPSTREAM_BRANCH ($BEHIND commits, $DATE)" \
  --body "Automated by \`scripts/fork-sync.sh\`. Upstream HEAD: \`$UPSTREAM_SHA\`. See commit log for the per-PR breakdown of what landed upstream."

echo "==> done. PR opened against $PATCH_BRANCH."
