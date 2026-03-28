---
name: delegation-routing
description: Complexity-based task routing with model tier selection
argument-hint: <task-description>
user-invocable: false
---

# Delegation Routing

## Complexity Assessment

Evaluate the task against these criteria to determine the routing tier:

| Signal | INSTANT | STANDARD | DEEP | ULTRADEEP |
|--------|---------|----------|------|-----------|
| Files affected | 0-1 | 1-3 | 3-10 | 10+ |
| Test changes | None | Unit tests | Unit + integration | Unit + integration + e2e |
| Architectural impact | None | Local | Cross-module | System-wide |
| Security sensitivity | None | Low | Medium | High |
| Risk of regression | Negligible | Low | Medium | High |
| Estimated changes | < 20 lines | 20-100 lines | 100-500 lines | 500+ lines |

## Routing Decisions

### INSTANT (Fast tier)
- Typo fixes, comment updates, config tweaks
- Direct response — no subagent delegation
- Model tier: **fast** (Haiku 4.5)

### STANDARD (Default tier)
- Single-file feature, straightforward bug fix
- Workflow: Planner → Implementer → Reviewer
- Pause after: plan creation
- Model tiers: **default** for all agents

### DEEP (Mixed tiers)
- Multi-file feature, refactor, new API endpoint
- Workflow: Researcher → Planner → Implementer → Reviewer → Security-Reviewer
- Pause after: plan creation, review completion
- Model tiers: **default** for implementation, **heavy** for review + planning

### ULTRADEEP (Heavy tier dominant)
- Architectural change, security-critical, public API change
- Workflow: Researcher → Planner → Implementer → Trilateral Review (Reviewer + Security-Reviewer + Red-Team)
- Pause after: plan creation, each review phase
- Model tiers: **heavy** for all judgment roles, **default** for implementation

## Escalation Rules

- If a STANDARD task reveals cross-module impact during implementation → escalate to DEEP
- If a DEEP task involves PII, auth, or payment → escalate to ULTRADEEP
- If an ULTRADEEP trilateral review produces conflicting verdicts → pause for human decision
- Never de-escalate without explicit human approval

## Model Tier Quick Reference

| Agent | INSTANT | STANDARD | DEEP | ULTRADEEP |
|-------|---------|----------|------|-----------|
| Conductor | fast | default | heavy | heavy |
| Planner | — | default | heavy | heavy |
| Implementer | — | default | default | default |
| Reviewer | — | default | heavy | heavy |
| Researcher | — | — | default | default |
| Security | — | — | heavy | heavy |
| Red-Team | — | — | — | heavy |
| TDD-Guide | — | default | default | default |
| Doc-Updater | — | default | default | default |
