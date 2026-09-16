# Community lenses

Each folder is a lens: a `LENS.md` (reviewer prompt + checklist) and an optional `checks/` folder with executable checks. They ship with the npm package and are trusted by default, so every change here is reviewed before merge.

## Adding a check

1. Put a script in `lenses/<lens>/checks/`. `.sh`, `.py` (python3), `.js` (node) and `.ts` (bun) are supported; anything else must be executable.
2. Start it with a header:
   ```bash
   #!/usr/bin/env bash
   # duo: severity=should phase=code
   # One line saying what this checks
   ```
   `severity` is `blocking`, `should` or `nit`. `phase` is `code` (default) or `plan`.
3. Exit `0` for pass, `1` for fail, `2` for not applicable (print why).
4. Report locations with `::issue file=path,line=12::message` lines.
5. Source the helpers: `. "$DUO_LIB/diff.sh"` gives you `added_lines`, `changed_files`, `issue` and `skip`.

## Rules

- No network calls, unless the tool's whole job needs one (dependency audits), and then only when relevant files changed.
- Never install anything. If a tool is missing, `skip "tool not installed (brew install tool)"`.
- Stay fast: the default timeout is 180 s.
- Only judge what the change adds. Pre-existing problems are not this change's fault.
- Prefer `should` over `blocking`. `blocking` triggers the fix loop; use it only when a failure is almost certainly real.
- Add fixtures in `test/fixtures/<lens>/<check>/` (at least one `pass-` and one `fail-` case) and run `bash test/run-checks.sh <check>`.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full walkthrough.
