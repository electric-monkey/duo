#!/usr/bin/env bash
# duo: severity=should
# Risky code patterns added by this change: eval, raw HTML, shell/SQL built from strings
. "$DUO_LIB/diff.sh"
found=0
while IFS=$'\t' read -r file line text; do
  [[ -z "$file" ]] && continue
  msg=""
  case "$text" in
    *eval\(*|*"new Function("*)                     msg="dynamic code execution" ;;
    *dangerouslySetInnerHTML*|*.innerHTML*=*|*v-html*) msg="raw HTML insertion (XSS risk)" ;;
    *os.system\(*|*shell=True*)                     msg="shell command execution" ;;
    *pickle.loads*|*"yaml.load("*)                  msg="unsafe deserialization" ;;
  esac
  if [[ -z "$msg" ]] && echo "$text" | grep -qE '(exec|execSync|spawn)\(`|exec\([^)]*\+'; then msg="shell command built from a string"; fi
  if [[ -z "$msg" ]] && echo "$text" | grep -qiE '(select|insert|update|delete)[^;]*(\$\{|" *\+|%s|\.format\()'; then msg="SQL built from a string (injection risk)"; fi
  if [[ -n "$msg" ]]; then issue "$file" "$line" "$msg"; found=1; fi
done < <(added_lines '\.(js|jsx|ts|tsx|mjs|cjs|vue|svelte|py|rb|php)$')
exit $found
