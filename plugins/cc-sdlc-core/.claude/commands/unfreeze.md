# /unfreeze — Remove Edit Restriction

Remove the directory edit restriction: $ARGUMENTS

## Instructions

1. Write `ORCH_FREEZE_PATH=` (empty) to `CLAUDE_ENV_FILE` if available
2. Remove `artifacts/sessions/.freeze-path` if it exists
3. Confirm: "Edit restriction removed — all files are now editable."

## Notes

- If no freeze is active, report: "No freeze is currently active."
- This does not affect `/careful` mode — those are independent controls
