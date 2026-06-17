#!/usr/bin/env bash
# fork-sync.sh — manual
 helper that mirrors what fork-upstream-sync.
yml does in CI.
#
# Usage:
#   ./scripts/fork
-sync.sh                    # merge upstream 
main into legatus-svg
#   ./scripts/fork-sy
nc.sh --branch NAME      # use a custom sync 
branch name
#   ./scripts/fork-sync.sh --dry-
run          # attempt merge, don't push or P
R
#
# Requires: git, gh (GitHub CLI) authenti
cated with repo access.
#
# What it does:
#  
 1. Switches to legatus-svg.
#   2. Adds upst
ream servo/servo remote (idempotent).
#   3. 
Fetches upstream main.
#   4. Creates a dat
ed sync/auto-YYYY-MM-DD branch off legatus-sv
g.
#   5. Merges upstream/main.
#   6. Auto
-resolves Cargo.lock conflicts by taking upst
ream's lock (servo's
#      own Cargo.lock do
esn't propagate when servo is consumed as a g
it dep).
#   7. On success: pushes the branch
 and opens a PR against legatus-svg.
#   8. O
n other conflicts: stops, prints conflict lis
t, leaves the branch for
#      manual resolu
tion.
#
# Why this exists: the SVG CSS work i
n legatus-svg is small (3 commits) but
# upst
ream servo moves fast (~20 commits/day). Week
ly sync keeps the merge
# trivial; letting it
 slide turns a 5-minute job into a multi-hour
 conflict
# session. The CI workflow automate
s the weekly run; this script is for ad-hoc
#
 local syncs.

set -euo pipefail

UPSTREAM_RE
MOTE="${SERVO_UPSTREAM_REMOTE:-https://github
.com/servo/servo.git}"
UPSTREAM_BRANCH="${SER
VO_UPSTREAM_BRANCH:-main}"
PATCH_BRANCH="${
SERVO_PATCH_BRANCH:-legatus-svg}"
DATE="$(dat
e -u +%Y-%m-%d)"
SYNC_BRANCH="${SERVO_SYNC_BR
ANCH:-sync/auto-$DATE"}"
DRY_RUN=0

while [[ 
$# -gt 0 ]]; do
  case "$1" in
    --branch) 
SYNC_BRANCH="$2"; shift 2 ;;
    --dry-run) D
RY_RUN=1; shift ;;
    -h|--help)
      sed -
n '2,30p' "$0"
      exit 0 ;;
    *) echo "u
nknown arg: $1" >&2; exit 2 ;;
  esac
done

e
cho "==> fork-sync: $UPSTREAM_REMOTE ($UPSTRE
AM_BRANCH) -> $PATCH_BRANCH as $SYNC_BRANCH"


# Ensure we're on the patch branch and up to
 date.
git fetch origin "$PATCH_BRANCH"
git c
heckout -B "$PATCH_BRANCH" "origin/$PATCH_BRA
NCH"

# Ensure upstream remote is configured.

if ! git remote get-url upstream >/dev/null 
2>&1; then
  git remote add upstream "$UPSTRE
AM_REMOTE"
fi
git fetch upstream "$UPSTREAM_B
RANCH"

# Create the sync branch.
git checkou
t -B "$SYNC_BRANCH" "$PATCH_BRANCH"

# Attemp
t the merge.
if ! git merge "upstream/$UPSTRE
AM_BRANCH" --no-edit; then
  echo "==> merge 
produced conflicts:"
  git diff --name-only -
-diff-filter=U | sed 's/^/    /'

  # Auto-re
solve Cargo.lock by taking upstream's version
. Rationale: servo's
  # own Cargo.lock does 
not propagate when servo is consumed as a git
 dep by
  # versoview-shim (each consumer gen
erates its own lock), so this lock only
  # m
atters for standalone servo development. The 
[patch."...servo/stylo"]
  # block in Cargo.t
oml (which redirects stylo crates to ../stylo
-fork for
  # local dev) still wins at build 
time.
  if git diff --name-only --diff-filter
=U | grep -q '^Cargo.lock$'; then
    echo "=
=> auto-resolving Cargo.lock (taking upstream
's)"
    git checkout --theirs Cargo.lock
   
 git add Cargo.lock
  fi

  # If only Cargo.l
ock was conflicting, the merge is now resolva
ble; commit it.
  # Otherwise surface and bai
l.
  if git diff --name-only --diff-filter=U 
| grep -q .; then
    echo "==> non-trivial c
onflicts remain; resolve manually, then:" >&2

    echo "    git commit --no-edit && git pu
sh -u origin $SYNC_BRANCH" >&2
    exit 1
  f
i
  git commit --no-edit
fi

# Compose a shor
t PR body.
UPSTREAM_SHA="$(git rev-parse --sh
ort "upstream/$UPSTREAM_BRANCH")"
AHEAD_BEHIN
D="$(git rev-list --left-right --count "$PATC
H_BRANCH"..."upstream/$UPSTREAM_BRANCH")"
AHE
AD="${AHEAD_BEHIND%% *}"
BEHIND="${AHEAD_BEHI
ND##* }"

echo "==> merge OK: $BEHIND upstrea
m commits behind, $AHEAD local commits preser
ved"
echo "==> upstream HEAD: $UPSTREAM_SHA"


if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "==> 
--dry-run: skipping push + PR"
  exit 0
fi

g
it push -u origin "$SYNC_BRANCH"

gh pr creat
e \
  --repo legatus-ai/servo \
  --base "$PA
TCH_BRANCH" \
  --head "$SYNC_BRANCH" \
  --t
itle "sync: merge upstream servo/servo@$UPSTR
EAM_BRANCH ($BEHIND commits, $DATE)" \
  --bo
dy "Automated by \`scripts/fork-sync.sh\`. Up
stream HEAD: \`$UPSTREAM_SHA\`. See commit lo
g for the per-PR breakdown of what landed ups
tream."

echo "==> done. PR opened against $P
ATCH_BRANCH."


