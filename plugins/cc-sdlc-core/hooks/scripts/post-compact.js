#!/usr/bin/env node
/**
 * PostCompact hook — restores state after context compaction.
 * Reads artifacts/memory/activeContext.md and injects as additional context.
 */
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const contextFile = path.join(projectDir, 'artifacts', 'memory', 'activeContext.md');

try {
  if (fs.existsSync(contextFile)) {
    const content = fs.readFileSync(contextFile, 'utf8');
    const result = {
      additionalContext: `State restored after compaction from activeContext.md:\n${content.slice(0, 2000)}`
    };
    process.stdout.write(JSON.stringify(result));
  }
} catch (err) {
  process.stderr.write(`[post-compact] Warning: ${err.message}\n`);
}

process.exit(0);
