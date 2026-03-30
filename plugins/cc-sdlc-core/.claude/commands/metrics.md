# /metrics — Session Analytics

Display session analytics: $ARGUMENTS

## Instructions

Read session log files from `artifacts/sessions/` and present a summary.

### Data Sources

- `artifacts/sessions/session-log.jsonl` — session start/stop events
- `artifacts/sessions/delegation-log.jsonl` — subagent start/stop events
- `artifacts/sessions/audit-log.jsonl` — file edit events

### Report

Generate a Markdown report with these sections:

1. **Session Summary**: Total sessions, date range of logs
2. **Delegation Summary**: Total delegations, breakdown by agent name, sorted by frequency
3. **File Activity**: Total edits, most-edited files (top 10)
4. **Agent Usage by Session**: Average delegations per session

### Format

```
--- Session Metrics ---
Sessions:    {N} ({date range})
Delegations: {N} total across {M} agents

--- Agent Usage (top 10) ---
| Agent | Delegations | % of Total |
|-------|-------------|------------|
| {name} | {count} | {pct}% |

--- Most Edited Files (top 10) ---
| File | Edits |
|------|-------|
| {path} | {count} |
```

### Flags

- No arguments: show the full report
- `--agents`: show only agent usage
- `--files`: show only file activity
- `--sessions`: show only session summary

## Notes

- If no log files exist, report: "No session data found. Run some sessions first."
- Use `scripts/analyze-sessions.ps1` or `scripts/analyze-sessions.sh` for the same data in a terminal context
- This command is read-only — it never modifies any files
