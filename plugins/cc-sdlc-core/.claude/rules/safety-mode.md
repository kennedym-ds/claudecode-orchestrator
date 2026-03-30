---
paths:
  - "**/*"
---

## Safety Mode (Careful + Freeze)

When `ORCH_CAREFUL=true` or the file `artifacts/sessions/.careful-mode` exists:

- Confirm with the user before every file edit — describe what will change and why
- Prefer read-only commands: `cat`, `ls`, `git status`, `git diff`, `Get-Content`, `Get-ChildItem`
- Do not run commands that modify filesystem state without explicit user approval
- Add a "careful mode active" note when delegating to subagents

When `ORCH_FREEZE_PATH` is set or `artifacts/sessions/.freeze-path` exists:

- All file edits MUST be within the frozen directory path
- The `freeze-guard.js` hook enforces this as a hard block on Edit/Write tool use
- Bash commands that write files should also respect the freeze boundary
- Read operations (cat, grep, find) are unrestricted regardless of freeze state
- Report the active freeze path when starting work: "Note: edits frozen to `<path>`"
