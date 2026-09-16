#!/usr/bin/env bash
# duo: severity=should phase=plan
# The plan states how to verify it is done (acceptance criteria, success criteria, how to test)
if grep -qiE 'acceptance|done when|definition of done|success criteria|how to (test|verify)|verification' "$DUO_PLAN"; then exit 0; fi
echo "PLAN.md has no acceptance / verification section"
exit 1
