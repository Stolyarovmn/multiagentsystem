# DISPUTE Process

Open a formal dispute when there is a conceptual conflict:

- docs contradict runtime behavior;
- executor and auditor disagree on criteria;
- target contract conflicts with observed target repo state;
- two plausible process paths need a human/orchestrator decision.

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

## Position A

## Position B

## Evidence

## Resolution
```

Closed disputes must produce a follow-up artifact: docs update, task, issue, PR or roadmap entry.
