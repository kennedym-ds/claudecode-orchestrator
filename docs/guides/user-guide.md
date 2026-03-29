# User Guide

Guide to using cc-sdlc for orchestrated software development with Claude Code.

## Table of Contents

- [Getting Started](#getting-started)
- [Understanding the Conductor](#understanding-the-conductor)
- [Complexity Routing](#complexity-routing)
- [Core Workflows](#core-workflows)
- [Working with Agents](#working-with-agents)
- [Integration Workflows](#integration-workflows)
- [Artifacts and Session State](#artifacts-and-session-state)
- [Configuration](#configuration)
- [Commands Reference](#commands-reference)
- [Tips and Best Practices](#tips-and-best-practices)
- [Common Patterns Cookbook](#common-patterns-cookbook)

---

## Getting Started

### First Session

After [installing](installation.md) and running [onboarding](installation.md#interactive-onboarding), start your first orchestrated session:

```bash
# Launch the conductor agent
claude --agent conductor

# Describe what you want to build
# /conduct Add user authentication with JWT tokens
```

The conductor assesses complexity, creates a plan, delegates to specialized agents, and manages the full lifecycle — pausing for your approval at key checkpoints.

### When to Use the Conductor

| Scenario | Approach |
|----------|----------|
| Multi-file feature | `claude --agent conductor` → `/conduct` |
| Quick question | `claude -p "explain this function"` (no conductor needed) |
| Single-file bug fix | `claude -p "fix the null check in utils.ts"` or `/conduct` for TDD |
| Code review only | `claude --agent reviewer` → `/review src/` |
| Research only | `claude --agent researcher` → `/research GraphQL vs REST` |
| Architecture decision | `/conduct` or `claude --agent planner` |

### Resuming Sessions

```bash
# Resume most recent session
claude --resume

# Resume a specific session
claude --resume <session-id>

# Continue last conversation
claude --continue
```

---

## Understanding the Conductor

The conductor is the lifecycle orchestrator. It never writes code directly — it delegates to specialized agents and manages transitions between phases.

### Lifecycle Phases

```
┌─────────┐    ┌──────────┐    ┌──────────────┐    ┌────────┐    ┌──────────┐
│ Routing  │───▶│ Planning │───▶│Implementation│───▶│ Review │───▶│ Complete │
└─────────┘    └──────────┘    └──────────────┘    └────────┘    └──────────┘
                    │                                    │
                    ▼                                    ▼
               PAUSE POINT                         PAUSE POINT
            (approve plan)                     (approve findings)
```

**What happens at each phase:**

1. **Routing** — Conductor assesses complexity (INSTANT → ULTRADEEP) and selects the right workflow depth.
2. **Planning** — Planner agent drafts a multi-phase implementation plan with success criteria, risks, and testing strategy.
3. **PAUSE** — You review and approve the plan (or request changes).
4. **Implementation** — Implementer agent executes each phase using TDD (write test → make it pass → refactor).
5. **Review** — Reviewer agent audits changes with severity-tagged findings (BLOCKER, MAJOR, MINOR, NIT).
6. **PAUSE** — You review findings and approve or request fixes.
7. **Complete** — Final report with summary, residual risks, and follow-up recommendations.

### State Tracking

Every conductor response includes a state block:

```
Current Phase: Implementation
Plan Progress: 2 of 4 phases
Last Action: Implementer completed Phase 2 (API endpoints)
Next Action: Launch Phase 3 (frontend integration)
```

This helps you track where you are in multi-phase work across long sessions.

---

## Complexity Routing

Before starting any task, the conductor (or you, via `/route`) assesses complexity to choose the right workflow depth.

### Complexity Tiers

| Tier | Description | Example | Agents Involved |
|------|-------------|---------|-----------------|
| **INSTANT** | Trivial question or one-liner | "What's the default port?" | Direct response |
| **STANDARD** | Single-file or small change | "Add input validation to the form" | Plan → Implement → Review |
| **DEEP** | Multi-file feature | "Add OAuth2 authentication" | Research → Plan → Implement → Review → Security |
| **ULTRADEEP** | Architectural change | "Migrate from monolith to microservices" | Research → Plan → Implement → Trilateral Review |

### Manual Complexity Assessment

```bash
# Ask the conductor to assess without executing
/route Refactor the payment processing module

# Expected output:
# Complexity: DEEP
# Rationale: Multi-file refactor, touches payment logic (financial risk),
#            requires careful testing and security review
# Recommended agents: Researcher, Planner, Implementer, Reviewer, Security
```

### Trilateral Review (ULTRADEEP)

For high-risk tasks, the conductor runs three independent reviews in parallel:

1. **Reviewer** — Correctness, quality, maintainability
2. **Red Team** — Adversarial testing, edge cases, failure modes
3. **Security Reviewer** — OWASP compliance, threat surface

All three must reach consensus before the conductor marks the phase complete.

---

## Core Workflows

### Feature Development

The most common workflow — building a new feature from start to finish.

```bash
claude --agent conductor

# Full lifecycle orchestration
/conduct Add password reset with email verification

# Conductor will:
# 1. Assess complexity → DEEP
# 2. Delegate to planner → multi-phase plan
# 3. PAUSE for your approval
# 4. Execute each phase via implementer (TDD)
# 5. Review each phase via reviewer
# 6. Security scan at the end
# 7. Compile final report
```

### Bug Fix

```bash
claude --agent conductor

/conduct Fix the race condition in UserCache.refresh()
# Routes as STANDARD → Plan → Implement (with regression test) → Review
```

Or skip the conductor for simple fixes:

```bash
claude -p "fix the null pointer in src/utils/parser.ts, write a failing test first"
```

### Code Review

```bash
# Interactive review session
claude --agent reviewer
/review src/auth/

# One-shot review
claude -p "review src/api/handlers/ for security and correctness"

# Security-focused review
claude --agent security-reviewer
/secure src/payments/
```

Review output uses severity tags:

| Severity | Meaning | Action |
|----------|---------|--------|
| **BLOCKER** | Security vulnerability or data loss risk | Must fix before merge |
| **MAJOR** | Bug or significant logic error | Should fix before merge |
| **MINOR** | Code quality or maintainability issue | Fix in this PR or create follow-up |
| **NIT** | Style preference or minor optimization | Optional |

### Research

```bash
claude --agent researcher
/research Compare WebSocket vs SSE for real-time notifications

# Output: evidence summary with citations, trade-offs, recommendation
```

### Planning Only

```bash
claude --agent planner
/plan Migrate from PostgreSQL to DynamoDB

# Output: multi-phase plan in artifacts/plans/
```

### Architecture Decision

```bash
claude --agent conductor
/conduct Should we use a message queue for async processing?

# Conductor routes to: Researcher → Planner
# Produces an ADR (Architecture Decision Record) in artifacts/decisions/
```

---

## Working with Agents

### Agent Categories

| Category | Agents | Purpose |
|----------|--------|---------|
| **Orchestration** | conductor | Lifecycle management |
| **Planning** | planner, architect, spec-builder, req-analyst, estimator | Design and planning |
| **Execution** | implementer, pair-programmer, tdd-guide | Code writing |
| **Quality** | reviewer, security-reviewer, red-team, threat-modeler | Review and testing |
| **Testing** | test-architect, tdd-guide, e2e-tester | Test strategy and writing |
| **Support** | researcher, doc-updater, deploy-engineer, incident-responder | Research, docs, ops |
| **Integration** | github-pr, github-issue, jira-sync, confluence-sync, jama-sync | External tools |

### Direct Agent Access

You can bypass the conductor and work with agents directly:

```bash
# Start a specific agent
claude --agent implementer
claude --agent researcher
claude --agent reviewer

# Use the agent's commands
/implement Add rate limiting to the API
/research Compare Redis vs Memcached for session storage
/review src/api/
```

### Model Tiers

Each agent runs on a model tier matched to its task complexity:

| Tier | Model | Used For |
|------|-------|----------|
| **heavy** (Opus) | Judgment-heavy tasks | Conductor, Planner, Reviewer, Security, Architect |
| **default** (Sonnet) | Execution tasks | Implementer, Researcher, Test writing, Docs |
| **fast** (Haiku) | Lightweight tasks | Triage, routing, estimation, deploy checks |

You can override per-session:

```bash
claude --model claude-opus-4-6-20260320 --agent implementer
```

---

## Integration Workflows

### GitHub (PRs and Issues)

Requires `GITHUB_TOKEN` configured during [onboarding](installation.md#interactive-onboarding).

```bash
# Create a PR from current changes
/github-pr

# Triage and manage issues
/github-issue

# Full workflow: implement → review → create PR
/conduct Add pagination to the user list API
# After completion, conductor can delegate to github-pr agent
```

**What the GitHub integration does:**
- Creates pull requests with structured descriptions
- Adds review comments and suggestions
- Manages labels, assignees, milestones
- Links PRs to issues
- Checks CI/CD status

### Jira (Sprint Planning)

Requires `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, `JIRA_API_TOKEN` configured during onboarding.

```bash
# Pull issue context into the session
/jira-context PROJ-123

# Sync a plan to Jira stories
/jira-sync
# Converts plan phases → Jira stories with acceptance criteria

# Full workflow: pull issue → plan → implement → sync back
/conduct Implement PROJ-123
```

**What the Jira integration does:**
- Pulls issue details, acceptance criteria, and sprint context
- Generates stories from implementation plans
- Updates issue status and adds work notes
- Links related issues

### Confluence (Documentation)

Requires `CONFLUENCE_BASE_URL`, `CONFLUENCE_USER_EMAIL`, `CONFLUENCE_API_TOKEN` configured during onboarding.

```bash
# Search existing documentation
/confluence-search authentication flow

# Publish artifacts to Confluence
/confluence-publish
# Publishes plan, review findings, or ADRs as Confluence pages

# Research using Confluence as a source
/research How does the current auth system work?
# Researcher agent can pull from Confluence if configured
```

### Jama Connect (Requirements Tracing)

Requires `JAMA_BASE_URL`, `JAMA_CLIENT_ID`, `JAMA_CLIENT_SECRET` configured during onboarding.

```bash
# Pull requirements context
/jama-context REQ-456

# Trace requirements to implementation
/jama-trace
# Maps code changes to Jama requirements items

# Useful for regulated industries (DO-178C, IEC 62304, ISO 26262)
```

### Checking Integration Status

If an integration isn't configured, the conductor gracefully degrades — it skips integration agents and notes the missing configuration:

```
Note: Jira integration not configured. Skipping story sync.
To configure: pwsh -File installer/onboard.ps1
```

---

## Artifacts and Session State

### Artifact Directory Structure

```
artifacts/
├── plans/              ← Implementation plans
│   └── {feature}/
│       ├── plan.md
│       ├── phase-1-complete.md
│       └── plan-complete.md
├── reviews/            ← Code review findings
├── research/           ← Research summaries
├── security/           ← Security audit reports
├── sessions/           ← Session state snapshots
├── decisions/          ← Architecture Decision Records (ADRs)
└── memory/
    └── activeContext.md ← Current focus, decisions, open questions
```

### Initializing Artifacts

```bash
# Create the directory structure
bash scripts/init-artifacts.sh
# or
pwsh -File scripts/init-artifacts.ps1
```

### Active Context

The file `artifacts/memory/activeContext.md` tracks your current session state:

```markdown
# Active Context

## Current Focus
Phase 2 of 4: Implementing API endpoints for password reset

## Recent Decisions
1. Using JWT with short-lived tokens (15 min) for reset links
2. Email verification via SendGrid API
3. Rate limiting: 3 reset requests per hour per email

## Open Questions
- Should we support SMS as an alternative to email?
- What's the token expiry policy for enterprise accounts?

## Plan Progress
- [x] Phase 1: Database schema and migrations
- [ ] Phase 2: API endpoints (IN PROGRESS)
- [ ] Phase 3: Email service integration
- [ ] Phase 4: Frontend reset flow
```

This file persists across context compactions, so you don't lose critical state in long sessions.

### Cleaning Up Artifacts

```bash
# Preview what would be cleaned
pwsh -File scripts/cleanup-artifacts.ps1 -DryRun

# Clean old artifacts (keeps recent sessions)
pwsh -File scripts/cleanup-artifacts.ps1
```

---

## Configuration

### sdlc-config.md

Your project-level configuration file. Created by the installer.

```yaml
project:
  name: "My Project"
  language: "typescript"
  framework: "react"

domain:
  primary: "web-frontend"      # Applies domain-specific coding overlay
  secondary: ["uiux"]

workflow:
  default_complexity: "STANDARD"
  require_plan_approval: true   # Pause after planning phase
  tdd: true                     # Enforce test-first in implementer
  confidence_threshold: 80      # Minimum confidence score for auto-approval
```

### Model Tier Configuration

Edit `.claude/settings.json`:

```json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
    "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
  }
}
```

**Prebuilt profiles** (copy from `examples/`):

| Profile | Heavy | Default | Fast | Best For |
|---------|-------|---------|------|----------|
| `settings-standard.json` | Opus | Sonnet | Haiku | Recommended balance |
| `settings-budget.json` | Sonnet | Haiku | Haiku | Cost-conscious |
| `settings-premium.json` | Opus | Opus | Sonnet | Maximum quality |

### Cost Control

```bash
# Set a hard cost cap for the session
claude --agent conductor --max-budget-usd 5

# Check spending mid-session
/status
```

**Cost reduction tips:**
- Use `STANDARD` complexity routing for most tasks (Sonnet handles 80%+ of work)
- Run `/compact` at milestones to reduce context size
- Use `/clear` between unrelated tasks
- Keep fewer than 10 MCP servers and 80 tools active
- Use `settings-budget.json` for non-critical work

---

## Commands Reference

### Orchestration Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/conduct <task>` | Full lifecycle orchestration | Multi-phase work |
| `/route <task>` | Assess complexity without executing | Before starting, to preview workflow |
| `/status` | Session state, phase progress, budget | Mid-session checkpoints |
| `/compact` | Strategic context compaction | Long sessions, at milestones |

### Planning Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/plan <task>` | Create implementation plan | Feature design |
| `/architect <task>` | Architecture design + ADR | System design decisions |
| `/spec <feature>` | Interactive specification builder | Requirements gathering |
| `/estimate <task>` | Effort estimation (T-shirt / story points) | Sprint planning |

### Execution Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/implement <task>` | TDD implementation | Writing code |
| `/test <scope>` | Write tests | Adding test coverage |
| `/test-arch <scope>` | Test strategy design | Planning test pyramid |
| `/e2e <scope>` | End-to-end tests | Acceptance testing |
| `/pair` | Pair programming session | Collaborative coding |

### Quality Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/review <scope>` | Code review with severity tags | Before merge |
| `/secure <scope>` | OWASP security audit | Security-sensitive changes |
| `/threat-model <scope>` | STRIDE/DREAD analysis | Architecture review |
| `/red-team <scope>` | Adversarial testing | High-risk features |
| `/audit` | Orchestrator self-check | Validating harness health |

### Support Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/research <topic>` | Evidence gathering with citations | Technical decisions |
| `/doc <scope>` | Documentation generation | After implementation |
| `/deploy-check` | CI/CD readiness check | Before deployment |
| `/incident <issue>` | Root cause analysis (5-why) | Production issues |

### Integration Commands

| Command | Purpose | Prerequisites |
|---------|---------|---------------|
| `/jira-context <key>` | Pull Jira issue details | Jira configured |
| `/jira-sync` | Sync plan to Jira stories | Jira configured |
| `/confluence-search <query>` | Search Confluence | Confluence configured |
| `/confluence-publish` | Publish artifacts to Confluence | Confluence configured |
| `/jama-context <key>` | Pull Jama requirements | Jama configured |
| `/jama-trace` | Requirements traceability | Jama configured |

---

## Tips and Best Practices

### Do

- **Start with `/route`** to preview complexity before launching a full workflow
- **Approve plans carefully** — the plan shapes everything that follows
- **Use `/compact` at milestones** to keep context lean in long sessions
- **Commit after each phase** — the conductor pauses to let you manage git
- **Use `--max-budget-usd`** to prevent runaway sessions
- **Edit `sdlc-config.md`** to match your project's language, framework, and domain
- **Keep artifacts up to date** — they're your session's persistent memory

### Don't

- **Don't skip pause points** — they exist to catch problems early
- **Don't use ULTRADEEP for simple tasks** — it's expensive and slow
- **Don't ignore review findings** — BLOCKER and MAJOR findings indicate real risks
- **Don't commit secrets** — add `.claude/settings.json` to `.gitignore`
- **Don't run multiple conductors** on the same branch simultaneously

### Session Management

```bash
# Long feature (multiple sessions)
# Session 1: Plan + Phase 1
claude --agent conductor
/conduct Add multi-tenant support
# ... approve plan, complete Phase 1, commit ...
# Session ends

# Session 2: Resume and continue
claude --resume
# Conductor reads activeContext.md and picks up where you left off

# Unrelated task between sessions
claude --agent conductor
/clear
/conduct Fix the login page CSS
```

### Handling Review Feedback

When the reviewer finds issues:

1. **BLOCKER/MAJOR findings** — Conductor routes back to implementer for fixes
2. **MINOR findings** — You choose: fix now or create follow-up task
3. **NIT findings** — Noted in the report, no action required

You can also request a re-review after fixes:

```bash
/review src/auth/  # Re-review after fixing findings
```

---

## Common Patterns Cookbook

### Pattern: API Endpoint Development

```bash
/conduct Add CRUD endpoints for the products resource
# Plan: schema → endpoints → tests → docs
# Implements: model, routes, controllers, integration tests, OpenAPI spec
```

### Pattern: Database Migration

```bash
/conduct Migrate user preferences from JSON column to normalized tables
# Plan: new schema → migration script → update queries → backfill → verify
# Includes rollback strategy
```

### Pattern: Security Hardening

```bash
/conduct Harden the authentication system
# Routes as DEEP → Researcher + Security Reviewer + Implementer
# Produces threat model + implementation + security audit report
```

### Pattern: Performance Optimization

```bash
/conduct Optimize the product search to handle 10k concurrent queries
# Researcher analyzes current bottlenecks
# Planner proposes caching, indexing, and query optimization
# Implementer executes with benchmarks
```

### Pattern: Legacy Code Refactor

```bash
/conduct Refactor the payment module from callbacks to async/await
# Routes as DEEP
# Researcher maps current call chains
# Planner creates safe migration phases (no big bang)
# Each phase maintains backward compatibility
```

### Pattern: One-Shot Tasks (No Conductor)

```bash
# Quick explanation
claude -p "explain the authentication flow in src/auth/"

# Generate tests for a file
claude -p "write unit tests for src/utils/validators.ts"

# Fix a specific bug
claude -p "fix the off-by-one error in src/pagination.ts line 42"

# Format/lint a file
claude -p "fix all ESLint errors in src/components/Dashboard.tsx"
```

---

## Further Reading

- [Installation Guide](installation.md) — Install and configure cc-sdlc
- [CLI Quick Reference](cli-quick-reference.md) — Command flags and patterns
- [Common Workflows](common-workflows.md) — Step-by-step workflow examples
- [Model Configuration](model-configuration.md) — Detailed model tier setup
- [Creating Agents](creating-agents.md) — Build custom agents
- [Creating Skills](creating-skills.md) — Package domain knowledge
- [Creating Hooks](creating-hooks.md) — Add deterministic automation
- [Creating Plugins](creating-plugins.md) — Build and distribute plugins
- [Troubleshooting](troubleshooting.md) — Common issues and fixes
