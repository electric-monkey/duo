#!/usr/bin/env bash
# duo: severity=should phase=plan
# The plan stays small: at most DUO_MAX_PLAN_FILES files (15) and DUO_MAX_PLAN_TASKS tasks (6)
files="$(jq '[.tasks[].files[]] | unique | length' "$DUO_PLAN_JSON")"
tasks="$(jq '.tasks | length' "$DUO_PLAN_JSON")"
echo "$tasks task(s), $files file(s)"
if (( files > ${DUO_MAX_PLAN_FILES:-15} || tasks > ${DUO_MAX_PLAN_TASKS:-6} )); then
  echo "scope is large — consider splitting the task"
  exit 1
fi
