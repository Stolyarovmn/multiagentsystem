# Target Pack: <name>

TARGET_NAME <name>
TARGET_TYPE repo
ACTIVE_REPO /absolute/path/to/active/repo
BASELINE_REPO none

## Purpose

Describe the external repository this local target-pack connects.

## Active Repo

- `/absolute/path/to/active/repo`

## Baseline / Reference

- `none`

## Read-Order For Fresh Agent

1. `README.md`
2. `ROADMAP.md`
3. `CHANGELOG.md` or equivalent
4. project-specific docs required for safe work
5. relevant source, tests and data

## Recovery Anchors

- `/absolute/path/to/recovery/doc.md`

## Canon Rules

- Validate docs against current repository contents.
- Do not import chat history as source of truth.
- Keep product UI and framework management UI separate.

## Known Risks

- Absolute paths are local and must not be committed unless intentionally generalized.
