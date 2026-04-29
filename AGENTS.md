# AGENTS.md

This repository is the canonical operating layer for agents.

If an agent starts in this repository, it must orient by these files, not by hidden chat history or target-project documents.

## Read Order

1. `MANIFEST.md`
2. `ARCHITECTURE.md`
3. `OPERATIONS.md`
4. `PRINCIPLES.md`
5. `EVOLUTION.md`
6. `STATE.md` if it exists; otherwise create it from `STATE.template.md`
7. `targets/README.md` if work touches an external repository
8. the active `targets/<name>.local.md` target-pack if selected
9. the concrete `tasks/TASK-XXX.md` task file if assigned

## Roles

- `orchestrator`: plans work, creates tasks, selects target-packs, handles escalation and closes disputes.
- `executor`: performs the task, verifies locally and emits explicit status signals.
- `auditor`: checks criteria and evidence; it does not silently rewrite executor work.

## Startup Rule

If runtime files are missing, create them without asking the user:

- create `STATE.md` from `STATE.template.md`;
- create `inbox/`, `outbox/`, `tasks/`, `targets/`, `auditor_logs/`, `memory/`, `.locks/`;
- create empty local channel files as needed.

The scripts call the shared bootstrap path automatically. A fresh agent should run `./smoke-runtime.sh` or any runtime command before declaring the system unusable.

## Main Rules

- Keep this repository generic; committed files must not depend on a specific target product.
- Use local target-packs for real target repositories unless a human explicitly asks to publish one.
- Do not copy chat history into task context.
- Every system-level decision leaves an artifact: task, dispute, roadmap entry, issue or PR.
- If a fresh agent cannot continue from committed docs plus local runtime state, continuity is broken.
