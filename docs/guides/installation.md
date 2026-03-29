# Installation Guide

Guide for installing cc-sdlc into your Claude Code environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Install](#quick-install)
- [Installation Methods](#installation-methods)
- [Interactive Onboarding](#interactive-onboarding)
- [Plugin Selection](#plugin-selection)
- [Post-Install Configuration](#post-install-configuration)
- [Verify Installation](#verify-installation)
- [Updating](#updating)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)

## Prerequisites

| Requirement | Version | Check command |
|------------|---------|---------------|
| Claude Code CLI | Latest | `claude --version` |
| Node.js | 18+ | `node --version` |
| Git | 2.20+ | `git --version` |
| PowerShell (Windows) | 5.1+ / 7+ | `$PSVersionTable.PSVersion` |
| Bash (macOS/Linux) | 4.0+ | `bash --version` |

**Optional** (for integrations):
- GitHub PAT for PR/issue workflows
- Jira API token for sprint/issue management
- Confluence API token for knowledge base publishing
- Jama OAuth credentials for requirements tracing

## Quick Install

### 1. Clone the repository

```bash
git clone https://github.com/kennedym-ds/claudecode-orchestrator.git
cd claudecode-orchestrator
```

### 2. Run the installer

```bash
# macOS/Linux
bash installer/install.sh --target /path/to/your/project --plugins all

# Windows PowerShell
pwsh -File installer/install.ps1 -TargetPath C:\path\to\project -Plugins all
```

### 3. Run interactive onboarding

```bash
# macOS/Linux
bash installer/onboard.sh --target /path/to/your/project

# Windows PowerShell
pwsh -File installer/onboard.ps1 -TargetPath C:\path\to\project
```

### 4. Start using it

```bash
claude --agent conductor
# /conduct Add user authentication to the API
```

## Installation Methods

### Method 1: Project-Level Install (Recommended)

Installs plugins into a specific project's directory. Best for team projects where everyone should use the same configuration.

```bash
# macOS/Linux
bash installer/install.sh --target ~/projects/myapp

# Windows
pwsh -File installer/install.ps1 -TargetPath C:\projects\myapp
```

**What gets installed:**
- `.claude/agents/` — Agent definitions
- `.claude/skills/` — Workflow skills and coding standards
- `.claude/commands/` — Slash commands
- `.claude/rules/` — Behavioral guardrails
- `hooks/` — Hook scripts and configuration
- `mcp/` — MCP server scripts (for integration plugins)
- `sdlc-config.md` — Project configuration template
- `artifacts/` — Session output directories

### Method 2: User-Level Install (Global)

Installs to `~/.claude/` so agents and skills are available in all projects.

```bash
# macOS/Linux (requires Node.js for settings merge)
bash scripts/deploy-user.sh

# Windows PowerShell
pwsh -File scripts/deploy-user.ps1
```

**Symlink mode** — auto-updates when you pull repo changes:

```bash
bash scripts/deploy-user.sh --mode symlink
pwsh -File scripts/deploy-user.ps1 -Mode Symlink
```

### Method 3: Plugin Install (Claude Code Marketplace)

```
/plugin marketplace add kennedym-ds/claudecode-orchestrator
/plugin install cc-sdlc@kennedym-ds/claudecode-orchestrator
```

### Method 4: Direct Plugin Directory

For development or testing:

```bash
claude --plugin-dir ./plugins/cc-sdlc-core --plugin-dir ./plugins/cc-sdlc-standards
```

## Interactive Onboarding

After installing plugins, run the onboarding wizard to configure integration credentials:

```bash
# macOS/Linux
bash installer/onboard.sh

# Windows PowerShell
pwsh -File installer/onboard.ps1
```

The onboarding wizard walks you through:

```
╔══════════════════════════════════════════════╗
║        cc-sdlc  Interactive  Onboarding      ║
║    Configure integrations and API keys        ║
╚══════════════════════════════════════════════╝

── GitHub Integration ──
  Required for PR workflows, issue management, and CI/CD checks.

  Configure GitHub? [Y/n]:
  Create a token at: https://github.com/settings/tokens
  Required scopes: repo, read:org, read:user
  GitHub Personal Access Token (PAT):

── Jira Integration ──
  Required for issue context, sprint planning, and story generation.

  Configure Jira? [y/N]:

── Confluence Integration ──
  ...

── Jama Connect Integration ──
  ...

── Model Configuration ──
  Profiles: standard (recommended), budget (cost-saving), premium (max quality)

── Summary ──
  ✓ GitHub
  ○ Jira (skipped)
  ○ Confluence (skipped)
  ○ Jama (skipped)
  ○ Models (skipped)
```

### Onboarding options

| Option | Description |
|--------|-------------|
| `--target DIR` | Target project directory (default: current) |
| `--scope project\|user` | Where to store credentials (default: project) |
| `--non-interactive` | Skip prompts, validate existing configuration |

### Re-running onboarding

You can re-run onboarding at any time to add integrations you skipped:

```bash
bash installer/onboard.sh --scope project
pwsh -File installer/onboard.ps1 -Scope project
```

### Where credentials are stored

| Scope | Location | Committed to git? |
|-------|----------|-------------------|
| `project` | `.claude/settings.json` → `env` | Add to `.gitignore` |
| `user` | `~/.claude/settings.json` → `env` | No |

**Security note:** Credentials are stored as environment variables in Claude's settings file. For project-scoped installs, add `.claude/settings.json` to your `.gitignore` to prevent committing secrets. Use `.claude/settings.local.json` for personal credentials that should never be committed.

## Plugin Selection

Choose which plugins to install based on your needs:

| Plugin | Short name | What it provides | When to install |
|--------|-----------|------------------|-----------------|
| **cc-sdlc-core** | `core` | 19 agents, 19 skills, 24 commands, 20 hooks, 6 rules | Always (required) |
| **cc-sdlc-standards** | `standards` | 20 language standards, 7 domain overlays | Always (recommended) |
| **cc-github** | `github` | PR workflows, issue triage, GitHub MCP | If using GitHub |
| **cc-jira** | `jira` | Sprint planning, story generation, Jira MCP | If using Jira |
| **cc-confluence** | `confluence` | Knowledge publishing, search, Confluence MCP | If using Confluence |
| **cc-jama** | `jama` | Requirements tracing, test coverage, Jama MCP | If using Jama Connect |

### Common combinations

```bash
# Minimal — core orchestration + coding standards
bash installer/install.sh --plugins core,standards

# GitHub-focused — adds PR and issue workflows
bash installer/install.sh --plugins core,standards,github

# Enterprise — full Atlassian + GitHub stack
bash installer/install.sh --plugins all

# Regulated industry — core + requirements tracing
bash installer/install.sh --plugins core,standards,jama
```

### Dry run

Preview what would be installed without making changes:

```bash
bash installer/install.sh --plugins all --dry-run
pwsh -File installer/install.ps1 -Plugins all -DryRun
```

## Post-Install Configuration

### 1. Edit sdlc-config.md

The installer creates a `sdlc-config.md` in your project root. Edit it to match your project:

```yaml
project:
  name: "My Project"
  language: "typescript"
  framework: "react"

domain:
  primary: "web-frontend"
  secondary: ["uiux"]

workflow:
  default_complexity: "STANDARD"
  require_plan_approval: true
  tdd: true
```

### 2. Configure model tiers (optional)

The defaults (Opus for judgment, Sonnet for execution, Haiku for triage) work well for most projects. To customize:

```json
// .claude/settings.json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
    "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
  }
}
```

Or use prebuilt profiles during onboarding:
- **standard** — Opus/Sonnet/Haiku (recommended)
- **budget** — Sonnet/Haiku/Haiku (cost-saving)
- **premium** — Opus/Opus/Sonnet (max quality)

### 2b. Configure Agent Teams (optional)

Agent Teams run multiple specialized Claude instances in parallel for DEEP/ULTRADEEP tasks. Disabled by default.

To enable, add to `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "ORCH_TEAMS_ENABLED": "true"
  }
}
```

Or copy a prebuilt team profile:

```bash
# Standard models + teams enabled (explicit --team flag required)
cp examples/settings-teams-enabled.json .claude/settings.json

# Premium models + teams auto-routing (teams activate automatically for DEEP/ULTRADEEP)
cp examples/settings-teams-premium.json .claude/settings.json
```

**Cost note:** Team sessions cost approximately 7x a single session. The conductor always presents a cost estimate and requires explicit confirmation before assembling any team. See [Using Agent Teams](using-agent-teams.md) for full details.

### 3. Initialize artifacts directory

```bash
# If not already created by the installer:
bash scripts/init-artifacts.sh
# or
pwsh -File scripts/init-artifacts.ps1
```

### 4. Add to .gitignore

```gitignore
# cc-sdlc artifacts (local session data)
artifacts/

# Credentials (if using project-scoped settings)
.claude/settings.json
.claude/settings.local.json
```

## Verify Installation

### Run validation

```bash
# From the cc-sdlc repo (validates source)
bash scripts/validate-assets.sh
pwsh -File scripts/validate-assets.ps1 -ShowDetails

# Expected output:
# Agents:   24
# Skills:   55
# Commands: 31
# Errors:   0
# RESULT: PASS
```

### Test basic workflow

```bash
# Start Claude with the conductor
claude --agent conductor

# Try a simple command
# /route What is the square root of 144?
# Expected: INSTANT complexity — direct response

# Try a planning command
# /plan Add input validation to the login form
# Expected: Multi-phase plan with pause point
```

### Check integration connectivity

```bash
# Run onboarding in non-interactive mode to check existing config
bash installer/onboard.sh --non-interactive
pwsh -File installer/onboard.ps1 -NonInteractive
```

## Updating

### Project-level install

Re-run the installer from the latest repo:

```bash
cd claudecode-orchestrator
git pull
bash installer/install.sh --target /path/to/project --plugins all
```

### User-level install

```bash
cd claudecode-orchestrator
git pull
bash scripts/deploy-user.sh
```

Symlink mode updates automatically when you `git pull`.

## Uninstalling

### User-level

```bash
bash scripts/deploy-user.sh --uninstall
pwsh -File scripts/deploy-user.ps1 -Uninstall
```

This uses the deployment manifest to cleanly remove only files that were installed.

### Project-level

Remove the installed directories:

```bash
rm -rf .claude/agents/ .claude/skills/ .claude/commands/ .claude/rules/
rm -rf hooks/ mcp/ artifacts/ sdlc-config.md
```

## Troubleshooting

### "Agent not found" after install

- Restart your Claude Code session
- Check that files are in `.claude/agents/` (not nested deeper)
- Run `claude --agent conductor` to test directly

### MCP server won't connect

- Verify credentials are set: `pwsh -File installer/onboard.ps1 -NonInteractive`
- Check Node.js is installed: `node --version`
- Test MCP servers directly: `node plugins/cc-jira/mcp/server.js`
- For cc-github, verify Docker is running: `docker run --rm ghcr.io/github/github-mcp-server --help`

### Hooks not firing

- Check that `hooks/hooks.json` was copied to the target project
- Verify the hook scripts are present in `hooks/scripts/`
- Review `.claude/settings.json` for hook configuration

### Skills not showing up

- Skills live in `.claude/skills/<name>/SKILL.md` — check the directory structure
- For plugin skills, use the namespace: `/cc-sdlc-core:skill-name`
- Run `/reload-plugins` to pick up changes

### Validation fails

```bash
# Show detailed validation output
pwsh -File scripts/validate-assets.ps1 -ShowDetails
```

Common issues:
- Missing `name` or `description` in agent/skill frontmatter
- `SKILL.md` not inside a subdirectory
- Invalid JSON in `hooks.json` or `plugin.json`

### Permissions issues on Windows

If hook scripts can't execute:
```powershell
Get-ChildItem -Path hooks/scripts/*.js | ForEach-Object {
    Unblock-File -Path $_.FullName
}
```

See the [Troubleshooting Guide](troubleshooting.md) for more solutions.
