# Using Agent Teams

Agent Teams run multiple specialized Claude instances in parallel, each with its own context window, within a single orchestrated session. This guide covers when to use teams, how to enable them, and what to expect.

## Table of Contents

- [Overview](#overview)
- [When to Use Teams](#when-to-use-teams)
- [Prerequisites](#prerequisites)
- [Enabling Teams](#enabling-teams)
- [Available Teams](#available-teams)
- [Running a Team Session](#running-a-team-session)
- [Cost and Budget](#cost-and-budget)
- [Team State and Monitoring](#team-state-and-monitoring)
- [Fallback Behavior](#fallback-behavior)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

By default, cc-sdlc orchestrates tasks using sequential subagents — the conductor delegates to one agent at a time. Agent Teams remove this bottleneck for DEEP and ULTRADEEP tasks by running multiple agents simultaneously:

| Mode | How it works | Best for |
|------|-------------|----------|
| **Subagent** (default) | Sequential delegation — one agent at a time | Most tasks |
| **Team** (opt-in) | Parallel — multiple agents with shared task list | Large DEEP/ULTRADEEP tasks |

Teams are an opt-in experimental feature. The subagent mode remains the default and is always available as a fallback.

---

## When to Use Teams

Teams are beneficial only for DEEP or ULTRADEEP tasks where phases can genuinely run in parallel:

| Scenario | Recommended Team | Benefit |
|----------|-----------------|---------|
| Large multi-file feature needing code + security + threat review | `review-team` | All 3 reviewers run simultaneously |
| Research question with 3 orthogonal sub-topics | `research-team` | Each sub-topic explored in parallel |
| ULTRADEEP feature with two clearly independent modules | `implement-team` | Both modules implemented simultaneously |

**Do not use teams for:**
- INSTANT or STANDARD tasks — the overhead isn't justified
- Work where modules share state or contracts — use sequential implementers
- Exploratory work — teams require upfront task decomposition

---

## Prerequisites

| Requirement | How to Set |
|------------|-----------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | `.claude/settings.json` → `env` |
| `ORCH_TEAMS_ENABLED=true` | `.claude/settings.json` → `env` |
| Task complexity: DEEP or ULTRADEEP | Assessed by conductor via `/route` |
| No active team in this session | Checked automatically |
| For implement-team: confirmed zero coupling | Planner must confirm before assembly |

Both env vars must be set. If either is absent, the conductor falls back to subagent mode silently.

---

## Enabling Teams

### Option 1: Copy a ready-made settings profile

```bash
# From the repo root — enable teams with standard models
cp examples/settings-teams-enabled.json .claude/settings.json

# With premium models (Opus for all judgment roles)
cp examples/settings-teams-premium.json .claude/settings.json
```

### Option 2: Edit `.claude/settings.json` manually

```json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
    "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "ORCH_TEAMS_ENABLED": "true",
    "ORCH_TEAM_MAX_TASKS": "20",
    "ORCH_TEAM_SIZE_MAX": "3",
    "ORCH_TEAM_DISPLAY_MODE": "auto",
    "ORCH_TEAM_AUTO_ROUTE": "false"
  }
}
```

### Auto-routing vs. explicit flag

| Setting | Behavior |
|---------|----------|
| `ORCH_TEAM_AUTO_ROUTE=false` (default) | Teams only when you pass `--team` to `/conduct` |
| `ORCH_TEAM_AUTO_ROUTE=true` | Conductor auto-selects teams for DEEP/ULTRADEEP tasks |

Auto-routing is off by default to keep costs predictable. Enable it once you're comfortable with team sessions.

---

## Available Teams

### review-team

Three reviewers run in parallel, each from a distinct angle:

| Teammate | Role | Focus |
|----------|------|-------|
| reviewer | Quality review | Correctness, logic, maintainability, test coverage |
| security-reviewer | Security audit | OWASP, auth, injection, data exposure |
| threat-modeler | Threat modeling | STRIDE/DREAD, attack surface, mitigations |

All three run on Opus. The conductor synthesizes their findings using the `pr-review` skill after all complete. Used for DEEP and ULTRADEEP tasks.

### research-team

Two or three researchers explore orthogonal sub-questions simultaneously:

| Teammate | Task | Model |
|----------|------|-------|
| researcher-1 | Domain/technology research | Sonnet |
| researcher-2 | Prior art and alternatives | Sonnet |
| researcher-3 *(ULTRADEEP only)* | Risk and edge case research | Sonnet |

The planner synthesizes findings from `artifacts/research/` into a planning brief. researcher-3 is only assembled when `ORCH_TEAM_SIZE_MAX >= 3` and complexity is ULTRADEEP.

### implement-team

Two implementers work on independent modules in isolated git worktrees:

| Teammate | Scope | Model | Isolation |
|----------|-------|-------|-----------|
| implementer-1 | Module 1 (non-overlapping files) | Sonnet | worktree |
| implementer-2 | Module 2 (non-overlapping files) | Sonnet | worktree |

**Requires explicit user approval and zero-coupling confirmation.** The planner must have decomposed the work into modules with no shared imports, state, or API contracts. ULTRADEEP only.

After completion, the conductor merges both worktrees, runs the verification loop, then assembles a review-team.

---

## Running a Team Session

### With `--team` flag (recommended)

```bash
claude --agent conductor

# Full lifecycle with team mode enabled at DEEP/ULTRADEEP phases
/conduct --team Add OAuth2 authentication with GitHub and Google providers
```

The conductor will:
1. Assess complexity → DEEP
2. Plan with planner agent (subagent)
3. **PAUSE** — present plan + team cost estimate, wait for approval
4. Assemble research-team → parallel research
5. Assemble implement-team (if applicable) → parallel implementation
6. Assemble review-team → parallel review
7. Synthesize findings, present final report

### With auto-routing

```bash
# Set ORCH_TEAM_AUTO_ROUTE=true in settings.json, then:
/conduct Add OAuth2 authentication with GitHub and Google providers
# Conductor auto-selects teams for DEEP phases
```

### Direct team management

```bash
# Check what teams are available
/team list

# Assemble a specific team manually
/team assemble review-team

# Check team status
/team status

# Cancel if needed
/team cancel
```

---

## Cost and Budget

Team sessions cost approximately **7x a single session**. Before assembling any team, the conductor presents a cost estimate and requires explicit confirmation:

```
Team mode cost estimate
  Team: review-team
  Teammates: 3 × Opus (~$15/MTok input, ~$75/MTok output)
  Expected turns per teammate: 20
  Estimated multiplier: ~7x vs single session
  Estimated session cost: ~$2.10

Proceed? [y/N]
```

Only `y` or `yes` proceeds. Any other input uses subagent fallback instead.

### Budget limits

| Limit | Warning | Hard Stop |
|-------|---------|-----------|
| Active teams per session | — | 1 (CC runtime enforces) |
| Tasks per team | — | `ORCH_TEAM_MAX_TASKS` (default 20) |
| Estimated team cost | $10.00 | User confirmed before assembly |

Hard cost caps work as usual:

```bash
claude --agent conductor --max-budget-usd 10
```

---

## Team State and Monitoring

Team state is persisted in `artifacts/sessions/team-state.json` and updated by hooks:

```json
{
  "teamName": "review-team",
  "assembledAt": "2026-03-29T10:00:00Z",
  "status": "in_progress",
  "totalTaskCount": 3,
  "completedTaskCount": 1,
  "teammates": ["reviewer", "security-reviewer", "threat-modeler"],
  "taskIds": ["review-quality", "review-security", "review-threat"]
}
```

Status values: `assembling` → `in_progress` → `all_tasks_complete` → `complete`

Events are logged to `artifacts/sessions/team-log.jsonl`:

```jsonl
{"event":"team_assembled","teamName":"review-team","timestamp":"..."}
{"event":"teammate_task_complete","taskId":"review-quality","teamName":"review-team","timestamp":"..."}
{"event":"team_complete","teamName":"review-team","timestamp":"..."}
```

### Check status mid-session

```bash
/team status
# Shows: current status, task counts, recent events, pending synthesis
```

---

## Fallback Behavior

The conductor always falls back to sequential subagent mode if:

- `ORCH_TEAMS_ENABLED` is not `true`
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is not `1`
- Complexity is INSTANT or STANDARD
- Another team is already active this session
- User does not confirm the cost estimate
- Team assembly fails for any reason

Fallback is silent — the task continues with subagents. No action required.

---

## Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `ORCH_TEAMS_ENABLED` | `false` | Master switch — must be `true` to enable teams |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | CC runtime flag — must be `1` |
| `ORCH_TEAM_MAX_TASKS` | `20` | Maximum tasks per team (TaskCreated hook blocks at limit) |
| `ORCH_TEAM_SIZE_MAX` | `3` | Maximum teammates (controls research-team size) |
| `ORCH_TEAM_DISPLAY_MODE` | `auto` | `auto` or `split-panes` (split-panes requires tmux/iTerm2) |
| `ORCH_TEAM_AUTO_ROUTE` | `false` | Auto-assemble teams for DEEP/ULTRADEEP without `--team` flag |

---

## Troubleshooting

### "Teams not available — falling back to subagent mode"

Check both env vars are set correctly:

```bash
cat .claude/settings.json | grep -E "ORCH_TEAMS|EXPERIMENTAL"
# Expected:
# "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
# "ORCH_TEAMS_ENABLED": "true",
```

### "Task limit reached — cannot create new tasks"

The `ORCH_TEAM_MAX_TASKS` limit was hit. Either:
- Increase `ORCH_TEAM_MAX_TASKS` in settings
- Break the task into smaller sessions

### "Another team is already active"

Only one team per session. Check `artifacts/sessions/team-state.json`:

```bash
cat artifacts/sessions/team-state.json
# If status is 'complete', the conductor can assemble a new team
# If status is 'in_progress', wait or run /team cancel
```

### review-team synthesis not starting

The conductor waits for `artifacts/reviews/team-consensus-pending.md` before synthesizing. If it's missing after teammates complete, check `team-log.jsonl` for the `task-completed.js` hook output.

### implement-team: merge conflicts after worktree merge

This means the modules were not truly zero-coupling. Use sequential subagent implementation instead — cancel the team, re-plan with a single implementer.

---

## Further Reading

- [Installation Guide](installation.md) — Configure settings for teams
- [User Guide](user-guide.md) — Team mode in the full workflow
- [Creating Agents](creating-agents.md) — Custom agent frontmatter including `isolation: worktree`
- [Creating Hooks](creating-hooks.md) — TeammateIdle, TaskCreated, TaskCompleted hooks
