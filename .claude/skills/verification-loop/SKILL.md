---
name: verification-loop
description: Build-test-lint-typecheck verification cycle
argument-hint: <project-path>
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Grep
---

# Verification Loop

## Four-Step Verification

Run after every meaningful code change:

### 1. Build / Compile
```bash
# Detect and run the project's build command
# npm run build | cargo build | go build | dotnet build | etc.
```
- Must succeed with zero errors
- Warnings should be reviewed — new warnings are red flags

### 2. Run Tests
```bash
# Run the project's test suite
# npm test | pytest | cargo test | go test ./... | dotnet test | etc.
```
- All tests must pass
- New tests should be included in the run
- Note any skipped tests and why

### 3. Lint / Format
```bash
# Run linter and formatter
# npm run lint | ruff check | cargo clippy | golangci-lint | etc.
```
- Zero lint errors (warnings acceptable only if pre-existing)
- Code should be auto-formatted before commit

### 4. Type Check (if applicable)
```bash
# Run type checker
# tsc --noEmit | mypy | pyright | etc.
```
- Zero type errors
- New code must maintain type safety

## Verification Report

```
--- Verification Report ---
Build:     ✅ PASS
Tests:     ✅ PASS (47 passed, 0 failed, 2 skipped)
Lint:      ✅ PASS (0 errors, 1 pre-existing warning)
Typecheck: ✅ PASS
Verdict:   ALL CLEAR
```

## Failure Handling

If any step fails:
1. **Stop** — Don't proceed to the next step
2. **Diagnose** — Read the error, understand the root cause
3. **Fix** — Address the issue
4. **Re-run** — Start the verification loop from step 1

Do NOT:
- Skip a failing step ("it's probably fine")
- Disable a lint rule to make errors go away
- Add `@ts-ignore` or `# type: ignore` without justification
