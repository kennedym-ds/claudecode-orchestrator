---
name: artifact-management
description: Session artifact lifecycle — creation, indexing, retention, and compaction of plans, reviews, decisions, and session state.
user-invocable: false
---

# Artifact Management

## Artifact Types

| Type | Location | Created By | Retention |
|------|----------|-----------|-----------|
| Plans | `artifacts/plans/{feature}/` | Planner, Conductor | Until project complete |
| Reviews | `artifacts/reviews/` | Reviewer | 30 days |
| Research | `artifacts/research/` | Researcher | 30 days |
| Security | `artifacts/security/` | Security-Reviewer | 90 days |
| Decisions (ADRs) | `artifacts/decisions/` | Architect | Permanent |
| Sessions | `artifacts/sessions/` | Conductor | 7 days |
| Memory | `artifacts/memory/` | All agents | Rolling |

## Naming Convention

```
{type}/{feature-slug}/{date}-{descriptor}.md

Examples:
plans/auth-redesign/2026-03-28-plan.md
reviews/2026-03-28-phase-1-review.md
decisions/ADR-0001-use-jwt-auth.md
sessions/2026-03-28-session.md
```

## Active Context

`artifacts/memory/activeContext.md` tracks:
- Current phase and plan progress
- Last 3-5 decisions made
- Open questions awaiting human input
- Blocked items and their blockers

Updated at every pause point by the conductor.

## Artifact Index

`artifacts/artifact-index.md` inventories all active artifacts. Updated when artifacts are created or archived.

## Compaction Protocol

When session gets long:
1. Pre-compact hook saves critical state to `artifacts/memory/`
2. Context compacts (loses in-context history)
3. Post-compact hook restores state from artifacts
4. Session continues with preserved context

## Cleanup

- Sessions > 7 days → archive or delete
- Reviews > 30 days → archive
- Plans for completed features → move to `artifacts/archive/`
- ADRs → never delete (permanent record)
