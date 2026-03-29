#!/usr/bin/env node
/**
 * SessionStart hook — loads previous session state and sets orchestrator env vars.
 * Uses CLAUDE_ENV_FILE to persist environment variables for the session.
 * See: https://code.claude.com/docs/en/hooks#sessionstart
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const contextFile = path.join(projectDir, 'artifacts', 'memory', 'activeContext.md');

try {
  // Write orchestrator env vars to CLAUDE_ENV_FILE if available
  const envFile = process.env.CLAUDE_ENV_FILE;
  if (envFile) {
    const envVars = [];

    // Mark that we're running in orchestrator mode
    envVars.push('ORCH_SESSION_ACTIVE=true');

    // Check if activeContext.md exists (session has prior state)
    if (fs.existsSync(contextFile)) {
      envVars.push('ORCH_HAS_PRIOR_STATE=true');
    }

    fs.appendFileSync(envFile, envVars.join('\n') + '\n');
  }

  // Log session start for observability
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  const logFile = path.join(sessionsDir, 'session-log.jsonl');
  const entry = {
    event: 'session_start',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    hasPriorState: fs.existsSync(contextFile)
  };
  fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
} catch (err) {
  // Non-blocking — session starts even if hook fails
  process.stderr.write(`[session-start] Warning: ${err.message}\n`);
}

process.exit(0);
