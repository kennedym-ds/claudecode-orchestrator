#!/usr/bin/env node
/**
 * SubagentStop hook — quality gate when a subagent completes.
 * Logs subagent completion for budget tracking.
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
    // CC hook input uses snake_case: agent_name, stop_reason
    const agentName = data.agent_name || 'unknown';
    const stopReason = data.stop_reason || 'completed';

    // Log to sessions for budget tracking
    const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
    const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
    if (!fs.existsSync(sessionsDir)) {
      fs.mkdirSync(sessionsDir, { recursive: true });
    }

    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    const entry = {
      event: 'subagent_stop',
      timestamp: new Date().toISOString(),
      agent: agentName,
      stopReason,
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown'
    };

    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
  }
} catch (err) {
  process.stderr.write(`[subagent-stop-gate] Warning: ${err.message}\n`);
}

process.exit(0);
