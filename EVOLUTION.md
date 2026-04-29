# EVOLUTION — Framework Evolution Protocol

## Purpose

This document defines how `multiagentsystem` adopts external ideas, research findings, and design patterns into its canonical layer.

Without a formal evolution mechanism, good ideas either disappear into chat history or enter canon without review. This protocol ensures every meaningful external input leaves a traceable artifact.

## Read-Order Position

Required reading for all agents. Position in read-order: after `PRINCIPLES.md`, before `OPERATIONS.md`.

An agent that does not know the evolution mechanism will either propose changes chaotically or ignore valuable external ideas.

## The Four Stages

### 1. Intake

External ideas enter via:
- GitHub Issues with label `type:proposal`
- `research/` folder for source-level reviews
- GitHub Discussions (informal only --- no canonical decisions here)

Rule: an idea without a GitHub artifact does not exist in the system.

### 2. Research

For any non-trivial idea:
1. Create a source review file in `research/` using `SOURCE_REVIEW_TEMPLATE.md`
2. Document: source, what it proposes, what fits our model, what conflicts, risk assessment
3. Reference the review from the intake issue

### 3. Decision

Accepted or rejected ideas become decisions:
1. Create a decision file in `decisions/` using `DECISION_TEMPLATE.md`
2. Status: `accepted` or `rejected`
3. Link to source review and intake issue
4. For `accepted`: add implementation tasks

Rule: no external feature enters canon without a decision artifact.

### 4. Promotion

Accepted decisions are promoted into canon via Pull Requests:
- PR must reference the decision file
- PR must reference the source review
- PR must update affected canonical docs (AGENTS.md, OPERATIONS.md, etc.)
- PR must not introduce machine-local paths or product-specific references

## What Goes Into `research/`

Source reviews for:
- external repositories with patterns we might adopt
- articles, papers, or posts that propose architectural approaches
- internal experiments that should be documented before adoption

Format: see `research/SOURCE_REVIEW_TEMPLATE.md`.

## What Goes Into `decisions/`

One file per design decision. Both accepted and rejected decisions are recorded.

Rejected decisions are equally important --- they prevent re-litigating the same ground.

Format: see `decisions/DECISION_TEMPLATE.md`.

## Evolution vs Dispute

Evolution: adopting or rejecting an external pattern.
Dispute: disagreement between agents or roles about an internal framework rule.

Use `type:dispute` issues for disputes. Use `type:proposal` issues for evolution intake.

## Canon Stability Rule

During v5 evolution, existing canon is stable unless:
1. A decision artifact explicitly changes it
2. The change is implemented via PR with review
3. Affected docs are updated in the same PR

Do not patch canon docs in side PRs without a linked decision.
