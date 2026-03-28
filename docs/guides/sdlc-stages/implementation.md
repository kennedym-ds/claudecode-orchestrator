# SDLC Stage: Implementation

Writing code, following the plan, enforcing TDD, and running verification loops.

## Agents at This Stage

| Agent | Role | Model | Permission |
|-------|------|-------|------------|
| `implementer` | TDD execution, plan phase delivery | Sonnet | `acceptEdits` |
| `tdd-guide` | Test-first enforcement | Sonnet | `acceptEdits` |
| `pair-programmer` | Collaborative coding with user | Sonnet | `default` |

## Entry Points

**Full lifecycle (recommended for multi-phase work):**
```bash
claude --agent conductor
/conduct <feature>
# Conductor routes, plans, delegates to implementer, and reviews
```

**Direct implementation from an approved plan:**
```bash
claude --agent implementer
/implement <task or phase description>
```

**Test-first with implementer:**
```bash
claude --agent tdd-guide
/test <scope>
# Writes failing tests → implementer makes them pass
```

**Collaborative session:**
```bash
claude --agent pair-programmer
/pair
# Interactive — user and agent code together
```

## The TDD Cycle

Every change the implementer makes follows RED → GREEN → REFACTOR:

```
1. RED    — Write a failing test that defines the expected behavior
             Run it. Confirm it fails for the right reason.
2. GREEN  — Write the minimum code to make the test pass
             No more, no less.
3. REFACTOR — Clean up the implementation
             Keep all tests green throughout.
4. VERIFY — Run full verification loop:
             build → tests → lint → typecheck
```

If tests pass before writing any implementation code — the tests are wrong.

## Implementer Rules

The implementer follows the plan exactly. If anything is ambiguous:
- Notes the assumption
- Proceeds with the simplest interpretation
- Flags it in the completion report

It does **not**:
- Add scope or "while I'm here" improvements
- Refactor adjacent code that wasn't in the plan
- Skip tests for "obviously simple" changes

## Verification Loop

After each phase, the implementer runs:

```bash
# Build/compile (if applicable)
# Run tests (unit + integration if available)
# Lint/format check
# Type check (if applicable)
```

All must pass before the phase is marked complete. If any fail, the implementer diagnoses the root cause — it doesn't add workarounds or skip the failing check.

## Hooks That Run During Implementation

These run automatically on every file edit — no action needed:

| Hook | When | What It Does |
|------|------|--------------|
| `post-edit-validate.js` | After every Edit/Write | Runs lint + basic validation |
| `secret-detector.js` | After every Edit/Write | Flags hardcoded secrets |
| `dependency-scanner.js` | After edits to `*package*.json` | Scans for vulnerable dependencies |

If a hook returns a non-zero exit code, it blocks the edit and reports the issue.

## Working with isolation: worktree

The implementer runs in `isolation: worktree` — it works in a separate git branch, isolated from your main working directory.

- Your uncommitted changes are not affected
- The worktree is merged back when the implementer completes
- The `worktree-create.js` hook seeds the worktree with `artifacts/memory/activeContext.md` so the implementer has full session context

## Pair Programming

The pair-programmer works differently from the implementer:

- **Explains reasoning** as it goes — no silent 200-line dumps
- **Presents options** at decision points rather than picking unilaterally
- **Asks for input** before committing to an approach
- **Teaches patterns** — the "why" not just the "what"

Use it when:
- Learning unfamiliar code
- Working through complex logic you want to understand
- Exploring trade-offs interactively

```bash
claude --agent pair-programmer
/pair
# Start describing what you're working on
```

## Completion Report

When the implementer finishes a phase, it reports:

```
Files modified: [list]
Tests added: [count] — all passing
Verification loop: build ✓ | tests ✓ | lint ✓ | typecheck ✓
Deviations from plan: [none / description and rationale]
```

If any verification step fails, it does not report completion — it reports the failure and attempts to fix it.

## Handoff to Review

After implementation completes:
- Phase output is in the modified files (committed or staged)
- Completion report is in `artifacts/plans/{feature}/phase-N-complete.md`
- The conductor routes to the reviewer automatically in a managed workflow
- Or trigger manually: `claude --agent reviewer` → `/review <scope>`
