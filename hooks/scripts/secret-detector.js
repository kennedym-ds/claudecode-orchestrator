#!/usr/bin/env node
/**
 * UserPromptSubmit hook — detects secrets in user input.
 * Exit code 2 = block the prompt. Exit code 0 = allow.
 */
const fs = require('fs');

const SECRET_PATTERNS = [
  /(?:api[_-]?key|apikey)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{20,}/i,
  /(?:secret|token|password|passwd|pwd)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{8,}/i,
  /(?:aws_access_key_id|aws_secret_access_key)\s*[:=]\s*['"]?[A-Z0-9]{16,}/i,
  /AKIA[0-9A-Z]{16}/,                                          // AWS access key
  /ghp_[A-Za-z0-9]{36}/,                                       // GitHub personal access token
  /gho_[A-Za-z0-9]{36}/,                                       // GitHub OAuth token
  /github_pat_[A-Za-z0-9_]{22,}/,                              // GitHub fine-grained PAT
  /sk-[A-Za-z0-9]{32,}/,                                       // OpenAI / Anthropic key pattern
  /-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----/,             // Private keys
  /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/, // JWT
];

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    // CC hook input uses snake_case field names
    const userPrompt = data.prompt || data.content || '';

    for (const pattern of SECRET_PATTERNS) {
      if (pattern.test(userPrompt)) {
        // Exit 2 blocks the prompt submission; stderr is shown to user
        process.stderr.write('Potential secret detected in prompt. Remove credentials before submitting.');
        process.exit(2);
      }
    }
  }
} catch (err) {
  process.stderr.write(`[secret-detector] Warning: ${err.message}\n`);
}

process.exit(0);
