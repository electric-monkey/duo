#!/usr/bin/env bash
# duo: severity=blocking
# Secrets added by this change (built-in patterns, plus gitleaks when installed)
. "$DUO_LIB/diff.sh"
found=0
patterns='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(sk|rk)_live_[0-9A-Za-z]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'
generic='(password|passwd|secret|api[_-]?key|access[_-]?token)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}["'"'"']'
while IFS=$'\t' read -r file line text; do
  [[ -z "$file" ]] && continue
  if echo "$text" | grep -qE "$patterns"; then
    issue "$file" "$line" "looks like a credential ($(echo "$text" | grep -oE "$patterns" | head -1 | cut -c1-6)…)"; found=1
  elif ! [[ "$file" =~ (test|spec|fixture|mock|example|\.md$) ]] && echo "$text" | grep -qiE "$generic"; then
    issue "$file" "$line" "hardcoded secret-like value"; found=1
  fi
done < <(added_lines)
if command -v gitleaks >/dev/null 2>&1; then
  if ! gitleaks detect --no-banner --redact --source "$DUO_ROOT" --log-opts="$DUO_BASE..HEAD" >/tmp/duo-gitleaks.$$ 2>&1; then
    if grep -qi 'leaks found' /tmp/duo-gitleaks.$$; then grep -iE 'finding|file|line' /tmp/duo-gitleaks.$$ | head -20; found=1; fi
  fi
  rm -f /tmp/duo-gitleaks.$$
else
  echo "gitleaks not installed — built-in patterns only (brew install gitleaks)"
fi
exit $found
