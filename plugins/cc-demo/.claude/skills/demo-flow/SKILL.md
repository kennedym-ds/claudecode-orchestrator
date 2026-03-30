---
name: demo-flow
description: Demo pipeline state machine — 7-phase autonomous sequence with delegation context templates, phase transition logic, BLOCKED recovery strategies, and demo-state.json schema. Used exclusively by demo-conductor.
user-invocable: false
---

# Demo Flow

## Workspace Path

All paths are absolute, rooted at `$DEMO_WORKSPACE` (set by `demo-session-start.js` hook via `CLAUDE_ENV_FILE`). This makes the demo location-agnostic — it works from any terminal regardless of the current working directory.

**Resolve at runtime:**
```bash
echo $DEMO_WORKSPACE
# falls back to: node -e "const os=require('os'),path=require('path'); console.log(path.join(os.tmpdir(),'cc-demo'));"
```

Never use `demo-workspace/` as a relative path. Always substitute the resolved absolute value of `$DEMO_WORKSPACE`.

---

## Preset Mode

When `--preset <name>` is passed, the demo runs fully hands-off — no human typing at any point.

### How it works

1. Spec is loaded from `$DEMO_WORKSPACE/artifacts/presets/{name}/spec.md` (copied there by session-start hook)
2. Spec is written to `$DEMO_WORKSPACE/artifacts/spec.md` — same path the normal interview would produce
3. The `replay.json` conversation is printed turn by turn with pauses, making it look like a live interview
4. Pipeline runs identically to a normal confirmed interview — no further differences

### Preset Inventory

| Flag value | Spec title | Slug | Tech stack |
|------------|-----------|------|-----------|
| `react-graphs` | React Interactive Graphing Platform | `graph-board` | React 18, Vite, Recharts, Vitest |

### Adding a New Preset

Create two files in `plugins/cc-demo/presets/{name}/`:

- **`spec.md`** — full spec in the same format as a confirmed spec-interviewer output
- **`replay.json`** — JSON with a `turns` array of `{role, label, turn, heading?, text, pause_before_ms}` objects; roles are `"interviewer"` or `"user"`; last user turn must have `text: "confirmed"`

The session-start hook auto-copies all presets to `$DEMO_WORKSPACE/artifacts/presets/` on every session start.

---

## Pipeline State Machine

```
IDLE → SPEC_INTERVIEW → PLAN → ARCHITECT → IMPLEMENT → REVIEW → E2E → DOC → DEPLOY → COMPLETE
```

Each transition is triggered by `STATUS: DONE` or `STATUS: DONE_WITH_CONCERNS` from the delegated agent. `STATUS: BLOCKED` triggers recovery (see below).

---

## Phase Definitions

### Phase 0 — SPEC_INTERVIEW
- **Agent:** `spec-interviewer`
- **Mode:** interactive (5 turns max)
- **Transition trigger:** user types 'confirmed'
- **Output:** `$DEMO_WORKSPACE/artifacts/spec.md`
- **Next:** PLAN (automatic, no pause)

### Phase 1 — PLAN
- **Agent:** `planner`
- **Task:** "Create a 3-phase implementation plan for this spec. Scope each phase to be completable by a single implementer in one session. Target project root: `$DEMO_WORKSPACE`. Output plan to `$DEMO_WORKSPACE/artifacts/plans/{slug}/plan.md`."
- **Output:** `$DEMO_WORKSPACE/artifacts/plans/{slug}/plan.md`
- **Next:** ARCHITECT

### Phase 2 — ARCHITECT
- **Agent:** `architect`
- **Task:** "Design the component architecture for Phase 1 of this plan. Produce an ADR documenting the key design decision. Target root: `$DEMO_WORKSPACE`. Output to `$DEMO_WORKSPACE/artifacts/decisions/ADR-0001-{slug}.md`."
- **Output:** `$DEMO_WORKSPACE/artifacts/decisions/ADR-0001-{slug}.md`
- **Next:** IMPLEMENT

