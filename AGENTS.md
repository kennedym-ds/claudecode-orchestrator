# Claude Code Orchestrator — Project Playbook

> **Status:** Active  
> **Version:** 1.0.0

SDLC lifecycle orchestration for Claude Code CLI. Built natively for Claude Code's primitives — subagents with real isolation, hook-driven quality gates, skills-based workflows, and complexity-based routing.

---

## Architecture

```
.claude/agents/       → 9 subagent definitions (conductor, planner, implementer, reviewer, etc.)
.claude/skills/       → 10 workflow skills (TDD, security, planning, routing, etc.)
.claude/commands/     → 12 slash commands (entry points for workflows)
.claude/rules/        → 6 behavioral guardrails (persona, quality, security, lifecycle, etc.)
hooks/                → Hook configurations + Node.js handler scripts
scripts/              → Validation, installation, and utility scripts
artifacts/            → Local session outputs (plans, reviews, research, decisions)
docs/                 → Guides, templates, examples
examples/             → Example CLAUDE.md and settings profiles
```

## Core Workflow

**Lifecycle:** Conductor → Planner → Implementer → Reviewer → Completion

1. Start complex tasks with `/conduct` — it routes to specialized subagents
2. Pause points are mandatory after plans and reviews (wait for human approval)
3. The conductor agent is the lifecycle orchestrator — it delegates, never implements directly
4. Subagents have real isolation: scoped tools, model selection, persistent memory, optional worktree isolation
5. Artifacts persist to `artifacts/` using templates from `docs/templates/`
6. Run as main agent: `claude --agent conductor` for full orchestration mode

**Complexity-Based Routing:**

| Tier | Agents Involved | Pause Points |
|------|----------------|-------------|
| INSTANT | Direct response | None |
| STANDARD | Plan → Implement → Review | After plan |
| DEEP | Research → Plan → Implement → Review → Security | After plan, after review |
| ULTRADEEP | Research → Plan → Implement → Trilateral Review | After plan, after each review |

## Model Configuration

Model selection is tier-based and fully configurable. Three tiers map to task complexity:

| Tier | Env Variable | Default | Role |
|------|-------------|---------|------|
| **heavy** | `ORCH_MODEL_HEAVY` | `claude-opus-4-6-20260320` | Judgment-heavy: reviews, security, planning, orchestration |
| **default** | `ORCH_MODEL_DEFAULT` | `claude-sonnet-4-6-20260320` | Implementation: coding, research, testing, documentation |
| **fast** | `ORCH_MODEL_FAST` | `claude-haiku-4-5-20250315` | Lightweight: triage, routing, simple hooks, INSTANT tasks |

**How to customize:**

1. **Project-wide** — Edit `.claude/settings.json`:
   ```json
   {
     "env": {
       "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
       "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
       "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
     }
   }
   ```

2. **Per-session** — CLI flag: `claude --model claude-opus-4-6-20260320`

3. **Per-agent** — Override `model:` in agent frontmatter (`.claude/agents/<name>.md`)

4. **Profiles** — Copy from `examples/` to `.claude/settings.json`:
   - `settings-budget.json` — Haiku default, Sonnet for review, Opus for security only
   - `settings-standard.json` — Sonnet default, Opus for judgment roles (recommended)
   - `settings-premium.json` — Opus for everything (max quality, higher cost)

## Agent Roster (9 Agents)

| Agent | Tier | Model | Tools | Memory | Purpose |
|-------|------|-------|-------|--------|---------|
| **conductor** | heavy | opus | Agent(), Read, Grep, Glob, Bash | project | Lifecycle routing, phase management |
| **planner** | heavy | opus | Read, Grep, Glob, Bash | project | Multi-phase planning, risk analysis |
| **implementer** | default | sonnet | All (inherited) | — | TDD execution, code changes |
| **reviewer** | heavy | opus | Read, Grep, Glob, Bash + plan mode | project | Severity-tagged code review |
| **researcher** | default | sonnet | All (inherited) | project | Evidence gathering, citation |
| **security-reviewer** | heavy | opus | Read, Grep, Glob, Bash + plan mode | — | OWASP, threat modeling |
| **tdd-guide** | default | sonnet | All (inherited) | — | Test-first enforcement |
| **red-team** | heavy | opus | Read, Grep, Glob, Bash + plan mode | — | Adversarial testing, edge cases |
| **doc-updater** | default | sonnet | Read, Write, Edit, Grep, Glob | — | Documentation sync |

### Agent Frontmatter Reference

All agents use these Claude Code frontmatter fields:

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `name` | Yes | lowercase-with-hyphens | Unique agent identifier |
| `description` | Yes | text | When Claude should delegate (include "Use proactively" for auto-delegation) |
| `model` | No | `opus`, `sonnet`, `haiku`, `inherit`, or full ID | Model to use (default: `inherit`) |
| `tools` | No | tool names, `Agent(name, ...)` | Allowlist; inherits all if omitted |
| `disallowedTools` | No | tool names | Denylist; removed from inherited set |
| `permissionMode` | No | `default`, `plan`, `acceptEdits`, `dontAsk`, `bypassPermissions` | Permission handling |
| `maxTurns` | No | number | Max agentic turns before stopping |
| `skills` | No | skill names | Skills injected at startup (not inherited from parent) |
| `memory` | No | `user`, `project`, `local` | Persistent memory scope for cross-session learning |
| `effort` | No | `low`, `medium`, `high`, `max` | Thinking effort level (max is Opus only) |
| `isolation` | No | `worktree` | Run in isolated git worktree |
| `hooks` | No | hook config | Lifecycle hooks scoped to this agent |
| `mcpServers` | No | server configs | Scoped MCP servers |
| `background` | No | `true`/`false` | Always run as background task |

