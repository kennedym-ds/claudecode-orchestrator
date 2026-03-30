# CLI Quick Reference

Fast lookup for Claude Code CLI commands, flags, and orchestrator workflows.

## Core CLI Syntax

```bash
claude [flags] [prompt]
```

### Essential Flags

| Flag | Description | Example |
|------|-------------|---------|
| `-p "prompt"` | Non-interactive mode (single prompt, exits after) | `claude -p "explain this function"` |
| `--agent <name>` | Start with a specific agent | `claude --agent conductor` |
| `--model <id>` | Override model for this session | `claude --model claude-opus-4-6-20260320` |
| `--tool <name>` | Restrict to specific tools | `claude --tool mcp__cc_jira__get_issue` |
| `--max-budget-usd <n>` | Hard cost cap for session | `claude --max-budget-usd 5` |
| `--resume` | Resume most recent session | `claude --resume` |
| `--resume <id>` | Resume specific session | `claude --resume abc123` |
| `--continue` | Continue last conversation | `claude --continue` |

### Interactive Commands

Run inside an active Claude Code session:

| Command | Purpose |
|---------|---------|
| `/conduct <task>` | Full lifecycle orchestration |
| `/plan <task>` | Create a multi-phase implementation plan |
| `/architect <task>` | Architecture design and ADR generation |
| `/spec <task>` | Interactive specification builder |
| `/implement <task>` | TDD-driven implementation |
| `/review <scope>` | Code review with severity tagging |
| `/research <topic>` | Evidence gathering with citations |
| `/secure <scope>` | OWASP-aligned security audit |
| `/threat-model <scope>` | STRIDE/DREAD threat modeling |
| `/red-team <scope>` | Adversarial testing and edge cases |
| `/test <scope>` | Write tests (Red-Green-Refactor) |
| `/test-arch <scope>` | Test strategy and pyramid design |
| `/e2e <scope>` | End-to-end acceptance tests |
| `/estimate <task>` | T-shirt sizing and story points |
| `/pair <task>` | Collaborative pair programming |
| `/incident <scope>` | Root cause analysis and 5-why |
| `/deploy-check` | CI/CD readiness check |
| `/doc <scope>` | Generate or update documentation |
| `/audit` | Self-check the orchestrator harness |
| `/route <task>` | Assess complexity without executing |
| `/status` | Session state, phase progress, budget |
| `/compact` | Strategic context compaction |
| `/demo [idea]` | Autonomous SDLC showcase — idea → spec → plan → implement → review → deploy |
| `/demo-teardown` | Purge demo workspace |

### Plugin Commands

| Command | Plugin | Purpose |
|---------|--------|---------|
| `/github-pr` | cc-github | PR creation and review workflows |
| `/github-issue` | cc-github | Issue triage and creation |
| `/jira-sync` | cc-jira | Sync orchestrator plans to Jira stories |
| `/jira-context` | cc-jira | Pull Jira issue details into session |
| `/confluence-publish` | cc-confluence | Publish artifacts to Confluence pages |
| `/confluence-search` | cc-confluence | Search Confluence for existing docs |
| `/jama-trace` | cc-jama | Trace requirements in Jama |
| `/jama-context` | cc-jama | Pull Jama item details into session |
| `/demo [idea]` | cc-demo | Autonomous SDLC showcase with cinematic narration |
| `/demo-teardown` | cc-demo | Purge demo workspace |

## Common Patterns

### Start a Full Lifecycle

```bash
# Launch conductor agent for orchestrated workflow
claude --agent conductor
# Then inside the session:
# /conduct Add OAuth2 authentication to the API
```

### Quick One-Shot Tasks

```bash
# Explain code
claude -p "explain the authentication flow in src/auth/"

# Fix a bug
claude -p "fix the null pointer exception in UserService.getUser()"

# Generate tests
claude -p "write unit tests for src/utils/validators.ts"
```

### Review Code

```bash
# Interactive review
claude --agent reviewer
# /review src/auth/

# One-shot review
claude -p "review src/auth/login.ts for security issues" --agent reviewer
```

### Assess Complexity First

```bash
# Check routing before committing to a workflow
claude -p "/route Refactor the database layer to support multi-tenancy"
# Output: DEEP — triggers Research → Plan → Implement → Review → Security
```

### Use Plugins

```bash
# Pull Jira context into a coding session
claude -p "get Jira issue PROJ-123 and summarize the requirements" \
  --tool mcp__cc_jira__get_issue

# Search Confluence for prior art
claude -p "search Confluence for pages about SSO integration in space ENG" \
  --tool mcp__cc_confluence__search_pages

# Trace a Jama requirement
claude -p "trace Jama item 4567 — show upstream needs and downstream test cases" \
  --tool mcp__cc_jama__get_item --tool mcp__cc_jama__get_relationships
```

### Cost-Conscious Session

```bash
# Set a budget cap
claude --max-budget-usd 2 --agent conductor

# Use budget profile (Haiku default, Sonnet for review)
# Copy examples/settings-budget.json to .claude/settings.json first
```

### Resume Work

```bash
# Continue where you left off
claude --resume

# List recent sessions
claude sessions list

# Resume a specific session
claude --resume <session-id>
```

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `ORCH_MODEL_HEAVY` | Override heavy-tier model | `claude-opus-4-6-20260320` |
| `ORCH_MODEL_DEFAULT` | Override default-tier model | `claude-sonnet-4-6-20260320` |
| `ORCH_MODEL_FAST` | Override fast-tier model | `claude-haiku-4-5-20250315` |
| `JIRA_BASE_URL` | Jira Cloud instance URL | `https://your-domain.atlassian.net` |
| `JIRA_USER_EMAIL` | Jira auth email | `you@company.com` |
| `JIRA_API_TOKEN` | Jira API token | *(from Atlassian account)* |
| `CONFLUENCE_BASE_URL` | Confluence Cloud URL | `https://your-domain.atlassian.net` |
| `CONFLUENCE_USER_EMAIL` | Confluence auth email | `you@company.com` |
| `CONFLUENCE_API_TOKEN` | Confluence API token | *(from Atlassian account)* |
| `JAMA_BASE_URL` | Jama Connect URL | `https://your-instance.jamacloud.com` |
| `JAMA_CLIENT_ID` | Jama OAuth client ID | *(from Jama admin)* |
| `JAMA_CLIENT_SECRET` | Jama OAuth client secret | *(from Jama admin)* |

## Complexity Routing

| Tier | Trigger | What Happens |
|------|---------|-------------|
| **INSTANT** | Trivial question or fix | Direct response, no agents |
| **STANDARD** | Single-file change | Plan → Implement → Review |
| **DEEP** | Multi-file feature | Research → Plan → Implement → Review → Security |
| **ULTRADEEP** | Architecture change | Research → Plan → Implement → Trilateral Review |

## Validation

```bash
# Validate orchestrator assets
powershell -File scripts/validate-assets.ps1          # Windows
bash scripts/validate-assets.sh --verbose              # macOS/Linux

# Run smoke tests
powershell -File scripts/run-smoke-tests.ps1           # Windows
bash scripts/run-smoke-tests.sh                        # macOS/Linux
```