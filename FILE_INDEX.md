# FILE_INDEX — Framework Navigation Map

> Navigation index for all canonical framework files.
> Read this first when onboarding to the system or when you need to locate a specific layer.
>
> **Cross-references:** MANIFEST.md · AGENTS.md · OPERATIONS.md

---

## Canonical Core

| File | Purpose | Cross-references |
|------|---------|-----------------|
| `AGENTS.md` | Universal agent startup instructions — read by every agent on session start | MANIFEST.md, OPERATIONS.md |
| `MANIFEST.md` | Why the system exists and how all layers fit together | All core docs |
| `ARCHITECTURE.md` | Runtime and layer design — component diagram, data-flow | MANIFEST.md, OPERATIONS.md |
| `PRINCIPLES.md` | Constitutional rules — non-negotiable constraints for all agents | MANIFEST.md |
| `DISPUTE.md` | Conflict protocol — how disagreements between agents are logged and resolved | auditor_logs/ |
| `DISPATCH_SPEC.md` | Envelope contract — schema for all inter-agent messages | coordinator.sh, lib/runtime.sh |
| `OPERATIONS.md` | Runtime usage — day-to-day commands, task lifecycle | start.sh, coordinator.sh |
| `ROADMAP.md` | System evolution — planned features and milestones | MANIFEST.md |
| `EVOLUTION.md` | Long-term evolution strategy and guiding principles for framework growth | ROADMAP.md, MANIFEST.md |
| `README.md` | Repository overview and quick-start guide | All core docs |
| `STATE.template.md` | Template for the live STATE.md file (created at runtime, not committed) | coordinator.sh |

---

## Runtime Scripts

| File | Purpose |
|------|---------|
| `start.sh` | Bootstrap the full agent runtime |
| `stop.sh` | Graceful shutdown |
| `watchdog.sh` | Monitors agent liveness; restarts stalled agents |
| `coordinator.sh` | Central dispatch loop |
| `ws-status.sh` | Print current workspace status summary |
| `new-task.sh` | Scaffold a new task from `tasks/TASK_TEMPLATE.md` |
| `set-target.sh` | Set or switch the active target project |
| `smoke-runtime.sh` | Lightweight sanity check for the runtime |
| `automation-run-guard.sh` | Mutex lock for automation loops (prevents concurrent runs) |
| `automation-report-status.sh` | Check automation stream alignment (`--json`, `--strict`) |
| `lib/runtime.sh` | Shared shell library used by all runtime scripts |

---

## Agent Role Packs

> Note: agent role files live in each agent's local `.claude/agents/` directory and are not committed to the canonical repo. The canonical role specifications are referenced in `AGENTS.md`.

---

## Task Layer

| File | Purpose |
|------|---------|
| `tasks/README.md` | How to create and manage tasks |
| `tasks/TASK_TEMPLATE.md` | Template for new task files |

---

## Audit Layer

| File | Purpose |
|------|---------|
| `auditor_logs/README.md` | Audit log conventions and retention policy |
| `auditor_logs/events.log` | Created at runtime by the auditor agent; not committed |
| `auditor_logs/DISPUTE-NNN.md` | Per-dispute log files, created as needed |

---

## Target Layer

| File | Purpose |
|------|---------|
| `targets/README.md` | How to register and describe a target project |
| `targets/TARGET_TEMPLATE.md` | Template for new target descriptors |

---

## Memory Layer

| File | Purpose |
|------|---------|
| `memory/README.md` | Memory conventions and directory layout |

---

## Config

| File | Purpose |
|------|---------|
| `config/agents.env.example` | Environment variable template for agent credentials and settings |

---

## Queues (Runtime-created, not committed)

| Path | Purpose |
|------|---------|
| `inbox/` | Inbound message drop-zone (`.gitkeep` placeholder committed) |
| `outbox/` | Outbound message and log output (`.gitkeep` placeholder committed) |
| `outbox/coordinator.log` | Coordinator activity log — created at runtime |
| `outbox/watchdog.log` | Watchdog dispatch delivery log — created at runtime |
| `outbox/metrics.log` | Event log for stall detection — created at runtime |

---

## Automation Reports

| Path | Purpose |
|------|---------|
| `automation_reports/README.md` | Report format conventions |
| `automation_reports/executions/` | Execution reports (`YYYY-MM-DDTHHMMSSZ_execution.md`) — created at runtime |
| `automation_reports/audits/` | Audit reports (`YYYY-MM-DDTHHMMSSZ_audit.md`) — created at runtime |
| `automation_reports/improvements/` | Improvement reports (`YYYY-MM-DDTHHMMSSZ_improvement.md`) — created at runtime |

---

## Decisions

| File | Purpose |
|------|---------|
| `decisions/README.md` | Decision record conventions (ADR-style) |
| `decisions/DECISION_TEMPLATE.md` | Template for new architectural decision records |

---

## Research

| File | Purpose |
|------|---------|
| `research/README.md` | Research document conventions |
| `research/SOURCE_REVIEW_TEMPLATE.md` | Template for source/reference reviews |

---

## Tests

| Path | Purpose |
|------|---------|
| `tests/github_operating_model_test.sh` | Integration test for GitHub operating model |
| `tests/fixtures/` | Test fixture files |

---

## Docs

| Path | Purpose |
|------|---------|
| `docs/github/` | GitHub-specific documentation |

---

## Files absent from this index (local-only)

The following files from local development environments are intentionally excluded from the canonical repo:

- `STATE.md` — live runtime state; created locally by `start.sh`, never committed (use `STATE.template.md`)
- `auditor_logs/events.log` — runtime-generated log
- `outbox/coordinator.log`, `outbox/watchdog.log`, `outbox/metrics.log` — runtime-generated logs
- `.claude/agents/*/agent.md` — agent role files live in each agent's local environment
- Any `automation_reports/executions/`, `audits/`, `improvements/` files — runtime-generated reports

---

*Last updated: 2026-04-29 · Maintained by coordinator agent*
