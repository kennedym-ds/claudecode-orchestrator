#!/usr/bin/env node
/**
 * Hook Template: Logging/Async Hook (PostToolUse, SubagentStart, SessionStart, etc.)
 *
 * This hook logs events to a JSONL file. It should never block operations.
 * Use "async": true in your hook config for non-blocking execution.
 *
 * Usage in hooks.json or .claude/settings.json:
 *   {
 *     "hooks": {
 *       "PostToolUse": [{
 *         "matcher": "Edit|Write",
 *         "hooks": [{
 *           "type": "command",
 *           "command": "node hooks/scripts/my-logging-hook.js",
 *           "async": true,
 *           "statusMessage": "Logging changes..."
 *         }]
 *       }]
 *     }
 *   }
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const sessionId = process.env.CLAUDE_SESSION_ID || 'unknown';

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);

    // Build log entry
    const entry = {
      timestamp: new Date().toISOString(),
      session_id: sessionId,
      event: data.tool_name || data.agent_name || 'unknown',
      // Customize these fields for your use case:
      file: data.tool_input?.file_path || null,
      command: data.tool_input?.command || null,
    };

    // Write to log file
    const logDir = path.join(projectDir, 'artifacts', 'sessions');
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }

    fs.appendFileSync(
      path.join(logDir, 'hook-log.jsonl'),
      JSON.stringify(entry) + '\n'
    );
  }
} catch (err) {
  // Never crash — just warn
  process.stderr.write(`[my-logging-hook] Warning: ${err.message}\n`);
}

process.exit(0);
