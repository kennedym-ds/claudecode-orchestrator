Subagent delegation rules:

- The conductor delegates — it does not implement directly
- Match agent to task: read-only agents for review, full-access for implementation
- Summarize context before each delegation
- Read-only agents use permissionMode: plan — they cannot modify files
- Never spawn more than 3 concurrent subagents
- Track every delegation for budget gatekeeper reporting
- Escalate back to the user if a subagent fails twice on the same task

Escalation counter:

- Track attempt count per delegation objective
- On 3rd failure, subagent must return STATUS: BLOCKED with all 3 attempts documented
- Conductor must surface BLOCKED responses to the user at the next pause point — do not retry silently
- Only retry a BLOCKED delegation with explicit human override
- All subagents must use the completion-protocol skill for structured responses (STATUS, SUMMARY, DELIVERABLES, etc.)

Team delegation guardrails:

- Teams are opt-in: both `ORCH_TEAMS_ENABLED=true` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set before assembling any team
- Only one active team per session — check `artifacts/sessions/team-state.json` before assembling
- Never assemble a team without presenting the ~7x cost estimate and receiving explicit `y` confirmation
- implement-team requires the planner to have confirmed zero coupling between modules — never assemble without this confirmation
- If team assembly fails for any reason, fall back to subagent delegation silently — never fail the task
- Teams are DEEP/ULTRADEEP only — never assemble for INSTANT or STANDARD tasks
