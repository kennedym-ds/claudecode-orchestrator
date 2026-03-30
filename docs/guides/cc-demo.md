# cc-demo — Autonomous SDLC Showcase Guide

The `cc-demo` plugin runs a complete software development lifecycle — from a raw idea to a local git commit — with zero human input after you confirm the spec. It's a live showcase of every cc-sdlc-core capability: spec elicitation, planning, architecture, TDD implementation, parallel review, acceptance testing, documentation, and deployment.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Usage](#cli-usage)
- [The Pipeline](#the-pipeline)
- [Terminal Output](#terminal-output)
- [Agent Teams Mode](#agent-teams-mode)
- [Preset Mode — Hands-Off Demo](#preset-mode--hands-off-demo)
- [Spec Interview](#spec-interview)
- [Resuming a Demo](#resuming-a-demo)
- [Teardown](#teardown)
- [Workspace Layout](#workspace-layout)
- [Environment Variables](#environment-variables)
- [Troubleshooting](#troubleshooting)

---

## Overview

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

The workspace is always in the OS temp directory — `/tmp/cc-demo` on Linux/macOS, `C:\Users\you\AppData\Local\Temp\cc-demo` on Windows. Call `/demo` from any terminal in any directory.

---

## Prerequisites

| Requirement | Why |
|-------------|-----|
| `--dangerously-skip-permissions` | The pipeline writes files without prompting — required for a fully autonomous run |
| `cc-sdlc-core` installed | All 7 execution agents (planner through deploy-engineer) live in this plugin |
| Node.js in PATH | Hook scripts are Node.js — required for the session-start, teardown guard, visual ticker, and opening sequence |
| `ORCH_TEAMS_ENABLED=true` + `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | For parallel review (Phase 4) — optional, falls back to sequential |

`--dangerously-skip-permissions` is intentional and scoped to the demo workspace only. The `demo-teardown-guard.js` hook blocks any file write outside `$DEMO_WORKSPACE`, so no project files can be touched.

---

## Installation

```bash
bash installer/install.sh --target /path/to/project --plugins cc-sdlc-core,cc-demo
```

Or deploy user-level (available from any terminal):

```bash
bash scripts/deploy-user.sh
```

Verify both plugins are present:

```bash
bash scripts/validate-assets.sh --verbose | grep -E "cc-sdlc-core|cc-demo"
```

---

## Quick Start

```bash
# Start Claude Code with autonomous permissions
claude --dangerously-skip-permissions

# Fully hands-off — pre-built spec, simulated interview, no typing required
/demo --preset react-graphs

# Run the demo — opens the live spec interview
/demo

# Seed an idea (interview still runs)
/demo "a REST API for a TODO list in Python"

# Skip the interview — use the argument as the full spec
/demo --skip-interview "Python CLI fibonacci calculator with memoization"
```

For a presentation: use `--preset react-graphs`. For an interactive demo: use `/demo` with or without an idea. After you type `confirmed` at the end of the interview, the conductor takes over completely.

---

## CLI Usage

### `/demo [flags] [idea]`

| Flag | Effect |
|------|--------|
| *(no flags)* | Opens spec interview |
| `"your idea"` | Seeds the interview with an initial concept |
| `--preset <name>` | Fully hands-off: loads a pre-built spec, simulates the interview as a scripted replay, then runs the autonomous pipeline. No typing required at any point. |
| `--skip-interview "spec text"` | Uses argument as spec directly — no interview, no replay. Useful for repeated or scripted demos |
| `--no-teams` | Forces sequential subagent review even if Agent Teams env vars are set |
| `--verbose` | Prints full agent output instead of narrated summaries |

### `/demo-teardown`

Purges the demo workspace. Shows the git log and requires an explicit `y` confirmation before deleting anything.

---

## The Pipeline

### Phase 0 — Spec Interview

`spec-interviewer` (Sonnet) runs a structured 5-turn conversation:

1. **Idea Capture** — what are you building?
2. **Scope Lock** — in scope, out of scope, constraints
3. **Behaviour Walkthrough** — key user flows, edge cases
4. **Risk Check** — what could go wrong?
5. **Confirmation** — review and type `confirmed`

Once you type `confirmed`, the spec is written to `$DEMO_WORKSPACE/artifacts/spec.md` and the conductor takes over. You won't be prompted again.

### Phase 1 — Plan

`planner` (Opus) reads the spec and produces a multi-phase implementation roadmap at `artifacts/plans/{slug}/plan.md`. This defines the module structure the implementer will follow.

### Phase 2 — Architect

`architect` (Opus) produces a component design and Architecture Decision Record at `artifacts/decisions/ADR-0001-{slug}.md`. This gives the implementer a blueprint.

### Phase 3 — Implement

`implementer` (Sonnet) follows TDD: writes failing tests first, then source code, then refactors. Output goes to `src/` and `tests/unit/`. The conductor narrates as files are created.

### Phase 4 — Review

With Agent Teams (recommended):
- `reviewer`, `security-reviewer`, and `threat-modeler` (all Opus) run simultaneously
- Each has an independent context window — findings are unbiased
- Reports written to `artifacts/reviews/review-quality.md`, `review-security.md`, `review-threat.md`
- Conductor synthesizes into `artifacts/reviews/demo-review-{date}.md`

Without Agent Teams: the three reviewers run sequentially in the same order.

### Phase 5 — E2E Tests

`e2e-tester` (Sonnet) writes acceptance tests derived from the spec's acceptance criteria. Output goes to `tests/e2e/`.

### Phase 6 — Documentation

`doc-updater` (Sonnet) updates `README.md` and adds inline documentation to key source files.

### Phase 7 — Deploy

`deploy-engineer` (Haiku) runs a pre-deploy readiness check, then commits all workspace files to the local git repo at `$DEMO_WORKSPACE` with a descriptive commit message.

---

## Terminal Output

The demo is designed to be visually engaging throughout.

### Session Opening (automatic)

When Claude Code starts with cc-demo installed, `demo-opening.js` fires automatically and prints:

- Full ASCII art `CC-DEMO` logo in bright cyan
- Pipeline overview with numbered phase icons (① through ⑧)
- Model tier legend: `● Opus` (red) · `● Sonnet` (yellow) · `● Haiku` (green)
- Resolved workspace path and `--dangerously-skip-permissions` mode notice

This fires once per session via the `SessionStart` hook. No action required.

### Pipeline Scoreboard

Before every phase banner, the conductor prints a live scoreboard:

```
  Pipeline:  ✓SPEC  ✓PLAN  ✓ARCH  ⚡IMPL  ·REVIEW  ·E2E  ·DOC  ·DEPLOY
```

- `✓` (bright green) — phase complete
- `⚡` (bright cyan) — currently active
- `⟳` (yellow) — skipped due to recovery failure
- `·` (dim) — pending

### Phase Banners

Each phase opens with a box-drawn banner:

```
╔══════════════════════════════════════════════════════════════════════╗
║  PHASE 3 — IMPLEMENTATION (TDD)                                      ║
║  Agent: implementer · ● Sonnet · max 30 turns                        ║
║  Red-Green-Refactor: tests first, then implementation                ║
╚══════════════════════════════════════════════════════════════════════╝
```

And closes with a completion summary quoting artifact names:

```
✓ PHASE 3 — IMPLEMENTATION (TDD)
  implementer wrote 4 source files and 12 unit tests. All tests pass.
  Artifacts: src/main.py, src/cli.py, tests/unit/test_main.py, tests/unit/test_cli.py
```

### Live Agent Ticker

The `demo-agent-ticker.js` hook fires on every `SubagentStart` and `SubagentStop` event, printing a real-time feed:

```
10:42:03  ⚡ DISPATCHING  implementer  ·  ● Sonnet
10:43:57  ✓ RETURNED     implementer  →  DONE  (1m 54s)
10:43:58  ⚡ DISPATCHING  reviewer     ·  ● Opus
10:46:12  ✓ RETURNED     reviewer     →  DONE_WITH_CONCERNS  (2m 14s)
```

Tier colours match the opening legend. BLOCKED agents are shown in red with a `✗` icon.

### No-Colour Mode

If `NO_COLOR` is set in the environment, all ANSI codes are stripped and the output falls back to plain ASCII. Box-drawing characters are preserved.

---

## Agent Teams Mode

Parallel review runs three Opus reviewers simultaneously, each with an independent context window.

### Enable

```json
// .claude/settings.json
{
  "env": {
    "ORCH_TEAMS_ENABLED": "true",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or set at launch:

```bash
ORCH_TEAMS_ENABLED=true CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --dangerously-skip-permissions
/demo "a REST API for TODO lists"
```

### What changes at Phase 4

Without teams:
```
╔══════════════════════════════════════════════════════════════════════╗
║  PHASE 4 — SEQUENTIAL REVIEW                                         ║
║  reviewer → security-reviewer → threat-modeler                       ║
╚══════════════════════════════════════════════════════════════════════╝
```

With teams:
```
╔══════════════════════════════════════════════════════════════════════╗
║  PHASE 4 — PARALLEL REVIEW  (Agent Teams)                            ║
║  ● reviewer  ● security-reviewer  ● threat-modeler                   ║
║  3 Opus agents run simultaneously — independent context windows      ║
║  (~7x cost narrated to audience — not a blocking gate in demo mode)  ║
╚══════════════════════════════════════════════════════════════════════╝
```

The ~7x cost confirmation that production sessions require is narrated to the audience and skipped as a gate — the demo already runs with `--dangerously-skip-permissions`. The live ticker shows all three agents dispatching near-simultaneously.

### Fallback

If either env var is absent, the conductor falls back to sequential subagents silently. The demo continues — Phase 4 just takes longer.

---

## Preset Mode — Hands-Off Demo

For presentations where you don't want to type anything — no spec interview, no `confirmed`, no interaction at all — use a preset. The spec is pre-written, and the interview plays back as a scripted conversation so the audience still sees the full flow.

```bash
/demo --preset react-graphs
```

That's the entire command. Nothing else required.

### What happens

1. The pre-built spec loads from the workspace (copied there at session start)
2. The interview replay prints automatically, turn by turn, with realistic pauses:

```
╔══════════════════════════════════════════════════════════════════════╗
║  SPEC INTERVIEW — REPLAY MODE                                        ║
║  Preset: react-graphs  ·  simulated 5-turn conversation             ║
╚══════════════════════════════════════════════════════════════════════╝

  ── TURN 1 — IDEA CAPTURE ──

  spec-interviewer ·  What are you building? Give me the core idea in
                      a sentence or two — don't worry about details yet.

  you ·  An interactive graphing platform in React — a live dashboard that
         shows four different chart types side by side, all updating in real
         time with simulated data...

  ── TURN 2 — SCOPE LOCK ──
  ...

  ✓ Spec confirmed — handing off to the autonomous pipeline
```

3. The 7-phase autonomous pipeline runs as normal

From first keystroke to git commit — zero interaction.

### Available Presets

| Name | Project | Stack | What gets built |
|------|---------|-------|-----------------|
| `react-graphs` | GraphBoard | React 18, Vite, Recharts, Vitest | Interactive graphing dashboard: 4 live-updating chart types (line, bar, pie, scatter), per-chart config drawer, light/dark theme, PNG export |

### The react-graphs preset in detail

**GraphBoard** is designed to be a visually compelling demo target — it produces something an audience can immediately understand and appreciate:

- Four chart panels in a 2×2 grid, all live-ticking at 1 Hz
- Line chart with zoom/pan, Bar chart with animation, Pie/Donut, Scatter with bubble sizing
- Per-chart settings: title, 8-colour preset palette, update speed (0.5×–5×), pause/resume toggle
- Global light/dark theme toggle with localStorage persistence
- PNG export via html2canvas at 2× resolution
- React.memo and useMemo throughout for smooth 50+ fps with all charts running

The spec includes a full component tree (`App.jsx`, `Dashboard`, `ChartPanel`, `ConfigDrawer`, individual chart components, custom hooks for data simulation, theme, and export), acceptance criteria tied to the e2e phase, and explicit risk callouts for the implementer.

### Adding Your Own Preset

Create two files in `plugins/cc-demo/presets/{name}/`:

**`spec.md`** — the complete confirmed spec. Follow the same format as the react-graphs example: overview, requirements table, out-of-scope, key user flows, acceptance criteria, component architecture, risks.

**`replay.json`** — the scripted interview. Structure:
```json
{
  "preset": "my-preset",
  "title": "My Project Title",
  "slug": "my-project",
  "turns": [
    { "role": "interviewer", "turn": 1, "heading": "TURN 1 — IDEA CAPTURE",
      "text": "What are you building?", "pause_before_ms": 400 },
    { "role": "user", "turn": 1,
      "text": "I'm building...", "pause_before_ms": 900 },
    ...
    { "role": "user", "turn": 5, "text": "confirmed", "pause_before_ms": 700 }
  ]
}
```

The session-start hook copies all presets to `$DEMO_WORKSPACE/artifacts/presets/` automatically. No other configuration needed.

---

## Spec Interview

The interview is the only interactive phase. The other 7 run autonomously.

**Tips for a good demo:**

- Give a concrete idea: "a Python CLI Pomodoro timer with task tracking" is better than "a productivity app"
- Mention key constraints in turn 2 (scope lock): "no database, just a JSON file"
- The acceptance criteria you agree on in turn 5 become the e2e test cases in Phase 5
- Type `confirmed` exactly (case-insensitive) to end the interview and start the pipeline

**Skipping the interview:**

```bash
/demo --skip-interview "Python CLI fibonacci calculator with memoization and a test suite"
```

This is useful for repeated demos or when showing the visual pipeline without waiting for the interview.

---

## Resuming a Demo

If a demo session was interrupted, the conductor checks `demo-state.json` on startup and offers to resume from the last completed phase or restart from scratch.

The state file at `$DEMO_WORKSPACE/artifacts/memory/demo-state.json` tracks which phases completed, their artifacts, and timestamps. Phase status values:

| Status | Meaning |
|--------|---------|
| `pending` | Not yet started |
| `in_progress` | Currently running |
| `done` | Completed successfully |
| `done_with_concerns` | Completed — reviewer flagged issues |
| `skipped` | Blocked and recovery also failed — pipeline continued |

---

## Teardown

```bash
/demo-teardown
```

Shows the git log of the demo workspace, then requires explicit `y` confirmation before running `rm -rf`. Useful to purge between demos so the next run starts fresh.

The workspace is in the OS temp directory — it will be cleaned by the OS on next reboot regardless — but `/demo-teardown` removes it immediately.

---

## Workspace Layout

```
{os.tmpdir()}/cc-demo/
  README.md                              ← updated by doc-updater (Phase 6)
  src/                                   ← implementation (Phase 3)
  tests/
    unit/                                ← unit tests — TDD, written first (Phase 3)
    e2e/                                 ← acceptance tests from spec (Phase 5)
  artifacts/
    spec.md                              ← confirmed spec from interview
    plans/{slug}/plan.md                 ← implementation roadmap (Phase 1)
    decisions/ADR-0001-{slug}.md         ← architecture decision record (Phase 2)
    reviews/
      review-quality.md                  ← code quality findings (Phase 4)
      review-security.md                 ← OWASP security findings (Phase 4)
      review-threat.md                   ← STRIDE threat model (Phase 4)
      demo-review-{date}.md              ← consolidated review (Phase 4)
    memory/
      demo-state.json                    ← pipeline state tracker
      ticker-state.json                  ← agent dispatch timestamps (ticker hook)
    sessions/
      team-state.json                    ← Agent Teams state (Phase 4, if used)
```

All paths are under `$DEMO_WORKSPACE`. No files are written to the project directory.

---

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `DEMO_WORKSPACE` | Set automatically | Absolute workspace path — set by `demo-session-start.js` hook to `{os.tmpdir()}/cc-demo`. Do not set manually. |
| `ORCH_TEAMS_ENABLED` | Optional | `true` enables parallel review-team at Phase 4 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Optional | `1` — CC runtime flag, required alongside `ORCH_TEAMS_ENABLED` |
| `NO_COLOR` | Optional | Set to any value to disable ANSI colour output |

---

## Troubleshooting

### Demo workspace already exists from a previous run

The session-start hook checks for an existing `demo-state.json` and preserves it. If you want a clean run:

```bash
/demo-teardown
# answer y
/demo
```

### `DEMO_WORKSPACE` is empty in an agent

The `demo-session-start.js` hook sets this via `CLAUDE_ENV_FILE`. If propagation is delayed, the conductor and agents fall back to deriving it directly:

```bash
node -e "const os=require('os'),path=require('path'); console.log(path.join(os.tmpdir(),'cc-demo'));"
```

This fallback is built into all demo agents so the pipeline never stalls.

### Phase 4 shows "SEQUENTIAL REVIEW" even with teams enabled

Both variables must be set:

```bash
# Verify settings
cat .claude/settings.json | grep -E "ORCH_TEAMS|EXPERIMENTAL"
# Expected:
# "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
# "ORCH_TEAMS_ENABLED": "true",
```

Only one team can be active per session. If a previous team never reached `complete` status, check:

```bash
cat $(node -e "const os=require('os'),path=require('path'); console.log(path.join(os.tmpdir(),'cc-demo','artifacts','sessions','team-state.json'));"
```

### A phase is skipped with `⟳`

The conductor applied a recovery strategy and it also failed. The demo continues — subsequent phases are unaffected. The skipped phase is noted in `demo-state.json` with `status: skipped`. For the review phase, this means the consolidated review was not produced, but implementation and deployment still complete.

### The opening banner didn't print

The `demo-opening.js` hook fires as `async: true` on `SessionStart`. If the terminal session started very quickly, the output may appear slightly delayed. It only fires once per session (`once: true`) — starting a new Claude Code session will reprint it.

### Hook scripts not found

```bash
ls plugins/cc-demo/hooks/scripts/
# Expected: demo-opening.js  demo-session-start.js  demo-teardown-guard.js  demo-agent-ticker.js
```

If files are missing, re-run the installer:

```bash
bash installer/install.sh --target /path/to/project --plugins cc-demo
```

---

## Further Reading

- [Using Agent Teams](using-agent-teams.md) — Full Agent Teams setup and cost management
- [Common Workflows](common-workflows.md) — Production SDLC patterns (non-demo)
- [Installation Guide](installation.md) — Full install options and plugin management
- [Creating Plugins](creating-plugins.md) — How cc-demo is structured as a plugin
- [Creating Hooks](creating-hooks.md) — SessionStart, SubagentStart/Stop, PreToolUse hooks
- [CLI Quick Reference](cli-quick-reference.md) — All commands and flags
