#!/usr/bin/env node
/**
 * PreToolUse (Bash) hook — blocks destructive shell commands.
 * Exit code 2 = block the command. Stderr message is fed back to Claude.
 * See: https://code.claude.com/docs/en/hooks#pretooluse-input
 */
const fs = require('fs');

const BLOCKED_PATTERNS = [
  // Filesystem destruction — compact flags
  /rm\s+(-rf|-fr)\s+[\/~]/i,           // rm -rf / or ~
  /rm\s+(-rf|-fr)\s+\.\s*$/i,          // rm -rf . (end of command)
  /rm\s+(-rf|-fr)\s+\.\s/i,            // rm -rf . (followed by more)
  // Filesystem destruction — split flags and long flags
  /rm\s+(-[a-z]*r[a-z]*\s+-[a-z]*f[a-z]*|-[a-z]*f[a-z]*\s+-[a-z]*r[a-z]*)\s+[\/~]/i,  // rm -r -f / or rm -f -r /
  /rm\s+(--recursive\s+--force|--force\s+--recursive)\s/i,  // rm --recursive --force
  /rm\s+(-[a-z]*r[a-z]*\s+--force|--recursive\s+-[a-z]*f[a-z]*)\s/i,  // mixed: rm -r --force, rm --recursive -f

  // SQL destructive
  /DROP\s+(TABLE|DATABASE|SCHEMA)/i,
  /TRUNCATE\s+TABLE/i,
  /DELETE\s+FROM\s+\w+\s*;?\s*$/i,     // DELETE without WHERE

  // Disk/filesystem operations
  /mkfs\./i,                            // Format filesystem
  /dd\s+if=.*of=\/dev\//i,             // dd writing to block device
  />\s*\/dev\/sd/i,                     // Redirect to block device

  // Dangerous permission changes
  /chmod\s+-R\s+777/i,                  // Recursive 777
  /chmod\s+777\s/i,                     // Non-recursive 777 (still risky on key files)
  /chmod\s+777$/i,                      // 777 at end of command

  // Privilege escalation abuse
  /sudo\s+(rm|chmod|dd|mkfs|shred|wipe)/i,  // sudo + destructive tool

  // Remote code execution via pipe
  /curl[^|]*\|\s*(bash|sh|zsh)/i,       // curl | shell
  /wget[^|]*\|\s*(bash|sh|zsh)/i,       // wget | shell

  // Force-push (broadly blocked; deploy-guard handles prod-specific patterns)
  /git\s+push\s+.*--force-all/i,        // force-all pushes everything, catastrophic on shared repos
];

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const command = data.tool_input?.command || '';

    for (const pattern of BLOCKED_PATTERNS) {
      if (pattern.test(command)) {
        process.stderr.write(`Blocked destructive command matching pattern: ${pattern.source}`);
        process.exit(2);
      }
    }
  }
} catch (err) {
  // Blocking hook: if stdin was present but unparseable, fail closed (block)
  process.stderr.write(`[pre-bash-safety] Warning: ${err.message}\n`);
  if (err instanceof SyntaxError) process.exit(2);
}

process.exit(0);
