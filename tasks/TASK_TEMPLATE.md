# TASK-XXX: <title>

STATUS QUEUED
CREATED <ISO_TIMESTAMP>
AUTHOR orchestrator
TARGET none

## Goal

<one paragraph describing what must be accomplished>

## Criteria

- [ ] criterion 1
- [ ] criterion 2

## Context

- Active repo:         <!-- target project being modified -->
- Baseline repo:       <!-- reference repo, if any -->
- Related docs:        <!-- relevant framework or project docs -->
- Constraints:         <!-- e.g. no_network, readonly -->

## Dispatch Envelope

DISPATCH v2
TASK: TASK-XXX
GOAL: <one-line goal>
CONSTRAINTS: no_credentials,requires_review
BUDGET_TOKENS: 4000
ARTIFACTS:
  - path: <task-file-path>
    size_bytes: <bytes>
    sha256: <sha256>
REQUIRED_OUTPUT: {file_path, sha256, summary_1line, status}
DEADLINE: <YYYY-MM-DD>
END_DISPATCH

## Attempt Log

### v1

- started:
- result:
- note:

## Audit Notes

- none
