# MultiAgentSystem

`multiagentsystem` is a portable Agentic OS for coordinating AI agents across software projects.

It keeps the operating model separate from any target product:

- this repository defines how agents work;
- target repositories stay focused on their own product;
- live operational state is local by default and is not committed;
- GitHub is used for development of this framework through issues, pull requests, process changes, disputes and checks.

## Quick Start

1. Read `AGENTS.md`.
2. Run `./smoke-runtime.sh`.
3. Optionally copy `config/agents.env.example` to `config/agents.env`.
4. Create a local target-pack as `targets/<name>.local.md`.
5. Activate it with `./set-target.sh targets/<name>.local.md`.
6. Create work with `./new-task.sh "Short task title"`.
7. Inspect health with `./ws-status.sh`.

Agents must create missing runtime files themselves from templates or runtime scripts. Do not ask the user to create `STATE.md`, `inbox/`, `outbox/`, `tasks/`, `targets/`, `auditor_logs/`, or `memory/` when the framework can create them safely.

## Layers

- `canonical control plane`: rules, roles, lifecycle and continuity docs.
- `runtime`: bash/tmux/file IPC scripts for local execution.
- `target layer`: local target-packs that connect external repositories.
- `GitHub-native layer`: issue forms, PR template and hygiene checks for framework development.

## Non-Goals

- Do not store target-product chat history here.
- Do not commit product-specific live state.
- Do not make target project UI part of this framework UI.
- Do not treat GitHub Pages as required for v1.
