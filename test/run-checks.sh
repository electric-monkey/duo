#!/usr/bin/env bash
# Runs every community lens check against its fixtures.
#
#   test/run-checks.sh                 all checks
#   test/run-checks.sh security        only checks whose "<lens>/<check>" contains "security"
#
# Fixtures live in test/fixtures/<lens>/<check>/<expect>-<name>/ where <expect> is
# pass, fail or skip (exit 0, 1 or 2). A fixture directory may contain:
#   before/          files on the base branch (optional)
#   after/           files after the change, copied over before/
#   PLAN.md          plan text   (plan-phase checks; default: empty)
#   plan.json        plan        (default: {"tasks":[]})
#   task-files.txt   paths the plan lists for the task (default: every changed file)
# In after/ files, __FAKE_AWS_KEY__ is replaced with a generated fake key, so no
# credential-shaped string is ever committed.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LENSES="$ROOT/lenses"
FIXTURES="$ROOT/test/fixtures"
RUN_BASH="${DUO_TEST_BASH:-bash}"
FILTER="${1:-}"
FAKE_KEY="AKIA$(printf 'Q%.0s' $(seq 1 16))"

ok=0; bad=0; missing=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

g()  { printf '\033[32m%s\033[0m' "$*"; }
r()  { printf '\033[31m%s\033[0m' "$*"; }
d()  { printf '\033[2m%s\033[0m' "$*"; }

runner_for() {
  case "$1" in
    *.sh) echo "$RUN_BASH" ;;
    *.py) echo python3 ;;
    *.js|*.mjs|*.cjs) echo node ;;
    *.ts) echo bun ;;
    *) echo "" ;;
  esac
}

pm_for() {
  if   [[ -f "$1/bun.lock" || -f "$1/bun.lockb" ]]; then echo bun
  elif [[ -f "$1/pnpm-lock.yaml" ]]; then echo pnpm
  elif [[ -f "$1/yarn.lock" ]]; then echo yarn
  elif [[ -f "$1/package-lock.json" ]]; then echo npm
  fi
}

build_repo() { # fixture repo
  local fx="$1" repo="$2" f
  mkdir -p "$repo"
  (
    cd "$repo" || exit 1
    git init -q -b main
    git config user.email test@duo.local; git config user.name duo-test
    if [[ -d "$fx/before" ]]; then cp -R "$fx/before/." .; fi
    git add -A; git commit -q --allow-empty -m base
    git checkout -q -b change
    if [[ -d "$fx/after" ]]; then
      cp -R "$fx/after/." .
      grep -rl '__FAKE_AWS_KEY__' . --exclude-dir=.git 2>/dev/null | while read -r f; do
        sed "s/__FAKE_AWS_KEY__/$FAKE_KEY/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      done
    fi
    git add -A; git commit -q --allow-empty -m change
    git diff main...HEAD > "$repo.diff"
    git diff --name-only main...HEAD > "$repo.changed"
  )
  if [[ -f "$fx/task-files.txt" ]]; then cp "$fx/task-files.txt" "$repo.taskfiles"; else cp "$repo.changed" "$repo.taskfiles"; fi
  if [[ -f "$fx/PLAN.md" ]]; then cp "$fx/PLAN.md" "$repo.plan.md"; else : > "$repo.plan.md"; fi
  if [[ -f "$fx/plan.json" ]]; then cp "$fx/plan.json" "$repo.plan.json"; else echo '{"tasks":[]}' > "$repo.plan.json"; fi
}

for check in "$LENSES"/*/checks/*; do
  [[ -f "$check" ]] || continue
  lens="$(basename "$(dirname "$(dirname "$check")")")"
  name="$(basename "$check")"; name="${name%.*}"
  [[ -z "$FILTER" || "$lens/$name" == *"$FILTER"* ]] || continue

  fx_dir="$FIXTURES/$lens/$name"
  cases=()
  for c in "$fx_dir"/*/; do [[ -d "$c" ]] && cases+=("${c%/}"); done
  if (( ${#cases[@]} == 0 )); then
    echo "$(r MISSING)  $lens/$name — add fixtures in test/fixtures/$lens/$name/"
    missing=$((missing + 1)); continue
  fi
  have_fail=0
  phase="$(head -15 "$check" | grep -m1 'duo:' | grep -oE 'phase=[a-z]+' | cut -d= -f2)"
  runner="$(runner_for "$check")"

  for fx in "${cases[@]}"; do
    case_name="$(basename "$fx")"
    expect="${case_name%%-*}"
    case "$expect" in
      pass) want=0 ;;
      fail) want=1; have_fail=1 ;;
      skip) want=2 ;;
      *) echo "$(r BAD)      $lens/$name/$case_name — name must start with pass-, fail- or skip-"; bad=$((bad + 1)); continue ;;
    esac
    repo="$TMP/$lens-$name-$case_name/repo"
    build_repo "$fx" "$repo"
    (
      cd "$repo" || exit 99
      DUO_PHASE="${phase:-code}" DUO_ROOT="$repo" DUO_BASE=main DUO_LIB="$LENSES/_lib" \
      DUO_DIFF="$repo.diff" DUO_CHANGED_FILES="$repo.changed" DUO_TASK_FILES="$repo.taskfiles" \
      DUO_PLAN="$repo.plan.md" DUO_PLAN_JSON="$repo.plan.json" DUO_TASK=/dev/null \
      DUO_PM="$(pm_for "$repo")" DUO_LENS="$lens" DUO_CHECK="$name" DUO_TEST_CMD=true \
      $runner "$check" </dev/null
    ) > "$repo.out" 2>&1
    rc=$?
    if (( rc == want )); then
      echo "$(g ok)       $lens/$name/$case_name $(d "(exit $rc)")"
      ok=$((ok + 1))
    else
      echo "$(r FAIL)     $lens/$name/$case_name — expected exit $want, got $rc"
      sed 's/^/           /' "$repo.out" | tail -15
      bad=$((bad + 1))
    fi
  done
  if (( ! have_fail )) && [[ "$(head -15 "$check" | grep -m1 'duo:')" != *"requires="* ]]; then
    if ! ls "$fx_dir" | grep -q '^skip-' || ls "$fx_dir" | grep -q '^pass-'; then
      echo "$(r MISSING)  $lens/$name — needs at least one fail- fixture"
      missing=$((missing + 1))
    fi
  fi
done

echo
echo "$ok passed · $bad failed · $missing missing"
(( bad == 0 && missing == 0 ))
