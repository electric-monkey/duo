#!/usr/bin/env bash
# duo: severity=should
# Files changed that the plan did not list (scope creep); tests, fixtures and lockfiles are allowed
. "$DUO_LIB/diff.sh"
found=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$f" =~ (test|spec|__tests__|__mocks__|fixtures?|\.snap$|lock|\.lockb$) ]]; then continue; fi
  ok=0
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    p="${p%/}"
    if [[ "$f" == "$p" || "$f" == "$p"/* ]]; then ok=1; break; fi
  done < "$DUO_TASK_FILES"
  if (( ! ok )); then issue "$f" 1 "changed but not in the plan"; found=1; fi
done < "$DUO_CHANGED_FILES"
exit $found
