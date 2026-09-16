# shellcheck shell=bash
# duo check helpers — source with:  . "$DUO_LIB/diff.sh"
#
# added_lines [path-regex]   → "file<TAB>line<TAB>text" for every line this change adds
# changed_files [path-regex] → files changed by this change that still exist
# issue FILE LINE MESSAGE    → report a finding with a location
# skip MESSAGE               → mark the check as not applicable (exit 2)

added_lines() {
  awk -v f="${1:-.}" '
    /^\+\+\+ / { file = substr($0, 7); next }
    /^--- /    { next }
    /^@@/      { match($0, /\+[0-9]+/); line = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
    /^\\/      { next }
    /^\+/      { if (file ~ f) printf "%s\t%d\t%s\n", file, line, substr($0, 2); line++; next }
    /^-/       { next }
               { line++ }' "$DUO_DIFF"
}

changed_files() {
  local f
  while IFS= read -r f; do
    [[ -f "$DUO_ROOT/$f" ]] || continue
    if [[ -z "${1:-}" ]] || [[ "$f" =~ $1 ]]; then echo "$f"; fi
  done < "$DUO_CHANGED_FILES"
}

issue() { printf '::issue file=%s,line=%s::%s\n' "$1" "$2" "$3"; }
skip()  { echo "$*"; exit 2; }
