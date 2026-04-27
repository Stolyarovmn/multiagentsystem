# Architecture

## Design Goal

Build a self-contained framework that separates agent operating rules from target-project code.

## Layer Model

### Canonical Control Plane

Docs define roles, read order, lifecycle, dispute process and evidence rules.

### Runtime Layer

Portable bash scripts maintain local file-based IPC:

- `lib/runtime.sh`
- `start.sh`
- `stop.sh`
- `watchdog.sh`
- `coordinator.sh`
- `ws-status.sh`
- `new-task.sh`
- `set-target.sh`
- `smoke-runtime.sh`

### Continuity Layer

Local ignored files store live state:

- `STATE.md`
- `tasks/TASK-*.md`
- `targets/*.local.md`
- `inbox/`
- `outbox/`
- `auditor_logs/*.log`
- `memory/`

### GitHub-Native Layer

GitHub issues, pull requests, labels and actions govern changes to this framework. They do not replace the local runtime for target work.

## Boundary

Target repositories do not receive this runtime unless a human explicitly installs it there. A target product can have its own UI, issues and automation; this framework can later have a management UI, but those UIs must not be mixed.
