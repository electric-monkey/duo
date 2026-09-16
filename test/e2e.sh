#!/usr/bin/env bash
# End-to-end run of duo with stub agents: plan → review (1 blocker) → revise →
# converge → build → checks (a planted secret) → fix → re-check → report.
# No network, no tokens. Usage: test/e2e.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin" "$TMP/home/.config/duo" "$TMP/work/app"
cp "$ROOT/test/stubs/agent" "$TMP/bin/claude"
cp "$ROOT/test/stubs/agent" "$TMP/bin/codex"
touch "$TMP/home/.config/duo/onboarded"

cd "$TMP/work/app" || exit 1
git init -q -b main
git config user.email test@duo.local; git config user.name duo-test
echo '{"name":"app","scripts":{"test":"true"}}' > package.json
git add -A && git commit -q -m init

export HOME="$TMP/home" PATH="$TMP/bin:$PATH" NO_COLOR=1
export DUO_LENSES=security,product DUO_SETUP=none DUO_TEST=true DUO_ROUNDS=3 DUO_FIX_ROUNDS=1

printf 'Add a rate limit constant\ny\n' | "${DUO_TEST_BASH:-bash}" "$ROOT/bin/duo" > "$TMP/out.txt" 2>&1
rc=$?

fail=0
expect() { # description, command...
  local what="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok    $what"; else echo "FAIL  $what"; fail=1; fi
}
run="$(ls -dt .duo/2*/ 2>/dev/null | head -1)"
expect "duo exited 0"                         test "$rc" -eq 0
expect "plan converged in round 2"            grep -q '^converged:2$' "${run}loop"
expect "ledger recorded the decision"         jq -e 'length == 1 and .[0].decision == "accepted"' "${run}ledger.json"
expect "plan checks ran"                      jq -e 'length == 3' "${run}plan-checks-product-r1.json"
expect "branch was created"                   git rev-parse --verify -q "duo/$(basename "$run")/all"
expect "secrets check failed in round 1"      jq -e '.[] | select(.name == "secrets" and .result == "fail")' "${run}checks-all-security-r1.json"
expect "secrets check passed after the fix"   jq -e '.[] | select(.name == "secrets" and .result == "pass")' "${run}checks-all-security-r2.json"
expect "fix log says fixed"                   jq -e '.[0].decision == "fixed"' "${run}fixlog-all.json"
expect "task ended clean"                     grep -q '^clean:1$' "${run}fix-all"
expect "report was written"                   grep -q 'Scorecard' "${run}REPORT.md"
expect "no secret on the branch"              bash -c "git show 'duo/$(basename "$run")/all:src/limit.js' > '$TMP/limit.js' && ! grep -q AKIA '$TMP/limit.js'"

if (( fail )); then
  echo; echo "--- duo output ---"; cat "$TMP/out.txt"
  exit 1
fi
echo; echo "e2e passed"
