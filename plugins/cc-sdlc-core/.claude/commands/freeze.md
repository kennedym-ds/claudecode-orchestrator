# /freeze — Restrict Edits to a Directory

Lock edits to a specific path: $ARGUMENTS

## Instructions

1. Parse `$ARGUMENTS` as the target path (required — abort if empty)
2. Resolve the path relative to the project root
3. Write `ORCH_FREEZE_PATH=<resolved-path>` to `CLAUDE_ENV_FILE` if available
4. Also write the path to `artifacts/sessions/.freeze-path` as fallback signal
5. Confirm: "Edits frozen to `<path>` — all file modifications outside this directory will be blocked. Use `/unfreeze` to remove the restriction."

## Behavior When Active

When `ORCH_FREEZE_PATH` is set:

- The `freeze-guard.js` hook (PreToolUse for Edit|Write) blocks any file edit outside the frozen path with exit code 2
- Bash commands that write files outside the frozen path are flagged by the `safety-mode` rule (advisory)
- The restriction applies to all agents including subagents (env var is inherited)

## Notes

- Only one freeze path at a time — setting a new one replaces the previous
- Use a parent directory for broader scope (e.g., `/freeze src/` covers all of src)
- The hook enforces this as a hard block — the agent cannot bypass it
- Freeze resets when the session ends (env vars are session-scoped)
- The marker file provides persistence across compactions
