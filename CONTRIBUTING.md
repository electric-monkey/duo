# Contributing to duo

Thanks for helping. Most useful contributions are **lens checks**: small scripts that catch a concrete problem in a diff or a plan. Fixes to `bin/duo` are welcome too.

## Set up

```bash
git clone https://github.com/electric-monkey/duo
cd duo
npm link            # the global `duo` now runs this checkout
duo doctor
```

You don't need Claude Code or Codex to work on duo. The test suite uses stub agents and never calls a model.

## Run the tests

```bash
npm test                              # everything
bash test/run-checks.sh               # every lens check against its fixtures
bash test/run-checks.sh secrets       # one check
bash test/e2e.sh                      # a full duo run with stub agents
shellcheck -S error bin/duo lenses/*/checks/*.sh
```

On macOS, also run with the system bash, since that's what users have:

```bash
DUO_TEST_BASH=/bin/bash /bin/bash test/run-checks.sh
```

CI runs all of this on Ubuntu and on macOS with bash 3.2.

## Add a lens check

1. Create `lenses/<lens>/checks/<name>.sh`:

   ```bash
   #!/usr/bin/env bash
   # duo: severity=should
   # Console.log statements added to production code
   . "$DUO_LIB/diff.sh"
   found=0
   while IFS=$'\t' read -r file line text; do
     [[ -z "$file" ]] && continue
     if [[ "$text" == *console.log* ]]; then issue "$file" "$line" "console.log left in"; found=1; fi
   done < <(added_lines '^src/.*\.(js|ts)x?$')
   exit $found
   ```

2. Add fixtures. Each case is a folder whose name starts with the expected result:

   ```
   test/fixtures/<lens>/<name>/
   ├── pass-clean/after/src/app.ts
   ├── fail-console-log/after/src/app.ts
   └── skip-no-source-change/after/README.md
   ```

   `before/` holds files on the base branch, `after/` the files after the change. Plan checks use `PLAN.md` and `plan.json` instead. Write `__FAKE_AWS_KEY__` wherever you need a credential-shaped string; the harness substitutes a fake one so nothing secret-looking is committed.

3. Run `bash test/run-checks.sh <name>`.

The full contract (exit codes, environment variables, `::issue` lines) is in the README under [Checks](README.md#checks).

### What makes a good check

- It catches something concrete that a reviewer could miss, with a location.
- It only judges lines the change adds. Pre-existing problems aren't this change's fault.
- It's fast and quiet. False positives train people to ignore findings.
- `blocking` only when a failure is almost certainly real. Otherwise `should` or `nit`.
- No network calls, unless the tool's whole job needs one, and then only when relevant files changed.
- Never installs anything. If a tool is missing: `skip "tool not installed (brew install tool)"`.

### Checks that don't belong here

Checks specific to one codebase (your tenant model, your API conventions) belong in that repo's `duo-lenses/` folder, or in your organisation's own lens source. See [Layers](README.md#layers).

## Change bin/duo

- Keep it one file, bash 3.2 compatible: no associative arrays, `mapfile`, `wait -n`, `${var,,}`, or empty arrays under `set -u`.
- No runtime dependencies beyond git and jq.
- Agents produce files; duo produces commits. Validate every file an agent writes before using it.
- Add or extend an assertion in `test/e2e.sh` for behaviour you change.

## Pull requests

- One change per PR. Say what and why in two sentences.
- Every PR needs a passing CI run and a review from a code owner.
- Releases are cut by maintainers; you don't need to bump the version.
