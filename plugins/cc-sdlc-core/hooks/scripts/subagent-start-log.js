#!/usr/bin/env node
/**
 * SubagentStart hook — logs subagent launches for budget tracking.
 * See: https://code.claude.com/docs/en/hooks#subagentstart
 */
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
    const agentName = data.agent_name || 'unknown';

    // Log to sessions for budget tracking
    const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
    if (!fs.existsSync(sessionsDir)) {
      fs.mkdirSync(sessionsDir, { recursive: true });
    }

    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    const entry = {
      event: 'subagent_start',
      timestamp: new Date().toISOString(),
      agent: agentName,
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown'
    };

    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
  }
} catch (err) {
  process.stderr.write(`[subagent-start-log] Warning: ${err.message}\n`);
}

process.exit(0);
