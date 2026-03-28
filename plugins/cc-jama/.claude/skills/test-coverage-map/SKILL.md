---
name: "test-coverage-map"
description: "Maps test execution results from Jama test cycles to requirements, showing coverage gaps and pass/fail status."
---

# Test Coverage Map

## When to Use

During review or deploy-check phases when you need to verify test coverage against requirements.

## Workflow

1. Get the test cycle (by ID) to see all test runs
2. For each test run, get the associated test case
3. For each test case, trace upstream to the requirement it covers
4. Build a coverage matrix showing requirement → test case → execution status

## Output Format

```markdown
## Test Coverage Map: {test_cycle_name}

### Overall Coverage
- Requirements covered: {count}/{total} ({percentage}%)
- Test runs passed: {passed}/{total} ({percentage}%)
- Test runs failed: {failed}
- Test runs blocked: {blocked}
- Test runs not executed: {not_run}

### Coverage Detail
| Requirement | Test Case | Last Run | Status | Result |
|---|---|---|---|---|
| REQ-100 | TC-200 | 2025-01-15 | Executed | PASSED |
| REQ-101 | TC-201 | 2025-01-15 | Executed | FAILED |
| REQ-102 | — | — | — | NO COVERAGE |

### Risks
- {requirements with no test coverage}
- {test cases that are failing}
- {test cases not yet executed}
```

## CLI Example

```bash
# Map test coverage for a cycle
claude -p "build a test coverage map for Jama test cycle 789 — show which requirements are covered and pass/fail status" \
  --tool mcp__cc_jama__get_test_runs --tool mcp__cc_jama__get_relationships

# Check coverage for a specific requirement
claude -p "check if Jama requirement 1234 has test coverage and show test results" \
  --tool mcp__cc_jama__get_item --tool mcp__cc_jama__get_relationships --tool mcp__cc_jama__get_test_runs
```