#!/usr/bin/env bash
# duo: severity=nit
# TODO / FIXME / HACK comments added by this change
. "$DUO_LIB/diff.sh"
found=0
while IFS=$'\t' read -r file line text; do
  [[ -z "$file" ]] && continue
  if echo "$text" | grep -qE '(^|[^A-Za-z])(TODO|FIXME|XXX|HACK)([^A-Za-z]|$)'; then issue "$file" "$line" "$(echo "$text" | grep -oE '(TODO|FIXME|XXX|HACK).*' | cut -c1-80)"; found=1; fi
done < <(added_lines)
exit $found
