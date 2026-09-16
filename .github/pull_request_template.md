## What and why

<!-- One or two sentences. Link an issue if there is one. -->

## Checklist

- [ ] `bash test/run-checks.sh` passes
- [ ] `bash test/e2e.sh` passes
- [ ] Works on bash 3.2 (no associative arrays, `mapfile`, `wait -n`, `${var,,}`)

### If this adds or changes a lens check

- [ ] Header has `# duo: severity=...` and a one-line description
- [ ] Fixtures in `test/fixtures/<lens>/<check>/` with at least one `pass-` and one `fail-` case
- [ ] No network calls (or only when relevant files changed, like dependency audits)
- [ ] Never installs anything; skips with a clear reason when a tool is missing
- [ ] Only judges lines this change adds
