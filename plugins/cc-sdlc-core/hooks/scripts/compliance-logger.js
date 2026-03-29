#!/usr/bin/env node
/**
 * PostToolUse (Edit|Write) hook — logs file changes for compliance audit trail.
 * Non-blocking (async). Appends to artifacts/sessions/audit-log.jsonl.
 */
const fs = require('fs');
const path = require('path');

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const filePath = data.tool_input?.file_path || '';
    const toolName = data.tool_name || 'unknown';

    if (!filePath) {
      process.exit(0);
    }

    const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');

    if (!fs.existsSync(sessionsDir)) {
      fs.mkdirSync(sessionsDir, { recursive: true });
    }

    const logEntry = {
      timestamp: new Date().toISOString(),
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
      tool: toolName,
      file: path.relative(projectDir, filePath),
      action: toolName === 'Write' ? 'create' : 'edit',
    };

    fs.appendFileSync(
      path.join(sessionsDir, 'audit-log.jsonl'),
      JSON.stringify(logEntry) + '\n'
    );
  }
} catch (err) {
  // Compliance logging failure is non-blocking
  process.stderr.write(`[compliance-logger] Warning: ${err.message}\n`);
}

process.exit(0);
