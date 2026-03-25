# Claude Code Orchestrator

SDLC lifecycle orchestration for Claude Code CLI. 9 focused agents, hook-driven quality gates, complexity-based routing with configurable model tiers.

## What This Is

A structured framework for using Claude Code across the entire software development lifecycle. It provides:

- **9 specialized agents** with scoped tools and model selection
- **Complexity-based routing** (INSTANT → ULTRADEEP) to match effort to task
- **Three configurable model tiers** (Opus / Sonnet / Haiku) for cost control
- **Hook-driven quality gates** — deterministic automation at zero context cost
- **TDD enforcement** — tests before implementation, always
- **Session continuity** — state persists across compaction and session boundaries

## Quick Start

```bash
# Clone
git clone <repo-url>
cd claudecode-orchestrator

# Deploy to your user ~/.claude/ folder (available in all projects)
bash scripts/deploy-user.sh              # macOS/Linux
pwsh -File scripts/deploy-user.ps1       # Windows

# Or install to a specific project
bash scripts/install.sh /path/to/your/project

# Validate
bash scripts/validate-assets.sh

# Start working
claude --agent conductor
# /conduct "Add user authentication"
```

### User-Level Deployment

The `deploy-user` scripts push all orchestrator assets to `~/.claude/` so agents, commands, skills, rules, and hooks are available globally:

```bash
# Default: copy files
bash scripts/deploy-user.sh

# Symlink mode: auto-updates when you pull repo changes
bash scripts/deploy-user.sh --mode symlink

# Dry run: preview what would change
bash scripts/deploy-user.sh --dry-run

# Uninstall: clean removal using deployment manifest
bash scripts/deploy-user.sh --uninstall
```

Settings are **merged** (not overwritten) — your existing permissions, env vars, and model choices are preserved. Hook paths are rewritten to absolute paths so they work from any project directory.

## Model Tiers

| Tier | Default Model | Used For |
|------|--------------|----------|
| **heavy** | Opus 4.6 | Reviews, planning, security, architecture |
| **default** | Sonnet 4.6 | Implementation, research, testing, docs |
| **fast** | Haiku 4.5 | Triage, routing, trivial fixes |

Configure in `.claude/settings.json` → `env`:
```json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
    "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
  }
}
```

Pre-built profiles in `examples/`: budget, standard, premium.

## Commands

| Command | Purpose |
|---------|---------|
| `/conduct` | Full lifecycle orchestration |
| `/plan` | Multi-phase planning |
| `/implement` | TDD execution |
| `/review` | Severity-tagged code review |
| `/route` | Complexity assessment (no execution) |
| `/secure` | Security audit |
| `/test` | TDD test writing |
| `/audit` | Self-check the orchestrator |

## Architecture

```
.claude/agents/     → 9 subagent definitions
.claude/skills/     → 10 workflow skills
.claude/commands/   → 12 slash commands
.claude/rules/      → 6 behavioral guardrails
hooks/              → Hook config + 9 handler scripts
scripts/            → Validation + installation
docs/               → Guides + templates
examples/           → Settings profiles + example CLAUDE.md
```

## Documentation

- [Onboarding Guide](docs/guides/onboarding.md)
- [Model Configuration](docs/guides/model-configuration.md)
- [Changelog](docs/CHANGELOG.md)

## License

MIT
