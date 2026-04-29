# Multi-Agent Operating System

`multiagentsystem` is a portable Agentic OS for coordinating AI agents across software projects.

It keeps the operating model separate from any target product:

- this repository defines how agents work;
- target repositories stay focused on their own product;
- live operational state is local by default and is not committed;
- GitHub is used for development of this framework through issues, pull requests, process changes, disputes and checks.

It is assembled from three evolutionary sources:

- live continuity and institutional memory from the root workspace;
- a formalized runtime/spec layer;
- a target-oriented product overlay layer.

## Goals

- run a real working loop, not a collection of disconnected rules;
- give a fresh agent a clear read-order and a reproducible runtime;
- allow any new target repository to be connected through a target-pack;
- preserve continuity without depending on old chat history.

## Why GitHub Is Part Of The OS

The local runtime proved that agent work needs explicit state, roles, tasks, audit trails and disputes. The problem is that a purely local control plane makes every fresh agent spend tokens rediscovering the same context: which tasks exist, what changed, what was reviewed, which dispute was resolved and what the current policy is.

GitHub is used here as the durable shared control plane for developing this framework. It gives us native IDs, timelines, review surfaces, status checks, permissions and project views without asking an agent to rebuild those structures from chat history or local logs.

This does not make GitHub the executor. Local runtime still handles fast agent work, tmux sessions, file IPC, target-packs and machine-local state. GitHub handles the shared coordination artifacts that benefit from durability, search, links and review.

## What Moved From Local Runtime To GitHub

For framework development, these responsibilities move from local-only files into GitHub-native surfaces:

- Work intake moves from ad hoc local task files to GitHub Issues created from task forms.
- Formal disputes move from only `auditor_logs/DISPUTE-NNN.md` to `type:dispute` issues with evidence and resolution.
- Review and audit of framework changes move from local audit notes to Pull Requests, review comments, required checks and linked evidence.
- Shared lifecycle visibility moves from only `STATE.md` and task metadata to labels and GitHub Projects.
- Deterministic process checks move from agent-written audit text to GitHub Actions.
- Process changes move from chat decisions to `type:process-change` issues and reviewed PRs.
- Public framework memory moves into versioned docs in this repository instead of hidden chat context.

These local pieces remain local by design:

- `STATE.md`, because it describes one machine's live runtime.
- `targets/*.local.md`, because target paths are machine-specific.
- `tasks/TASK-*.md`, because local execution tasks can be temporary and target-specific.
- `inbox/`, `outbox/`, tmux sessions and logs, because they are runtime transport.
- credentials and environment files, because they must not become artifacts.

## Token Economics

The split saves tokens by moving deterministic coordination out of the model's context window:

- GitHub Issues provide compact, structured task context instead of long chat replay.
- Issue and PR timelines preserve handoff history without requiring agents to summarize every turn.
- Labels and Projects answer "what state is this in?" without scanning all local files.
- Pull request diffs focus review on changed lines instead of full-repository rereads.
- GitHub Actions run repeatable checks with zero LLM tokens.
- Templates reduce prompt size by making required fields predictable.
- Local target-packs keep target context as file references, so dispatch envelopes can point to artifacts instead of embedding content.

The expected economy is simple: humans and agents spend tokens on judgment, design, code and audit; GitHub spends ordinary compute on indexing, status, routing, checks and durable timelines.

## Three Layers

1. `runtime`
   `start.sh`, `watchdog.sh`, `coordinator.sh`, `ws-status.sh`, `stop.sh`.
2. `canonical control plane`
   `AGENTS.md`, `MANIFEST.md`, `ARCHITECTURE.md`, `OPERATIONS.md`, `PRINCIPLES.md`, `DISPATCH_SPEC.md`, `DISPUTE.md`, `STATE.md`.
3. `continuity and targets`
   `tasks/`, `auditor_logs/`, `memory/`, `targets/`.

## Quick Start

1. Read `AGENTS.md`.
2. Run `./smoke-runtime.sh`.
3. Optionally copy `config/agents.env.example` to `config/agents.env`.
4. Create a local target-pack as `targets/<name>.local.md`.
5. Activate it with `./set-target.sh targets/<name>.local.md`.
6. Create work with `./new-task.sh "Short task title"`.
7. Inspect health with `./ws-status.sh`.

Agents must create missing runtime files themselves from templates or runtime scripts. Do not ask the user to create `STATE.md`, `inbox/`, `outbox/`, `tasks/`, `targets/`, `auditor_logs/`, or `memory/` when the framework can create them safely.

## Automation Report Coverage

The autonomous loop writes timestamped reports under `automation_reports/`:

- `execution/` records concrete target-repo work.
- `audit/` records review of execution reports.
- `improvements/` records fixes or no-op decisions made after reading audits.

Use `./automation-report-status.sh` to check whether the streams are aligned. It exits 0 by default for dashboards and human inspection, and `./automation-report-status.sh --strict` exits non-zero when audit or improvement coverage is stale. Automation prompts can use `./automation-report-status.sh --json` for machine-readable routing.

## Read-Order For Fresh Agent

1. `AGENTS.md`
2. `MANIFEST.md`
3. `ARCHITECTURE.md`
4. `OPERATIONS.md`
5. `STATE.md`
6. `targets/README.md` if work touches an external repo
7. active `targets/<name>.md` if one is selected
8. `tasks/TASK-XXX.md`

## What This Project Intentionally Does Not Do

- It does not copy old chat history into itself.
- It does not hardwire one product as the meaning of the system.
- It does not treat legacy docs outside this folder as automatic canon.
- Do not store target-product chat history here.
- Do not commit product-specific live state.
- Do not make target project UI part of this framework UI.
- Do not treat GitHub Pages as required for v1.

Instead it keeps:

- a working runtime;
- coherent constitutional rules;
- a generic target-pack contract;
- durable task and audit continuity;
- a place where future evolution leaves artifacts instead of disappearing into chat.
