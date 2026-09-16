#!/usr/bin/env bash
# duo: severity=nit
# User-facing text written directly in components, in a project that uses translations
. "$DUO_LIB/diff.sh"
uses_i18n=0
if [[ -f "$DUO_ROOT/package.json" ]] && jq -e '[(.dependencies // {}), (.devDependencies // {})] | add | keys | map(select(test("i18n|intl|lingui|polyglot"))) | length > 0' "$DUO_ROOT/package.json" >/dev/null 2>&1; then uses_i18n=1; fi
if ls -d "$DUO_ROOT"/{src/,}{locales,i18n,lang,messages} >/dev/null 2>&1; then uses_i18n=1; fi
(( uses_i18n )) || skip "project has no translation setup"
found=0
while IFS=$'\t' read -r file line text; do
  [[ -z "$file" ]] && continue
  if echo "$text" | grep -qE '>[[:space:]]*[[:alpha:]][^<>{}]{3,}[[:space:]]*<'; then
    issue "$file" "$line" "hardcoded text: $(echo "$text" | grep -oE '>[^<>{}]{4,}<' | head -1 | cut -c2-40)"; found=1
  fi
done < <(added_lines '\.(jsx|tsx|vue|svelte)$')
exit $found
