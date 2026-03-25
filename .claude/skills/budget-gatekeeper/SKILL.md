---
name: budget-gatekeeper
description: Token and cost tracking with model tier enforcement
argument-hint: <session-context>
user-invocable: true
---

# Budget Gatekeeper

## Model Tier Costs

Track usage by tier to monitor cost distribution:

| Tier | Model | Relative Cost | Target Budget Share |
|------|-------|--------------|-------------------|
| **heavy** | Opus 4.6 | 1.0x (baseline) | ≤ 25% of session tokens |
| **default** | Sonnet 4.6 | ~0.2x | 60-70% of session tokens |
| **fast** | Haiku 4.5 | ~0.04x | 5-15% of session tokens |

## Budget Tracking

Subagent delegations are automatically logged to `artifacts/sessions/delegation-log.jsonl` by the SubagentStart and SubagentStop hooks. At each delegation, record:
- Agent name
- Model tier used
- Estimated input/output tokens
- Cumulative session cost estimate

## Soft Limits

| Metric | Warning | Hard Limit |
|--------|---------|------------|
| Total delegations | 8 | 15 |
| Heavy-tier delegations | 4 | 8 |
| Estimated session cost | $2.00 | $5.00 |
| Single agent turns | 30 | 60 |

When a **soft limit** is hit:
- Report usage to the conductor
- Suggest alternatives (downgrade tier, reduce scope, split into separate sessions)

When a **hard limit** is hit:
- Pause and present the usage report to the user
- Require explicit approval to continue

## Cost Optimization Strategies

1. **Tier downgrade:** Use `default` instead of `heavy` when a task doesn't require deep judgment
2. **Scope reduction:** Break large tasks into phases that can span multiple sessions
3. **Context management:** Use `/compact` at milestones to reduce token waste
4. **Session isolation:** Use `/clear` between unrelated tasks
5. **Fast tier routing:** Route INSTANT tasks to Haiku instead of Sonnet

## Budget Report Format

```
--- Budget Report ---
Delegations: 5 / 15
Heavy-tier: 2 / 8 (reviewer, security-reviewer)
Default-tier: 3 (implementer, researcher, doc-updater)
Fast-tier: 0
Estimated cost: ~$1.20
Recommendation: On track — no action needed
```
