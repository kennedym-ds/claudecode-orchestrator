# Common Workflows

End-to-end CLI patterns for every SDLC phase using the Claude Code orchestrator.

## 1. Feature Development (Full Lifecycle)

Use when adding a new feature that touches multiple files.

```bash
# Step 1: Launch conductor
claude --agent conductor

# Step 2: Start the lifecycle
# /conduct Add password reset flow with email verification

# Step 3: Conductor routes → Planner creates plan
# PAUSE — review and approve the plan

# Step 4: Conductor delegates to Implementer (TDD)
# Code is written with tests first

# Step 5: Conductor delegates to Reviewer
# PAUSE — review findings, approve or request changes

# Step 6: Complete
```

**One-liner (non-interactive):**
```bash
claude -p "plan and implement a password reset flow with email verification" --agent conductor --max-budget-usd 5
```

## 2. Bug Fix (Standard)

Use for bugs with known scope (single file or module).

```bash
# Assess complexity first
claude -p "/route Fix the race condition in UserCache.refresh()"
# → STANDARD: Plan → Implement → Review

# Direct fix with TDD
claude -p "fix the race condition in src/cache/UserCache.ts — write a failing test first, then fix it"
```

## 3. Code Review

Use before merging PRs or after implementation.

```bash
# Interactive review with full session
claude --agent reviewer
# /review src/auth/

# One-shot review of specific files
claude -p "review src/auth/login.ts and src/auth/session.ts for security and correctness"

# Security-focused review
claude -p "/secure src/api/handlers/" --agent security-reviewer
```

**Review output format:** Findings tagged with severity (BLOCKER, MAJOR, MINOR, NIT) and categorized (Security, Correctness, Performance, Style).

## 3. Planning Only

Use when you want a plan without execution.

```bash
# Interactive planning
claude --agent planner
# /plan Migrate from REST to GraphQL API

# One-shot plan
claude -p "create a multi-phase implementation plan for migrating the database from PostgreSQL to DynamoDB" --agent planner
```

Plan output goes to `artifacts/plans/{feature}/plan.md`.

## 4. Research Phase

Use when you need evidence gathering before planning.

```bash
# Research existing patterns
claude -p "/research What authentication libraries does this codebase use and what are the alternatives?"

# Research with Confluence (if plugin installed)
claude -p "search Confluence for architecture decisions about authentication in space ARCH" \
  --tool mcp__cc_confluence__search_pages --tool mcp__cc_confluence__get_page
```

## 5. TDD Workflow

Use for test-first development.

```bash
# Interactive TDD
claude --agent tdd-guide
# /test src/services/PaymentService.ts

# One-shot test writing
claude -p "write unit tests for the PaymentService class — cover happy path, edge cases, and error handling"
```

**TDD cycle:** Red (write failing test) → Green (minimal implementation) → Refactor (clean up) → Repeat.

## 6. Security Audit

Use before releases or when touching sensitive code.

```bash
# Full security audit
claude -p "/secure src/" --agent security-reviewer

# Focused audit
claude -p "audit src/api/auth/ for OWASP Top 10 vulnerabilities" --agent security-reviewer

# Adversarial testing
claude -p "/red-team src/api/handlers/payment.ts" --agent red-team
```

## 7. Documentation Generation

Use after features are complete.

```bash
# Generate docs for a module
claude -p "/doc src/auth/" --agent doc-updater

# Update README
claude -p "update README.md to reflect the new authentication module"
```

## 8. Deploy Readiness Check

Use before releases.

```bash
claude -p "/deploy-check"
```

Checks: test coverage, lint status, security scan, documentation freshness, dependency vulnerabilities.

## 9. Jira Integration Workflows

### Sync a Plan to Jira

```bash
# Create stories from an approved plan
claude "/jira-sync"
# Agent reads artifacts/plans/{feature}/plan.md
# Creates epic + stories in Jira

# One-shot
claude -p "create Jira stories in project PROJ from the plan in artifacts/plans/auth-refactor/plan.md" \
  --tool mcp__cc_jira__create_issue --tool mcp__cc_jira__search_issues
```

### Pull Issue Context

```bash
# Get issue details before implementing
claude -p "get Jira issue PROJ-456 and summarize the acceptance criteria" \
  --tool mcp__cc_jira__get_issue

# Get sprint overview
claude -p "show the active sprint for Jira project PROJ with all issues" \
  --tool mcp__cc_jira__get_sprint
```

### Update Issues After Work

```bash
# Transition issue and add comment
claude -p "transition Jira issue PROJ-456 to 'In Review' and add a comment with the review summary from artifacts/reviews/" \
  --tool mcp__cc_jira__transition_issue --tool mcp__cc_jira__add_comment
```

## 10. Confluence Integration Workflows

### Publish Artifacts

```bash
# Publish a plan
claude "/confluence-publish"
# Choose artifact → choose space → creates/updates page

# One-shot
claude -p "publish artifacts/plans/auth-refactor/plan.md to Confluence space DEV under 'Architecture Plans'" \
  --tool mcp__cc_confluence__create_page --tool mcp__cc_confluence__search_pages
```

### Research Existing Docs

```bash
claude "/confluence-search"
# Searches relevant spaces for docs matching current task

# One-shot
claude -p "find all Confluence pages about API authentication in spaces DEV and ARCH" \
  --tool mcp__cc_confluence__search_pages --tool mcp__cc_confluence__get_page
```

## 11. Jama Integration Workflows

### Requirements Traceability

```bash
# Trace a requirement
claude "/jama-trace"
# Enter item ID → shows upstream/downstream relationships

# One-shot
claude -p "trace Jama item 1234 and show all upstream stakeholder needs and downstream test cases" \
  --tool mcp__cc_jama__get_item --tool mcp__cc_jama__get_relationships
```

### Test Coverage Mapping

```bash
# Map test coverage for a cycle
claude -p "build a test coverage map for Jama test cycle 567 — show which requirements are covered" \
  --tool mcp__cc_jama__get_test_runs --tool mcp__cc_jama__get_relationships --tool mcp__cc_jama__get_item
```

## 12. Cost Management

```bash
# Set a hard budget
claude --max-budget-usd 3 --agent conductor

# Check mid-session
# /status

# Use budget profile
# Copy examples/settings-budget.json → .claude/settings.json
# Haiku for triage, Sonnet for implementation, Opus only for security

# Compact context to save tokens
# /compact
```

## 13. Session Recovery

```bash
# Resume last session
claude --resume

# List sessions
claude sessions list

# Resume specific session
claude --resume <session-id>

# After compaction, context is restored from artifacts/memory/activeContext.md
```

## Workflow Decision Tree

```
Is this a trivial fix or question?
├── Yes → claude -p "your question"  (INSTANT)
└── No
    Is it a single-file change?
    ├── Yes → /plan + /implement + /review  (STANDARD)
    └── No
        Does it touch architecture or security?
        ├── Yes → /conduct with DEEP or ULTRADEEP routing
        └── No → /conduct with DEEP routing
```