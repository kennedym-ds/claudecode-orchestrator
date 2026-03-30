#!/usr/bin/env node
/**
 * PreToolUse (Edit|Write) hook — blocks file edits outside the frozen path.
 * Only active when ORCH_FREEZE_PATH is set (non-empty).
 * Exit code 2 = block the edit. Exit 0 = allow.
 */
const fs = require('fs');
const path = require('path');

try {
  const freezePath = process.env.ORCH_FREEZE_PATH || '';

  // No freeze active — allow everything
  if (!freezePath) {
    process.exit(0);
  }

  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (!input) {
    process.exit(0);
  }

  const data = JSON.parse(input);
  const filePath = data.tool_input?.file_path || '';

  if (!filePath) {
    process.exit(0);
  }

  // Resolve both paths to absolute for reliable comparison
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const resolvedFreeze = path.resolve(projectDir, freezePath);
  const resolvedFile = path.resolve(projectDir, filePath);

  // Normalize to forward slashes for cross-platform comparison
  const normalizedFreeze = resolvedFreeze.replace(/\\/g, '/').toLowerCase();
  const normalizedFile = resolvedFile.replace(/\\/g, '/').toLowerCase();

  // Check if the file is within the frozen directory
  if (normalizedFile.startsWith(normalizedFreeze + '/') || normalizedFile === normalizedFreeze) {
    process.exit(0);
  }

  // File is outside the frozen path — block
  process.stderr.write(
    `[freeze-guard] BLOCKED: Edit to "${filePath}" is outside the frozen path "${freezePath}".\n` +
    'Use /unfreeze to remove the restriction, or edit a file within the frozen directory.\n'
  );
  process.exit(2);
} catch (err) {
  // If we can't parse input, allow (fail open) — the freeze is advisory safety, not security
  process.stderr.write(`[freeze-guard] Warning: ${err.message}\n`);
  process.exit(0);
}
