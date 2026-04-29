# Roadmap

## Current Goal

Make `multiagentsystem` the single working canon for multi-agent coordination and for connecting new target repositories.

## P0

- Keep the framework product-neutral.
- Keep runtime bootstrap idempotent.
- Preserve fresh-agent continuity without relying on hidden chat history.
- Keep GitHub process artifacts aligned with local runtime rules.
- Prevent the introduction of new legacy conflicts.

## P1

- Add an end-to-end task lifecycle test covering the full `dispatch -> review -> retry -> done` cycle.
- Add a reusable template for target-packs for new projects.
- Introduce an explicit lifecycle for `canonical / derived / legacy` documents.
- Add optional GitHub Pages management dashboard only after an explicit issue.
- Add richer recovery diagnostics for stale local sessions.

## P2

- Add a human-readable dashboard diff for task/status/events.
- Consider a lightweight index for archived disputes and events.
- Add portable validation for target project contracts.
- Add portable adapters for additional agent CLIs.
- Add generated health reports for framework maintainers.
