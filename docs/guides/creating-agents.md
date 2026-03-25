# Creating Custom Agents

This guide covers how to create, configure, and test custom subagents for Claude Code.

## Quick Start

1. Run `/agents` in Claude Code to use the interactive agent creator
2. Or manually create a file in `.claude/agents/`:

```markdown
---
name: my-agent
description: What this agent does and when Claude should use it
model: sonnet
---

Your system prompt here. This becomes the agent's instructions.
```

3. Restart your session or run `/agents` to load the new agent

## File Location & Scope

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Current session only | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin `agents/` directory | Where plugin enabled | 4 (lowest) |

When multiple agents share the same `name`, the higher-priority location wins.

## Frontmatter Reference

```yaml
---
# Required
name: my-agent              # lowercase-with-hyphens, unique identifier
description: >              # When Claude should delegate to this agent
  Expert code reviewer. Use proactively after code changes.

# Model selection
model: sonnet               # sonnet, opus, haiku, inherit, or full ID (e.g. claude-opus-4-6)

# Tool access (comma-separated or YAML list)
tools: Read, Grep, Glob, Bash           # Allowlist — inherits all if omitted
# OR
disallowedTools: Write, Edit             # Denylist — removed from inherited set

# Permission handling
permissionMode: default     # default | plan | acceptEdits | dontAsk | bypassPermissions

# Execution limits
maxTurns: 30                # Max agentic turns before stopping

# Skills injected at startup (not inherited from parent)
skills:
  - security-review
  - coding-standards

# Persistent memory (survives across sessions)
memory: project             # user | project | local

# Thinking effort level
effort: high                # low | medium | high | max (max requires Opus)

# Isolation
isolation: worktree         # Run in temporary git worktree

# Background execution
background: true            # Always run as background task (default: false)

# Scoped hooks (run only while this agent is active)
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"

# Scoped MCP servers
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  - github                  # Reference already-configured server by name
---
```

## System Prompt (Body)

Everything after the frontmatter `---` becomes the agent's system prompt. This replaces the default Claude Code system prompt. CLAUDE.md files and project memory still load normally.

Write focused prompts that:
- Define the agent's role clearly in the first sentence
- Describe the workflow (numbered steps)
- Specify output format expectations
- State constraints (what NOT to do)

```markdown
---
name: code-reviewer
description: Expert code reviewer. Use proactively after writing code.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a senior code reviewer. When invoked:
1. Run `git diff` to see recent changes
2. Focus on modified files
3. Review for quality, security, and best practices

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)  
- Suggestions (consider improving)

You cannot modify files. Include specific fix examples.
```

## Tool Access Patterns

### Read-only agent
```yaml
tools: Read, Grep, Glob, Bash
permissionMode: plan
```

### Implementation agent
```yaml
# Inherits all tools (omit tools field)
permissionMode: default
```

### Restricted subagent spawning (main thread only)
```yaml
tools: Agent(worker, researcher), Read, Bash
```

### Block specific tools
```yaml
disallowedTools: Write, Edit, WebFetch
```

## Persistent Memory

When `memory` is set, the agent gets a directory for cross-session learning:

| Scope | Path | Use when |
|-------|------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge applies across all projects |
| `project` | `.claude/agent-memory/<name>/` | Knowledge is project-specific, shareable via git |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not checked into git |

Include memory instructions in the system prompt:
```markdown
Update your agent memory as you discover patterns, library locations,
and key architectural decisions. Write concise notes about what you found.
```

## Hooks in Agent Frontmatter

Agents can define hooks that run only while that agent is active:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
```

`Stop` hooks in agent frontmatter are auto-converted to `SubagentStop` events.

## Testing

```bash
# Test interactively
claude   # then ask Claude to "use the my-agent agent"

# Run as main thread
claude --agent my-agent

# Set as project default
# In .claude/settings.json:
{ "agent": "my-agent" }
```

## Common Patterns

### Conductor (orchestrates other agents)
```yaml
name: conductor
tools: Agent(planner, implementer, reviewer), Read, Grep, Glob, Bash
model: opus
memory: project
effort: high
```

### Read-only reviewer
```yaml
name: reviewer
tools: Read, Grep, Glob, Bash
permissionMode: plan
model: opus
memory: project
```

### Background worker
```yaml
name: background-tester
tools: Read, Bash, Grep, Glob
background: true
model: haiku
```

### Isolated worker (git worktree)
```yaml
name: experiment-runner
isolation: worktree
permissionMode: default
```

## Important Constraints

- **Subagents cannot spawn other subagents.** Only the main thread (via `--agent`) can use `Agent()` to spawn subagents.
- **Plugin agents cannot use** `hooks`, `mcpServers`, or `permissionMode` (security restriction).
- **Skills are not inherited** from the parent conversation — list them explicitly.
- **Description drives delegation** — Claude uses the `description` field to decide when to delegate. Include "Use proactively" for auto-delegation.

## Invocation

- **Natural language:** "Use the code-reviewer agent to look at these changes"
- **@-mention:** `@"code-reviewer (agent)" review the auth module`
- **Main thread:** `claude --agent code-reviewer`
- **Project default:** Set `"agent": "code-reviewer"` in `.claude/settings.json`
