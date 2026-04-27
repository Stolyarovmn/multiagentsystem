# Operations

## First Principle

An agent should not ask the user to create missing runtime files. If `STATE.md`, channels, logs or local runtime folders are absent, create them through the scripts or by applying the documented templates.

## Fresh Clone

Run:

```bash
./smoke-runtime.sh
./ws-status.sh
```

Both commands call the shared bootstrap path and create local runtime files as needed.

## Optional Config

```bash
cp config/agents.env.example config/agents.env
```

`config/agents.env` is local and ignored by git.

## Target-Pack Workflow

Create a local target-pack:

```bash
cp targets/TARGET_TEMPLATE.md targets/example.local.md
```

Fill in absolute paths, then activate:

```bash
./set-target.sh targets/example.local.md
```

Local target-packs are ignored by git by default.

## Task Workflow

```bash
./new-task.sh "Short task title"
./ws-status.sh
```

Task files are local operational state unless promoted intentionally.

## Runtime Commands

- `./start.sh --dry-run`: preview local sessions and config.
- `./start.sh`: start tmux sessions and watchdog if dependencies exist.
- `./coordinator.sh`: route queued work and process signals once.
- `./watchdog.sh`: deliver dispatch files to live tmux sessions.
- `./stop.sh`: stop local sessions owned by this runtime.

## GitHub Workflow

Use GitHub issues for framework tasks and disputes, PRs for changes, and Actions for hygiene checks. GitHub Pages is optional and must be requested explicitly before implementation.
