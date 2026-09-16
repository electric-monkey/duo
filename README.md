# duo

**Codex plans · Claude reviews · git worktrees build.**

Type a task. duo has Codex write a plan and Claude review it, looping until the
review converges (with a decision ledger so settled points aren't re-raised).
You approve the plan, then duo builds it in isolated git worktrees — in
parallel when the tasks are provably independent — runs your tests, and has the
other agent review each diff.

```
duo › add input validation to the photo upload

  ✓ plan          codex     1m52s  1 task(s) · serial
  ● review r1     claude    2m40s  1 blocking · 2 should · 1 nit
  ✓ revise r1     codex     0m58s  14 lines changed · 3 accepted · 0 rejected
  ✓ review r2     claude    1m31s  0 blocking · 0 should · 2 nit
```

## Install

```bash
npm install -g @electricmonkey/duo      # or: bun add -g @electricmonkey/duo
duo doctor                      # checks git, jq, claude, codex
```

Requirements: macOS or Linux, git, jq, [Claude Code](https://docs.claude.com/en/docs/claude-code)
and [Codex CLI](https://github.com/openai/codex), both installed and logged in.
duo uses your existing subscriptions — it has no API keys of its own.

## Use

```bash
cd your-repo
duo                          # interactive session
duo "add refund webhooks"    # one-shot
duo update                   # latest version
```

In a session, `/help` lists every command. The useful ones:

| command | what it does |
|---|---|
| `/config` | show settings |
| `/impl claude\|codex` | who builds (the other reviews) |
| `/rounds N` | max plan/review rounds |
| `/split auto\|prefer\|off` | how eager the planner is to parallelise |
| `/setup`, `/test` | install and test commands (auto-detected) |
| `/save` | keep settings as defaults for this repo |
| `/merge` | merge the last run's branches, then run tests |
| `/clean` | remove duo worktrees and branches |

## How the loop stops

| status | meaning |
|---|---|
| ✓ converged | zero blocking issues |
| ! stalled | the revision changed too little to matter |
| ! deadlock | the planner rejected an issue the reviewer still insists on — you decide |
| ✗ round cap | out of rounds with blockers left |

## Safety

- duo refuses to start with uncommitted changes.
- Planning and review never touch source code. Building happens only in
  worktrees next to your repo (`../<repo>-wt-*`), never in your checkout.
- Nothing is merged without you (`/merge` asks first and stops on conflicts).
- Claude runs with `--permission-mode acceptEdits`; Codex runs with
  `--sandbox workspace-write`. Read what that allows before using duo on code
  you don't trust.
- Run files live in `.duo/` and are ignored via `.git/info/exclude`.

## License

MIT