## Commands

| Command | Purpose |
|---------|---------|
| `/conduct` | Lifecycle orchestrator entry point |
| `/plan` | Multi-phase planning |
| `/implement` | TDD execution |
| `/review` | Code review with severity tagging |
| `/research` | Evidence gathering |
| `/secure` | Security audit |
| `/test` | TDD test writing |
| `/deploy-check` | CI/CD readiness check |
| `/doc` | Documentation generation |
| `/red-team` | Adversarial testing |
| `/audit` | Harness quality audit |
| `/route` | Complexity-based task routing |

## Hook Events

Hooks are configured in `.claude/settings.json` (for standalone usage) and `hooks/hooks.json` (for plugin distribution). Both point to the same scripts in `hooks/scripts/`.

**Hook types:** `command` (Node.js/shell), `http` (REST endpoint), `prompt` (LLM-evaluated), `agent` (subagent-handled).

**Available CC hook events (used by this orchestrator marked with ✓):**

| Event | Matcher | Handler | Purpose |
|-------|---------|---------|--------|
| ✓ SessionStart | — | session-start.js | Set env vars via `CLAUDE_ENV_FILE`, log session |
| ✓ UserPromptSubmit | — | secret-detector.js | Block secrets in prompts (exit 2) |
| ✓ PreToolUse | Bash | pre-bash-safety.js | Block destructive commands (exit 2) |
| ✓ PostToolUse | Edit\|Write | post-edit-validate.js | Lint/format after edits (async) |
| ✓ SubagentStart | — | subagent-start-log.js | Log subagent launches for budget tracking |
| ✓ SubagentStop | — | subagent-stop-gate.js | Log completion, quality gate |
| ✓ PreCompact | — | pre-compact.js | Preserve state before compaction |
| ✓ PostCompact | — | post-compact.js | Restore state after compaction |
| ✓ Stop | — | stop-summary.js | Update session timestamp |
| ✓ SessionEnd | — | session-end.js | Archive session state |
| PostToolUseFailure | — | — | Available: log failed tool uses |
| PermissionRequest | — | — | Available: custom permission UI |
| Notification | — | — | Available: external notifications |
| TaskCompleted | — | — | Available: autopilot completion signal |
| InstructionsLoaded | — | — | Available: debug which instructions loaded |

**Hook input schema:** All hooks receive JSON on stdin. Key fields use snake_case:
- `tool_input.command` (PreToolUse Bash)
- `tool_input.file_path` (PostToolUse Edit/Write)
- `agent_name` (SubagentStart/SubagentStop)
- `prompt` (UserPromptSubmit)

**Exit codes:** `0` = success, `2` = block (PreToolUse/UserPromptSubmit), non-zero (except 2) = logged warning.

**Environment variables in hooks:**
- `CLAUDE_PROJECT_DIR` — project root path
- `CLAUDE_SESSION_ID` — current session ID
- `CLAUDE_ENV_FILE` — write env vars here in SessionStart to persist for session

## Validation

```bash
# Validate all assets
bash scripts/validate-assets.sh

# Run smoke tests
bash scripts/run-smoke-tests.sh

# Windows PowerShell
pwsh -File scripts/validate-assets.ps1
```

## Installation

### User-Level (Global)

Deploy agents, skills, commands, rules, and hooks to `~/.claude/` so they are available in **all** Claude Code projects:

```bash
# macOS/Linux (requires jq for settings merge)
bash scripts/deploy-user.sh

# Windows PowerShell
pwsh -File scripts/deploy-user.ps1

# Symlink mode — auto-updates when repo changes
bash scripts/deploy-user.sh --mode symlink
pwsh -File scripts/deploy-user.ps1 -Mode Symlink

# Preview before deploying
bash scripts/deploy-user.sh --dry-run
pwsh -File scripts/deploy-user.ps1 -DryRun

# Remove deployed assets
bash scripts/deploy-user.sh --uninstall
pwsh -File scripts/deploy-user.ps1 -Uninstall
```

**What it deploys:** 9 agents, 10 skills, 12 commands, 6 rules, 10 hook scripts. Settings are merged (not overwritten). Hook paths are rewritten to absolute paths. A manifest tracks deployed files for clean uninstall.

**Modes:**
- **Copy** (default) — files copied; re-run to sync updates
- **Symlink** — symlinks to repo files; auto-updates but needs elevated prompt on Windows

### Project-Level

Install to a specific project directory:

```bash
# macOS/Linux
bash scripts/install.sh /path/to/your/project

# Windows PowerShell
pwsh -File scripts/install.ps1 -TargetPath C:\path\to\project
```

### Plugin

```bash
/plugin marketplace add <owner>/claudecode-orchestrator
/plugin install claudecode-orchestrator@claudecode-orchestrator
```

## Local Artifact Storage

```
artifacts/
├── plans/          # Planner, Implementer, Conductor
├── reviews/        # Reviewer
├── research/       # Researcher
├── security/       # Security Reviewer
├── sessions/       # Session state
├── decisions/      # Architectural Decision Records
├── memory/         # Active context and session memory
│   └── activeContext.md
└── artifact-index.md
```

Initialize with: `bash scripts/init-artifacts.sh`

## Safety & Compliance

- Security guardrails in `.claude/rules/security.md`
- Secret detection hook blocks credentials in prompts and edits
- Bash safety hook blocks destructive commands (`rm -rf`, `DROP TABLE`, etc.)
- Read-only agents use `permissionMode: plan` — cannot modify files
- Never include secrets in artifacts or session logs

## Contribution Protocol

1. Update documentation alongside code changes
2. Run `bash scripts/validate-assets.sh` before committing
3. Follow conventional commit format
4. Add tests for new hooks or scripts
