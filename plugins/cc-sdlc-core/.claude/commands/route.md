# /route — Complexity Assessment

Assess the complexity of: $ARGUMENTS

## Instructions

1. Evaluate the task against the delegation-routing skill's criteria:
   - Files affected
   - Test changes needed
   - Architectural impact
   - Security sensitivity
   - Risk of regression
   - Estimated lines of change

2. Classify: INSTANT / STANDARD / DEEP / ULTRADEEP

3. Recommend:
   - Agents to involve
   - Model tiers for each agent
   - Pause points
   - Estimated effort

4. If complexity is DEEP or ULTRADEEP, add a **Team Mode** recommendation:
   - Which teams are applicable (review-team, research-team, implement-team)
   - Prerequisite status: check `ORCH_TEAMS_ENABLED` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
   - Estimated cost multiplier (~7x) vs subagent mode
   - How to enable: `/conduct --team <task>`

Do NOT start execution — only assess and recommend.
Use the delegation-routing skill.
