#!/usr/bin/env node
/**
 * PostCompact hook — restores state after context compaction.
 * Reads artifacts/memory/activeContext.md and injects as additional context.
 * Warns on stderr if the state file is large (> 4000 chars) but always returns full content.
 */
const fs = require('fs');
const path = require('path');

const WARN_THRESHOLD = 4000;

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const contextFile = path.join(projectDir, 'artifacts', 'memory', 'activeContext.md');

try {
  if (fs.existsSync(contextFile)) {
    const content = fs.readFileSync(contextFile, 'utf8');

    if (content.length > WARN_THRESHOLD) {
      process.stderr.write(
        `[post-compact] Note: activeContext.md is ${content.length} chars — ` +
        `consider pruning old compaction snapshots to keep context lean.\n`
      );
    }

    const result = {
      additionalContext: `State restored after compaction from activeContext.md:\n${content}`
    };
    process.stdout.write(JSON.stringify(result));
  }
} catch (err) {
  process.stderr.write(`[post-compact] Warning: ${err.message}\n`);
}

process.exit(0);
