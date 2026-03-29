# /team — Agent Team Management

Manage agent teams for: $ARGUMENTS

## Instructions

Parse the subcommand from `$ARGUMENTS`:

### `assemble <team-name>`

Assemble the named team (review-team, research-team, or implement-team).

1. Check prerequisites via the `team-routing` skill:
   - `ORCH_TEAMS_ENABLED === 'true'` — abort with clear message if not
   - `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS === '1'` — abort with clear message if not
   - No active team in this session (`artifacts/sessions/team-state.json` absent or `status === 'complete'`)
   - For implement-team: confirm zero coupling between modules
2. Read the team definition from `.claude/teams/<team-name>.md`
3. Present cost estimate (~7x single session) and require explicit `y` to proceed
4. Write `artifacts/sessions/team-state.json` (status: assembling)
5. Inject tasks using the task templates from the team definition
6. Spawn the team and begin monitoring `team-state.json`

### `status`

Report current team state.

1. Read `artifacts/sessions/team-state.json` — display status, task counts, teammates
2. Tail the last 10 lines of `artifacts/sessions/team-log.jsonl` for recent events
3. If `artifacts/reviews/team-consensus-pending.md` exists — flag it as awaiting synthesis
4. If no team is active, report "No active team this session"

### `cancel`

Cancel the active team session.

1. Read `artifacts/sessions/team-state.json` — confirm a team is active
2. Set `status: 'cancelled'` and `cancelledAt` timestamp
3. Log event `team_cancelled` to `artifacts/sessions/team-log.jsonl`
4. Report what was completed before cancellation

### `list`

List available team definitions.

1. Glob `.claude/teams/*.md`
2. For each file, read the frontmatter and display: name, complexity tiers, teammate count, model, display_mode
3. Show whether each team requires explicit approval

## Notes

- Teams are opt-in: both `ORCH_TEAMS_ENABLED=true` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` must be set
- Team sessions cost ~7x a single session — always confirm before assembling
- Only one active team per session is supported by the CC runtime
- Use the `team-routing` skill for assembly details