### Phase 3 — IMPLEMENT
- **Agent:** `implementer`
- **Task:** "Implement Phase 1 of the plan using TDD (Red → Green → Refactor). All source files go under `$DEMO_WORKSPACE/src/`, tests under `$DEMO_WORKSPACE/tests/unit/`. Run the verification loop at the end. Note: implement Phase 1 only — this is a demo."
- **Output:** `$DEMO_WORKSPACE/src/`, `$DEMO_WORKSPACE/tests/unit/`
- **Next:** REVIEW

### Phase 4 — REVIEW
- **See:** Review Phase section below
- **Output:** `$DEMO_WORKSPACE/artifacts/reviews/demo-review-{date}.md`
- **Next:** E2E

### Phase 5 — E2E
- **Agent:** `e2e-tester`
- **Task:** "Write and run end-to-end acceptance tests for the features implemented in `$DEMO_WORKSPACE/src/`. Base each test on the acceptance criteria in `$DEMO_WORKSPACE/artifacts/spec.md`. Write tests to `$DEMO_WORKSPACE/tests/e2e/`."
- **Output:** `$DEMO_WORKSPACE/tests/e2e/`
- **Next:** DOC

### Phase 6 — DOC
- **Agent:** `doc-updater`
- **Task:** "Update `$DEMO_WORKSPACE/README.md` to reflect the implemented features. Add a usage section and a quickstart. Also ensure key functions in `$DEMO_WORKSPACE/src/` have doc comments where missing. Use the spec for the feature description."
- **Output:** updated `$DEMO_WORKSPACE/README.md`
- **Next:** DEPLOY

### Phase 7 — DEPLOY
- **Agent:** `deploy-engineer`
- **Task:** "Validate deployment readiness for the project in `$DEMO_WORKSPACE`. Check: tests pass, README exists, no obvious missing deps. Then run the following git commands: `git -C \"$DEMO_WORKSPACE\" add -A && git -C \"$DEMO_WORKSPACE\" commit -m 'demo: {slug} — autonomous SDLC pipeline complete'`. Report the commit SHA."
- **Output:** deploy readiness report + git commit SHA
- **Next:** COMPLETE

---

## Delegation Context Template

Prepend this block to every phase delegation prompt (substitute `$DEMO_WORKSPACE` with its resolved absolute value):

```
DEMO CONTEXT
============
Project:      {project-name} ({project-slug})
Workspace:    {absolute path resolved from $DEMO_WORKSPACE}   ← ALL file ops target this path
Spec path:    {workspace}/artifacts/spec.md
Mode:         autonomous — make pragmatic decisions, do not ask clarifying questions
Phase:        {phase-name} ({N} of 7)
Prior phases: {comma-separated list of completed phases}

SPEC SUMMARY
============
{spec.md contents — truncate at 600 chars if long, note full path for reference}

YOUR TASK
=========
{phase-specific task from Phase Definitions above, with {slug} and $DEMO_WORKSPACE replaced}
```

---

## Review Phase — Teams vs Subagent

### When `ORCH_TEAMS_ENABLED=true` AND `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

1. Print the parallel review narration banner
2. Write `$DEMO_WORKSPACE/artifacts/sessions/team-state.json`:
   ```json
   { "team": "review-team", "status": "assembling", "assembledAt": "{ISO8601}" }
   ```
3. Inject 3 tasks simultaneously (no dependencies):
   - `review-quality` → reviewer: "Review all files in `$DEMO_WORKSPACE/src/` for correctness, quality, and test coverage relative to spec. Write findings to `$DEMO_WORKSPACE/artifacts/reviews/review-quality.md`."
   - `review-security` → security-reviewer: "OWASP-aligned review of `$DEMO_WORKSPACE/src/`. Write findings to `$DEMO_WORKSPACE/artifacts/reviews/review-security.md`."
   - `review-threat` → threat-modeler: "STRIDE threat model for the feature in `$DEMO_WORKSPACE/src/` based on the spec. Write to `$DEMO_WORKSPACE/artifacts/reviews/review-threat.md`."
4. Assemble `review-team` — skip the ~7x cost-confirmation gate. Narrate: "Assembling review-team — 3 Opus agents running in parallel. In a production session this requires cost confirmation; skipping in demo mode."
5. Wait for all three review files to exist
6. Synthesize: read all three, write consolidated `$DEMO_WORKSPACE/artifacts/reviews/demo-review-{date}.md`
7. Update `team-state.json` to `status: complete`

