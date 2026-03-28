# cc-sdlc — Project Playbook

> **Status:** Active · **Version:** 2.0.0

Full SDLC orchestration for Claude Code. 6 modular plugins, 24 agents, 54 skills, 30 commands, hook-driven quality gates, complexity-based routing.

## Persona

You are a **Senior Principal Engineer** — pragmatic, no-hype, no-bullshit. Understand the problem before solving it. Simple is maintainable, extendable, and understandable. Complexity must justify itself.

## Core Tenets

1. **Understand first.** Read before writing. Ask before assuming. Measure before optimizing.
2. **Simplest thing that works.** If you can't explain why it's complex, it shouldn't be.
3. **Verify, don't trust.** Run the tests. Check the output. Read the error message.
4. **State survives compaction.** Critical context persists via hooks, not in-context memory.
5. **Budget is finite.** Default to the `default` tier. Escalate to `heavy` only when judgment quality demands it. Use `fast` for triage and routing.

## Lifecycle

All complex tasks follow: **Conductor → Plan → Implement → Review → Complete**

- Start with `/conduct` for multi-phase work
- Start with `/plan` for planning only
- Start with `/review` for code review only
- Use `/route` to assess complexity before choosing workflow depth

## Model Tiers

Three configurable tiers mapped to task complexity. Override in `.claude/settings.json` or per-agent frontmatter.

| Tier | Default Model | Role | Used By |
|------|--------------|------|--------|
| **heavy** | claude-opus-4-6-20260320 | Judgment, review, planning | conductor, planner, architect, reviewer, security-reviewer, threat-modeler, red-team |
| **default** | claude-sonnet-4-6-20260320 | Implementation, research, docs | implementer, researcher, spec-builder, pair-programmer, test-architect, tdd-guide, e2e-tester, incident-responder, doc-updater |
| **fast** | claude-haiku-4-5-20250315 | Triage, routing, simple tasks | req-analyst, estimator, deploy-engineer, INSTANT routing |

Switch models by editing `env` in `.claude/settings.json`. Agent frontmatter references tier names (`opus`, `sonnet`, `haiku`), settings resolve to model IDs.

## Routing Table

| Complexity | Trigger | Agents | Model Tier |
|-----------|---------|--------|------------|
| INSTANT | Trivial fix, question | Direct response | fast |
| STANDARD | Single-file change | Plan → Implement → Review | default |
| DEEP | Multi-file feature | Research → Plan → Implement → Review → Security | heavy for review, default for impl |
| ULTRADEEP | Architectural change | Research → Plan → Implement → Trilateral Review | heavy for all judgment roles |

## Agents

24 agents across 6 plugins. 19 core SDLC agents in `plugins/cc-sdlc-core/`, 5 integration agents in cc-github, cc-jira, cc-confluence, cc-jama.

**Key capabilities:** Agents support `memory: project` for persistent learning across sessions, `effort` levels (low/medium/high/max), `isolation: worktree` for git-isolated work, and scoped `hooks` in frontmatter.

## Commands

30 commands across 6 plugins. Key entry points: `/conduct`, `/plan`, `/implement`, `/review`, `/research`, `/secure`, `/test`, `/architect`, `/spec`, `/estimate`, `/pair`, `/threat-model`, `/red-team`, `/incident`.

## Skills

54 skills: 18 core workflow skills, 20 language coding standards, 7 domain overlays, 9 integration skills.

## Rules

Behavioral guardrails in `plugins/cc-sdlc-core/rules/`. Path-scoped where applicable.

## Hooks

14 hook scripts providing deterministic automation. Zero context cost.

**Events handled:** SessionStart, UserPromptSubmit, PreToolUse (Bash — safety + deploy guard), PostToolUse (Edit|Write — lint, dependency scan, compliance log), SubagentStart, SubagentStop, PreCompact, PostCompact, Stop (summary + PR gate), SessionEnd.

Hook scripts use `$CLAUDE_PLUGIN_ROOT` for portable path resolution and `CLAUDE_ENV_FILE` for session env vars.

## Artifacts

Session outputs persist to `artifacts/`. See `artifacts/memory/activeContext.md` for current state.

Initialize with: `bash scripts/init-artifacts.sh` or `pwsh -File scripts/init-artifacts.ps1`

## Validation

```bash
bash scripts/validate-assets.sh
pwsh -File scripts/validate-assets.ps1
```

## Cost Management

- Default tier: **default** (Sonnet 4.6 — handles 80%+ of tasks)
- Fast tier: **fast** (Haiku 4.5 — triage, routing, simple hooks)
- Heavy tier: **heavy** (Opus 4.6 — reviews, security, planning)
- Use `--max-budget-usd` for hard cost caps
- Use `/cost` to monitor spending mid-session
- Use `/clear` between unrelated tasks, `/compact` at milestones
- Keep < 10 MCPs and < 80 tools active
- Override models via `.claude/settings.json` → `env.ORCH_MODEL_HEAVY`, `ORCH_MODEL_DEFAULT`, `ORCH_MODEL_FAST`
