---
name: pr-review
description: Pull request review workflow — orchestrates multi-agent review with confidence scoring, parallel analysis, and PR comment formatting.
user-invocable: false
---

# PR Review Workflow

## Overview

Multi-perspective PR review using parallel specialized agents with confidence-based filtering.

## Review Pipeline

1. **Gather context** — PR diff, CLAUDE.md guidelines, related files
2. **Launch parallel reviews:**
   - Convention compliance (vs CLAUDE.md and coding standards)
   - Bug detection (focused on changes only, not pre-existing issues)
   - Historical context (git blame, related changes)
   - Test coverage assessment (are changes tested?)
3. **Score findings** — Each finding gets a confidence score 0-100
4. **Filter** — Only findings ≥80 confidence are reported (configurable)
5. **Format** — Output as terminal summary or PR comment

## Finding Format

```markdown
### {severity}: {title}
**Confidence:** {score}/100
**File:** {path}#L{start}-L{end}
**Category:** Bug | Convention | Security | Coverage | Performance

{description}

**Suggestion:**
{specific fix or recommendation}
```

## Severity Levels

- **BLOCKER** (confidence ≥90): Breaks functionality, security vulnerability
- **MAJOR** (confidence ≥80): Significant quality issue, missing coverage
- **MINOR** (confidence ≥70): Style, naming, minor improvement
- **NIT** (confidence ≥60): Optional, author's discretion

## Auto-Skip Conditions

Don't review if:
- PR is closed or draft
- PR is trivial/automated (dependabot, version bumps)
- PR already has a review from this session
- All changes are documentation-only (use doc-updater instead)

## Comment Modes

- `--terminal` (default): Output to terminal for local review
- `--comment`: Post as PR comment via `gh` CLI
- `--inline`: Post inline comments on specific code lines
