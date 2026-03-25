#!/usr/bin/env node
/**
 * Stop hook — generates session summary and saves state.
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

  // Update the timestamp in activeContext.md
  if (fs.existsSync(contextFile)) {
    let content = fs.readFileSync(contextFile, 'utf8');
    const timestampRegex = /## Updated\n.*/;
    const newTimestamp = `## Updated\n${new Date().toISOString()}`;

    if (timestampRegex.test(content)) {
      content = content.replace(timestampRegex, newTimestamp);
    } else {
      content += `\n${newTimestamp}\n`;
    }

    fs.writeFileSync(contextFile, content);
  }
} catch (err) {
  process.stderr.write(`[stop-summary] Warning: ${err.message}\n`);
}

process.exit(0);
