#!/usr/bin/env node
/**
 * WorktreeRemove hook — logs worktree teardown for delegation tracking.
 * Fires when an isolation: worktree agent completes and its worktree is removed.
 * See: https://code.claude.com/docs/en/hooks#worktreeremove
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
  const worktreePath = data.worktree_path;

  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (fs.existsSync(sessionsDir)) {
    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    const entry = {
      event: 'worktree_remove',
      timestamp: new Date().toISOString(),
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
      worktreePath: worktreePath || 'unknown'
    };
    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
  }
} catch (err) {
  process.stderr.write(`[worktree-remove] Warning: ${err.message}\n`);
}

process.exit(0);
