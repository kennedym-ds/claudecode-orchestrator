---
# REQUIRED — must match the directory name
name: my-skill

# REQUIRED — Claude uses this to decide when to auto-invoke
description: >
  Brief description of what this skill does and when to use it.
  Include keywords that match user requests.

# ARGUMENTS — placeholder shown in autocomplete
# argument-hint: <file-or-scope>

# INVOCATION CONTROL
# disable-model-invocation: true    # Only user can invoke (default: false)
# user-invocable: true              # User can invoke via /name (default: true)

# TOOL RESTRICTIONS (same as agent tools field)
# allowed-tools:
#   - Read
#   - Grep
#   - Glob

# MODEL OVERRIDE — force specific model when this skill runs
# model: opus

# THINKING EFFORT — low | medium | high | max
# effort: high

# RUN IN SUBAGENT — fork context for isolated execution
# context: fork
# agent: Explore    # Explore | Plan | general-purpose | custom-agent-name

# SCOPED HOOKS
# hooks:
#   PostToolUse:
#     - matcher: "Edit|Write"
#       hooks:
#         - type: command
#           command: "./scripts/lint.sh"
---

# My Skill

Brief overview of what this skill provides.

## When to Use

- Trigger condition 1
- Trigger condition 2
- Trigger condition 3

## Workflow

1. **First step** — What to do
2. **Second step** — What to do next
3. **Third step** — How to conclude

## Rules

### Category 1

- Rule with rationale
- Another rule

### Category 2

- Rule with example:
  ```python
  # ✅ Good
  good_pattern()

  # ❌ Bad
  bad_pattern()
  ```

## Examples

### Example 1: Brief Description

```
Input: description of input
Output: description of expected output
```

## References

- Link to relevant documentation
- Link to related skills
