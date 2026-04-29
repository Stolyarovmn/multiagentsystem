# Tasks v4

## Purpose

A task file must be:

- human-readable;
- recoverable after failure;
- convenient for coordinator parsing;
- sufficient for the next agent without any hidden chat context.

## Naming

- `TASK-001.md`
- `TASK-002.md`
- ...

Template: `tasks/TASK_TEMPLATE.md`

Local task files are ignored by git by default.

## Required Metadata Lines

The following lines must appear at the top of each task file:

```text
STATUS QUEUED
CREATED 2026-04-23T10:00:00Z
AUTHOR orchestrator
TARGET none
```

The coordinator relies on the `STATUS ...` line.

`TARGET` holds the name of the active target-pack, or `none`.

## Statuses

- `QUEUED`
- `IN_PROGRESS`
- `REVIEW`
- `DONE`
- `BLOCKED`

## Dispatch Envelope

Every task must contain an envelope between:

- `DISPATCH v2`
- `END_DISPATCH`

This allows the runtime to extract a machine-readable dispatch without breaking the human-readable sections.

## Recommended Sections

- `## Goal`
- `## Criteria`
- `## Context`
- `## Dispatch Envelope`
- `## Attempt Log`
- `## Audit Notes`

## Continuity Rule

If an audit fail, retry, or manual decision changes the context, that change must be recorded in the task file so that the next attempt does not depend on hidden chat history.

If a task becomes important framework history, promote it to a GitHub issue or an explicit docs artifact.
