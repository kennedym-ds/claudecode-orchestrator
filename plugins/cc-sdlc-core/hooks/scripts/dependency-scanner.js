#!/usr/bin/env node
/**
 * PostToolUse (Edit|Write) hook — scans modified dependency manifests for security issues.
 * Two-pass approach:
 *   1. Fast static check against known supply-chain compromises (immediate, always runs)
 *   2. Real audit tool invocation for comprehensive CVE detection (npm audit / pip-audit)
 * Non-blocking (async in settings). Findings go to stderr for Claude to see.
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const MANIFEST_FILES = new Set([
  'package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml',
  'requirements.txt', 'Pipfile.lock', 'poetry.lock',
  'Gemfile.lock', 'go.sum', 'Cargo.lock',
  'composer.lock', 'pom.xml', 'build.gradle',
]);

const NODE_MANIFESTS = new Set(['package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml']);
const PYTHON_MANIFESTS = new Set(['requirements.txt', 'Pipfile.lock', 'poetry.lock']);

// Known supply-chain compromises — static, instant, no network
const KNOWN_VULNERABLE = [
  { pattern: /"event-stream"/, message: 'event-stream: known supply-chain compromise (malicious code injection)' },
  { pattern: /"ua-parser-js"\s*:\s*"0\.7\.29"/, message: 'ua-parser-js@0.7.29: malware injection' },
  { pattern: /"colors"\s*:\s*"1\.4\.1"/, message: 'colors@1.4.1: protestware — infinite loop' },
  { pattern: /"node-ipc"\s*:\s*"[1-9]\d+\./, message: 'node-ipc@10+: protestware — data destruction' },
  { pattern: /"lodash"\s*:\s*"[0-3]\.\d+/, message: 'lodash < 4.x: prototype pollution CVEs (CVE-2019-10744 etc.)' },
  { pattern: /"flatmap-stream"/, message: 'flatmap-stream: malicious package (event-stream supply chain)' },
  { pattern: /"crossenv"/, message: 'crossenv: typosquat of cross-env — data exfiltration' },
  { pattern: /"is-promise"\s*:\s*"[24]\.[0-1]\.[0-9]"/, message: 'is-promise@2.x/4.x: known breaking release' },
  { pattern: /\beval\s*\(/, message: 'eval() usage detected in manifest — potential code injection risk' },
];

function runAudit(manifestDir, manifestType) {
  const AUDIT_TIMEOUT_MS = 20000;

  if (manifestType === 'node') {
    try {
      // npm audit exits non-zero if vulnerabilities found; stdout has the JSON report
      execFileSync('npm', ['audit', '--json'], {
        cwd: manifestDir,
        timeout: AUDIT_TIMEOUT_MS,
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      });
      // exit 0 = no vulnerabilities
    } catch (e) {
      // exit non-zero = vulnerabilities found OR npm not available
      if (e.stdout) {
        try {
          const report = JSON.parse(e.stdout);
          const vulns = report.vulnerabilities || report.advisories || {};
          const count = Object.keys(vulns).length;
          const high = Object.values(vulns).filter(v => v.severity === 'high' || v.severity === 'critical').length;
          if (count > 0) {
            process.stderr.write(
              `[dependency-scanner] npm audit: ${count} vulnerabilit${count === 1 ? 'y' : 'ies'} found` +
              (high > 0 ? `, ${high} high/critical` : '') +
              `. Run \`npm audit\` for details.\n`
            );
          }
        } catch {
          // JSON parse failed — npm audit may not be available
        }
      }
    }
  } else if (manifestType === 'python') {
    try {
      const output = execFileSync('pip-audit', ['--format', 'json'], {
        cwd: manifestDir,
        timeout: AUDIT_TIMEOUT_MS,
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      });
      const report = JSON.parse(output);
      if (Array.isArray(report) && report.length > 0) {
        process.stderr.write(
          `[dependency-scanner] pip-audit: ${report.length} vulnerabilit${report.length === 1 ? 'y' : 'ies'} found. Run \`pip-audit\` for details.\n`
        );
      }
    } catch (e) {
      // pip-audit exits non-zero when vulnerabilities are found (like npm audit)
      if (e.stdout) {
        try {
          const report = JSON.parse(e.stdout);
          if (Array.isArray(report) && report.length > 0) {
            const fixable = report.filter(v => v.fix_versions && v.fix_versions.length > 0).length;
            process.stderr.write(
              `[dependency-scanner] pip-audit: ${report.length} vulnerabilit${report.length === 1 ? 'y' : 'ies'} found` +
              (fixable > 0 ? `, ${fixable} fixable` : '') +
              `. Run \`pip-audit\` for details.\n`
            );
          }
        } catch {
          // JSON parse failed — pip-audit may not be available or output format changed
        }
      }
      // If no stdout at all, pip-audit is likely not installed — skip silently
    }
  }
}

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (!input) process.exit(0);

  const data = JSON.parse(input);
  const filePath = data.tool_input?.file_path || '';
  const fileName = path.basename(filePath);

  if (!MANIFEST_FILES.has(fileName)) {
    process.exit(0);
  }

  // Pass 1: static known-bad patterns (instant)
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, 'utf8');
    const findings = KNOWN_VULNERABLE.filter(({ pattern }) => pattern.test(content));

    if (findings.length > 0) {
      process.stderr.write(
        `[dependency-scanner] STATIC CHECK — known vulnerable patterns detected:\n` +
        findings.map(f => `  - ${f.message}`).join('\n') + '\n'
      );
    }
  }

  // Pass 2: real audit tool (takes a few seconds, async-safe since hook is marked async)
  const manifestDir = path.dirname(filePath);
  if (NODE_MANIFESTS.has(fileName)) {
    runAudit(manifestDir, 'node');
  } else if (PYTHON_MANIFESTS.has(fileName)) {
    runAudit(manifestDir, 'python');
  }
} catch (err) {
  process.stderr.write(`[dependency-scanner] Warning: ${err.message}\n`);
}

process.exit(0);
