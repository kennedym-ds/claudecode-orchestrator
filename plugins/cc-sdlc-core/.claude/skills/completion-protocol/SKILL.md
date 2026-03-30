---
name: completion-protocol
description: >
  Standardized completion and escalation protocol for subagent responses.
  Ensures the conductor can machine-parse every subagent return.
  Use when reporting completion status back to the orchestrator.
user-invocable: false
---

# Completion Protocol

## Status Codes

Every subagent response to the conductor **must** end with a structured status block. Use one of these four statuses:

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `DONE` | All objectives completed successfully | Deliverables met, tests pass, no concerns |
| `DONE_WITH_CONCERNS` | Completed, but issues exist the user should know about | Edge cases found, tech debt introduced, partial coverage |
| `BLOCKED` | Cannot proceed — requires human intervention | Missing access, ambiguous requirements, 3rd failed attempt |
| `NEEDS_CONTEXT` | Missing information required to continue | Need clarification, missing files, unclear acceptance criteria |

## Required Fields

```
STATUS: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
SUMMARY: {1-2 sentence description of what was accomplished or attempted}
```

### Additional Fields by Status

**DONE:**
```
STATUS: DONE
SUMMARY: {what was accomplished}
DELIVERABLES:
  - {deliverable 1}
  - {deliverable 2}
VERIFICATION: {test results, validation output}
```

**DONE_WITH_CONCERNS:**
```
STATUS: DONE_WITH_CONCERNS
SUMMARY: {what was accomplished}
DELIVERABLES:
  - {deliverable 1}
CONCERNS:
  - {concern 1 — severity and impact}
  - {concern 2 — severity and impact}
VERIFICATION: {test results}
RECOMMENDATION: {suggested follow-up action}
```

**BLOCKED:**
```
STATUS: BLOCKED
SUMMARY: {what was attempted}
REASON: {specific blocker}
ATTEMPTED:
  - {attempt 1 — what was tried and what happened}
  - {attempt 2 — what was tried and what happened}
RECOMMENDATION: {what the user or conductor should do next}
```

**NEEDS_CONTEXT:**
```
STATUS: NEEDS_CONTEXT
SUMMARY: {what was attempted so far}
REASON: {what information is missing}
QUESTIONS:
  - {specific question 1}
  - {specific question 2}
RECOMMENDATION: {who can provide the answer — user, researcher, or specific source}
```

## Escalation Protocol

Subagents track their own attempt count for a given objective:

1. **Attempt 1** — Try the standard approach
2. **Attempt 2** — Try an alternative approach, note what failed on attempt 1
3. **Attempt 3** — If still failing, **STOP** and return `STATUS: BLOCKED`

After 3 failed attempts, the subagent **must not** retry. Return:

```
STATUS: BLOCKED
SUMMARY: Failed after 3 attempts to {objective}
REASON: {root cause if identified, or "unable to determine root cause"}
ATTEMPTED:
  - Attempt 1: {approach} → {result}
  - Attempt 2: {approach} → {result}
  - Attempt 3: {approach} → {result}
RECOMMENDATION: Escalate to user — {specific guidance on what human input would unblock}
```

The conductor will surface BLOCKED responses to the user at the next pause point. Do not retry a BLOCKED subagent without explicit human override.

## Conductor Parsing

The conductor parses completion blocks by matching the `STATUS:` line. When receiving a subagent response:

1. Look for `STATUS:` at the start of a line
2. Extract the status code and route accordingly:
   - `DONE` → Proceed to next phase
   - `DONE_WITH_CONCERNS` → Log concerns, proceed but surface at next pause point
   - `BLOCKED` → Stop pipeline, surface to user immediately
   - `NEEDS_CONTEXT` → Route questions to the appropriate source (user, researcher, or codebase search)

## Usage

Reference this skill in your agent's `skills:` frontmatter. Then end every response to the conductor with the appropriate status block. The status block should be the **last structured section** in your response — after your deliverables, analysis, or findings.
