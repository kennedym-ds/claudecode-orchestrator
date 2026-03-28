# Worked Example: Adding a Rate Limiter with `/conduct`

> This walkthrough shows a realistic `/conduct` session end-to-end — from initial request through planning, implementation, review, and completion. It demonstrates how the conductor delegates to subagents, enforces pause points, and tracks state across phases.

## 1. User Starts the Session

```
User: /conduct Add rate limiting to the /api/v1/orders endpoint.
       Max 100 requests per minute per API key. Return 429 with Retry-After header.
```

## 2. Conductor Assesses Complexity

The conductor evaluates the request against the routing table:

- **Scope:** Single endpoint, new middleware, tests, docs
- **Risk:** Medium — affects API contract, potential for false positives
- **Verdict:** **STANDARD** (Plan → Implement → Review)

**State Tracking:**
```
Current Phase: Planning
Plan Progress: 0 of 2 phases
Last Action: Complexity assessment → STANDARD
Next Action: Delegate to planner
```

## 3. Conductor Delegates to Planner

```
#runSubagent planner "Draft plan for rate limiting on /api/v1/orders.
  Constraints: 100 req/min per API key, 429 + Retry-After header, must not break existing tests.
  Success criteria: Rate limiter passes load test, existing order tests green, 429 response validated."
```

### Planner Output: `artifacts/plans/rate-limiter/plan.md`

```markdown
# Plan: API Rate Limiter

> **Author:** planner
> **Date:** 2025-01-15
> **Complexity:** STANDARD
> **Status:** Draft

## Objective

Add per-API-key rate limiting (100 req/min) to the orders endpoint,
returning HTTP 429 with a Retry-After header when exceeded.

## Constraints

- Must use the existing Redis instance for counter storage
- Must not add latency > 5ms at p99 to the happy path
- Existing order endpoint tests must remain green

## Success Criteria

- [ ] Rate limiter blocks request 101 within a 1-minute window
- [ ] Response includes Retry-After header with correct TTL
- [ ] Existing /api/v1/orders tests pass unchanged
- [ ] Load test confirms < 5ms p99 overhead

## Phases

### Phase 1: Rate Limiter Middleware

**Scope:** src/middleware/rate-limiter.ts, src/routes/orders.ts
**Model Tier:** default
**Deliverables:**
- Sliding-window counter middleware using Redis INCR + EXPIRE
- Wire middleware to orders route
- Unit tests for limiter logic

**Acceptance Criteria:**
- [ ] Middleware exported and tested in isolation
- [ ] Orders route applies middleware
- [ ] Tests: 5+ cases (allow, block, reset, header, multi-key)

### Phase 2: Integration Tests & Documentation

**Scope:** tests/integration/rate-limiter.test.ts, docs/api/orders.md
**Model Tier:** default
**Deliverables:**
- Integration test with Redis test container
- Updated API docs with 429 response schema

**Acceptance Criteria:**
- [ ] Integration test confirms 100/101 boundary
- [ ] API docs include rate limit section
- [ ] All existing tests pass

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| Redis unavailable | MEDIUM | Fail-open with warning log |
| Clock skew in sliding window | LOW | Use Redis server time, not client |

## Open Questions

- [ ] Should rate limit headers (X-RateLimit-Remaining) be on all responses?

## Model Tier Summary

| Phase | Tier | Rationale |
|-------|------|-----------|
| Phase 1 | default | Straightforward middleware implementation |
| Phase 2 | default | Integration tests and docs |
```

## 4. Pause Point — Plan Approval

The conductor presents the plan and pauses:

```
Conductor: Plan drafted for "API Rate Limiter" (2 phases, STANDARD complexity).

📋 Plan: artifacts/plans/rate-limiter/plan.md
❓ Open question: Should X-RateLimit-Remaining headers be on all responses?

Approve the plan to proceed, or request changes.
```

**State Tracking:**
```
Current Phase: Planning (awaiting approval)
Plan Progress: 0 of 2 phases
Last Action: Plan drafted by planner
Next Action: Awaiting human approval
```

```
User: Approved. Yes, add X-RateLimit-* headers to all responses.
```

## 5. Conductor Launches Phase 1

```
#runSubagent implementer "Execute Phase 1: Rate Limiter Middleware.
  Files: src/middleware/rate-limiter.ts, src/routes/orders.ts
  Requirements: Sliding-window 100 req/min per API key via Redis INCR + EXPIRE.
  Return 429 with Retry-After. Add X-RateLimit-Remaining to all responses.
  TDD approach. Validate with: npm test -- --grep rate-limiter"
```

### Implementer Works (TDD Cycle)

The implementer:
1. Writes failing test for `rateLimiter()` middleware
2. Implements sliding-window counter in `rate-limiter.ts`
3. Tests pass (block at 101, Retry-After header, X-RateLimit-* headers)
4. Wires middleware to orders route
5. Runs existing tests — all green

### Phase 1 Artifact: `artifacts/plans/rate-limiter/phase-1-complete.md`

