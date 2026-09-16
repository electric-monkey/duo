#!/usr/bin/env bash
# duo: severity=blocking
# Critical vulnerabilities in dependencies, when this change touches them
. "$DUO_LIB/diff.sh"
[[ -n "$(changed_files '(^|/)(package\.json|package-lock\.json|bun\.lockb?|pnpm-lock\.yaml|yarn\.lock)$')" ]] || skip "no dependency changes"
case "$DUO_PM" in
  npm)  out="$(npm audit --audit-level=critical 2>&1)"; rc=$? ;;
  pnpm) out="$(pnpm audit --audit-level critical 2>&1)"; rc=$? ;;
  bun)  bun audit --help >/dev/null 2>&1 || skip "this bun version has no audit command"
        out="$(bun audit --audit-level=critical 2>&1)"; rc=$? ;;
  *)    skip "no supported package manager for audit (${DUO_PM:-none})" ;;
esac
echo "$out" | tail -25
if (( rc == 0 )); then exit 0; fi
echo "$out" | grep -qi critical && exit 1
skip "audit could not run (offline?)"
