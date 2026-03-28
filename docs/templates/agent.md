---
# REQUIRED — unique identifier, lowercase-with-hyphens
name: my-agent

# REQUIRED — describes when Claude should delegate to this agent
# Include "Use proactively" for auto-delegation
description: >
  Brief role description — what it does and when.
  Use when [trigger conditions].

# MODEL — opus (heavy/judgment), sonnet (default/execution), haiku (fast/triage)
# Or full ID: claude-opus-4-6-20260320
model: sonnet

# TOOL ACCESS — allowlist (inherits all if omitted)
# tools: Read, Grep, Glob, Bash
# tools: Agent(sub-agent-1, sub-agent-2), Read, Bash
# OR denylist:
# disallowedTools: Write, Edit

# PERMISSIONS — default | plan (read-only) | acceptEdits | dontAsk | bypassPermissions
# permissionMode: default

# EXECUTION LIMITS
maxTurns: 30

# SKILLS — injected at startup (NOT inherited from parent)
# skills:
#   - coding-standards
#   - tdd-workflow

# PERSISTENT MEMORY — survives across sessions
# memory: project    # user | project | local

# THINKING EFFORT — low | medium | high | max (max requires Opus)
# effort: medium

# ISOLATION — run in temporary git worktree
# isolation: worktree

# BACKGROUND — always run as background task
# background: false

# SCOPED HOOKS — run only while this agent is active
# hooks:
#   PreToolUse:
#     - matcher: "Bash"
#       hooks:
#         - type: command
#           command: "./scripts/my-guard.sh"

# SCOPED MCP SERVERS
# mcpServers:
#   - my-server:
#       type: stdio
#       command: node
#       args: ["mcp/server.js"]
---

You are the **My Agent** — [one-sentence role definition].

## Process

1. **Step one** — What to do first
2. **Step two** — What to do next
3. **Step three** — How to finish

## Output Format

Describe the expected output structure.

## Constraints

- What the agent should NOT do
- Boundaries of responsibility
- When to escalate back to the conductor
