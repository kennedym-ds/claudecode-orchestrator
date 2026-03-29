# Creating Custom Hooks

Hooks are deterministic scripts that run at specific points in the Claude Code lifecycle. They cost zero context tokens and enforce invariants that prompts and instructions cannot guarantee.

**Templates:** [`docs/templates/hook-blocking.js`](../templates/hook-blocking.js) and [`docs/templates/hook-logging.js`](../templates/hook-logging.js) — copy-paste starters

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Locations](#configuration-locations)
- [Hook Events Reference](#hook-events-reference)
- [Hook Types](#hook-types)
- [Hook Configuration Fields](#hook-configuration-fields)
- [Input Schema (stdin JSON)](#input-schema-stdin-json)
- [Exit Codes](#exit-codes)
- [Writing Hook Scripts (Node.js)](#writing-hook-scripts-nodejs)
- [Writing Hook Scripts (Bash)](#writing-hook-scripts-bash)
- [Environment Variables](#environment-variables)
- [Hooks in Agent Frontmatter](#hooks-in-agent-frontmatter)
- [Hooks in Plugin Distribution](#hooks-in-plugin-distribution)
- [Adding Hooks to cc-sdlc](#adding-hooks-to-cc-sdlc)
- [Hook Patterns Cookbook](#hook-patterns-cookbook)
- [Debugging Hooks](#debugging-hooks)
- [Performance Considerations](#performance-considerations)
- [Best Practices](#best-practices)

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

## Adding Hooks to cc-sdlc

### Where hooks live

All cc-sdlc-core hooks are in:

```
plugins/cc-sdlc-core/
├── hooks/
│   ├── hooks.json              # Hook configuration
│   └── scripts/
│       ├── session-start.js    # SessionStart
│       ├── secret-detector.js  # UserPromptSubmit (exit 2 to block)
│       ├── pre-bash-safety.js  # PreToolUse Bash (exit 2 to block)
│       ├── deploy-guard.js     # PreToolUse Bash (exit 2 to block)
│       ├── post-edit-validate.js   # PostToolUse Edit|Write (async)
│       ├── dependency-scanner.js   # PostToolUse Edit|Write (async)
│       ├── compliance-logger.js    # PostToolUse Edit|Write (async)
│       ├── subagent-start-log.js   # SubagentStart
│       ├── subagent-stop-gate.js   # SubagentStop
│       ├── pre-compact.js      # PreCompact
│       ├── post-compact.js     # PostCompact
│       ├── stop-summary.js     # Stop
│       ├── pr-gate.js          # Stop
│       └── session-end.js      # SessionEnd
```

### Steps to add a new hook

#### 1. Write the hook script

Create a new `.js` file in `plugins/cc-sdlc-core/hooks/scripts/`:

```javascript
#!/usr/bin/env node
// my-hook.js — Brief description of what this hook does
const fs = require('fs');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    // Your hook logic here
  }
} catch (err) {
  process.stderr.write(`[my-hook] Warning: ${err.message}\n`);
}

process.exit(0);
```

#### 2. Register in hooks.json

Add your hook to `plugins/cc-sdlc-core/hooks/hooks.json`:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "node ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/my-hook.js"
          }
        ]
      }
    ]
  }
}
```

**Important:** Use `${CLAUDE_PLUGIN_ROOT}` for portable path resolution in plugin hooks.

#### 3. Update documentation

Add the hook to the events table in `AGENTS.md`:

```markdown
| ✓ EventName | Matcher | my-hook.js | Brief description |
```

#### 4. Validate

```bash
pwsh -File scripts/validate-assets.ps1 -ShowDetails
```

The validator checks that `hooks.json` is valid JSON with a `hooks` key.

### Hook safety tiers in cc-sdlc

The orchestrator uses a 3-tier hook safety system:

| Tier | Event | Purpose | Exit behavior |
|------|-------|---------|--------------|
| **Blocking** | UserPromptSubmit, PreToolUse | Prevent dangerous operations | Exit 2 = block |
| **Async validation** | PostToolUse | Lint, scan, log after changes | `async: true`, exit 0 |
| **Lifecycle logging** | SessionStart/End, SubagentStart/Stop, Compact | Track state and budget | Exit 0 always |

When adding a new hook, decide which tier it belongs to:
- **Blocking hooks** must be fast (< 1 second) and deterministic
- **Async hooks** can be slower — they run in the background
- **Lifecycle hooks** should never fail — wrap everything in try/catch

## Hook Patterns Cookbook

### Pattern: Enforce file naming conventions

Block file creation with wrong naming:

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
    const filePath = data.tool_input?.file_path || '';

    // Enforce kebab-case for .ts files
    if (filePath.endsWith('.ts')) {
      const filename = filePath.split('/').pop().replace('.ts', '');
      if (filename !== filename.toLowerCase().replace(/[^a-z0-9-]/g, '-')) {
        process.stderr.write(
          `Blocked: TypeScript files must use kebab-case. Got: ${filename}`
        );
        process.exit(2);
      }
    }
  }
} catch (err) {
  process.stderr.write(`[naming-check] Warning: ${err.message}\n`);
}

process.exit(0);
```

Register as `PreToolUse` with matcher `Write`.

### Pattern: Auto-format after edit

```javascript
#!/usr/bin/env node
const fs = require('fs');
const { execSync } = require('child_process');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const filePath = data.tool_input?.file_path || '';

    if (filePath.endsWith('.py')) {
      execSync(`cd "${projectDir}" && python -m black "${filePath}" --quiet`, {
        timeout: 10000
      });
    } else if (filePath.match(/\.(ts|js|tsx|jsx)$/)) {
      execSync(`cd "${projectDir}" && npx prettier --write "${filePath}"`, {
        timeout: 10000
      });
    }
  }
} catch (err) {
  // Formatter failure should not block — just warn
  process.stderr.write(`[auto-format] Warning: ${err.message}\n`);
}

process.exit(0);
```

Register as `PostToolUse` with matcher `Edit|Write` and `"async": true`.

### Pattern: Budget tracking on subagent launches

```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

// Model cost estimates per 1K tokens (approximate)
const MODEL_COSTS = {
  opus: { input: 0.015, output: 0.075 },
  sonnet: { input: 0.003, output: 0.015 },
  haiku: { input: 0.00025, output: 0.00125 }
};

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const budgetFile = path.join(projectDir, 'artifacts', 'sessions', 'budget.jsonl');
    const budgetDir = path.dirname(budgetFile);

    if (!fs.existsSync(budgetDir)) {
      fs.mkdirSync(budgetDir, { recursive: true });
    }

    fs.appendFileSync(budgetFile, JSON.stringify({
      timestamp: new Date().toISOString(),
      agent: data.agent_name || 'unknown',
      session: process.env.CLAUDE_SESSION_ID || 'unknown',
      event: 'subagent_start'
    }) + '\n');
  }
} catch (err) {
  process.stderr.write(`[budget-track] Warning: ${err.message}\n`);
}

process.exit(0);
```

### Pattern: Block commands matching environment-specific patterns

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

    // Block production database connections
    const blocked = [
      /\bprod\b.*\b(mysql|psql|mongo|redis-cli)\b/i,
      /\b(mysql|psql|mongo|redis-cli)\b.*\bprod\b/i,
      /DATABASE_URL=.*prod/i,
    ];

    for (const pattern of blocked) {
      if (pattern.test(command)) {
        process.stderr.write(
          'Blocked: Production database access is not allowed in this environment.'
        );
        process.exit(2);
      }
    }
  }
} catch (err) {
  process.stderr.write(`[env-guard] Warning: ${err.message}\n`);
}

process.exit(0);
```

## Debugging Hooks

### Hook not firing

1. **Check event name** — Must exactly match: `PreToolUse`, `PostToolUse`, `SessionStart`, etc.
2. **Check matcher** — For tool events, the matcher must match the tool name (e.g., `Bash`, `Edit|Write`)
3. **Check config location** — Project hooks in `.claude/settings.json`, plugin hooks in `hooks/hooks.json`
4. **Check permissions** — Script must be executable (`chmod +x` on Unix)
5. **Test manually** — Run the script with sample JSON on stdin:
   ```bash
   echo '{"tool_input":{"command":"ls"}}' | node hooks/scripts/my-hook.js
   echo $?  # Should be 0
   ```

### Hook blocking unexpectedly

1. **Check exit code** — Only exit code 2 blocks. Other non-zero codes are warnings.
2. **Check stderr** — The stderr output becomes the error message Claude sees
3. **Check regex patterns** — Test your patterns against the actual commands being blocked
4. **Add debug logging** — Temporarily log to a file:
   ```javascript
   fs.appendFileSync('/tmp/hook-debug.log', JSON.stringify(data) + '\n');
   ```

### Hook crashing

1. **Check JSON parsing** — Always guard against empty or malformed stdin
2. **Check file paths** — Use `CLAUDE_PROJECT_DIR`, not relative paths
3. **Check dependencies** — hooks run in a Node.js/Bash environment, not in Claude's context
4. **Check timeout** — Long-running hooks may be killed. Use `async: true` for slow operations.

### Testing hooks end-to-end

```bash
# Test a PreToolUse hook
echo '{"tool_input":{"command":"rm -rf /"}}' | node hooks/scripts/pre-bash-safety.js
# Expected: exit code 2, stderr message

# Test a PostToolUse hook
echo '{"tool_input":{"file_path":"src/app.ts"}}' | node hooks/scripts/post-edit-validate.js
# Expected: exit code 0

# Test a SessionStart hook
CLAUDE_ENV_FILE=/tmp/test-env node hooks/scripts/session-start.js < /dev/null
cat /tmp/test-env  # Should contain env vars
```

## Performance Considerations

| Hook type | Target latency | Impact if slow |
|-----------|---------------|----------------|
| PreToolUse (blocking) | < 100ms | Blocks every tool invocation |
| UserPromptSubmit | < 100ms | Delays prompt processing |
| PostToolUse (async) | < 5s | Runs in background, no user impact |
| SessionStart | < 1s | Delays session initialization |
| SubagentStart/Stop | < 500ms | Delays delegation handoff |

**Tips for fast hooks:**
- Avoid network calls in blocking hooks
- Use `async: true` for anything involving I/O, linting, or scanning
- Cache regex patterns (compile once, test many)
- Use `once: true` for hooks that only need to run once per session
