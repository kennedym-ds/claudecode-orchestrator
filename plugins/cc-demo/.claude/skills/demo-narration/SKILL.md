---
name: demo-narration
description: Cinematic narration style guide for demo-conductor — ANSI-coloured banner formats, live pipeline scoreboard, audience-facing language, phase summaries, and error narration patterns. Keeps the demo presentation-quality throughout.
user-invocable: false
---

# Demo Narration

## Core Principle

Every phase transition is a story beat. The audience is watching live. Make it engaging, honest, and clear. Never expose raw error stack traces or agent-internal state. Narrate like you're presenting to stakeholders.

Use ANSI colour codes in all banners. The live agent ticker hook handles individual dispatch/return events — conductor handles phase-level narration.

---

## ANSI Colour Reference

Use these escape sequences in all output blocks. Wrap in `\x1b[0m` (reset) after every coloured segment.

| Purpose              | Code         | Label       |
|----------------------|--------------|-------------|
| Phase headers        | `\x1b[96m`   | bright cyan |
| Opus tier indicator  | `\x1b[31m`   | red         |
| Sonnet tier          | `\x1b[33m`   | yellow      |
| Haiku tier           | `\x1b[32m`   | green       |
| Success / done       | `\x1b[92m`   | bright green|
| Warning / concerns   | `\x1b[93m`   | bright yellow|
| Error / blocked      | `\x1b[91m`   | bright red  |
| Box borders          | `\x1b[36m`   | cyan        |
| Dim labels           | `\x1b[2m`    | dim         |
| Bold                 | `\x1b[1m`    | bold        |
| Reset                | `\x1b[0m`    | reset       |

When `NO_COLOR` env var is set, emit plain text only (no escape codes).

---

## Opening Banner

The `demo-opening.js` SessionStart hook emits this automatically. demo-conductor does NOT reprint it. Instead, print the interactive prompt immediately:

```
\x1b[96m┌─────────────────────────────────────────────────────────────────────┐\x1b[0m
\x1b[96m│\x1b[0m  \x1b[1mTell me what you want to build.\x1b[0m                                      \x1b[96m│\x1b[0m
\x1b[96m│\x1b[0m  \x1b[2mExample: "a CLI task manager in Python"\x1b[0m                             \x1b[96m│\x1b[0m
\x1b[96m└─────────────────────────────────────────────────────────────────────┘\x1b[0m
```

---

## Pipeline Scoreboard

Print the scoreboard before each phase banner. It tracks all 7 autonomous phases (spec interview is pre-pipeline) — audiences can see exactly where the pipeline is at a glance.

Status icons:
- `\x1b[92m✓\x1b[0m` — complete
- `\x1b[96m⚡\x1b[0m` — active (current phase, blinking feel)
- `\x1b[93m⟳\x1b[0m` — skipped
- `\x1b[2m·\x1b[0m`  — pending

