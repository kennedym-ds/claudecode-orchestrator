#!/usr/bin/env node
/**
 * Hook Template: Blocking Hook (PreToolUse / UserPromptSubmit)
 *
 * Exit codes:
 *   0 — Allow the operation to proceed
 *   2 — Block the operation (stderr message shown to Claude)
 *   Other — Warning logged, operation proceeds
 *
 * Usage in hooks.json or .claude/settings.json:
 *   {
 *     "hooks": {
 *       "PreToolUse": [{
 *         "matcher": "Bash",
 *         "hooks": [{
 *           "type": "command",
 *           "command": "node hooks/scripts/my-blocking-hook.js"
 *         }]
 *       }]
 *     }
 *   }
 */
const fs = require('fs');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);

    // --- PreToolUse (Bash) example ---
    const command = data.tool_input?.command || '';

    // Define blocked patterns (regex)
    const blockedPatterns = [
      /\brm\s+-rf\s+\/(?!\btmp\b)/i,          // rm -rf / (except /tmp)
      /\bDROP\s+(TABLE|DATABASE)\b/i,           // SQL destructive ops
      // Add your patterns here:
      // /your-pattern/i,
    ];

    for (const pattern of blockedPatterns) {
      if (pattern.test(command)) {
        process.stderr.write(
          `Blocked: Command matches safety rule. Pattern: ${pattern.source}`
        );
        process.exit(2);
      }
    }

    // --- UserPromptSubmit example ---
    // const prompt = data.prompt || '';
    // if (/secret-pattern/.test(prompt)) {
    //   process.stderr.write('Blocked: Prompt contains restricted content.');
    //   process.exit(2);
    // }
  }
} catch (err) {
  // Non-blocking error — log and continue
  process.stderr.write(`[my-blocking-hook] Warning: ${err.message}\n`);
}

process.exit(0);
