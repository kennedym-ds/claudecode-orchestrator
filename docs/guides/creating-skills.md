# Creating Custom Skills

Skills are reusable workflows that Claude can invoke on demand or automatically. This guide covers creating, configuring, and testing skills, with specific guidance for extending the cc-sdlc orchestrator.

**Template:** [`docs/templates/skill.md`](../templates/skill.md) — copy-paste SKILL.md starter

## Table of Contents

- [Quick Start](#quick-start)
- [Skills vs Commands vs Rules](#skills-vs-commands-vs-rules)
- [Frontmatter Reference](#frontmatter-reference)
- [Arguments](#arguments)
- [Dynamic Context with !command](#dynamic-context-with-command)
- [Supporting Files](#supporting-files)
- [Running in a Subagent (Fork Context)](#running-in-a-subagent-fork-context)
- [Tool Permissions in Settings](#tool-permissions-in-settings)
- [Plugin Skills](#plugin-skills)
- [Testing](#testing)
- [Common Patterns](#common-patterns)
- [Adding Skills to cc-sdlc](#adding-skills-to-cc-sdlc)
- [Writing Coding Standard Skills](#writing-coding-standard-skills)
- [Writing Domain Overlay Skills](#writing-domain-overlay-skills)
- [Debugging Skills](#debugging-skills)
- [Best Practices](#best-practices)

## Quick Start

1. Create a directory in `.claude/skills/` with a `SKILL.md` file:

```
.claude/skills/
└── my-skill/
    └── SKILL.md
```

2. Add frontmatter and instructions:

```markdown
---
name: my-skill
description: What this skill does and when Claude should use it
---

# My Skill

Instructions for Claude when this skill is invoked.
```

3. Invoke with `/my-skill` or let Claude auto-invoke based on context.

## Skills vs Commands vs Rules

| Primitive | When loaded | Invocation | Modifies context |
|-----------|-------------|-----------|-----------------|
| **Skills** | On demand (user or model) | `/skill-name` or auto | Yes, when invoked |
| **Commands** | On demand (user only if `disable-model-invocation: true`) | `/command-name` | Yes, when invoked |
| **Rules** | At session start or on file match | Automatic | Always in context |

Skills and commands are functionally merged in CC — commands in `.claude/commands/` work the same way as skills in `.claude/skills/`. Skills are the recommended approach.

## Frontmatter Reference

```yaml
---
# Required
name: my-skill
description: >
  Detailed description of what this skill does. Claude uses this to decide
  when to invoke the skill automatically.

# Arguments
argument-hint: <file-or-scope>    # Placeholder shown in autocomplete

# Invocation control
disable-model-invocation: true    # Only user can invoke (default: false)
user-invocable: true              # User can invoke via /name (default: true)

# Tool restrictions (same as agent tools field)
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash

# Model override
model: opus                       # Override session model when this skill runs

# Thinking effort
effort: high                      # low | medium | high | max

# Run in subagent (fork context)
context: fork                     # Runs in isolated subagent context
agent: Explore                    # Which agent type: Explore, Plan, general-purpose, or custom

# Scoped hooks
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/lint.sh"
---
```

## Arguments

Skills accept arguments via `$ARGUMENTS` and positional parameters:

```markdown
---
name: review-file
description: Review a specific file for code quality
argument-hint: <file-path>
---

Review the file at $ARGUMENTS for:
1. Code quality
2. Security issues
3. Test coverage gaps
```

**Invocation:** `/review-file src/auth.ts`

### Positional arguments

Use `$1`, `$2`, `$N` or `$ARGUMENTS[0]`, `$ARGUMENTS[1]`:

```markdown
---
name: compare
description: Compare two files
argument-hint: <file1> <file2>
---

Compare $1 and $2 for differences in approach, patterns, and quality.
```

### Environment substitutions

```markdown
Session: ${CLAUDE_SESSION_ID}
Skill directory: ${CLAUDE_SKILL_DIR}
```

## Dynamic Context with `!command`

Inject command output into the skill at invocation time:

```markdown
---
name: review-changes
description: Review recent git changes
---

Here are the recent changes:
`!git diff HEAD~1`

Review these changes for quality and security issues.
```

The backtick-bang syntax runs the command and injects its output.

## Supporting Files

Skills can include additional files in their directory. Reference them with relative paths:

```
.claude/skills/
└── security-review/
    ├── SKILL.md
    ├── owasp-checklist.md
    └── examples/
        └── common-vulnerabilities.md
```

In SKILL.md:
```markdown
Refer to the checklist in @owasp-checklist.md for the full review criteria.
```

## Running in a Subagent (Fork Context)

Use `context: fork` to run the skill in an isolated subagent. The skill's output returns to the main conversation as a summary.

```yaml
---
name: deep-analysis
description: Comprehensive codebase analysis
context: fork
agent: Explore        # Uses the fast, read-only Explore agent
effort: high
---

Analyze the entire codebase structure and report:
1. Architecture patterns
2. Dependency graph
3. Test coverage gaps
```

Agent types for `context: fork`:
- `Explore` — Fast, read-only (Haiku model)
- `Plan` — Planning mode, read-only
- `general-purpose` — Full capabilities
- Custom agent name — Uses your defined agent

## Tool Permissions in Settings

Control which skills are auto-approved:

```json
{
  "permissions": {
    "allow": [
      "Skill(my-skill)",
      "Skill(another-skill *)"
    ]
  }
}
```

`Skill(name)` allows invocation; `Skill(name *)` allows with any arguments.

## Plugin Skills

Skills in plugins are namespaced: `/plugin-name:skill-name`.

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── review/
        └── SKILL.md    → becomes /my-plugin:review
```

## Testing

```bash
# Direct invocation
claude
> /my-skill some-argument

# Check it's loaded
# Run /help to see available skills in the skill list
```

After editing a skill file, it loads automatically on next invocation. Use `/reload-plugins` for plugin skills.

## Common Patterns

### Read-only analysis skill
```yaml
---
name: analyze
description: Analyze code patterns in the codebase
allowed-tools: [Read, Grep, Glob]
---
```

### User-only skill (not auto-invoked)
```yaml
---
name: deploy
description: Run deployment checklist
disable-model-invocation: true
---
```

### High-effort thinking skill
```yaml
---
name: architect
description: Deep architectural analysis
model: opus
effort: max
---
```

### Forked exploration skill
```yaml
---
name: explore-deps
description: Map dependency graph
context: fork
agent: Explore
---
```

## Best Practices

1. **Keep SKILL.md under 200 lines** — Shorter content produces better adherence
2. **Write specific descriptions** — Claude uses the description for auto-invocation decisions
3. **Use `allowed-tools` for safety** — Restrict tool access when the skill doesn't need full capabilities
4. **Use `context: fork` for heavy analysis** — Keeps verbose output out of main context
5. **Use `disable-model-invocation: true`** for destructive or expensive operations that should only run when explicitly requested

## Adding Skills to cc-sdlc

### Choose the right plugin

| Plugin | Skill type | Example |
|--------|-----------|---------|
| `cc-sdlc-core` | Workflow skills (review, planning, deploy) | `confidence-scoring`, `tdd-workflow` |
| `cc-sdlc-standards` | Language coding standards | `python-standards`, `typescript-standards` |
| `cc-sdlc-standards` | Domain overlays | `embedded-systems-overlay`, `web-frontend-overlay` |
| `cc-github` | GitHub workflow skills | `pr-workflow`, `issue-triage` |
| `cc-jira` | Jira workflow skills | `issue-context`, `plan-to-stories` |
| `cc-confluence` | Confluence workflow skills | `publish-plan`, `research-confluence` |
| `cc-jama` | Jama workflow skills | `req-tracing`, `test-coverage-map` |

### Create the skill directory

```bash
# Core workflow skill
mkdir -p plugins/cc-sdlc-core/.claude/skills/my-skill/

# Language standard
mkdir -p plugins/cc-sdlc-standards/.claude/skills/my-language-standards/

# Domain overlay
mkdir -p plugins/cc-sdlc-standards/.claude/skills/my-domain-overlay/
```

### Write SKILL.md

Use the template at `docs/templates/skill.md` as a starting point.

### Register with agents

Add the skill name to any agent's `skills:` frontmatter that should use it:

```yaml
# In the agent's frontmatter
skills:
  - my-skill
  - existing-skill
```

### Validate

```bash
pwsh -File scripts/validate-assets.ps1 -ShowDetails
```

The validator checks: `SKILL.md` exists, frontmatter has `name` and `description`.

## Writing Coding Standard Skills

Coding standard skills live in `plugins/cc-sdlc-standards/` and follow a consistent structure.

### Structure

```
plugins/cc-sdlc-standards/.claude/skills/
└── my-language-standards/
    └── SKILL.md
```

### Severity tiers

All coding standards use three severity levels:

| Severity | Meaning | Review action |
|----------|---------|--------------|
| **ERROR** | Must fix before merge | Blocks code review approval |
| **WARNING** | Should fix, reviewer flags | Reviewer notes, may approve with caveat |
| **RECOMMENDATION** | Consider improving | Informational, does not affect approval |

### Template structure

```markdown
---
name: my-language-standards
description: >
  MyLanguage coding standards — idiomatic patterns, safety rules, and
  style conventions. Applied automatically during code review for
  .mylang files.
---

# MyLanguage Coding Standards

## ERROR — Must Fix

### MY-E001: Descriptive rule name
**Why:** Explain the risk or quality impact.
```mylang
// ❌ Bad
dangerousPattern()

// ✅ Good
safePattern()
```

## WARNING — Should Fix

### MY-W001: Descriptive rule name
**Why:** Explain why this matters.
```mylang
// ❌ Avoid
lessIdealPattern()

// ✅ Prefer
betterPattern()
```

## RECOMMENDATION — Consider

### MY-R001: Descriptive rule name
**Why:** Explain the benefit.
```mylang
// Consider this approach
improvedPattern()
```
```

### Naming conventions

- Skill directory: `{language}-standards` (e.g., `python-standards`, `typescript-standards`)
- Rule IDs: `{LANG}-{SEVERITY}{NUMBER}` (e.g., `PY-E001`, `TS-W003`, `GO-R002`)
- Severity prefix: `E` = ERROR, `W` = WARNING, `R` = RECOMMENDATION

### Reference: Existing language standards

The orchestrator ships with 20 language standards: python, javascript, typescript, c, cpp, csharp, go, rust, java, kotlin, swift, ruby, php, sql, terraform, bicep, powershell, vba, markdown, shell.

## Writing Domain Overlay Skills

Domain overlays add context-specific rules on top of language standards. They're activated via `sdlc-config.md` in the project.

### Structure

```
plugins/cc-sdlc-standards/.claude/skills/
└── my-domain-overlay/
    └── SKILL.md
```

### Template structure

```markdown
---
name: my-domain-overlay
description: >
  Domain overlay for {domain} — adds {domain}-specific patterns,
  safety rules, and compliance requirements on top of language standards.
---

# {Domain} Domain Overlay

## Context

This overlay applies when `sdlc-config.md` sets `domain.primary` or
`domain.secondary` to `my-domain`.

## ERROR — Domain-Specific Safety

### DOM-E001: Rule name
**Context:** When this domain rule applies.
**Why:** Domain-specific risk.

## WARNING — Domain Best Practices

### DOM-W001: Rule name
**Context:** When this applies.

## Integration with Language Standards

This overlay composes with any language standard. When conflicts exist:
- Domain ERROR overrides language RECOMMENDATION
- Domain WARNING adds to language WARNING
- If a language ERROR conflicts with domain practice, flag for human review
```

### Reference: Existing domain overlays

The orchestrator ships with 7 domain overlays: embedded-systems, semiconductor-test, safety-critical, edge-ai, enterprise-app, web-frontend, uiux.

## Debugging Skills

### Skill not auto-invoked

1. **Check description** — Does it match the user's request context?
2. **Check `disable-model-invocation`** — If `true`, only manual `/skill-name` works
3. **Check plugin namespace** — Plugin skills use `/plugin-name:skill-name`
4. **Check file structure** — Must be `skills/my-skill/SKILL.md` (directory with SKILL.md inside)

### Skill produces weak output

1. **Check length** — Skills over 200 lines tend to have lower adherence
2. **Check specificity** — Vague instructions produce vague output
3. **Use examples** — Include ✅/❌ code examples for clearer guidance
4. **Check model** — Complex skills may need `model: opus` or `effort: high`

### Skill arguments not working

1. **Use `$ARGUMENTS`** — The full argument string
2. **Use `$1`, `$2`** — Positional arguments (space-delimited)
3. **Check `argument-hint`** — Missing hint means no autocomplete guidance

### Supporting files not found

1. **Check relative paths** — Use `@filename.md` syntax in SKILL.md
2. **Check directory structure** — Files must be in the same skill directory or subdirectory
3. **Use `${CLAUDE_SKILL_DIR}`** — Resolves to the skill's directory at runtime