```markdown
# Phase 1 Complete: Rate Limiter Middleware

> **Plan:** API Rate Limiter
> **Date:** 2025-01-15
> **Status:** Complete

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| src/middleware/rate-limiter.ts | Created | Sliding-window rate limiter using Redis |
| src/middleware/rate-limiter.test.ts | Created | 7 unit tests for limiter logic |
| src/routes/orders.ts | Modified | Applied rate limiter middleware |

## Tests

| Test | Status | Description |
|------|--------|-------------|
| allows requests under limit | PASS | 100 requests succeed |
| blocks at 101 | PASS | Returns 429 |
| includes Retry-After | PASS | Header present with correct TTL |
| resets after window | PASS | New window allows requests |
| isolates per API key | PASS | Key A limit doesn't affect Key B |
| X-RateLimit-Remaining | PASS | Decrements on each request |
| fail-open on Redis error | PASS | Allows request + logs warning |

## Verification Loop

- Build: PASS
- Tests: PASS (47 passed, 0 failed, 0 skipped)
- Lint: PASS
- Typecheck: PASS

## Deviations from Plan

None

## Model Tiers Used

| Agent | Tier | Tokens (est.) |
|-------|------|--------------|
| implementer | default (sonnet) | ~12,000 |

## Next Phase

Phase 2: Integration tests and documentation
```

## 6. Conductor Launches Review

```
#runSubagent reviewer "Review Phase 1 changes for rate-limiter.
  Files: src/middleware/rate-limiter.ts, src/middleware/rate-limiter.test.ts, src/routes/orders.ts
  Acceptance criteria: Sliding-window correctness, fail-open behavior, header accuracy, no regressions.
  Tag findings by severity."
```

### Reviewer Findings

```
## Review: Phase 1 — Rate Limiter Middleware

**Verdict: APPROVED with 1 recommendation**

### Findings

| # | Severity | File | Finding |
|---|----------|------|---------|
| 1 | REC | rate-limiter.ts:34 | Consider extracting the window size (60s) to a config constant |

### Summary

Implementation is correct. Sliding-window logic properly uses MULTI/EXEC for atomicity.
Fail-open path tested. Headers accurate. No regressions in existing test suite.
Recommendation is non-blocking.
```

## 7. Conductor Proceeds to Phase 2

After reviewer approval, the conductor launches Phase 2 without requiring another pause (reviews within phases are non-blocking for STANDARD complexity).

```
#runSubagent implementer "Execute Phase 2: Integration Tests & Documentation.
  Files: tests/integration/rate-limiter.test.ts, docs/api/orders.md
  Requirements: Integration test with Redis test container confirming 100/101 boundary.
  Update API docs with 429 response schema and rate limit headers.
  TDD approach. Validate with: npm test -- --grep rate-limiter"
```

*(Implementer completes Phase 2 with integration tests and doc updates.)*

## 8. Final Review and Completion

The conductor runs a final review, then compiles the completion report:

### `artifacts/plans/rate-limiter/plan-complete.md`

```markdown
# Plan Complete: API Rate Limiter

> **Date:** 2025-01-15
> **Phases:** 2 completed
> **Status:** Complete

## Summary

Added per-API-key rate limiting (100 req/min) to /api/v1/orders with
429 + Retry-After response and X-RateLimit-* headers on all responses.
Fail-open on Redis errors. Covered by 7 unit tests + 3 integration tests.

## Phases Completed

| Phase | Title | Verdict |
|-------|-------|---------|
| 1 | Rate Limiter Middleware | APPROVED |
| 2 | Integration Tests & Documentation | APPROVED |

## Total Cost Summary

| Tier | Delegations | Est. Tokens |
|------|------------|-------------|
| Heavy (Opus) | 2 | ~8,000 |
| Default (Sonnet) | 2 | ~24,000 |
| Fast (Haiku) | 0 | 0 |
| **Total** | **4** | **~32,000** |

## Residual Risks

- Redis failover during deployment may cause brief rate limit gaps (fail-open by design)

## Follow-Up Tasks

- [ ] Extract window size to environment config (reviewer recommendation)
- [ ] Add Grafana dashboard for rate limit hit rate
- [ ] Load test in staging before production deploy

## Artifacts Created

| Type | Path |
|------|------|
| Plan | artifacts/plans/rate-limiter/plan.md |
| Phase 1 | artifacts/plans/rate-limiter/phase-1-complete.md |
| Phase 2 | artifacts/plans/rate-limiter/phase-2-complete.md |
| Review | artifacts/reviews/rate-limiter-review.md |
```

## Key Observations

| Aspect | What Happened |
|--------|---------------|
| **Complexity routing** | STANDARD — 2 phases, no security gate needed |
| **Pause points** | 1 mandatory pause after plan (approved) |
| **Model tiers** | Opus for reviewer (judgment), Sonnet for implementer (execution) |
| **Artifacts** | Plan, 2 phase completions, review, final report — all persisted |
| **State tracking** | Every conductor response included Current Phase / Plan Progress / Last Action / Next Action |
| **Budget** | 4 delegations, ~32K tokens — well within STANDARD limits |
| **TDD** | Implementer wrote tests first, then implementation (red→green→refactor) |
| **Reviewer** | Found 1 non-blocking recommendation, approved the phase |
