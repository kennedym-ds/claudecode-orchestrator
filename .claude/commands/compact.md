# /compact — Strategic Compaction

Compact context while preserving critical state: $ARGUMENTS

## Instructions

1. Save current state to `artifacts/memory/activeContext.md`:
   - Current task and phase
   - Plan progress ({completed} of {total})
   - Last 3 decisions
   - Open questions
   - Active files
   - Model tiers in use
   - Next action
2. Record any unsaved verification results
3. Run `/compact` to trigger context compaction
4. The PreCompact hook will snapshot state automatically
5. After compaction, verify state was restored by the PostCompact hook

Use the strategic-compact skill for compaction strategy guidance.

## When to Use

- After completing a plan phase (before starting next phase)
- After completing implementation (before starting review)
- When the session feels sluggish (context window filling up)
- Before delegating to a subagent
- After `/clear` or major topic shift