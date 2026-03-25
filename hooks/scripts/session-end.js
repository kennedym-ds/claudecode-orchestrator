#!/usr/bin/env node
/**
 * SessionEnd hook — archives session state to artifacts.
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');

try {
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  const sessionId = process.env.CLAUDE_SESSION_ID || 'unknown';
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const sessionFile = path.join(sessionsDir, `session-${timestamp}.json`);

  const sessionData = {
    sessionId,
    endedAt: new Date().toISOString(),
    status: 'completed'
  };

  fs.writeFileSync(sessionFile, JSON.stringify(sessionData, null, 2));
} catch (err) {
  process.stderr.write(`[session-end] Warning: ${err.message}\n`);
}

process.exit(0);
