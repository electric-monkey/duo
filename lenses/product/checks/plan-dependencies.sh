#!/usr/bin/env bash
# duo: severity=nit phase=plan
# Flags plans that add dependencies, so the reason gets checked
hits="$(grep -niE '(npm (i|install)|bun add|pnpm add|yarn add|pip install|new dependenc|add(ing)? (a |the )?(package|library|dependency))' "$DUO_PLAN")"
[[ -z "$hits" ]] && exit 0
echo "plan adds dependencies:"; echo "$hits" | head -5
exit 1
