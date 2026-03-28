#!/usr/bin/env node
/**
 * PostToolUse (Edit|Write) hook — scans new/modified files for dependency security issues.
 * Non-blocking (async). Checks package manifests for known vulnerable patterns.
 */
const fs = require('fs');
const path = require('path');

const MANIFEST_FILES = new Set([
  'package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml',
  'requirements.txt', 'Pipfile.lock', 'poetry.lock',
  'Gemfile.lock', 'go.sum', 'Cargo.lock',
  'composer.lock', 'pom.xml', 'build.gradle',
]);

const KNOWN_VULNERABLE = [
  // Packages with critical RCE or supply-chain issues (examples)
  { pattern: /"event-stream"/, message: 'event-stream: known supply-chain compromise' },
  { pattern: /"ua-parser-js"\s*:\s*"0\.7\.29"/, message: 'ua-parser-js@0.7.29: malware injection' },
  { pattern: /"colors"\s*:\s*"1\.4\.1"/, message: 'colors@1.4.1: protestware — infinite loop' },
  { pattern: /"node-ipc"\s*:\s*"[1-9][0-9]\.[0-9]+"/, message: 'node-ipc@10+: protestware — data destruction' },
  { pattern: /"lodash"\s*:\s*"[0-3]\.\d+/, message: 'lodash < 4.x: prototype pollution CVEs' },
];

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (input) {
    const data = JSON.parse(input);
    const filePath = data.tool_input?.file_path || '';
    const fileName = path.basename(filePath);

    if (!MANIFEST_FILES.has(fileName)) {
      process.exit(0);
    }

    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      const findings = [];

      for (const { pattern, message } of KNOWN_VULNERABLE) {
        if (pattern.test(content)) {
          findings.push(message);
        }
      }

      if (findings.length > 0) {
        process.stderr.write(
          `[dependency-scanner] WARNING: Potential vulnerable dependencies detected:\n` +
          findings.map(f => `  - ${f}`).join('\n') + '\n' +
          'Run `npm audit` / `pip-audit` / language-specific audit tool for full scan.\n'
        );
      }
    }
  }
} catch (err) {
  process.stderr.write(`[dependency-scanner] Warning: ${err.message}\n`);
}

process.exit(0);
