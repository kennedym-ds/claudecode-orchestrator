# cc-sdlc — Full SDLC Orchestration for Claude Code

Modular plugin marketplace for Claude Code covering the entire software development lifecycle. 24 specialized agents, 54 skills, 30 commands, hook-driven quality gates, and complexity-based routing with configurable model tiers.

## What This Is

A collection of Claude Code plugins that orchestrate development workflows from spec through deployment:

- **6 plugins** — core SDLC, coding standards, GitHub, Jira, Confluence, Jama
- **24 specialized agents** — conductor, planner, architect, implementer, reviewer, threat-modeler, and more
- **54 skills** — 20 language standards, 7 domain overlays, 18 core workflow skills, 9 integration skills
- **30 slash commands** — `/conduct`, `/plan`, `/implement`, `/review`, `/spec`, `/threat-model`, and more
- **17 hook scripts** — secret detection, bash safety, deploy guard, compliance logging
- **Complexity-based routing** — INSTANT → STANDARD → DEEP → ULTRADEEP
- **3 model tiers** — Opus (judgment), Sonnet (execution), Haiku (triage)

## Quick Start

```bash
# Clone
git clone https://github.com/kennedym-ds/cc-sdlc.git
cd cc-sdlc

# Install core + standards to your project
bash installer/install.sh --target /path/to/your/project
# Or Windows:
pwsh -File installer/install.ps1 -TargetPath C:\path\to\project

# Install all plugins (including integrations)
bash installer/install.sh --target /path/to/your/project --plugins all

# Validate
bash scripts/validate-assets.sh

# Start working
claude --agent conductor
```

## Plugins

| Plugin | Description | Assets |
|--------|-------------|--------|
| **cc-sdlc-core** | SDLC orchestration engine | 19 agents, 18 skills, 22 commands, 6 rules, 17 hooks |
| **cc-sdlc-standards** | Universal coding standards | 20 language skills + 7 domain overlays |
| **cc-github** | GitHub integration | 2 agents, 2 commands, 2 skills + GitHub MCP |
| **cc-jira** | Jira integration | 1 agent, 2 commands, 2 skills + Jira MCP |
| **cc-confluence** | Confluence integration | 1 agent, 2 commands, 3 skills + Confluence MCP |
| **cc-jama** | Jama integration | 1 agent, 2 commands, 2 skills + Jama MCP |

Install individually: `--plugins core,github` or all: `--plugins all`

## Agents (24)

### Core SDLC
| Agent | Model | Purpose |
|-------|-------|---------|
| conductor | opus | Lifecycle orchestrator — routes, delegates, tracks state |
| planner | opus | Multi-phase planning with risk analysis |
| architect | opus | Architecture design, ADRs, trade-off analysis |
| implementer | sonnet | TDD execution — tests first, then code |
| reviewer | opus | Severity-tagged code review |
| researcher | sonnet | Evidence gathering with citations |
| security-reviewer | opus | OWASP-aligned security audit |
| threat-modeler | opus | STRIDE/DREAD threat analysis |
| red-team | opus | Adversarial testing, edge case hunting |
| spec-builder | sonnet | Interactive 5-phase specification elicitation |
| req-analyst | haiku | Story decomposition, acceptance criteria |
| estimator | haiku | T-shirt sizing with confidence ratings |
| pair-programmer | sonnet | Collaborative coding with teaching |
| test-architect | sonnet | Test pyramid design, coverage analysis |
| tdd-guide | sonnet | Test-first enforcement |
| e2e-tester | sonnet | End-to-end acceptance test writing |
| deploy-engineer | haiku | Pre-deploy checklist, CI/CD validation |
| incident-responder | sonnet | Root cause analysis, 5-why investigation |
| doc-updater | sonnet | Documentation sync |

