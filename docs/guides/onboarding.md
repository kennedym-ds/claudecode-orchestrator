# Onboarding Guide

## Quick Start

1. **Clone the repo:**
   ```bash
   git clone <repo-url>
   cd claudecode-orchestrator
   ```

2. **Deploy to your user folder** (recommended â‚¬â€ available in all projects):
   ```bash
   # macOS/Linux (requires jq for settings merge)
   bash scripts/deploy-user.sh

   # Windows PowerShell
   pwsh -File scripts/deploy-user.ps1
   ```

   Or install to a specific project only:
   ```bash
   bash scripts/install.sh /path/to/your/project
   pwsh -File scripts/install.ps1 -TargetPath C:\path\to\project   # Windows
   ```

3. **Configure model tiers** (optional â‚¬â€ defaults are already set):
   Edit `~/.claude/settings.json` (user-level) or `.claude/settings.json` (project-level):
   ```json
   {
     "env": {
       "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
       "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
       "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
     }
   }
   ```
   Or copy a profile from `examples/`:
   - `settings-budget.json` â‚¬â€ Haiku default, minimal Opus
   - `settings-standard.json` â‚¬â€ Sonnet default, Opus for reviews (recommended)
   - `settings-premium.json` â‚¬â€ Opus everywhere

4. **Validate:**
   ```bash
   bash scripts/validate-assets.sh --verbose
   ```

5. **Start working:**
   ```bash
   claude --agent conductor
   # /conduct Add user authentication to the API
   ```

## Deployment Modes

### User-Level (`~/.claude/`)

Makes all orchestrator assets globally available. Best for personal setups.

```bash
# Copy mode (default) â‚¬â€ re-run to sync updates
bash scripts/deploy-user.sh

# Symlink mode â‚¬â€ auto-updates when you pull repo changes
bash scripts/deploy-user.sh --mode symlink

# Preview changes without writing
bash scripts/deploy-user.sh --dry-run

# Clean removal (uses manifest)
bash scripts/deploy-user.sh --uninstall
```

**How it works:**
- Agents, skills, commands, rules copied/symlinked to `~/.claude/`
- Hook scripts deployed to `~/.claude/hooks/scripts/` with absolute paths in settings
- Settings are **merged** â‚¬â€ existing env vars, permissions, and model choices preserved
- A manifest file (`.orchestrator-manifest.json`) tracks deployed files for clean uninstall
- Previous settings backed up to `~/.claude/.orchestrator-backup/`

### Project-Level

Installs orchestrator assets into a specific project's `.claude/` folder.

```bash
bash scripts/install.sh /path/to/project
```

### Plugin

```bash
/plugin marketplace add <owner>/claudecode-orchestrator
```

## Key Commands

| Command | What it does |
|---------|-------------|
| `/conduct <task>` | Start a full lifecycle workflow |
| `/plan <task>` | Create a multi-phase plan |
| `/implement <task>` | Execute with TDD |
| `/review <scope>` | Code review with severity tagging |
| `/route <task>` | Assess complexity without executing |
| `/status` | Session state, phase progress, budget |
| `/compact` | Strategic context compaction |
| `/audit` | Self-check the orchestrator harness |

**Plugin commands** (requires MCP plugins):

| Command | What it does |
|---------|-------------|
| `/jira-sync` | Sync plans to Jira stories |
| `/jira-context` | Pull Jira issue details into session |
| `/confluence-publish` | Publish artifacts to Confluence |
| `/confluence-search` | Search Confluence for docs |
| `/jama-trace` | Trace requirements in Jama |
| `/jama-context` | Pull Jama items into session |

See the [CLI Quick Reference](cli-quick-reference.md) for all commands and flags.

## Model Configuration

The orchestrator uses three tiers mapped to task complexity:

| Tier | Default | Used For |
|------|---------|----------|
| **heavy** | Opus 4.6 | Reviews, planning, security, architecture |
| **default** | Sonnet 4.6 | Implementation, research, testing, docs |
| **fast** | Haiku 4.5 | Triage, routing, trivial fixes |

Change tiers by editing `ORCH_MODEL_HEAVY`, `ORCH_MODEL_DEFAULT`, and `ORCH_MODEL_FAST` in `.claude/settings.json` -> `env`.

## Workflow Overview

```
You: /conduct "Add feature X"
  |
  +-- Conductor assesses complexity -> STANDARD
  +-- Delegates to Planner (Opus) -> plan created
  +-- PAUSE -- you review and approve the plan
  |
  +-- Delegates to Implementer (Sonnet) -> TDD execution
  +-- Delegates to Reviewer (Opus) -> severity-tagged review
  +-- PAUSE -- you review findings
  |
  +-- Plan complete -> summary + follow-up tasks
```

## Project Layout

```
.claude/
  agents/     -> 9 subagent definitions
  skills/     -> 10 workflow skills
  commands/   -> 14 slash commands
  rules/      -> 6 behavioral guardrails
  settings.json -> Model tiers + permissions

hooks/          -> Hook config + 10 handler scripts
scripts/        -> Validation + installation
plugins/        -> 3 MCP plugins (Jira, Confluence, Jama)
artifacts/      -> Session outputs (plans, reviews, etc.)
docs/guides/    -> Onboarding, CLI reference, workflows, troubleshooting
```

## Further Reading

- [CLI Quick Reference](cli-quick-reference.md) — All commands and flags
- [Common Workflows](common-workflows.md) — End-to-end SDLC patterns
- [Troubleshooting](troubleshooting.md) — Common issues and solutions
- [MCP Plugin Development](mcp-plugin-development.md) — Build custom integrations
- [Creating Agents](creating-agents.md) — Add new agents
- [Creating Skills](creating-skills.md) — Add new workflow skills
- [Creating Hooks](creating-hooks.md) — Add new lifecycle hooks
- [Creating Plugins](creating-plugins.md) — Package for distribution
- [Model Configuration](model-configuration.md) — Tier customization