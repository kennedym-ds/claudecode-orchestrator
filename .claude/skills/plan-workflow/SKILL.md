---
name: plan-workflow
description: Structured planning methodology for multi-phase implementation
argument-hint: <objective-description>
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Plan Workflow

## Planning Process

### Phase 1 — Understand
- Clarify the objective: what, why, and for whom
- Identify constraints: time, tech, dependencies, compatibility
- Gather context: read relevant code, docs, prior decisions

### Phase 2 — Decompose
- Break the objective into ordered phases
- Each phase should be completable in one implementation session
- Each phase should be independently verifiable
- Minimize cross-phase dependencies

### Phase 3 — Specify
For each phase, define:
- **Scope:** Files and modules affected
- **Deliverables:** Concrete outputs (code, tests, docs)
- **Acceptance criteria:** Verifiable conditions for completion
- **Risks:** What could go wrong and how to mitigate
- **Model tier:** Which tier (heavy/default/fast) suits this phase's complexity

### Phase 4 — Validate
- Review the plan for gaps, circular dependencies, and missing edge cases
- Confirm success criteria are measurable
- Identify any open questions that need human input
- Estimate relative effort per phase

## Plan Template

Use the template at `docs/templates/plan.md` for consistent formatting.

## Model Tier Recommendations for Phases

| Phase Type | Recommended Tier | Rationale |
|-----------|-----------------|-----------|
| Research/exploration | default | Breadth over depth |
| Architecture design | heavy | Judgment-critical decisions |
| Standard implementation | default | Execution, not judgment |
| Complex algorithm | heavy | Correctness-critical |
| Code review | heavy | Quality gate |
| Documentation | default | Execution task |
| Trivial fix | fast | Minimal reasoning needed |
