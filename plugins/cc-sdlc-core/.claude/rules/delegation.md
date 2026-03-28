Subagent delegation rules:

- The conductor delegates — it does not implement directly
- Match agent to task: read-only agents for review, full-access for implementation
- Summarize context before each delegation
- Read-only agents use permissionMode: plan — they cannot modify files
- Never spawn more than 3 concurrent subagents
- Track every delegation for budget gatekeeper reporting
- Escalate back to the user if a subagent fails twice on the same task
