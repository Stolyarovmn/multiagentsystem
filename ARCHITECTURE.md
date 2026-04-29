# Architecture

## Design Goal

Build a self-contained framework that separates agent operating rules from target-project code, providing simultaneously:

- a working runtime;
- coherent canonical docs;
- durable continuity;
- generic target integration.

## Layer Model

### 1. Canonical Control Plane

Docs define roles, read order, lifecycle, dispute process and evidence rules.

Files:

- `AGENTS.md`
- `MANIFEST.md`
- `ARCHITECTURE.md`
- `OPERATIONS.md`
- `PRINCIPLES.md`
- `DISPATCH_SPEC.md`
- `DISPUTE.md`
- `STATE.md`

Role:

- defines canon;
- sets read-order;
- records rules and the working model.

### 2. Runtime Layer

Portable bash scripts maintain local file-based IPC:

- `lib/runtime.sh`
- `start.sh`
- `watchdog.sh`
- `coordinator.sh`
- `stop.sh`
- `ws-status.sh`
- `new-task.sh`
- `set-target.sh`
- `smoke-runtime.sh`

Role:

- creates and maintains the live IPC loop;
- delivers dispatch;
- updates state and queue;
- leaves a runtime trail.

### 3. Continuity Layer

Local ignored files store live state:

- `STATE.md`
- `tasks/TASK-*.md`
- `targets/*.local.md`
- `inbox/`
- `outbox/`
- `auditor_logs/*.log`
- `memory/`

Role:

- stores task history;
- records audit evidence;
- provides recovery points after failures.

### 4. Target Layer

Files:

- `targets/README.md`
- `targets/TARGET_TEMPLATE.md`
- `targets/*.md`

Role:

- connects any external repository without copying old conversations;
- describes the active path, baseline, read-order and canon rules for a specific repo.

### 5. GitHub-Native Layer

GitHub issues, pull requests, labels and actions govern changes to this framework. They do not replace the local runtime for target work.

## Runtime Flow

```text
orchestrator
  -> creates TASK-XXX
  -> coordinator extracts dispatch and writes inbox/for-executor.md
  -> watchdog prepends executor role pack and delivers message into tmux
  -> executor writes signals into outbox/for-orchestrator.md
  -> coordinator updates state/task and routes to auditor when needed
  -> watchdog delivers audit dispatch
  -> auditor writes AUDIT PASS or AUDIT FAIL
  -> coordinator closes, retries or escalates
```

## Why Bash + Files + tmux

- routing and retry logic is deterministic, so it should not burn tokens;
- file-based continuity survives crashes better than hidden in-chat state;
- tmux keeps long-lived agent sessions inspectable;
- target-packs separate "how agents work" from "what product they currently touch".

## Boundary

Target repositories do not receive this runtime unless a human explicitly installs it there. A target product can have its own UI, issues and automation; this framework can later have a management UI, but those UIs must not be mixed.

## Non-Goals

- Do not store the full history of a target product inside the control plane.
- Do not create a target-specific runtime for each repository.
- Do not replace repository docs with old chat memory.
