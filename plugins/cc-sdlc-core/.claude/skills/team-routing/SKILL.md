---
name: team-routing
description: Agent Teams assembly and task injection — selects appropriate team, validates prerequisites, estimates cost, injects tasks into the shared task list, and manages team lifecycle.
argument-hint: <team-name> <scope>
user-invocable: false
---

# Team Routing

## Team Selection Matrix

| Phase | Complexity | Preferred Team | Fallback |
|-------|-----------|----------------|---------|
| Research | DEEP | research-team (2 researchers) | Subagent researcher |
| Research | ULTRADEEP | research-team (3 researchers) | Subagent researcher |
| Review | DEEP | review-team | Subagent reviewer + security-reviewer |
| Review | ULTRADEEP | review-team | Subagent trilateral review |
| Implement | ULTRADEEP (modular) | implement-team | Sequential subagent implementers |

Teams are **never** used for INSTANT or STANDARD complexity. Cost does not justify it.

## Prerequisite Checks

Before assembling any team, verify all of:

1. `ORCH_TEAMS_ENABLED === 'true'` — if not, log and fall back to subagent mode silently
2. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS === '1'` — if not, log and fall back
3. Complexity is DEEP or ULTRADEEP
4. No active team in this session (`team-state.json` does not exist or `status === 'complete'`)
5. For implement-team only: planner has confirmed zero coupling between modules

If any check fails, fall back to subagent delegation without user disruption.

## Cost Estimation

Present this estimate before assembly (require user confirmation):

```
Team mode cost estimate
  Team: {team-name}
  Teammates: {count} × {model} (Opus ~$15/MTok, Sonnet ~$3/MTok)
  Expected turns per teammate: {maxTurns}
  Estimated multiplier: ~7x vs single session
  Estimated session cost: ~${estimate}

Proceed? [y/N] (default: N — use subagent mode instead)
```

Only proceed on explicit `y` or `yes`. Any other response → subagent fallback.

For implement-team, also display the module partition plan and require confirmation that modules are non-overlapping.

## Task Injection Protocol

### Step 1: Write team-state.json

```json
{
  "teamName": "{team-name}",
  "assembledAt": "{ISO8601}",
  "sessionId": "{CLAUDE_SESSION_ID}",
  "totalTaskCount": 0,
  "completedTaskCount": 0,
  "status": "assembling",
  "teammates": ["{role-1}", "{role-2}", ...],
  "taskIds": []
}
```

Write to `artifacts/sessions/team-state.json` before spawning.

### Step 2: Compose tasks

For each task, provide:
- `task_id`: short slug (e.g., `review-quality`, `research-domain`)
- `team_name`: matches team definition
- `title`: clear imperative title
- `description`: full instructions from the team's task template, with `{scope}` and `{slug}` filled in
- `dependencies`: array of task IDs that must complete first (empty for parallel tasks)
- `created_by`: `conductor`

### Step 3: Inject and update state

After all tasks are injected (and `TaskCreated` hooks have fired), update `team-state.json`:
- `status`: `in_progress`
- `totalTaskCount`: actual count
- `taskIds`: all injected IDs

### Step 4: Spawn team

Request team assembly using the team name. Set display_mode from team frontmatter (`auto` / `split-panes`).

## Monitoring

After assembly:
- Monitor `artifacts/sessions/team-state.json` for `status === 'all_tasks_complete'`
- Monitor `artifacts/sessions/team-log.jsonl` for completion events
- For review-team: watch for `artifacts/reviews/team-consensus-pending.md`

Do not proceed to synthesis until the completion signal is present.

## Synthesis Handoff

| Team | Synthesis Agent | Synthesis Action |
|------|----------------|-----------------|
| review-team | conductor | Invoke `pr-review` skill on merged findings; remove `team-consensus-pending.md` after synthesis |
| research-team | planner | Read all `artifacts/research/{slug}-*.md`; produce planning brief |
| implement-team | conductor | Merge worktrees; run `verification-loop`; then assemble review-team |

## Team Teardown

After synthesis:
1. Update `team-state.json`: `status → 'complete'`
2. Archive `team-log.jsonl` (it persists in `artifacts/sessions/` — no action needed)
3. Continue SDLC lifecycle (conductor resumes as lead)

## Fallback Decision Tree

```
ORCH_TEAMS_ENABLED=true?
  No  → use subagent mode (silent fallback)
  Yes → CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1?
          No  → use subagent mode (log warning)
          Yes → complexity DEEP or ULTRADEEP?
                  No  → use subagent mode
                  Yes → user confirmed cost?
                          No  → use subagent mode
                          Yes → assemble team
                                  failure? → log to team-log.jsonl + subagent fallback
```

Never fail the overall task due to team unavailability.
