# /conduct — Lifecycle Orchestrator

Start a multi-phase workflow for: $ARGUMENTS

## Instructions

1. Assess the complexity of this task using the delegation-routing skill
2. Select the appropriate workflow depth (INSTANT/STANDARD/DEEP/ULTRADEEP)
3. Determine model tiers for each phase based on complexity
4. Begin the lifecycle: Plan → Implement → Review → Complete
5. If `--team` flag is present in `$ARGUMENTS` (or `ORCH_TEAM_AUTO_ROUTE=true` and complexity is DEEP/ULTRADEEP), check team eligibility via the `team-routing` skill before starting each phase
6. Enforce pause points after plans and reviews
7. Track state in every response (Current Phase, Plan Progress, Last Action, Next Action)

## Flags

- `--team` — Enable team mode for DEEP/ULTRADEEP phases (requires `ORCH_TEAMS_ENABLED=true` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Context

Read `artifacts/memory/activeContext.md` if continuing a previous session.
Use the conductor agent for orchestration.
