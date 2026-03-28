---
name: issue-triage
description: Issue classification, prioritization, and management patterns for GitHub integration.
---

# Issue Triage Skill

## Priority Classification

| Priority | Response Time | Criteria |
|----------|-------------|----------|
| P0 — Critical | < 1 hour | Data loss, security breach, complete outage |
| P1 — High | < 4 hours | Major feature broken, no workaround |
| P2 — Medium | < 1 week | Feature degraded, workaround available |
| P3 — Low | Backlog | Cosmetic, enhancement, nice-to-have |

## Label Taxonomy

### Type Labels
- `bug` — Something isn't working
- `enhancement` — New feature or improvement
- `documentation` — Documentation update needed
- `question` — Clarification needed
- `tech-debt` — Code quality improvement

### Status Labels
- `needs-triage` — Not yet classified
- `needs-info` — Waiting for reporter
- `confirmed` — Reproduced and accepted
- `wont-fix` — Intentional behavior or out of scope

### Area Labels
Apply area labels matching the affected component: `area/api`, `area/ui`, `area/auth`, `area/data`, etc.

## Duplicate Detection

Before creating new issues:
1. Search by title keywords
2. Search by error message
3. Check recently closed issues (last 30 days)
4. Link as duplicate if match found

## Issue Hygiene

- Stale after 30 days without activity → add `stale` label
- Auto-close `needs-info` after 14 days without response
- Move `P3` to milestone "Backlog" after triage