Format (substitute `{icon_N}` for each phase's current icon):

```
\x1b[2m  Pipeline:\x1b[0m  {icon_1}\x1b[2mPLAN\x1b[0m  {icon_2}\x1b[2mARCH\x1b[0m  {icon_3}\x1b[2mIMPL\x1b[0m  {icon_4}\x1b[2mREVIEW\x1b[0m  {icon_5}\x1b[2mE2E\x1b[0m  {icon_6}\x1b[2mDOC\x1b[0m  {icon_7}\x1b[2mDEPLOY\x1b[0m
```

Example — at Phase 3 (IMPL), Phases 1-2 done:

```
  Pipeline:  \x1b[92m✓\x1b[0m\x1b[2mPLAN\x1b[0m  \x1b[92m✓\x1b[0m\x1b[2mARCH\x1b[0m  \x1b[96m⚡\x1b[0m\x1b[2mIMPL\x1b[0m  \x1b[2m·\x1b[0m\x1b[2mREVIEW\x1b[0m  \x1b[2m·\x1b[0m\x1b[2mE2E\x1b[0m  \x1b[2m·\x1b[0m\x1b[2mDOC\x1b[0m  \x1b[2m·\x1b[0m\x1b[2mDEPLOY\x1b[0m
```

---

## Phase Banner Format

Print scoreboard first, then this banner block before each delegation:

```
\x1b[36m╔══════════════════════════════════════════════════════════════════════╗\x1b[0m
\x1b[36m║\x1b[0m  \x1b[1m\x1b[96m{PHASE TITLE — e.g. PHASE 3 — IMPLEMENTATION (TDD)}\x1b[0m\x1b[1m               \x1b[0m\x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mAgent: {agent-name} · {tier-dot} {model-label} · max {maxTurns} turns\x1b[0m  \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  {one-sentence description}                                           \x1b[36m║\x1b[0m
\x1b[36m╚══════════════════════════════════════════════════════════════════════╝\x1b[0m
```

Tier dot colours: `\x1b[31m●\x1b[0m` Opus · `\x1b[33m●\x1b[0m` Sonnet · `\x1b[32m●\x1b[0m` Haiku

Example:
```
\x1b[36m╔══════════════════════════════════════════════════════════════════════╗\x1b[0m
\x1b[36m║\x1b[0m  \x1b[1m\x1b[96mPHASE 3 — IMPLEMENTATION (TDD)\x1b[0m\x1b[1m                                    \x1b[0m\x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mAgent: implementer · \x1b[33m●\x1b[0m\x1b[2m Sonnet · max 30 turns\x1b[0m                        \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  Red-Green-Refactor: tests first, then implementation                 \x1b[36m║\x1b[0m
\x1b[36m╚══════════════════════════════════════════════════════════════════════╝\x1b[0m
```

---

## Phase Complete Format

Print after each delegation returns:

```
\x1b[92m✓\x1b[0m \x1b[1m{PHASE TITLE}\x1b[0m
  {1-2 sentence outcome. Quote key deliverable names.}
  \x1b[2mArtifacts: {paths relative to $DEMO_WORKSPACE, comma-separated}\x1b[0m
```

Example:
```
\x1b[92m✓\x1b[0m \x1b[1mPHASE 3 — IMPLEMENTATION (TDD)\x1b[0m
  implementer wrote 4 source files and 12 unit tests. All tests pass.
  \x1b[2mArtifacts: src/main.py, src/cli.py, tests/unit/test_main.py, tests/unit/test_cli.py\x1b[0m
```

---

## Review Phase — Teams Banner

When Agent Teams are available:
```
\x1b[36m╔══════════════════════════════════════════════════════════════════════╗\x1b[0m
\x1b[36m║\x1b[0m  \x1b[1m\x1b[96mPHASE 4 — PARALLEL REVIEW\x1b[0m\x1b[1m  (Agent Teams)\x1b[0m                           \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[31m●\x1b[0m\x1b[2m reviewer  \x1b[31m●\x1b[0m\x1b[2m security-reviewer  \x1b[31m●\x1b[0m\x1b[2m threat-modeler\x1b[0m                \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2m3 Opus agents run simultaneously — independent context windows\x1b[0m       \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2m(~7x cost narrated to audience — not a blocking gate in demo mode)\x1b[0m  \x1b[36m║\x1b[0m
\x1b[36m╚══════════════════════════════════════════════════════════════════════╝\x1b[0m
```

When falling back to sequential subagents:
```
\x1b[36m╔══════════════════════════════════════════════════════════════════════╗\x1b[0m
\x1b[36m║\x1b[0m  \x1b[1m\x1b[96mPHASE 4 — SEQUENTIAL REVIEW\x1b[0m\x1b[1m\x1b[0m                                       \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mreviewer → security-reviewer → threat-modeler\x1b[0m                       \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mTip: set ORCH_TEAMS_ENABLED=true for parallel review-team mode\x1b[0m       \x1b[36m║\x1b[0m
\x1b[36m╚══════════════════════════════════════════════════════════════════════╝\x1b[0m
```

---

## BLOCKED Narration

When a subagent returns BLOCKED:
```
\x1b[93m⚠\x1b[0m  \x1b[1m{PHASE TITLE}\x1b[0m — applying recovery strategy
   \x1b[2mIssue: {plain-language description — no raw error text}\x1b[0m
   \x1b[2mRecovery: {what demo-conductor is trying next}\x1b[0m
```

After successful recovery:
```
\x1b[96m↻\x1b[0m  \x1b[1m{PHASE TITLE}\x1b[0m — recovered with reduced scope, continuing...
```

When phase is skipped after recovery failure:
```
\x1b[93m⟳\x1b[0m  \x1b[1m{PHASE TITLE}\x1b[0m skipped
   \x1b[2m{brief explanation — what was skipped and why it doesn't block the remaining phases}\x1b[0m
```

---

## Completion Banner

Print after Phase 7 completes. Substitute `{workspace}` with the resolved absolute `$DEMO_WORKSPACE`:

```
\x1b[36m╔══════════════════════════════════════════════════════════════════════╗\x1b[0m
\x1b[36m║\x1b[0m  \x1b[1m\x1b[92mDEMO COMPLETE\x1b[0m\x1b[1m                                                         \x1b[0m\x1b[36m║\x1b[0m
\x1b[36m╠══════════════════════════════════════════════════════════════════════╣\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mProject:\x1b[0m    \x1b[1m{project-name}\x1b[0m                                             \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mPhases:\x1b[0m     \x1b[92m{N} of 7 completed\x1b[0m  \x1b[93m({skipped} skipped)\x1b[0m               \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mGit commit:\x1b[0m \x1b[96m{short-sha}\x1b[0m                                              \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mWorkspace:\x1b[0m  {workspace}                                              \x1b[36m║\x1b[0m
\x1b[36m╠══════════════════════════════════════════════════════════════════════╣\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mArtifacts produced:\x1b[0m                                                  \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/artifacts/spec.md\x1b[0m       confirmed spec                 \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/artifacts/plans/\x1b[0m        implementation roadmap         \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/artifacts/decisions/\x1b[0m    architecture decision record   \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/src/\x1b[0m                    implementation                 \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/tests/\x1b[0m                  unit + acceptance tests         \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/artifacts/reviews/\x1b[0m      consolidated review findings   \x1b[36m║\x1b[0m
\x1b[36m║\x1b[0m  \x1b[96m·\x1b[0m \x1b[2m{workspace}/README.md\x1b[0m               updated documentation          \x1b[36m║\x1b[0m
\x1b[36m╠══════════════════════════════════════════════════════════════════════╣\x1b[0m
\x1b[36m║\x1b[0m  \x1b[2mRun /demo-teardown to purge the workspace\x1b[0m                            \x1b[36m║\x1b[0m
\x1b[36m╚══════════════════════════════════════════════════════════════════════╝\x1b[0m
```

---

## Audience Language Rules

- Say "agent" or the agent's name — never "subagent"
- Never expose raw STATUS/DELIVERABLES blocks — summarise them in narration
- Say "Handing off to {agent-name}..." rather than "delegating"
- Keep technical jargon out of banners — detail belongs in verbose output
- When `DONE_WITH_CONCERNS`: "The reviewer flagged {N} issue(s) — logged in the review artifact."
- When deploy completes: "Committed to {workspace} at \x1b[96m{short-sha}\x1b[0m."
- When teams are used: call it "parallel review" — the audience should feel the parallelism
- Never apologise for autonomous decisions — narrate them confidently
- Phase scoreboard is mandatory before every phase banner — audiences track progress at a glance
