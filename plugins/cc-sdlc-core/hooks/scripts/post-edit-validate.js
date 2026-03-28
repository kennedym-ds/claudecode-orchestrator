#!/usr/bin/env node
/**
 * PostToolUse (Edit/Write) hook — runs lint/format after file edits.
 * Non-blocking — warns on lint issues but doesn't block the edit.
 */
const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    // CC hook input uses snake_case: tool_input.file_path
    const filePath = data.tool_input?.file_path || '';

    if (!filePath) {
      process.exit(0);
    }

    // Validate filePath: must be a real path, reject shell metacharacters
    if (/[;|&`$(){}]/.test(filePath)) {
      process.stderr.write(`[post-edit-validate] Rejected suspicious file path\n`);
      process.exit(0);
    }

    const ext = path.extname(filePath).toLowerCase();

    // Auto-format based on file extension
    // Each entry: [command, ...args] — filePath appended as last arg
    const formatters = {
      '.js': ['npx', 'prettier', '--write'],
      '.ts': ['npx', 'prettier', '--write'],
      '.jsx': ['npx', 'prettier', '--write'],
      '.tsx': ['npx', 'prettier', '--write'],
      '.json': ['npx', 'prettier', '--write'],
      '.py': ['python', '-m', 'black'],
      '.rs': ['rustfmt'],
      '.go': ['gofmt', '-w'],
    };

    const formatter = formatters[ext];
    if (formatter) {
      try {
        execFileSync(formatter[0], [...formatter.slice(1), filePath], {
          timeout: 10000,
          stdio: 'pipe'
        });
      } catch {
        // Formatter not installed or failed — non-blocking
      }
    }
  }
} catch (err) {
  process.stderr.write(`[post-edit-validate] Warning: ${err.message}\n`);
}

process.exit(0);
