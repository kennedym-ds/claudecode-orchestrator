# SDLC Stage: Incident Response

Structured investigation, root cause analysis, and post-mortem documentation.

## Agent at This Stage

| Agent | Role | Model | Permission |
|-------|------|-------|------------|
| `incident-responder` | Investigation, RCA, fix, prevention | Sonnet | `acceptEdits` |

## Launching an Investigation

```bash
claude --agent incident-responder
/incident <symptom description>

# Example:
/incident Payment processing failures since 14:30 UTC — 18% error rate, timeouts on Stripe API calls, no changes deployed in the past 6 hours
```

Include: what is failing, when it started, impact radius, whether it's ongoing.

## Investigation Protocol

The `incident-responder` follows a structured 4-phase protocol:

### Phase 1: Observe

Gather all available evidence before forming theories:

- Error messages and stack traces
- Log patterns around the failure window
- System metrics (CPU, memory, connection pool, queue depth)
- Recent deployments or config changes (`git log --since=24h`)
- User reports and reproduction steps

### Phase 2: Hypothesize

Form testable theories based on evidence:

```
Hypothesis 1: Stripe API is experiencing degraded latency
  Evidence for: Timeouts occurring on all Stripe calls
  Evidence against: Stripe status page shows green
  Test: Check p99 latency trend for Stripe calls over past 6 hours

Hypothesis 2: Connection pool exhausted under load
  Evidence for: Timeout errors match connection pool wait time
  Evidence against: Load metrics look normal
  Test: Check active connection count vs pool max
```

### Phase 3: Experiment

Test each hypothesis with the smallest possible change:
- Verify or eliminate — don't fix multiple things at once
- Instrument first (add logging), then interpret
- If 3 fix attempts fail → escalate to architecture review immediately

### Phase 4: Conclude

Once root cause is identified:

```
Root cause confirmed: Connection pool max (10) too low for current traffic (25 concurrent payment requests)
Fix: Increase pool max to 50, add circuit breaker with 500ms timeout
Verify: Error rate returns to 0% within 2 minutes of fix
```

## Severity Classification

| Level | Impact | Response |
|-------|--------|----------|
| SEV1 | Service down, data loss | Immediate — all hands |
| SEV2 | Major feature broken | < 1 hour |
| SEV3 | Minor feature degraded | < 4 hours |
| SEV4 | Cosmetic, non-blocking | Next sprint |

## 5-Why Root Cause Analysis

```
Why did the service fail?
  → Stripe API calls timed out

Why did they time out?
  → Connection pool was exhausted (all 10 connections in use)

Why was the pool exhausted?
  → Payment volume increased 3x after the marketing campaign launched

Why didn't the system handle the increased load?
  → Pool max was set at installation time and never reviewed

Why wasn't this caught?
  → No load test for payment flows, no alerting on pool utilization
```

**Systemic fix:** Circuit breaker + dynamic pool sizing + pool utilization alert + load test for payment paths.

## Fix Categorization

| Type | When to Use | How to Deploy |
|------|-------------|---------------|
| **Hotfix** | Restore service now | Deploy immediately, test after |
| **Proper fix** | Correct solution with tests | Deploy in next cycle |
| **Systemic fix** | Process or architecture | Plan and schedule |

For SEV1/SEV2: hotfix first to restore service, proper fix follows in the next sprint.

## Post-Mortem Template

The incident-responder produces a structured post-mortem:

```markdown
## Incident: Payment connection pool exhaustion
Date: 2026-03-28
Severity: SEV2
Duration: 14:30 → 15:15 UTC (45 minutes)
Impact: 18% of payment requests failed (~340 failed transactions)

### Timeline
- 14:28 — Marketing campaign email sent (3x traffic spike)
- 14:30 — Error rate begins climbing
- 14:35 — On-call alerted
- 14:52 — Root cause identified
- 15:10 — Hotfix deployed
- 15:15 — Error rate returns to 0%

### Root Cause
Connection pool max (10) insufficient for 3x traffic spike. No circuit breaker.

### Resolution
Increased pool max to 50. Added circuit breaker with 500ms timeout and fallback.

### Action Items
- [ ] Add pool utilization alert at 80% — Owner: DevOps — Due: 2026-04-04
- [ ] Load test for payment flows — Owner: QA — Due: 2026-04-11
- [ ] Review all other pool configurations — Owner: Arch — Due: 2026-04-11
```

## Using Existing Artifacts

The incident-responder can read `artifacts/plans/` and `artifacts/reviews/` to understand recent changes:

```bash
/incident Login failures after today's deployment

# Agent reads artifacts/plans/jwt-auth/plan-complete.md
# Immediately knows what changed, in which files, with what tests
# Correlates with the incident timeline without you having to reconstruct it
```

## Escalation Path

```
1 failed fix attempt → re-hypothesize with new evidence
2 failed fix attempts → broaden scope, check adjacent systems
3 failed fix attempts → ESCALATE to architecture review immediately

Do not keep trying random changes after 3 failures.
```

Escalation triggers the planner to produce a structured remediation plan rather than continuing ad-hoc debugging.

## Output Artifacts

| Artifact | Location |
|---------|---------|
| Post-mortem | `artifacts/sessions/{date}-incident-{slug}.md` |
| RCA log | `artifacts/sessions/failure-log.jsonl` |
| Action items | Tracked in the post-mortem or synced to Jira via `/jira-sync` |
