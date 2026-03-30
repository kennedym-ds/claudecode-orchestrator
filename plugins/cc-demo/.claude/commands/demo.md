# /demo — Autonomous SDLC Showcase

Start a fully autonomous end-to-end SDLC demo: $ARGUMENTS

## What This Does

Runs a complete software development lifecycle from raw idea to a local git commit — live, with zero human input after the spec is confirmed:

```
Spec Interview  (5 turns — interactive)
       ↓
Phase 1 — planner (Opus)         → implementation roadmap
Phase 2 — architect (Opus)       → component design + ADR
Phase 3 — implementer (Sonnet)   → TDD: tests first, then code
Phase 4 — review-team (3x Opus)  → quality + security + threat model (parallel)
Phase 5 — e2e-tester (Sonnet)    → acceptance tests
Phase 6 — doc-updater (Sonnet)   → README + inline docs
Phase 7 — deploy-engineer (Haiku)→ pre-deploy check + git commit
       ↓
{os.tmpdir()}/cc-demo/ — fully built, tested, documented, committed
```

## Prerequisites

- Run Claude Code with `--dangerously-skip-permissions` — the pipeline writes files autonomously
- `cc-sdlc-core` plugin must be installed (required dependency)
- For parallel review-team (Phase 4): set `ORCH_TEAMS_ENABLED=true` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## Instructions

1. Invoke `demo-conductor` with the full argument string and these parameters:
   - Working root: resolved absolute path from `$DEMO_WORKSPACE` (set by session-start hook)
   - Mode: `autonomous-after-spec`
   - Teams flag: check `ORCH_TEAMS_ENABLED` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
2. `demo-conductor` handles all phase sequencing, narration, and delegation
3. Do NOT pause at intermediate phases — autonomous mode overrides all lifecycle pause points
4. Output narration banners before each phase and completion summaries after

## Flags

- `--preset <name>` — Use a pre-built spec and simulate the interview as a scripted replay. No typing required — the full conversation plays back automatically then the pipeline runs. Available presets: `react-graphs` (React interactive graphing dashboard).
- `--skip-interview` — Use `$ARGUMENTS` as the spec directly (for scripted or repeated demos)
- `--no-teams` — Force sequential subagent review even if Agent Teams env vars are set
- `--verbose` — Print full agent output instead of narrated summaries

## Cleanup

Run `/demo-teardown` to purge the workspace after the demo.
