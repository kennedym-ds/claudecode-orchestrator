---
name: session-continuity
description: Cross-session state management and recovery
argument-hint: <session-context>
user-invocable: false
---

# Session Continuity

## State Persistence

Critical state is persisted to `artifacts/memory/activeContext.md` by hooks:
- **SessionStart** hook sets env vars via `CLAUDE_ENV_FILE` and logs session start
- **SubagentStart** hook logs subagent launches to `artifacts/sessions/delegation-log.jsonl`
- **SubagentStop** hook logs subagent completions for budget tracking
- **PreCompact** hook saves state before compaction
- **Stop** hook saves state when session pauses
- **SessionEnd** hook archives final state

## activeContext.md Format

```markdown
# Active Context

## Current Task
{One-line description of the active task}

## Phase
{Planning | Implementation Phase N | Review | Complete}

## Plan Progress
{completed} of {total} phases

## Last 3 Decisions
1. {Most recent decision}
2. {Previous decision}
3. {Earlier decision}

## Open Questions
- {Unresolved question 1}
- {Unresolved question 2}

## Active Files
- {path/to/file1}
- {path/to/file2}

## Model Tiers Active
- Heavy: {agent names using Opus}
- Default: {agent names using Sonnet}
- Fast: {agent names using Haiku}

## Next Action
{What should happen next}

## Updated
{ISO timestamp}
```

## Session Resume

When starting a new session that continues previous work:
1. Read `artifacts/memory/activeContext.md`
2. Read `artifacts/artifact-index.md` for recent artifacts
3. Confirm the current phase and plan progress with the user
4. Pick up from the recorded next action

## Session Isolation

When starting unrelated work:
1. Use `/clear` to reset context
2. The Stop hook will save current state before clearing
3. Start fresh — the previous context is preserved in artifacts
