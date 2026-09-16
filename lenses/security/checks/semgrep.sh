#!/usr/bin/env bash
# duo: severity=blocking
# Your repo's own semgrep rules (.semgrep.yml or .semgrep/) on the changed files
. "$DUO_LIB/diff.sh"
command -v semgrep >/dev/null 2>&1 || skip "semgrep not installed (brew install semgrep)"
rules=""
[[ -f "$DUO_ROOT/.semgrep.yml" ]] && rules="$DUO_ROOT/.semgrep.yml"
[[ -d "$DUO_ROOT/.semgrep" ]] && rules="$DUO_ROOT/.semgrep"
[[ -n "$rules" ]] || skip "no local rules (.semgrep.yml or .semgrep/) — duo does not download rules"
files=(); while IFS= read -r f; do files+=("$f"); done < <(changed_files)
(( ${#files[@]} )) || skip "no changed files"
semgrep scan --config "$rules" --metrics=off --error --quiet --emacs "${files[@]}" 2>&1 | head -40 |
  while IFS= read -r l; do
    if [[ "$l" =~ ^([^:]+):([0-9]+):[0-9]+:(.*)$ ]]; then issue "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"; else echo "$l"; fi
  done
exit "${PIPESTATUS[0]}"
