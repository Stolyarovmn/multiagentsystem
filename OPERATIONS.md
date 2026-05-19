# Operations Guide

## First Principle

An agent must not ask the user to create missing runtime files. If `STATE.md`, channels, logs, or local runtime folders are absent, create them through the scripts or by applying the documented templates.

## 1. What This Runtime Is

`multiagentsystem` is a file-based IPC layer for multi-agent coordination:

- `watchdog.sh` delivers dispatch files to live agent sessions;
- `coordinator.sh` routes signals, reviews and retries;
- `STATE.md` holds live short-form state;
- `tasks/` stores the recoverable task lifecycle;
- `targets/` connects external repositories via target-packs;
- `auditor_logs/` records critical events and disputes.

## 2. Setup

### Fresh Clone

Run:

```bash
./smoke-runtime.sh
./ws-status.sh
```

Both commands call the shared bootstrap path and create local runtime files as needed.

### Optional: Local Config

```bash
cp config/agents.env.example config/agents.env
```

`config/agents.env` is local and ignored by git. It can be used to:

- change agent session names;
- set executor and auditor launch commands;
- disable auto-cron;
- enable a default target-pack.

### Verify Setup

```bash
./smoke-runtime.sh
./start.sh --dry-run
```

## 3. Starting the Runtime

```bash
./start.sh
./ws-status.sh
```

`start.sh`:

- creates runtime dirs and logs;
- creates or reuses executor and auditor sessions;
- starts `watchdog.sh`;
- adds `coordinator.sh` to cron if auto-cron is enabled;
- activates the default target-pack if configured.

If a local agent CLI is not found automatically, the script still raises a shell session and leaves it ready for manual agent launch.

## 4. Stopping the Runtime

```bash
./stop.sh
```

`stop.sh`:

- stops the watchdog;
- removes the cron entry for this project;
- terminates only the executor/auditor sessions belonging to this runtime.

## 5. Creating a Task

Quick method:

```bash
./new-task.sh "Short task title"
```

Optionally specify a target explicitly:

```bash
./new-task.sh --target my-project "Investigate dashboard index drift"
```

After creating a task:

1. Open the generated `tasks/TASK-XXX.md`;
2. Clarify goal, criteria and context;
3. Check the dispatch envelope;
4. Leave `STATUS QUEUED`.

The coordinator picks up the first `QUEUED` task automatically when no task is active.

## 6. Activating a Target-Pack

If work is tied to a specific repository:

```bash
./set-target.sh targets/<name>.md
```

This updates `STATE.md` and makes the target the current system context.

To clear the target:

```bash
./set-target.sh --clear
```

Create a local target-pack from the template:

```bash
cp targets/TARGET_TEMPLATE.md targets/example.local.md
```

Fill in absolute paths, then activate as above. Local target-packs are ignored by git by default.

## 7. Channels

### inbox

- `inbox/for-executor.md`
- `inbox/for-auditor.md`

### outbox

- `outbox/for-orchestrator.md`
- `outbox/metrics.log`
- `outbox/coordinator.log`
- `outbox/watchdog.log`

## 8. Task Statuses

- `QUEUED`
- `IN_PROGRESS`
- `REVIEW`
- `DONE`
- `BLOCKED`

Retry after audit failure is tracked through task notes and the transition `REVIEW -> IN_PROGRESS`.

## 9. Working with a Target Repository

Before working on a target repository, read:

1. `targets/README.md`
2. The active `targets/<name>.md`
3. `README.md` of the active repository
4. `ROADMAP.md` or equivalent of the active repository
5. Recovery anchors from the target-pack if needed

Key rules:

- Do not carry over old chat history;
- Validate target docs against current repository contents;
- Record significant gaps between code, indexes, reports and docs in task or audit notes.

## 10. Stall Recovery

If a task is stuck:

```bash
./ws-status.sh
tail -40 outbox/coordinator.log
tail -40 outbox/metrics.log
```

If watchdog or sessions are dead:

```bash
./stop.sh
./start.sh
```

## 11. Automation Report Coverage

Check whether the audit/improve layer has fallen behind execution:

```bash
./automation-report-status.sh
./automation-report-status.sh --json
```

For gate-checking in automation:

```bash
./automation-report-status.sh --strict
```

If status is `audit_lag`, an audit loop over the latest execution report must run first. If status is `improvement_lag`, the improve loop must read the latest audit report and create a timestamped improvement report, even if the conclusion is no-op.

A `filename_warning` status means a report with a non-canonical filename exists in `automation_reports/*/`. Such a file does not participate in coverage decisions; the next improve loop must either create a correct canonical report or leave an explicit remediation note. The correct filename format is: `YYYY-MM-DDTHHMMSSZ_<kind>.md`.

## 12. Automation Run Guard

Before performing real execution work, acquire a lock and confirm the report chain is closed:

