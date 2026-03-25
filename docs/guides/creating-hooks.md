# Creating Custom Hooks

Hooks are deterministic scripts that run at specific points in the Claude Code lifecycle. They cost zero context tokens and enforce invariants that prompts and instructions cannot guarantee.

## Quick Start

Add hooks to `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "node hooks/scripts/run-linter.js"
          }
        ]
      }
    ]
  }
}
```

## Configuration Locations

| Location | Scope | Format |
|----------|-------|--------|
| `.claude/settings.json` | Project (standalone) | `"hooks": { ... }` key in settings |
| `.claude/settings.local.json` | Personal (not committed) | Same as above |
| Agent frontmatter | Per-agent | `hooks:` YAML field |
| Plugin `hooks/hooks.json` | Plugin distribution | `{ "hooks": { ... } }` wrapper |

## Hook Events Reference

### Session Lifecycle

| Event | Matcher | When it fires |
|-------|---------|--------------|
| `SessionStart` | — | Session begins |
| `SessionEnd` | — | Session ends |
| `Stop` | — | Agent/session stops (in agent frontmatter, auto-converted to SubagentStop) |

### User Input

| Event | Matcher | When it fires |
|-------|---------|--------------|
| `UserPromptSubmit` | — | User submits a prompt (before processing) |
| `Elicitation` | — | Before showing an elicitation form |
| `ElicitationResult` | — | After user responds to elicitation |

### Tool Lifecycle