### Integration
| Agent | Plugin | Purpose |
|-------|--------|---------|
| github-pr | cc-github | PR creation, review, merge workflows |
| github-issue | cc-github | Issue triage, creation, management |
| jira-sync | cc-jira | Jira issue context and sync |
| confluence-sync | cc-confluence | Confluence page publish and search |
| jama-sync | cc-jama | Jama requirements tracing |

## Commands (30)

| Command | Purpose |
|---------|---------|
| `/conduct` | Full lifecycle orchestration |
| `/plan` | Multi-phase planning |
| `/architect` | Architecture design and ADR generation |
| `/spec` | Interactive specification builder |
| `/implement` | TDD execution |
| `/review` | Severity-tagged code review |
| `/test` | TDD test writing |
| `/test-arch` | Test strategy and pyramid design |
| `/e2e` | End-to-end test writing |
| `/secure` | Security audit |
| `/threat-model` | STRIDE/DREAD threat modeling |
| `/red-team` | Adversarial testing |
| `/research` | Evidence gathering |
| `/estimate` | Effort estimation |
| `/pair` | Pair programming session |
| `/incident` | Incident response and root cause analysis |
| `/deploy-check` | Pre-deployment readiness check |
| `/route` | Complexity assessment (no execution) |
| `/doc` | Documentation generation |
| `/audit` | Self-check the orchestrator |
| `/status` | Session status |
| `/compact` | Strategic context compaction |
| `/github-pr` | GitHub PR workflow |
| `/github-issue` | GitHub issue management |
| `/jira-context` | Jira issue context |
| `/jira-sync` | Jira sync |
| `/confluence-publish` | Confluence page publish |
| `/confluence-search` | Confluence search |
| `/jama-context` | Jama requirements context |
| `/jama-trace` | Jama traceability |

## Model Tiers

| Tier | Default Model | Used For |
|------|--------------|----------|
| **heavy** | Opus 4.6 | Reviews, planning, security, architecture |
| **default** | Sonnet 4.6 | Implementation, research, testing, docs |
| **fast** | Haiku 4.5 | Triage, routing, trivial fixes |

Configure in `sdlc-config.md` after installation, or in `.claude/settings.json`.

## Coding Standards (27 skills)

### Languages (20)
Python, JavaScript, TypeScript, C, C++, C#, Go, Rust, Java, Kotlin, Swift, Ruby, PHP, SQL, Terraform, Bicep, PowerShell, VBA, Markdown, Shell

### Domain Overlays (7)
Embedded Systems, Semiconductor Test, Safety-Critical (DO-178C/IEC 61508), Edge AI, Enterprise App, Web Frontend, UI/UX

Each skill uses severity-tiered rules: **ERROR** (blocks merge) → **WARNING** (reviewer flags) → **RECOMMENDATION** (informational).

## Architecture

```
.claude-plugin/
  marketplace.json          → Plugin catalog (6 plugins)
plugins/
  cc-sdlc-core/             → Main SDLC engine
    .claude/agents/          → 19 agents
    .claude/skills/          → 18 skills
    .claude/commands/        → 22 commands
    .claude/rules/           → 6 guardrails
    hooks/                   → 17 hook scripts
  cc-sdlc-standards/         → Coding standards
    .claude/skills/          → 20 languages + 7 domains
  cc-github/                 → GitHub integration
  cc-jira/                   → Jira integration
  cc-confluence/             → Confluence integration
  cc-jama/                   → Jama integration
installer/                   → Cross-platform installers + config template
scripts/                     → Validation scripts
docs/                        → Guides + templates
```

## Documentation

- [Onboarding Guide](docs/guides/onboarding.md)
- [Model Configuration](docs/guides/model-configuration.md)
- [Creating Agents](docs/guides/creating-agents.md)
- [Creating Skills](docs/guides/creating-skills.md)
- [Changelog](docs/CHANGELOG.md)

## Validation

```bash
bash scripts/validate-assets.sh --verbose    # macOS/Linux
pwsh -File scripts/validate-assets.ps1 -ShowDetails  # Windows
```

## License

MIT
