# Guide: Product Owner / Business Analyst

Requirements gathering, specification building, estimation, and integration with Jira, Confluence, and Jama.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| Build a specification | `/spec <feature>` | spec-builder |
| Decompose stories from a spec | `/route` then delegate to req-analyst | req-analyst |
| Estimate effort | `/estimate <task or plan>` | estimator |
| Sync plan to Jira | `/jira-sync` | jira-sync |
| Pull Jira issue context | `/jira-context <issue-key>` | jira-sync |
| Publish spec to Confluence | `/confluence-publish` | confluence-sync |
| Trace requirements (Jama) | `/jama-trace` | jama-sync |

## Building a Specification

Start here when you have an idea but not a spec. The spec-builder guides you through a structured 5-phase dialogue:

```bash
claude --agent spec-builder
/spec User notification preferences with per-channel granularity

# Phase 1: Problem Discovery — what, who, why, constraints
# Phase 2: Scope Definition — in/out of scope, MoSCoW, NFRs
# Phase 3: Behavior Specification — user stories, acceptance criteria (Given/When/Then)
# Phase 4: Risk & Dependency Analysis — external APIs, compliance, assumptions
# Phase 5: Assembly — compiled spec with requirement IDs (REQ-NNNN)
```

The dialogue asks 3-5 focused questions per phase. If you're unsure about something, say so — the spec-builder will make a recommendation with rationale.

**Output formats:**
- `--format markdown` — local spec file (default)
- `--format jama` — Jama-ready JSON with requirement IDs
- `--format confluence` — wiki markup ready to publish

## Story Decomposition from a Spec

```bash
# After the spec is built, decompose it into sprint-ready stories
claude --agent req-analyst

# Req-analyst follows INVEST criteria:
# Independent, Negotiable, Valuable, Estimable, Small, Testable
# Output format per story:
# [STORY-NNN] Title
# As a {persona}, I want to {action} so that {outcome}
# Acceptance Criteria: Given/When/Then
# Priority: MUST / SHOULD / COULD
# Estimated Complexity: S / M / L / XL
```

## Effort Estimation

```bash
claude --agent estimator
/estimate Review artifacts/plans/notification-prefs/plan.md

# Returns:
# | Story | Size | Points | Confidence | Notes |
# Stories with LOW confidence are flagged for discussion
# Sprint capacity recommendation based on team velocity
```

Or estimate before a plan exists:

```bash
claude -p "/estimate Add user notification preferences with email, push, and SMS channels" \
  --agent estimator
```

## Jira Integration

### Pull Context Before a Meeting

```bash
/jira-context PROJ-456
# Fetches issue title, description, acceptance criteria, sprint, priority, linked issues
# Summarizes in a format useful for planning conversations
```

### Sync a Completed Plan to Stories

After the planner produces an implementation plan:

```bash
/jira-sync
# Reads artifacts/plans/{feature}/plan.md
# Creates: 1 Jira epic + N stories (one per plan phase)
# Each story gets: acceptance criteria, effort estimate, dependency links
```

### Update Issues After Delivery

```bash
claude -p "transition PROJ-456 to Done and add a comment summarizing what was delivered based on artifacts/plans/notification-prefs/plan-complete.md" \
  --tool mcp__cc_jira__transition_issue --tool mcp__cc_jira__add_comment
```

## Confluence Integration

### Publish Specs and Plans

```bash
/confluence-publish
# Choose which artifact to publish:
# - Specification → publishes to your configured spec space
# - Plan → publishes to your architecture/design space
# - Review findings → publishes to quality/review space
```

### Search Before Writing

```bash
/confluence-search notification preferences
# Finds existing Confluence pages that might contain relevant context
# Prevents duplicate documentation
```

## Jama Connect (Regulated Projects)

For DO-178C, IEC 62304, ISO 26262, or ISO 26262 projects where requirements must be traceable to implementation and tests:

```bash
# Pull requirement context before planning
/jama-context REQ-1234
# Fetches requirement text, rationale, upstream needs, downstream test cases

# After delivery — trace implementation back to requirements
/jama-trace
# Maps code changes to Jama items
# Identifies requirements with no test coverage
# Identifies requirements not addressed by any code change
```

## From Idea to Sprint

A typical end-to-end flow:

```
1. /spec           → Build structured spec with the spec-builder
2. req-analyst      → Decompose spec into stories
3. /estimate       → Size stories for sprint planning
4. /jira-sync      → Push stories to Jira
5. /confluence-publish → Publish spec as documentation
6. /jama-trace     → Verify requirements traceability (regulated projects)
```

## Working with Developers

Once stories are in Jira and the plan is approved:

- Developers run `/jira-context <issue-key>` to pull your acceptance criteria directly into their session
- The conductor uses your acceptance criteria as success conditions for review
- Review findings are posted back to the Jira issue by the `jira-sync` agent
