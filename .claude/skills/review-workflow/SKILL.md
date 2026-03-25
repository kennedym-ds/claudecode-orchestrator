---
name: review-workflow
description: Code review methodology with severity tagging
argument-hint: <files-or-diff-to-review>
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Review Workflow

## Review Process

### Step 1 — Context
- Read the plan or PR description to understand intent
- Identify the acceptance criteria for this change

### Step 2 — Correctness
- Does the code do what the plan/description says?
- Are there logic errors, off-by-one mistakes, or race conditions?
- Are edge cases handled?

### Step 3 — Quality
- Is the code readable and maintainable?
- Are names descriptive? Is structure clear?
- Is there unnecessary duplication?
- Is complexity justified?

### Step 4 — Tests
- Are there tests for the new/changed behavior?
- Do tests cover happy path, edge cases, and error conditions?
- Are tests meaningful (not just "it doesn't crash")?

### Step 5 — Security
- Is user input validated at boundaries?
- Are there injection risks, auth gaps, or secret exposure?
- Reference the security-review skill for thorough checks

### Step 6 — Verdict
- Tag each finding: BLOCKER / MAJOR / MINOR / NIT
- Deliver verdict: APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION

## Finding Format

```
**[SEVERITY] — Short description**
File: path/to/file.ext, line N
Issue: What's wrong
Suggestion: How to fix it
```

## Review Etiquette

- Praise good decisions — don't only criticize
- Be specific — "this is unclear" is useless; "rename `x` to `userCount`" is actionable
- Don't bikeshed — if it works and is clear, let it be
- Separate personal preference (NIT) from genuine issues (MAJOR/BLOCKER)
