# MANIFEST — MultiAgentSystem

## Purpose

`multiagentsystem` is a portable Agentic OS for:

- coordinating AI agents through explicit roles and artifacts;
- preserving continuity without hidden chat state;
- connecting any external repository through a target-pack;
- developing the framework itself through GitHub-native workflow.

## Canon

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

## Working Cycle

```text
orchestrator
  -> creates task
  -> coordinator dispatches to executor
  -> watchdog delivers the message to a live session
  -> executor works and emits DONE, NEEDS_REVIEW or BLOCKED
  -> coordinator routes review or closes/escalates
  -> auditor emits AUDIT PASS or AUDIT FAIL
```

## Success Definition

The system works when:

1. a fresh clone can create its missing local runtime files;
2. scripts run without product-specific paths;
3. a local target-pack can connect an external repository;
4. a task can be created, dispatched and inspected from files;
5. a fresh agent can recover by reading docs, local state, target-pack and task artifacts.
