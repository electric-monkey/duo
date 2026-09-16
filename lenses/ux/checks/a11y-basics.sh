#!/usr/bin/env bash
# duo: severity=should
# Accessibility basics in added markup: alt text, labels, roles, focus, tab order (single-line heuristics)
. "$DUO_LIB/diff.sh"
found=0
while IFS=$'\t' read -r file line text; do
  [[ -z "$file" ]] && continue
  msg=""
  if [[ "$text" == *"<img"* && "$text" != *"alt="* && "$text" == *">"* ]]; then msg="<img> without alt text"
  elif echo "$text" | grep -qE '<(div|span|li)[^>]*on[Cc]lick' && ! echo "$text" | grep -qE 'role=|onKey'; then msg="clickable element without role or keyboard handler — use a <button>"
  elif echo "$text" | grep -qE '<input[^>]*>' && ! echo "$text" | grep -qE 'type=["'"'"']hidden|aria-label|aria-labelledby|id='; then msg="<input> without a label (aria-label or id + <label for>)"
  elif echo "$text" | grep -qE 'tab[Ii]ndex=\{?["'"'"']?[1-9]'; then msg="positive tabIndex breaks the natural tab order"
  elif echo "$text" | grep -qE 'outline:[[:space:]]*(none|0)|outline-none'; then msg="focus outline removed — provide a visible focus style"
  elif echo "$text" | grep -qE '<button[^>]*>[[:space:]]*<(svg|img|Icon)' && ! echo "$text" | grep -q 'aria-label'; then msg="icon-only button without aria-label"
  fi
  if [[ -n "$msg" ]]; then issue "$file" "$line" "$msg"; found=1; fi
done < <(added_lines '\.(jsx|tsx|vue|svelte|html|css|scss)$')
exit $found
