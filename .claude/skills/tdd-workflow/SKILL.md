---
name: tdd-workflow
description: Test-Driven Development with Red-Green-Refactor cycle
argument-hint: <feature-or-fix-description>
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# TDD Workflow

## Red-Green-Refactor Cycle

### 1. RED — Write Failing Test
- Write a test that describes the expected behavior
- Run it — confirm it fails
- The failure message should clearly indicate what's missing

### 2. GREEN — Make It Pass
- Write the minimum code to make the test pass
- Don't optimize, don't generalize — just make it green
- Run tests again — confirm everything passes

### 3. REFACTOR — Clean Up
- Improve code quality while keeping tests green
- Remove duplication, improve naming, simplify logic
- Run tests after every refactor step

## When to Apply

- **New features:** Always — write the contract test before implementation
- **Bug fixes:** Always — reproduce the bug as a failing test first
- **Refactors:** Ensure existing tests cover the behavior before changing
- **Config/docs:** Skip TDD — no behavioral change to test

## Test Naming Convention

Use descriptive names that explain the behavior:
- `test_returns_empty_list_when_no_items_match`
- `should throw AuthError when token is expired`
- `it renders loading spinner during fetch`

## Verification Loop

After completing the Red-Green-Refactor cycle:
1. Run full test suite
2. Run linter/formatter
3. Run type checker (if applicable)
4. Run build (if applicable)

All four must pass before the change is considered complete.
