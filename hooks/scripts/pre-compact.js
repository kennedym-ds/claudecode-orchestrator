#!/usr/bin/env node
/**
 * PreCompact hook — saves critical state before context compaction.
 * Writes current state to artifacts/memory/activeContext.md.
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const memoryDir = path.join(projectDir, 'artifacts', 'memory');
const contextFile = path.join(memoryDir, 'activeContext.md');

try {
  if (!fs.existsSync(memoryDir)) {
    fs.mkdirSync(memoryDir, { recursive: true });
  }

  // Read stdin for current session state (if provided by Claude)
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    try {
      const data = JSON.parse(input);
      // Append compaction marker
      const marker = `\n## Pre-Compaction Snapshot\nTimestamp: ${new Date().toISOString()}\n`;
      const existing = fs.existsSync(contextFile) ? fs.readFileSync(contextFile, 'utf8') : '';
      fs.writeFileSync(contextFile, existing + marker);
    } catch {
      // Input wasn't JSON — that's fine
    }
  }
} catch (err) {
  process.stderr.write(`[pre-compact] Warning: ${err.message}\n`);
}

process.exit(0);