```bash
./automation-run-guard.sh acquire <lock-name> --require-status ok
trap './automation-run-guard.sh release <lock-name>' EXIT
```

If the guard returns `guard_blocked`, the execution loop must not modify the target repository. In that case, write a short blocker report or wait for the audit/improve loop if the cause is `audit_lag` / `improvement_lag`.

Check lock state:

```bash
./automation-run-guard.sh status <lock-name>
```

A lock older than `AUTOMATION_LOCK_STALE_MIN` minutes is considered stale and may be cleared by the guard automatically. Default value: `45`.

## 13. Automation Hygiene

If subagent/parallel role verification is unavailable due to an external error, the report must explicitly state:

- which role was requested;
- which infrastructure error was received;
- which shell checks replaced independent verification;
- that this is a limitation, not a full independent review.

Automation loops must not run broad scans across the entire workspace without a bounded scope. By default, search only within the active target repository, `multiagentsystem`, or specific recovery anchors from the target-pack.

If a broad search is genuinely required, the report must specify:

- the exact scope;
- why restriction to target-pack paths is insufficient;
- a timeout/cleanup strategy;
- confirmation that no long-running processes remain.

## 14. When to Open a DISPUTE

If the problem is not "a script won't start" but "we disagree on which contract is correct", open a `DISPUTE`.

## 15. What Counts as a Successful Runtime

- `smoke-runtime.sh` is green;
- `start.sh --dry-run` is green;
- `ws-status.sh` sees the runtime;
- a target-pack can be activated without manually rewriting documents;
- a fresh agent understands the read-order without consulting legacy docs.

## 16. Automation Reports Quarantine

`automation_reports/quarantine/` holds files moved there due to format or content errors.

Files in `quarantine/` do not participate in coverage decisions (`automation-report-status.sh` ignores them).

A file ends up in quarantine when:
- it has a `filename_warning` that was not fixed within 2+ cycles;
- the report has a critical structural error (no header, no timestamps, no summary);
- the file is a duplicate with the same timestamp as an existing canonical report.

To recover a file from quarantine:
1. Rename it to canonical format: `YYYY-MM-DDTHHMMSSZ_<kind>.md`;
2. Verify structure (summary, timestamp, conclusions present);
3. Move it back to the appropriate `automation_reports/<kind>s/`;
4. Run `./automation-report-status.sh` to confirm.

## GitHub Workflow

Use GitHub issues for framework tasks and disputes, PRs for changes, and Actions for hygiene checks. GitHub Pages is optional and must be requested explicitly before implementation.

### Target Project GitHub Issues

When a target-pack points to an external GitHub repository, the orchestrator manages issues there with the same artifact discipline:

- Check existing issues before creating new ones — avoid duplicates.
- Sign every comment: `— Роль (Модель)`.
- Write in the language defined by `ISSUE_LANGUAGE` in the target-pack (fallback: README language).
- If a rule has not completed canonical promotion yet, label it as `proposed` / `pending canon` in the issue thread instead of presenting it as accepted framework canon.
- Each issue round must advance to a next artifact or explicit decision.
- Before creating issues: read open issues list first.

### Issue → Artifact Lifecycle

```
open issue
  → discuss (each round: add comment + sign)
  → agree on next artifact type (PR / new issue / TASK / decision)
  → produce artifact
  → link artifact in issue
  → close issue
```

An issue with only comments and no linked artifact is incomplete.

## 18. Issue Quality for AI Agents

An issue that an AI agent will act on must be self-contained. The agent has no session memory — each dispatch starts cold. A vague issue wastes a full cycle.

### Required structure (use template `.github/ISSUE_TEMPLATE/task.md`)

```markdown
## Контекст
What already exists. Which files are relevant. Why this task is needed now.

## Цель
One or two sentences: what must work after this is done.

## Затронутые файлы
- `scripts/build_X.py` — add Y
- `core/paths.py` — add constant Z

## Acceptance criteria
- [ ] `python scripts/X.py` exits 0
- [ ] output appears in `data/reports/`
- [ ] server restarts without errors

## Не входит в scope
What is explicitly excluded from this issue.
```

### Rules

- **No vague goals.** "Реализовать A/B tracker" without acceptance criteria is invalid. An agent cannot know when it is done.
- **Name the files.** Always list affected files. An agent that has to discover them may touch the wrong ones.
- **One issue = one artifact.** Do not bundle unrelated changes. Split into separate issues.
- **Acceptance criteria must be testable.** Each item must be verifiable by running a command or reading a file.
- **State what exists.** If a partial implementation already exists, name the file and function. An agent that does not know this will reimplement from scratch.
- **Scope boundary is mandatory.** The "Не входит в scope" section prevents scope creep across sessions.

### Signs of a bad issue (reject and rewrite)

- Title only, no body
- Body describes a problem but not the expected output
- No file names mentioned
- Acceptance criteria contain words like "работает", "выглядит правильно" without a concrete check
- More than three unrelated changes in one issue
