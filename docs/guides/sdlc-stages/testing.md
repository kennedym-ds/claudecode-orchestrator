# SDLC Stage: Testing

Test strategy design, TDD enforcement, coverage analysis, and acceptance testing.

## Agents at This Stage

| Agent | Role | Model | Permission |
|-------|------|-------|------------|
| `test-architect` | Test pyramid design, coverage gap analysis | Sonnet | `plan` |
| `tdd-guide` | Test-first enforcement, unit/integration tests | Sonnet | `acceptEdits` |
| `e2e-tester` | End-to-end acceptance test writing and execution | Sonnet | `acceptEdits` |
| `reviewer` | Coverage assessment in code review | Opus | `plan` |

## Entry Points

**Design test strategy before implementation:**
```bash
claude --agent test-architect
/test-arch <feature or scope>
```

**Write tests (TDD — before implementation):**
```bash
claude --agent tdd-guide
/test <file or module>
```

**Write e2e acceptance tests (after implementation):**
```bash
claude --agent e2e-tester
/e2e <user journey or feature>
```

## Test Strategy Design

The `test-architect` produces a test strategy document before implementation begins. Bring this into the planning conversation so developers know what testing is expected.

```bash
claude --agent test-architect
/test-arch The checkout flow — cart → payment → order confirmation

# Output:
# Current State: what tests exist, coverage level, gaps
# Test Pyramid:
#   Unit (70%)     — fast, isolated, business logic
#   Integration (20%) — component boundaries, DB, external APIs
#   E2E (10%)      — critical user paths only
# Test cases table with priority
# Infrastructure needs: fixtures, mocks, test data, CI config
```

### Test Pyramid Allocation

| Layer | Target % | Focus |
|-------|----------|-------|
| Unit | ~70% | Business logic, pure functions, edge cases |
| Integration | ~20% | Database interactions, API contracts, service boundaries |
| E2E | ~10% | Critical happy paths only — slow and flaky by nature |

Don't invert the pyramid. A test suite that's 70% e2e tests is slow, flaky, and expensive to maintain.

## TDD: Writing Tests First

```bash
claude --agent tdd-guide
/test src/services/OrderService.ts

# Cycle:
# 1. tdd-guide writes failing tests (RED)
# 2. You verify the tests express the right behavior
# 3. implementer (or you) writes code to make them pass (GREEN)
# 4. Refactor while keeping green
```

### What Good Unit Tests Look Like

- **Descriptive name:** `test_order_total_includes_tax_at_configured_rate`
- **Isolated:** No shared mutable state, no external I/O
- **One assertion per concept** — not one assert per test
- **Covers:** happy path, empty/null input, boundary values, error conditions
- **Fast:** milliseconds, not seconds

## E2E Acceptance Tests

```bash
claude --agent e2e-tester
/e2e User can complete a purchase from product page to order confirmation

# e2e-tester:
# 1. Reads acceptance criteria from the plan or spec
# 2. Identifies critical user paths to test
# 3. Writes tests using the project's framework (Playwright, Cypress, supertest, etc.)
# 4. Runs tests and reports results
# 5. Assesses flakiness risk
```

### Framework Detection

The `e2e-tester` adapts to whatever test framework the project uses:

| Type | Frameworks |
|------|-----------|
| Web UI | Playwright, Cypress, Selenium |
| API | supertest, httpx, REST Assured |
| CLI | subprocess/child_process assertions |
| Mobile | Detox, XCTest, Espresso |

### E2E Test Design Rules

- Test ONE complete user journey per test
- Use realistic test data — not `user: "test"`, `email: "a@b.com"`
- Happy path first, then the critical failure paths
- Never test internal implementation details — test user-visible outcomes

## Coverage Assessment in Review

During code review, the `reviewer` specifically checks:

- New code paths without corresponding tests
- Tests that test implementation details instead of behavior
- Tests that only cover the happy path
- Missing edge cases: empty collections, null inputs, concurrent access, large inputs

```bash
claude --agent reviewer
/review src/services/OrderService.ts

# Reviewer tags coverage issues with:
# MAJOR: No tests for the new refund logic
# MINOR: Test names don't describe the scenario being tested
```

## Domain-Specific Testing Overlays

Activate domain profiles in `sdlc-config.md` to get domain-specific testing requirements:

```yaml
domain:
  primary: safety-critical
```

| Domain | Additional Requirements |
|--------|------------------------|
| `safety-critical` | MC/DC coverage for safety paths; static analysis (Polyspace, LDRA) |
| `embedded-systems` | HIL tests; WCET analysis; coverage per MISRA |
| `semiconductor-test` | ATE measurement uncertainty; lot/wafer traceability |
| `web-frontend` | Visual regression; cross-browser; WCAG accessibility |

## Test Artifacts

| Artifact | Location |
|---------|---------|
| Test strategy | `artifacts/plans/{feature}/test-strategy.md` |
| Test run results | Reported inline in completion summary |
| Coverage gaps | `artifacts/reviews/{feature}-coverage.md` |

## Handoff to Security Review / Deployment

Tests must all be green before moving to security review. The `deploy-check` agent enforces this as a blocking gate:

```
✓ Tests: PASS (147/147 passing, 0 skipped)
✓ Coverage: 84% line coverage (threshold: 80%)
```

If tests are failing, the pipeline stops here. Fix the tests — do not bypass the gate.
