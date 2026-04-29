# DISPATCH Specification v4

The system intentionally preserves the compatible typed envelope `DISPATCH v2`, using an explicit end marker `END_DISPATCH` inside task files.

## Format

```text
DISPATCH v2
TASK: TASK-NNN
GOAL: one-line goal
CONSTRAINTS: comma-separated flags
BUDGET_TOKENS: 4000
ARTIFACTS:
  - path: /absolute/or/workspace/path
    size_bytes: 123
    sha256: abcdef...
REQUIRED_OUTPUT: {file_path, sha256, summary_1line, status}
DEADLINE: YYYY-MM-DD
END_DISPATCH
```

## Required Fields

- `TASK`
- `GOAL`
- `BUDGET_TOKENS`
- `ARTIFACTS`
- `REQUIRED_OUTPUT`
- `DEADLINE`

## Useful Constraints

- `no_network`
- `readonly`
- `no_delete`
- `no_credentials`
- `requires_review`
- `max_files=N`
- `timeout=Ns`

## Output Contract

### executor

Success with audit request:

```text
SESSION_START agent=executor
ATTEMPT_START task=TASK-001 agent=executor
ARTIFACT_READY task=TASK-001 path=... sha256=...
TASK-001 NEEDS_REVIEW: one-line summary
ATTEMPT_END task=TASK-001 agent=executor status=needs_review
```

Direct completion without audit:

```text
SESSION_START agent=executor
ATTEMPT_START task=TASK-001 agent=executor
TASK-001 DONE: one-line summary
ATTEMPT_END task=TASK-001 agent=executor status=done
```

Blocker:

```text
SESSION_START agent=executor
ATTEMPT_START task=TASK-001 agent=executor
TASK-001 BLOCKED: specific reason
ATTEMPT_END task=TASK-001 agent=executor status=blocked
```

### auditor

```text
SESSION_START agent=auditor
ATTEMPT_START task=TASK-001 agent=auditor
TASK-001 AUDIT PASS
ATTEMPT_END task=TASK-001 agent=auditor status=pass
```

or

```text
SESSION_START agent=auditor
ATTEMPT_START task=TASK-001 agent=auditor
TASK-001 AUDIT FAIL: specific criterion that failed
ATTEMPT_END task=TASK-001 agent=auditor status=fail
```

## Envelope Size

- recommended maximum: `4KB`
- if larger: decompose the task or move context into artifacts

## Artifact Rule

File contents must not be embedded in the envelope if this can be avoided.

Agents reference artifacts by path.
