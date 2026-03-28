#!/usr/bin/env node
/**
 * PreToolUse (Bash) hook — guards against accidental production deployments.
 * Exit code 2 = block the command. Blocks deploy/push commands unless
 * DEPLOY_APPROVED=true is set in environment.
 */
const fs = require('fs');

const DEPLOY_PATTERNS = [
  /kubectl\s+apply.*--context\s+prod/i,
  /kubectl\s+apply.*production/i,
  /helm\s+(install|upgrade).*prod/i,
  /terraform\s+apply\s+(?!.*--target)/i,  // terraform apply without --target
  /aws\s+.*deploy/i,
  /az\s+.*deployment\s+create/i,
  /gcloud\s+.*deploy/i,
  /git\s+push.*--force.*main/i,
  /git\s+push.*--force.*master/i,
  /git\s+push.*--force.*release/i,
  /docker\s+push.*prod/i,
];

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const command = data.tool_input?.command || '';

    if (process.env.DEPLOY_APPROVED === 'true') {
      process.exit(0);
    }

    for (const pattern of DEPLOY_PATTERNS) {
      if (pattern.test(command)) {
        process.stderr.write(
          `[deploy-guard] BLOCKED: Command matches production deployment pattern: ${pattern.source}\n` +
          'Set DEPLOY_APPROVED=true in environment to allow, or use /deploy-check first.'
        );
        process.exit(2);
      }
    }
  }
} catch (err) {
  process.stderr.write(`[deploy-guard] Warning: ${err.message}\n`);
}

process.exit(0);
