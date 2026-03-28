# Guide: Developer

Day-to-day development — feature work, bug fixes, tests, and code review.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| Build a feature | `/conduct <feature>` | conductor |
| Fix a bug | `/conduct <bug>` or direct `-p` | conductor / direct |
| Write tests | `/test <scope>` | tdd-guide |
| Review your changes | `/review <scope>` | reviewer |
| Pair on complex logic | `/pair` | pair-programmer |
| Research a decision | `/research <question>` | researcher |

## Typical Day

### New Feature

```bash
claude --agent conductor

/conduct Add rate limiting to the POST /api/orders endpoint
# Conductor assesses complexity → STANDARD or DEEP
# → planner creates a plan
# PAUSE: review and approve the plan
# → implementer writes tests first, then implementation
# → reviewer checks the result
# PAUSE: review findings
```

### Bug Fix

```bash
# Simple fix — skip the conductor
claude -p "fix the null pointer exception in src/services/OrderService.ts line 142 — write a failing test first"

# Uncertain scope — use the conductor
claude --agent conductor
/conduct Fix the intermittent timeout in the payment processor
```

### TDD (write tests first yourself)

```bash
claude --agent tdd-guide
/test src/services/PaymentService.ts
# Writes failing tests → you review → implementer makes them pass
```

### Understand Unfamiliar Code

```bash
claude -p "explain how the authentication middleware chain works in src/middleware/"

claude --agent researcher
/research How does this codebase handle database transactions?
```

### Code Review Before PR

```bash
claude --agent reviewer
/review src/api/orders/

# Security-focused review
claude --agent security-reviewer
/secure src/api/orders/
```

## Routing Guide

Use this to decide how much ceremony to apply:

| Change | Approach |
|--------|----------|
| Typo, comment, config | Direct `-p` prompt (INSTANT) |
| Single-file bug fix | `-p` with test instruction (INSTANT/STANDARD) |
| Multi-file feature | `/conduct` (STANDARD/DEEP) |
| Feature touching auth, payments, security | `/conduct` → automatically routes DEEP |
| Architectural change | `/conduct` → routes ULTRADEEP, involves architect |

## Artifacts You'll Use

- `artifacts/plans/` — implementation plans, phase progress
- `artifacts/reviews/` — review findings you need to address
- `artifacts/memory/activeContext.md` — current session state; persists across context compactions

## Tips

- **Don't skip plan approval** — the plan shapes everything. If the plan is wrong, the code will be wrong.
- **Commit after each phase** — the conductor pauses between phases specifically to give you a commit window.
- **Use `/compact` in long sessions** — at milestones, not mid-phase.
- **Re-review after fixes** — run `/review` again if you addressed CRITICAL/HIGH findings before merging.
