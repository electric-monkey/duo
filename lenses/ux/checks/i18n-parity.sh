#!/usr/bin/env bash
# duo: severity=should
# Every language file has the same keys (checked when a translation file changed)
. "$DUO_LIB/diff.sh"
changed="$(changed_files '(^|/)(locales?|i18n|lang|messages|translations)/.*\.json$')"
[[ -n "$changed" ]] || skip "no translation files changed"
found=0
for dir in $(echo "$changed" | xargs -n1 dirname | sort -u); do
  files=("$DUO_ROOT/$dir"/*.json)
  (( ${#files[@]} >= 2 )) || { echo "$dir: only one language file"; continue; }
  all="$(for f in "${files[@]}"; do jq -r '[paths(scalars) | map(tostring) | join(".")] | .[]' "$f"; done | sort -u)"
  for f in "${files[@]}"; do
    missing="$(comm -23 <(echo "$all") <(jq -r '[paths(scalars) | map(tostring) | join(".")] | .[]' "$f" | sort -u))"
    if [[ -n "$missing" ]]; then
      rel="${f#$DUO_ROOT/}"
      issue "$rel" 1 "missing $(echo "$missing" | wc -l | tr -d ' ') key(s): $(echo "$missing" | head -5 | xargs | sed 's/ /, /g')"
      found=1
    fi
  done
done
exit $found
