# Guide: QA Engineer

Test strategy, coverage analysis, TDD enforcement, and acceptance testing.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| Design test strategy | `/test-arch <feature>` | test-architect |
| Write unit/integration tests | `/test <scope>` | tdd-guide |
| Write e2e acceptance tests | `/e2e <feature>` | e2e-tester |
| Verify deploy readiness | `/deploy-check` | deploy-engineer |
| Review for test coverage | `/review <scope>` | reviewer |

## Designing a Test Strategy

Before implementation begins, define the test pyramid:

```bash
claude --agent test-architect
/test-arch The new checkout flow with payment processing

# Produces:
# - Test pyramid breakdown (unit 70% / integration 20% / e2e 10%)
# - Coverage gap analysis vs existing tests
# - Test infrastructure needs (fixtures, mocks, test data)
# - Priority table with recommended test cases
```

Bring this output into the planning phase so developers know what they're expected to test.

## Writing Tests (TDD)

```bash
# Start with failing tests — the implementer makes them pass
claude --agent tdd-guide
/test src/services/CheckoutService.ts

# TDD cycle:
# 1. RED — write failing tests defining expected behavior
# 2. Hand off → implementer writes minimum code to pass
# 3. GREEN — verify tests pass
# 4. REFACTOR — clean up while keeping green
```

For targeted test writing without a full TDD session:

```bash
claude -p "write unit tests for src/services/CheckoutService.ts — cover happy path, edge cases, and error conditions including payment failure and inventory shortage"
```

## End-to-End Acceptance Tests

```bash
claude --agent e2e-tester
/e2e The checkout user journey — from cart to order confirmation

# Writes e2e tests using the project's existing test framework
# (Playwright, Cypress, supertest, etc.)
# Output includes:
# - Test files
# - Coverage map (which acceptance criteria are validated by which test)
# - Flakiness assessment
```

## Evaluating Test Coverage

```bash
# Review changed files specifically for test coverage gaps
claude --agent reviewer
/review src/checkout/

# Reviewer flags:
# - Missing tests for new code paths
# - Untested edge cases
# - Tests that test implementation details instead of behavior
```

## Pre-Deploy Readiness Check

Run this before any release:

```bash
claude --agent deploy-engineer
/deploy-check

# Checks:
# ✓ Build passes
# ✓ Full test suite passes
# ✓ Lint clean
# ✓ Security scan clean
# ✓ Version bumped
# ✓ No critical dependency vulnerabilities
# Output: READY / NOT READY with specific blockers
```

## Testing in Regulated Environments

If your project uses the `safety-critical`, `embedded-systems`, or `semiconductor-test` domain profile, the domain overlay adds:

- MC/DC coverage requirements for safety-critical paths
- Hardware-in-the-loop test patterns (embedded)
- ATE test program patterns (semiconductor)
- Traceability: requirement → test case mapping

Activate via `sdlc-config.md`:

```yaml
domain:
  primary: safety-critical
```

## Integration: Jama Requirements Traceability

For regulated projects where test coverage must trace to requirements:

```bash
/jama-trace
# Maps implementation changes to Jama requirements
# Identifies requirements with no test coverage

claude -p "build a test coverage map for Jama test cycle 567" \
  --tool mcp__cc_jama__get_test_runs --tool mcp__cc_jama__get_relationships
```

## What Good Test Output Looks Like

When `tdd-guide` or `e2e-tester` completes, you should see:

```
Tests written: 12
RED phase results: 12/12 failing (expected)
Coverage: happy path ✓, empty input ✓, concurrent access ✓, payment failure ✓
Non-deterministic risk: LOW (no time-based assertions, no network calls in unit tests)
```

If tests pass before implementation — the tests are wrong. Red first, always.
