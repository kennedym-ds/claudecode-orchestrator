---
name: strategic-compact
description: Context compaction strategy for long sessions
argument-hint: <current-session-state>
user-invocable: false
---

# Strategic Compact

## When to Compact

- After completing a plan phase (before starting implementation)
- After completing implementation (before starting review)
- When context window is > 60% full
- After a `/clear` or major topic shift
- Before delegating to a subagent (they get fresh context anyway)

## Pre-Compaction Checklist

Before running `/compact`, ensure:
1. Current phase and progress are recorded in `artifacts/memory/activeContext.md`
2. The most recent plan is saved to `artifacts/plans/`
3. Open questions and blockers are noted
4. Verification results are logged

The `PreCompact` hook (`hooks/scripts/pre-compact.js`) handles this automatically.

## Compaction Strategy

When compacting, prioritize retaining:
1. **Current objective** — What are we doing and why
2. **Phase progress** — Where are we in the plan
3. **Last 3 decisions** — Recent context that shapes next steps
4. **Open questions** — Unresolved items needing attention
5. **File paths** — What files are in play

Deprioritize:
- Detailed code snippets already written to files
- Exploration results that led to dead ends
- Verbose tool outputs that have been summarized

## Post-Compaction Recovery

The `PostCompact` hook restores state from `artifacts/memory/activeContext.md`. After compaction:
1. Verify the state tracking block is intact
2. Confirm you know the current phase and next action
3. If state is unclear, read `activeContext.md` explicitly

## Environment Variables

- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50` — Compact earlier (default: 80%)
- Set in `.claude/settings.json` → `env` or via CLI
