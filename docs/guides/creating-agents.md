# Creating Custom Agents

This guide covers how to create, configure, and test custom subagents for Claude Code, with specific guidance for extending the cc-sdlc orchestrator.

**Template:** [`docs/templates/agent.md`](../templates/agent.md) — copy-paste starter file

## Table of Contents

- [Quick Start](#quick-start)
- [File Location & Scope](#file-location--scope)
- [Frontmatter Reference](#frontmatter-reference)
- [System Prompt (Body)](#system-prompt-body)
- [Tool Access Patterns](#tool-access-patterns)
- [Persistent Memory](#persistent-memory)
- [Hooks in Agent Frontmatter](#hooks-in-agent-frontmatter)
- [Testing](#testing)
- [Common Patterns](#common-patterns)
- [Adding Agents to cc-sdlc](#adding-agents-to-cc-sdlc)
- [Model Tier Selection Guide](#model-tier-selection-guide)
- [Description Writing Guide](#description-writing-guide)
- [Debugging Agents](#debugging-agents)
- [Important Constraints](#important-constraints)
- [Invocation](#invocation)

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

## Adding Agents to cc-sdlc

When extending the orchestrator with a new core agent, follow these steps:

### 1. Choose the right plugin

| Plugin | When to use |
|--------|-------------|
| `cc-sdlc-core` | Core SDLC workflow agents (planning, implementing, reviewing, testing) |
| `cc-github` | GitHub-specific workflows |
| `cc-jira` | Jira-specific workflows |
| `cc-confluence` | Confluence-specific workflows |
| `cc-jama` | Jama-specific workflows |
| `cc-sdlc-standards` | Standards don't have agents — use skills instead |

### 2. Create the agent file

Place the agent in the target plugin's agent directory:

```
plugins/cc-sdlc-core/.claude/agents/my-agent.md
```

### 3. Register with the conductor

Add the agent name to the conductor's `tools` list so it can delegate:

```yaml
# In plugins/cc-sdlc-core/.claude/agents/conductor.md
tools:
  - Agent(planner, ..., my-agent)
```

### 4. Update the conductor's tier awareness

Add your agent to the appropriate model tier in the conductor's system prompt:

```markdown
## Model Tier Awareness

- **Heavy tier (Opus):** ..., My-Agent (if judgment-heavy)
- **Default tier (Sonnet):** ..., My-Agent (if implementation-focused)
- **Fast tier (Haiku):** ..., My-Agent (if lightweight)
```

### 5. Update documentation

- Add the agent to the roster table in `AGENTS.md`
- Add any new commands that invoke the agent to the commands table
- Run validation: `pwsh -File scripts/validate-assets.ps1`

### 6. Run validation

```bash
# Bash
bash scripts/validate-assets.sh

# PowerShell
pwsh -File scripts/validate-assets.ps1 -ShowDetails
```

The validator checks: frontmatter exists, `name` and `description` fields present, file is valid Markdown.

## Model Tier Selection Guide

Choosing the right model tier affects both quality and cost.

| Factor | → Opus (heavy) | → Sonnet (default) | → Haiku (fast) |
|--------|----------------|---------------------|----------------|
| **Decision quality** | Must be correct first time | Can iterate | Approximate is fine |
| **Context complexity** | Multi-file, cross-cutting | Single file or module | Single pattern |
| **Risk of error** | High (security, architecture) | Medium (features) | Low (docs, estimates) |
| **Turn count** | Few turns, high quality | Medium turns | Many turns, fast |
| **Cost sensitivity** | Not primary concern | Balanced | Cost-critical |

### Examples from cc-sdlc

```yaml
# Reviewer — judgment-heavy, must be accurate
model: opus
effort: high

# Implementer — execution-focused, iterative
model: sonnet
# effort defaults to medium

# Estimator — lightweight, approximate is fine
model: haiku
effort: low
```

## Description Writing Guide

The `description` field is how Claude decides when to delegate to your agent. Good descriptions drive accurate routing.

### Format

```
{Role summary} — {what it does}. Use {trigger conditions}.
```

### Good examples

```yaml
# ✅ Clear role, specific trigger
description: >
  Effort estimation and sprint planning — sizes work items and identifies
  scheduling risks. Use when estimating tasks, planning sprints, or
  assessing delivery timelines.

# ✅ Keyword-rich, auto-delegation enabled
description: >
  Expert code reviewer. Use proactively after code changes are made.
```

### Bad examples

```yaml
# ❌ Too vague — Claude won't know when to delegate
description: "Helps with code stuff"

# ❌ Too long — bloats tool list context
description: >
  This agent is a comprehensive multi-modal code analysis system that
  leverages advanced AI capabilities to perform deep semantic analysis
  of code patterns across multiple programming languages...
```

### Tips

- Include "Use proactively" if the agent should auto-activate
- Include keywords that match user requests ("sprint", "estimate", "deploy")
- Keep under 200 characters for the core description
- Describe **when** to use, not just **what** it does

## Debugging Agents

### Agent not being delegated to

1. **Check description** — Does it match the user's request keywords?
2. **Check conductor tools** — Is your agent listed in `Agent(...)`?
3. **Check name conflicts** — Run `grep -r "name: my-agent"` across all plugins
4. **Check file location** — Must be in `.claude/agents/` in the correct plugin

### Agent produces poor output

1. **Check model tier** — Is the task too complex for Haiku? Too simple for Opus?
2. **Check skills** — Are the right skills listed? Skills are **not inherited** from parent.
3. **Check system prompt** — Is the workflow clear? Are constraints explicit?
4. **Check maxTurns** — Is it running out of turns before completing?

### Agent has no tool access

1. **Check `tools` field** — If present, only listed tools are available
2. **Check `disallowedTools`** — Is the needed tool blocked?
3. **Check `permissionMode`** — `plan` mode blocks all writes
4. **Plugin restriction** — Plugin agents can't use `hooks`, `mcpServers`, or `permissionMode`

### Memory not persisting

1. **Check `memory` field** — Must be `user`, `project`, or `local`
2. **Check file path** — Memory is stored in `.claude/agent-memory/<name>/`
3. **Check system prompt** — Include instructions for the agent to use its memory

## Full Example: Adding a "Performance Profiler" Agent

Here's a complete walkthrough of adding a new agent to cc-sdlc-core.

### Step 1: Create the agent file

**`plugins/cc-sdlc-core/.claude/agents/performance-profiler.md`:**

```markdown
---
name: performance-profiler
description: >
  Performance profiling and optimization — measures runtime, memory, and
  I/O bottlenecks. Use when analyzing slow code, profiling endpoints,
  or optimizing hot paths.
model: sonnet
tools: Read, Grep, Glob, Bash
maxTurns: 25
memory: project
effort: high
skills:
  - coding-standards
---

You are the **Performance Profiler** — you identify and analyze
performance bottlenecks in code.

## Process

1. **Profile** — Identify the hot path using available tools
2. **Measure** — Get baseline metrics (time complexity, memory allocation)
3. **Analyze** — Determine root cause of bottleneck
4. **Recommend** — Propose optimizations with expected impact

## Output Format

| Metric | Current | After Fix | Improvement |
|--------|---------|-----------|-------------|
| Time complexity | O(n²) | O(n log n) | ~100x at n=10000 |
| Memory | 500MB | 50MB | 10x reduction |

## Constraints

- Never modify files — report findings only
- Always include Big-O analysis
- Compare against language-idiomatic patterns
```

### Step 2: Register with conductor

Add `performance-profiler` to the conductor's tools list and model tier docs.

### Step 3: Validate

```bash
pwsh -File scripts/validate-assets.ps1 -ShowDetails
# Should show: Agents: 25 (was 24)
```
