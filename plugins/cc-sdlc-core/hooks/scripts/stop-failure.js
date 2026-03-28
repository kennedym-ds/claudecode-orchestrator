#!/usr/bin/env node
/**
 * StopFailure hook — logs API errors and agent failures for post-mortem analysis.
 * Fired when Claude stops due to an error rather than normal completion.
 * See: https://code.claude.com/docs/en/hooks#stopfailure
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  const data = input ? JSON.parse(input) : {};

  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  const entry = {
    event: 'stop_failure',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    error: data.error || 'unknown error',
    reason: data.stop_reason || 'unknown'
  };

  // Append to failure log for trend analysis
  const logFile = path.join(sessionsDir, 'failure-log.jsonl');
  fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');

  // Also write a standalone failure report for the session
  const dateStr = new Date().toISOString().slice(0, 10);
  const reportFile = path.join(sessionsDir, `${dateStr}-failure.md`);
  const report = [
    `# Session Failure — ${entry.timestamp}`,
    '',
    `- **Session:** ${entry.sessionId}`,
    `- **Error:** ${entry.error}`,
    `- **Stop reason:** ${entry.reason}`,
    '',
    'Check `artifacts/memory/activeContext.md` for last known phase state.',
    ''
  ].join('\n');

  fs.writeFileSync(reportFile, report);
} catch (err) {
  process.stderr.write(`[stop-failure] Warning: ${err.message}\n`);
}

process.exit(0);
