#!/usr/bin/env node
/**
 * PreCompact hook — saves critical state before context compaction.
 * Writes current session summary to artifacts/memory/activeContext.md
 * so post-compact can restore meaningful context.
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

  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  const timestamp = new Date().toISOString();
  const sessionId = process.env.CLAUDE_SESSION_ID || 'unknown';

  // Parse CC PreCompact input — may include { summary, session_id }
  let summary = '';
  if (input) {
    try {
      const data = JSON.parse(input);
      summary = data.summary || '';
    } catch {
      // Input wasn't JSON — that's fine
    }
  }

  // Read existing context to preserve conductor-managed sections
  const existing = fs.existsSync(contextFile) ? fs.readFileSync(contextFile, 'utf8') : '';

  // Preserve sections that match the conductor's activeContext schema
  const preservedSections = [];
  const PRESERVE_HEADINGS = [
    'Current Phase', 'Current Task', 'Phase', 'Plan Progress',
    'Last 3 Decisions', 'Last Decision', 'Open Questions',
    'Active Files', 'Model Tiers Active', 'Next Action', 'Blockers',
  ];
  const headingPattern = PRESERVE_HEADINGS.map(h => h.replace(/\s+/g, '\\s+')).join('|');
  const sectionRe = new RegExp(`^## (${headingPattern})[\\s\\S]*?(?=^## |$)`, 'gm');
  let match;
  while ((match = sectionRe.exec(existing)) !== null) {
    preservedSections.push(match[0].trimEnd());
  }

  // Build the snapshot block
  const snapshotLines = [
    `## Compaction Snapshot`,
    `- Timestamp: ${timestamp}`,
    `- Session: ${sessionId}`,
  ];
  if (summary) {
    snapshotLines.push(`\n### Summary\n${summary}`);
  }

  const snapshot = snapshotLines.join('\n');

  // Assemble: preserved lifecycle sections first, then snapshot
  const parts = [];
  if (preservedSections.length > 0) {
    parts.push(...preservedSections);
  }
  parts.push(snapshot);

  fs.writeFileSync(contextFile, parts.join('\n\n') + '\n');
} catch (err) {
  process.stderr.write(`[pre-compact] Warning: ${err.message}\n`);
}

process.exit(0);
