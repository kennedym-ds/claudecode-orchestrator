# /careful — Enhanced Safety Mode

Toggle enhanced safety mode: $ARGUMENTS

## Instructions

### Enable (default — no arguments, or `on`)

1. Write `ORCH_CAREFUL=true` to `CLAUDE_ENV_FILE` if available
2. Also write a marker file `artifacts/sessions/.careful-mode` as fallback signal
3. Confirm: "Careful mode ON — I will confirm before every file edit and avoid destructive commands."

### Disable (`off`)

1. Write `ORCH_CAREFUL=false` to `CLAUDE_ENV_FILE` if available
2. Remove `artifacts/sessions/.careful-mode` if it exists
3. Confirm: "Careful mode OFF — returning to normal operation."

## Behavior When Active

When `ORCH_CAREFUL=true` or `artifacts/sessions/.careful-mode` exists:

- **Before every file edit**: Describe the change and wait for explicit user confirmation
- **Bash commands**: Prefer read-only commands (`cat`, `ls`, `git status`, `git diff`). Block any command that modifies state unless the user explicitly approves it.
- **Subagent delegation**: Add a note to delegation context that careful mode is active — subagents should follow the same caution level

## Notes

- Careful mode resets when the session ends (env vars are session-scoped)
- The marker file provides persistence if needed across compactions
- This is advisory — enforced by the `safety-mode` rule, not by a blocking hook
