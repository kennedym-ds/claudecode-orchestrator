#!/usr/bin/env node
/**
 * WorktreeCreate hook — seeds a new implementer worktree with current session context.
 * Fires when an agent with isolation: worktree starts. Copies activeContext.md into
 * the worktree so the implementer starts with full phase awareness.
 * See: https://code.claude.com/docs/en/hooks#worktreecreate
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

  if (!worktreePath) {
    process.exit(0);
  }

  // Seed the worktree with current active context
  const srcContext = path.join(projectDir, 'artifacts', 'memory', 'activeContext.md');
  if (fs.existsSync(srcContext)) {
    const destMemoryDir = path.join(worktreePath, 'artifacts', 'memory');
    if (!fs.existsSync(destMemoryDir)) {
      fs.mkdirSync(destMemoryDir, { recursive: true });
    }
    fs.copyFileSync(srcContext, path.join(destMemoryDir, 'activeContext.md'));
  }

  // Log the worktree creation
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (fs.existsSync(sessionsDir)) {
    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    const entry = {
      event: 'worktree_create',
      timestamp: new Date().toISOString(),
      sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
      worktreePath,
      contextSeeded: fs.existsSync(srcContext)
    };
    fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
  }
} catch (err) {
  process.stderr.write(`[worktree-create] Warning: ${err.message}\n`);
}

process.exit(0);
