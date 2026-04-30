# DECISION: Agent GitHub Comment Rules

## Status

`accepted`

## Date

2026-04-30

## Context

`TASK-007` requires canonicalizing three process rules that currently exist only as local draft edits:

- agents sign target-project GitHub issue comments with `— Роль (Модель)`;
- the comment language follows `ISSUE_LANGUAGE` from the active target-pack;
- the orchestrator creates and delegates `TASK` work instead of performing executor work directly.

Issue [#12](https://github.com/Stolyarovmn/multiagentsystem/issues/12) establishes the recoverability problem around unsigned comments and language drift. Its follow-up comment adds one more requirement: agents must not describe a merely proposed or locally drafted rule as accepted canon in target-project issues.

Issue [#11](https://github.com/Stolyarovmn/multiagentsystem/issues/11) is adjacent: issue threads should move toward an explicit next artifact instead of ending as chat-like discussion. This decision adopts that discipline for target-project issue handling, without trying to resolve the broader proposal scope of `#11`.

Per `EVOLUTION.md`, local edits alone do not make canon. The rule needs an explicit decision artifact before the drafted text in `AGENTS.md` and `OPERATIONS.md` can be treated as canonical.

## Options considered

### Option A

Keep the rules as local session practice only.

Pros:
- no doc churn;
- no additional canon surface.

Cons:
- fresh agents cannot recover the rule set from canon;
- target-project issue comments remain ambiguous about authorship and language;
- local drafts could still be misrepresented as accepted canon.

### Option B

Canonicalize only the comment-signature and language rules.

Pros:
- solves the most visible target-project issue ambiguity;
- smaller documentation change.

Cons:
- leaves the orchestrator/executor boundary implicit;
- keeps a known failure mode where the orchestrator bypasses task delegation;
- does not record the `pending canon` caution for issue comments.

### Option C

Canonicalize all three rules together and place them in both `AGENTS.md` and `OPERATIONS.md`, with a narrow operational note about `pending canon`.

Pros:
- keeps role boundaries and issue behavior recoverable from canon;
- aligns policy (`AGENTS.md`) with workflow guidance (`OPERATIONS.md`);
- prevents target-project comments from overstating proposal status.

Cons:
- slightly increases canon surface;
- overlaps with the broader issue-discipline topic tracked separately in `#11`.

## Decision

Adopt Option C.

The canon now treats the following as accepted framework rules:

1. Agents commenting in target-project GitHub issues sign comments with `— Роль (Модель)`.
2. Comment language follows `ISSUE_LANGUAGE` in the active target-pack; if that field is absent, fall back to the target project's README language.
3. The orchestrator creates `TASK` files, delegates execution, and does not directly perform executor work.
4. When a rule has not yet completed canonical promotion, target-project issue comments must describe it as `proposed` / `pending canon`, not as already accepted canon.
5. Target-project issue discussion must move toward a concrete next artifact or explicit decision, consistent with the narrower scope of this decision.

## Consequences

- `AGENTS.md` carries the normative boundary and target-project issue comment rules.
- `OPERATIONS.md` carries the operational workflow for target-project issue handling.
- `decisions/README.md` indexes this decision.
- `auditor_logs/events.log` records the local artifact trail for the promotion step requested by `TASK-007`.
- Broader framework-wide issue-shaping language proposed in issue `#11` remains a separate follow-up unless accepted independently.

## Related

- Source review: none
- Proposal issue: [#12](https://github.com/Stolyarovmn/multiagentsystem/issues/12)
- Related issue: [#11](https://github.com/Stolyarovmn/multiagentsystem/issues/11)
- Implementation PR: [#13](https://github.com/Stolyarovmn/multiagentsystem/pull/13)
