#!/usr/bin/env node
/**
 * PreToolUse (Bash) hook — blocks destructive shell commands.
 * Exit code 2 = block the command. Stderr message is fed back to Claude.
 * See: https://code.claude.com/docs/en/hooks#pretooluse-input
 */
const fs = require('fs');

const BLOCKED_PATTERNS = [
  /rm\s+(-rf|-fr)\s+[\/~]/i,           // rm -rf / or ~
  /rm\s+(-rf|-fr)\s+\.\s/i,            // rm -rf .
  /DROP\s+(TABLE|DATABASE|SCHEMA)/i,    // SQL destructive
  /TRUNCATE\s+TABLE/i,
  /DELETE\s+FROM\s+\w+\s*;?\s*$/i,     // DELETE without WHERE
  /mkfs\./i,                            // Format filesystem
  /dd\s+if=/i,                          // Direct disk write
  />\s*\/dev\/sd/i,                     // Write to block device
  /chmod\s+-R\s+777/i,                  // Dangerous permissions
  /curl.*\|\s*(bash|sh)/i,             // Pipe curl to shell
  /wget.*\|\s*(bash|sh)/i,
];

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    // CC hook input uses snake_case: tool_input.command
    const command = data.tool_input?.command || '';

    for (const pattern of BLOCKED_PATTERNS) {
      if (pattern.test(command)) {
        // Exit 2 blocks the tool use; stderr is shown to Claude as feedback
        process.stderr.write(`Blocked destructive command matching pattern: ${pattern.source}`);
        process.exit(2);
      }
    }
  }
} catch (err) {
  // Parse errors are non-blocking — let the command through
  process.stderr.write(`[pre-bash-safety] Warning: ${err.message}\n`);
}

process.exit(0);