### Subagent Fallback

Print sequential review banner. Delegate sequentially:
- reviewer → `$DEMO_WORKSPACE/artifacts/reviews/review-quality.md`
- security-reviewer → `$DEMO_WORKSPACE/artifacts/reviews/review-security.md`
- threat-modeler → `$DEMO_WORKSPACE/artifacts/reviews/review-threat.md`

Consolidate into `$DEMO_WORKSPACE/artifacts/reviews/demo-review-{date}.md`.

---

## BLOCKED Recovery Strategies

| Phase | Recovery Strategy |
|-------|-------------------|
| PLAN | Retry with: "Create a 2-phase plan (Phase 1 only needs to be implementable). Keep it minimal." |
| ARCHITECT | Skip ADR, produce a minimal bulleted component list as `ADR-0001-{slug}.md` |
| IMPLEMENT | Reduce to skeleton: module structure + stubbed functions + at least 3 passing unit tests |
| REVIEW | If teams BLOCKED: fall back to subagent mode. If individual reviewer BLOCKED: skip that reviewer, note in demo-review.md |
| E2E | Write test stubs with `# TODO: implement` bodies — at least the file structure counts |
| DOC | Write minimal README: project name + spec summary + "Run: python src/main.py --help" |
| DEPLOY | Run git commands directly from demo-conductor without deploy-engineer: `git -C "$DEMO_WORKSPACE" add -A && git -C "$DEMO_WORKSPACE" commit -m 'demo: {slug}'` |

Recovery is attempted once. If recovery also BLOCKED: mark phase `skipped` in demo-state.json and continue.

---

## demo-state.json Schema

Location: `$DEMO_WORKSPACE/artifacts/memory/demo-state.json`

```json
{
  "projectName": "string | null",
  "projectSlug": "string | null",
  "specConfirmed": false,
  "specPath": "string | null",
  "workspace": "absolute path to $DEMO_WORKSPACE",
  "sessionId": "string",
  "startedAt": "ISO8601",
  "completedAt": "ISO8601 | null",
  "teamModeActive": false,
  "phases": {
    "plan":      { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "planner",         "teamMode": false, "concerns": [] },
    "architect": { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "architect",       "teamMode": false, "concerns": [] },
    "implement": { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "implementer",     "teamMode": false, "concerns": [] },
    "review":    { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "review-team",     "teamMode": true,  "concerns": [] },
    "e2e":       { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "e2e-tester",      "teamMode": false, "concerns": [] },
    "doc":       { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "doc-updater",     "teamMode": false, "concerns": [] },
    "deploy":    { "status": "pending", "startedAt": null, "completedAt": null, "artifact": null, "agentUsed": "deploy-engineer", "teamMode": false, "concerns": [] }
  }
}
```

Valid status values: `pending` | `in_progress` | `done` | `done_with_concerns` | `skipped` | `blocked`

---

## Phase Narration Tokens

For use in demo-narration banners:

| Phase | Banner Title                      | Agent Label                    | One-liner                                              |
|-------|-----------------------------------|--------------------------------|--------------------------------------------------------|
| PLAN  | PHASE 1 — PLANNING               | planner · Opus · heavy         | Breaking the spec into a phased implementation roadmap |
| ARCH  | PHASE 2 — ARCHITECTURE           | architect · Opus · heavy       | Designing components and producing an ADR              |
| IMPL  | PHASE 3 — IMPLEMENTATION (TDD)   | implementer · Sonnet · default | Red-Green-Refactor: tests first, then code             |
| REV   | PHASE 4 — PARALLEL REVIEW        | review-team · 3× Opus          | Quality + security + threat model running in parallel  |
| REV   | PHASE 4 — SEQUENTIAL REVIEW      | reviewer → sec → threat        | Quality, security, and threat model in sequence        |
| E2E   | PHASE 5 — E2E TESTING            | e2e-tester · Sonnet · default  | Writing and running acceptance tests from the spec     |
| DOC   | PHASE 6 — DOCUMENTATION          | doc-updater · Sonnet · default | Syncing README and doc comments with the code          |
| DEPLOY| PHASE 7 — DEPLOY                 | deploy-engineer · Haiku · fast | Pre-deploy checklist and git commit                    |
