# MANIFEST — MultiAgentSystem

## 1. Purpose

`multiagentsystem` is a portable Agentic OS for:

- coordinating AI agents through file-based IPC and explicit roles;
- preserving live task and audit continuity;
- continuing work on any target repository through the target-pack mechanism;
- developing the framework itself through a GitHub-native workflow;
- evolving the system itself without fragmenting into inconsistent documents and scripts.

## 2. Three-Layer Assembly

The system is deliberately assembled from three layers:

1. `continuity layer`
   Live memory, task history, audit evidence and recovery anchors.
2. `runtime/spec layer`
   Formal rules, dispatch, watchdog, coordinator and task contract.
3. `target layer`
   Connecting external repositories through target-packs without copying old chat history.

## 3. Canon

Committed canon:

- `AGENTS.md`
- `MANIFEST.md`
- `ARCHITECTURE.md`
- `OPERATIONS.md`
- `PRINCIPLES.md`
- `DISPATCH_SPEC.md`
- `DISPUTE.md`
- `STATE.template.md`
- `tasks/README.md`
- `tasks/TASK_TEMPLATE.md`
- `targets/README.md`
- `targets/TARGET_TEMPLATE.md`
- runtime scripts and GitHub process files

Local canon during a run:

- `STATE.md`
- `tasks/TASK-*.md`
- `targets/*.local.md`
- `inbox/`
- `outbox/`
- `auditor_logs/*.log`
- `memory/context/*.local.md`

Local canon is ignored by git unless a human explicitly promotes an artifact into the framework.

## 4. Roles and Responsibility

### orchestrator

Responsible for:

- decomposing and creating tasks;
- selecting and activating the target-pack;
- updating `STATE.md`;
- escalations, retries and `DISPUTE`;
- preserving continuity so that a fresh agent can recover from files alone.

### executor

Responsible for:

- completing the task;
- local verification before handoff;
- correct signal contract in `outbox/metrics.log` and `outbox/for-orchestrator.md`;
- reading task artifacts and target context instead of waiting for hidden chat.

### auditor

Responsible for:

- a verifiable audit;
- PASS only on confirmed evidence;
- FAIL only with a specific reason;
- no unauthorized fixing in place of auditing.

## 5. Working Cycle

```text
orchestrator
  -> creates TASK-XXX
  -> coordinator dispatches envelope to inbox/for-executor.md
  -> watchdog delivers it into executor tmux session
  -> executor works and writes NEEDS_REVIEW / DONE / BLOCKED
  -> coordinator updates task/state and routes to auditor when needed
  -> watchdog delivers review context into auditor session
  -> auditor writes AUDIT PASS / AUDIT FAIL
  -> coordinator closes, retries or escalates
```

## 6. Task Model

Each task:

- lives as a separate file `tasks/TASK-XXX.md`;
- has a machine-readable metadata line `STATUS ...`;
- contains a typed dispatch envelope;
- contains enough human context for manual recovery after a failure.

The task file must be simultaneously:

- usable by an agent;
- parseable by the coordinator;
- sufficient for the next attempt without hidden chat memory.

## 7. Target Integration Contract

The system does not store the full history of a target repository internally.

Instead, for each target the following must exist:

- target name;
- active repo path;
- baseline/reference repo path if needed;
- read-order for a fresh agent;
- recovery anchors;
- canon rules for that specific repo.

The contract template is described in `targets/TARGET_TEMPLATE.md`.

## 8. Success Definition

The system works when:

1. `start.sh` brings up the runtime or correctly shows a dry-run;
2. `watchdog.sh` delivers dispatch into live sessions;
3. `coordinator.sh` can route, retry and leave an audit trail;
4. `ws-status.sh` shows the health of the loop;
5. a fresh agent can continue work from canonical system files and a target-pack without old chat history;
6. a fresh clone can create its missing local runtime files;
7. scripts run without product-specific paths;
8. a task can be created, dispatched and inspected from files.

## 9. Evolution Rule

The following changes must not disappear into chat without an artifact.

Permitted forms:

- a new task;
- an entry in `ROADMAP.md`;
- an entry in `auditor_logs/events.log`;
- a new `DISPUTE-XXX.md`;
- a GitHub Issue or Pull Request for framework-level changes.
