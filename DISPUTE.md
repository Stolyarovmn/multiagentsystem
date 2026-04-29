# DISPUTE Process v4

## When to Open a DISPUTE

Open a formal dispute when there is a conceptual conflict:

- between system documents;
- between rules and actual runtime behavior;
- between the executor's decision and the auditor's;
- between the system and the target-project contract;
- between two equally plausible paths where an arbiter is needed.

Technical failure without conceptual conflict is `BLOCKED`, not a dispute.

## GitHub Form

For framework development, create a `type:dispute` issue.

## Local Form

For local runtime work, create `auditor_logs/DISPUTE-NNN.md`:

```markdown
# DISPUTE-NNN
DATE: YYYY-MM-DD
STATUS: OPEN
INITIATOR: executor | auditor | orchestrator
TOPIC: one-line summary

## Conflict
...

## Position A
...

## Position B
...

## Evidence
- file/path
- file/path

## Resolution
...
```

## Rules

- a dispute without a file does not count as a dispute;
- reopening a dispute on the same topic requires a new fact;
- a closed DISPUTE must produce a follow-up artifact: a docs update, task, issue, PR, or roadmap entry;
- the final arbiter is the orchestrator/human.
