#!/usr/bin/env bash
# duo: severity=should
# New packages added to any package.json by this change
. "$DUO_LIB/diff.sh"
pkgs="$(changed_files '(^|/)package\.json$')"
[[ -n "$pkgs" ]] || skip "no package.json changes"
found=0
for p in $pkgs; do
  keys='[(.dependencies // {}), (.devDependencies // {}), (.peerDependencies // {})] | add // {} | keys[]'
  before="$(git -C "$DUO_ROOT" show "$DUO_BASE:$p" 2>/dev/null | jq -r "$keys" 2>/dev/null | sort)"
  after="$(jq -r "$keys" "$DUO_ROOT/$p" | sort)"
  added="$(comm -13 <(echo "$before") <(echo "$after") | grep .)"
  if [[ -n "$added" ]]; then issue "$p" 1 "added $(echo "$added" | xargs | sed 's/ /, /g')"; found=1; fi
done
exit $found
