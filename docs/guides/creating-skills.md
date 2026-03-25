# Creating Custom Skills

Skills are reusable workflows that Claude can invoke on demand or automatically. This guide covers creating, configuring, and testing skills.

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
