# /status — Session Status

Show current session state, budget usage, and active context.

## Instructions

1. Read `artifacts/memory/activeContext.md` for current task state
2. Read `artifacts/sessions/delegation-log.jsonl` for budget tracking
3. Report:
   - Current Phase and Plan Progress
   - Last 3 Decisions
   - Open Questions
   - Model tier usage (heavy/default/fast delegation counts)
   - Estimated session cost
   - Next recommended action

## Output Format

```
--- Session Status ---
Task:       {current task}
Phase:      {current phase}
Progress:   {N} of {M} phases
Next:       {next action}

--- Budget ---
Delegations: {N} / 15
Heavy-tier:  {N} ({agent names})
Default-tier: {N} ({agent names})
Fast-tier:   {N}
Est. cost:   ~${amount}

--- Open Questions ---
- {question 1}
- {question 2}
```

Do NOT start any new work — this is a read-only status check.