| Event | Matcher | Tool name | When it fires |
|-------|---------|-----------|--------------|
| `PreToolUse` | Tool name | `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, MCP tools | Before tool execution |
| `PostToolUse` | Tool name | Same as above | After successful tool execution |
| `PostToolUseFailure` | Tool name | Same as above | After failed tool execution |

### Subagent Lifecycle

| Event | Matcher | Matches against | When it fires |
|-------|---------|----------------|--------------|
| `SubagentStart` | Agent type name | `agent_name` | When a subagent begins |
| `SubagentStop` | Agent type name | `agent_name` | When a subagent completes |

### Context Management

| Event | Matcher | When it fires |
|-------|---------|--------------|
| `PreCompact` | — | Before context compaction |
| `PostCompact` | — | After context compaction |

### Permissions & Configuration

| Event | Matcher | When it fires |
|-------|---------|--------------|
| `PermissionRequest` | — | When a permission prompt would be shown |
| `Notification` | — | When Claude sends a notification |
| `InstructionsLoaded` | — | When CLAUDE.md/rules/skills are loaded |
| `ConfigChange` | — | When settings change |
| `TaskCompleted` | — | When task completes (autopilot mode) |

### Worktree Management

| Event | Matcher | When it fires |
|-------|---------|--------------|
| `WorktreeCreate` | — | When a git worktree is created |
| `WorktreeRemove` | — | When a git worktree is removed |

## Hook Types

### Command (default)

Runs a shell command. Hook input is passed as JSON on stdin.

```json
{
  "type": "command",
  "command": "node hooks/scripts/my-hook.js"
}
```

### HTTP

Sends hook input as POST to an HTTP endpoint.

```json
{
  "type": "http",
  "url": "http://localhost:3000/hooks/post-edit"
}
```

### Prompt

Evaluates an LLM prompt with the hook input as context. Uses fast model.

```json
{
  "type": "prompt",
  "prompt": "Review whether this bash command is safe to execute. If dangerous, respond with BLOCK."
}
```

### Agent

Delegates to a subagent to handle the hook.

```json
{
  "type": "agent",
  "agent": "security-reviewer"
}
```

## Hook Configuration Fields

```json
{
  "type": "command",
  "command": "./scripts/my-hook.sh",
  "async": true,
  "statusMessage": "Running linter...",
  "once": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | `command`, `http`, `prompt`, or `agent` |
| `command` | string | Shell command (for `command` type) |
| `url` | string | HTTP endpoint (for `http` type) |
| `prompt` | string | LLM prompt (for `prompt` type) |
| `agent` | string | Agent name (for `agent` type) |
| `async` | boolean | Run without blocking (default: false) |
| `statusMessage` | string | UI message shown while hook runs |
| `once` | boolean | Run only once per session (default: false) |

## Input Schema (stdin JSON)

### PreToolUse
```json
{
  "session_id": "abc123",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/test"
  }
}
```

### PostToolUse
```json
{
  "session_id": "abc123",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "src/app.ts",
    "content": "..."
  }
}
```

### SubagentStart / SubagentStop
```json
{
  "session_id": "abc123",
  "agent_name": "code-reviewer",
  "stop_reason": "completed"
}
```

### UserPromptSubmit
```json
{
  "session_id": "abc123",
  "prompt": "Fix the auth bug in login.ts"
}
```

## Exit Codes

| Code | Behavior |
|------|----------|
| `0` | Success — operation proceeds |
| `2` | Block — operation is prevented (PreToolUse, UserPromptSubmit) |
| Other non-zero | Warning — logged but operation proceeds |

**For exit code 2:** Content written to **stderr** is fed back to Claude as an error message.

## Writing Hook Scripts (Node.js)

### Template: Blocking hook (PreToolUse)

```javascript
#!/usr/bin/env node
const fs = require('fs');

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const command = data.tool_input?.command || '';

    if (/dangerous-pattern/.test(command)) {
      process.stderr.write('Blocked: reason for blocking');
      process.exit(2);
    }
  }
} catch (err) {
  process.stderr.write(`[my-hook] Warning: ${err.message}\n`);
}

process.exit(0);
```

### Template: Logging hook (SubagentStart)

```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const logDir = path.join(projectDir, 'artifacts', 'sessions');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }

    const entry = {
      event: 'subagent_start',
      timestamp: new Date().toISOString(),
      agent: data.agent_name || 'unknown',
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown'
    };

    fs.appendFileSync(
      path.join(logDir, 'hook-log.jsonl'),
      JSON.stringify(entry) + '\n'
    );
  }
} catch (err) {
  process.stderr.write(`[my-hook] Warning: ${err.message}\n`);
}

process.exit(0);
```

### Template: SessionStart with CLAUDE_ENV_FILE

```javascript
#!/usr/bin/env node
const fs = require('fs');

try {
  const envFile = process.env.CLAUDE_ENV_FILE;
  if (envFile) {
    fs.appendFileSync(envFile, 'MY_CUSTOM_VAR=value\n');
  }
} catch (err) {
  process.stderr.write(`[session-start] Warning: ${err.message}\n`);
}

process.exit(0);
```

## Writing Hook Scripts (Bash)

```bash
#!/bin/bash
# Read JSON input from stdin
INPUT=$(cat)

# Extract fields with jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block dangerous patterns
if echo "$COMMAND" | grep -iE '\b(DROP|TRUNCATE)\b' > /dev/null; then
  echo "Blocked: destructive SQL operation" >&2
  exit 2
fi

exit 0
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Project root path (use for file path resolution) |
| `CLAUDE_SESSION_ID` | Current session identifier |
| `CLAUDE_ENV_FILE` | Write `KEY=value` lines here in SessionStart to set session env vars |
| `CLAUDE_PLUGIN_ROOT` | Plugin root directory (for plugin hooks) |

## Hooks in Agent Frontmatter

Agents can define scoped hooks that run only while that agent is active:

```yaml
---
name: db-reader
description: Read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

## Hooks in Plugin Distribution

Plugin hooks go in `hooks/hooks.json` at the plugin root:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node hooks/scripts/lint.js"
          }
        ]
      }
    ]
  }
}
```

## Best Practices

1. **Always handle missing stdin gracefully** — Check `process.stdin.isTTY` or use `cat` with fallback
2. **Use `CLAUDE_PROJECT_DIR`** for path resolution instead of `process.cwd()`
3. **Keep hooks fast** — Use `async: true` for non-blocking operations like linting
4. **Write to stderr for user feedback** — Exit code 2 + stderr is the standard blocking pattern
5. **Use snake_case** for reading input fields (`tool_input`, `agent_name`, not camelCase)
6. **Non-blocking by default** — Only exit 2 when you need to prevent an operation
7. **Log, don't crash** — Wrap in try/catch, exit 0 on errors unless blocking is intended
