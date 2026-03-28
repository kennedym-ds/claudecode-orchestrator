# Guide: Tech Lead / Architect

Architecture decisions, planning, review governance, and cross-team coordination.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| Architecture decision | `/architect <decision>` | architect |
| Multi-phase planning | `/plan <task>` | planner |
| Review code (your team's PRs) | `/review <scope>` | reviewer |
| Adversarial review (high-risk) | `/red-team <scope>` | red-team |
| Threat model a new feature | `/threat-model <feature>` | threat-modeler |
| Estimate work for sprint | `/estimate <task list>` | estimator |
| Conduct full lifecycle | `/conduct <task>` | conductor |

## Architecture Decision Records

```bash
claude --agent architect
/architect Should we use an event-driven architecture for the notifications system?

# Architect will:
# 1. Explore current system structure
# 2. Present 2-3 design options with trade-offs
# 3. Recommend one approach with rationale
# 4. Output an ADR to artifacts/decisions/
```

ADRs capture the context, decision, and consequences — so future engineers know the "why" not just the "what."

## Planning a Feature for Your Team

```bash
claude --agent planner
/plan Migrate from session-based auth to JWT

# Planner produces:
# - Phased implementation plan
# - Risk register
# - Open questions for human input
# - Model tier recommendations per phase
# Output: artifacts/plans/jwt-auth/plan.md
```

Review the plan, then hand it off to developers to execute with `/conduct` or `/implement`.

## Reviewing PRs

```bash
# Review a directory before merge
claude --agent reviewer
/review src/auth/

# For high-risk changes (payment, auth, infra)
claude --agent red-team
/red-team src/payments/processor.ts
# Finds edge cases, failure modes, and adversarial scenarios

# Full security posture
claude --agent security-reviewer
/secure src/api/
```

### Managing Review Findings

| Severity | Your Action |
|----------|------------|
| CRITICAL | Block merge — route back to author |
| HIGH | Block merge unless explicitly accepted |
| MEDIUM | Require fix or filed follow-up ticket |
| LOW | Author's discretion |

## Sprint Planning

```bash
claude --agent estimator
/estimate Review the plan at artifacts/plans/jwt-auth/plan.md

# Returns T-shirt sizes + story points for each phase
# Flags risks that could blow estimates
```

```bash
# If using Jira — sync plan to stories
/jira-sync
# Converts plan phases → Jira epic + stories with acceptance criteria
```

## Threat Modeling (Pre-Implementation)

Do this before developers start building security-sensitive features:

```bash
claude --agent threat-modeler
/threat-model The new file upload API with S3 presigned URLs

# Output: STRIDE threat matrix + DREAD risk scores + recommended mitigations
# Hands this to the security-reviewer to monitor during implementation
```

## Cross-Session Continuity

For work that spans multiple sessions or multiple team members:

- Review `artifacts/memory/activeContext.md` at the start of each session
- Plans in `artifacts/plans/` are the authoritative source of truth for phase status
- Review findings in `artifacts/reviews/` give you a historical quality record

## Delegating Effectively

When handing off to developers:

1. Produce the plan (`/plan`)
2. Approve it and add your context (edit `artifacts/plans/{feature}/plan.md`)
3. Developer runs `/conduct` — conductor picks up from the plan
4. Review findings come back to `artifacts/reviews/` — you review or delegate

## When to Use ULTRADEEP Routing

Tell the conductor explicitly when a task warrants the highest scrutiny:

```bash
/conduct Migrate from monolith to microservices
# Conductor routes ULTRADEEP automatically for architectural changes:
# Research → Plan → Implement → Trilateral Review (Reviewer + Red Team + Security)
```

Trilateral review requires consensus across three independent agents before proceeding.
