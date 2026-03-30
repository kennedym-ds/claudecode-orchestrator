# cc-demo — Autonomous SDLC Showcase Plugin

A Claude Code plugin that runs a complete software development lifecycle — from raw idea to a local git commit — with zero human input after the spec is confirmed.

## The Demo

```
/demo "a CLI task manager in Python"
```

```
Spec Interview  (5 turns — you talk, then watch)
       ↓
Phase 1 — planner         (Opus)    → implementation roadmap
Phase 2 — architect       (Opus)    → component design + ADR
Phase 3 — implementer     (Sonnet)  → TDD: tests first, then code
Phase 4 — review-team     (3× Opus) → quality + security + threat (parallel)
Phase 5 — e2e-tester      (Sonnet)  → acceptance tests from spec
Phase 6 — doc-updater     (Sonnet)  → README + inline docs
Phase 7 — deploy-engineer (Haiku)   → pre-deploy check + git commit
       ↓
{os.tmpdir()}/cc-demo/  — built, tested, documented, committed
```

The demo-conductor orchestrates all 7 phases autonomously. Every phase is narrated with cinematic banners. The review phase uses Agent Teams (3 Opus reviewers in parallel) when available.

**Location-agnostic** — the workspace is always `{os.tmpdir()}/cc-demo` (e.g. `/tmp/cc-demo` on Linux/macOS, `C:\Users\you\AppData\Local\Temp\cc-demo` on Windows). Run `/demo` from any terminal in any directory.

## Prerequisites

| Requirement | Why |
|-------------|-----|
| `--dangerously-skip-permissions` | The pipeline writes files without prompting |
| `cc-sdlc-core` installed | All 7 execution agents come from this plugin |
| `ORCH_TEAMS_ENABLED=true` + `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | For parallel review-team (optional — falls back to sequential) |

## Install

```bash
bash installer/install.sh --target /path/to/project --plugins cc-sdlc-core,cc-demo
```

## Usage

```bash
# Start — opens spec interview
/demo

# Seed an idea (still runs the interview)
/demo "a REST API for a TODO list in Python"

# Skip interview — use argument as spec (for scripted or repeated demos)
/demo --skip-interview "Python CLI fibonacci calculator with memoization"

# Force sequential review (no Agent Teams)
/demo --no-teams "a file watcher utility in Node.js"

# Purge the workspace
/demo-teardown
```

## How It Works

### Spec Interview (interactive)
`spec-interviewer` runs a structured 5-turn conversation to produce `$DEMO_WORKSPACE/artifacts/spec.md`. This is the only time the user types anything after `/demo`. After they type `confirmed`, the conductor takes over.

### Autonomous Pipeline
`demo-conductor` drives phases 1-7 without pause. It:
- Prepends a standardised context block (spec, workspace path, phase) to every delegation
- Overrides the normal lifecycle pause-point rules (safe in demo mode with `--dangerously-skip-permissions`)
- Updates `$DEMO_WORKSPACE/artifacts/memory/demo-state.json` after each phase
- Handles BLOCKED agents with a recovery strategy (simplify + retry once, then skip with narration)
- Prints phase banners and completion summaries throughout

### Review Phase — Agent Teams
With `ORCH_TEAMS_ENABLED=true` and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`:
- 3 tasks are injected simultaneously with no dependencies
- `review-team` (reviewer + security-reviewer + threat-modeler) runs in parallel
- demo-conductor synthesises all 3 reports into one consolidated review
- The ~7x cost confirmation is narrated to the audience but not required as a gate

Without Agent Teams: reviewer → security-reviewer → threat-modeler run sequentially.

## Workspace Layout

The workspace lives at `{os.tmpdir()}/cc-demo` — fully outside the project tree.

```
{os.tmpdir()}/cc-demo/
  README.md                              ← updated by doc-updater
  src/                                   ← implementation (implementer)
  tests/
    unit/                                ← unit tests (TDD, implementer)
    e2e/                                 ← acceptance tests (e2e-tester)
  artifacts/
    spec.md                              ← confirmed spec (spec-interviewer)
    plans/{slug}/plan.md                 ← implementation roadmap (planner)
    decisions/ADR-0001-{slug}.md         ← architecture decision (architect)
    reviews/demo-review-{date}.md        ← consolidated review findings
    memory/demo-state.json               ← pipeline state tracker
    sessions/team-state.json             ← Agent Teams state (if used)
```

The `demo-teardown-guard.js` hook blocks any Edit/Write outside this path. The path is set by the `demo-session-start.js` hook via `DEMO_WORKSPACE` env var and is available to all agents.

## Hooks

| Event | Script | Purpose |
|-------|--------|---------|
| SessionStart | `demo-session-start.js` | Create `$DEMO_WORKSPACE` structure in OS temp dir, init `demo-state.json` |
| PreToolUse (Edit\|Write) | `demo-teardown-guard.js` | Block file writes outside `$DEMO_WORKSPACE` |

## Agents

| Agent | Source | Model | Purpose |
|-------|--------|-------|---------|
| `demo-conductor` | cc-demo | Opus | Autonomous pipeline orchestrator with narration |
| `spec-interviewer` | cc-demo | Sonnet | 5-turn interactive spec elicitation |
| `planner` | cc-sdlc-core | Opus | Implementation roadmap |
| `architect` | cc-sdlc-core | Opus | Component design + ADR |
| `implementer` | cc-sdlc-core | Sonnet | TDD implementation |
| `reviewer` | cc-sdlc-core | Opus | Code quality review |
| `security-reviewer` | cc-sdlc-core | Opus | OWASP security review |
| `threat-modeler` | cc-sdlc-core | Opus | STRIDE threat modelling |
| `e2e-tester` | cc-sdlc-core | Sonnet | Acceptance tests |
| `doc-updater` | cc-sdlc-core | Sonnet | README + doc comments |
| `deploy-engineer` | cc-sdlc-core | Haiku | Pre-deploy check + git commit |

## Skills

| Skill | Purpose |
|-------|---------|
| `demo-flow` | Pipeline state machine, delegation templates, BLOCKED recovery |
| `demo-narration` | Banner formats, audience language, completion narration |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ORCH_TEAMS_ENABLED=true` | Enable Agent Teams for parallel review |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | Required alongside ORCH_TEAMS_ENABLED |
| `DEMO_WORKSPACE` | Absolute workspace path — set by session-start hook to `{os.tmpdir()}/cc-demo` |

## Limitations

- Implements **Phase 1 of the plan only** — full multi-phase implementation would require significantly more turns and cost
- Deploy is a local git commit — not a cloud deployment
- `--dangerously-skip-permissions` is required — do not use in production
- Demo workspace is temporary by design — run `/demo-teardown` to purge

## License

MIT
