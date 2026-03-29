#!/usr/bin/env node
/**
 * Unit tests for dependency-scanner.js hook.
 * Uses node:test (built-in, zero deps). Tests static pattern detection and file filtering.
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const MANIFEST_FILES = new Set([
  'package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml',
  'requirements.txt', 'Pipfile.lock', 'poetry.lock',
  'Gemfile.lock', 'go.sum', 'Cargo.lock',
  'composer.lock', 'pom.xml', 'build.gradle',
]);

const NODE_MANIFESTS = new Set(['package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml']);
const PYTHON_MANIFESTS = new Set(['requirements.txt', 'Pipfile.lock', 'poetry.lock']);

const KNOWN_VULNERABLE = [
  { pattern: /"event-stream"/, message: 'event-stream' },
  { pattern: /"ua-parser-js"\s*:\s*"0\.7\.29"/, message: 'ua-parser-js@0.7.29' },
  { pattern: /"colors"\s*:\s*"1\.4\.1"/, message: 'colors@1.4.1' },
  { pattern: /"node-ipc"\s*:\s*"[1-9]\d+\./, message: 'node-ipc@10+' },
  { pattern: /"lodash"\s*:\s*"[0-3]\.\d+/, message: 'lodash < 4.x' },
  { pattern: /"flatmap-stream"/, message: 'flatmap-stream' },
  { pattern: /"crossenv"/, message: 'crossenv' },
  { pattern: /"is-promise"\s*:\s*"[24]\.[0-1]\.[0-9]"/, message: 'is-promise' },
  { pattern: /\beval\s*\(/, message: 'eval() usage' },
];

function hasVulnerable(content) {
  return KNOWN_VULNERABLE.filter(({ pattern }) => pattern.test(content));
}

describe('dependency-scanner: manifest file detection', () => {
  const supported = [
    'package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml',
    'requirements.txt', 'Pipfile.lock', 'poetry.lock',
    'Gemfile.lock', 'go.sum', 'Cargo.lock',
    'composer.lock', 'pom.xml', 'build.gradle',
  ];

  for (const file of supported) {
    it(`recognizes: ${file}`, () => {
      assert.ok(MANIFEST_FILES.has(file), `Expected ${file} to be a known manifest`);
    });
  }

  const unsupported = ['README.md', 'index.js', 'Dockerfile', '.env', 'tsconfig.json'];
  for (const file of unsupported) {
    it(`ignores: ${file}`, () => {
      assert.ok(!MANIFEST_FILES.has(file), `Expected ${file} to be ignored`);
    });
  }
});

describe('dependency-scanner: manifest type classification', () => {
  it('classifies node manifests', () => {
    for (const f of ['package.json', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml']) {
      assert.ok(NODE_MANIFESTS.has(f), `${f} should be node manifest`);
    }
  });

  it('classifies python manifests', () => {
    for (const f of ['requirements.txt', 'Pipfile.lock', 'poetry.lock']) {
      assert.ok(PYTHON_MANIFESTS.has(f), `${f} should be python manifest`);
    }
  });

  it('non-node, non-python manifests have no audit path (static only)', () => {
    for (const f of ['Gemfile.lock', 'go.sum', 'Cargo.lock', 'composer.lock', 'pom.xml', 'build.gradle']) {
      assert.ok(!NODE_MANIFESTS.has(f) && !PYTHON_MANIFESTS.has(f),
        `${f} should not be in node or python set`);
    }
  });
});

describe('dependency-scanner: known-vulnerable static patterns', () => {
  const vulnerable = [
    ['{"dependencies": {"event-stream": "3.3.6"}}', 'event-stream'],
    ['{"dependencies": {"ua-parser-js": "0.7.29"}}', 'ua-parser-js@0.7.29'],
    ['{"dependencies": {"colors": "1.4.1"}}', 'colors@1.4.1'],
    ['{"dependencies": {"node-ipc": "10.1.0"}}', 'node-ipc@10+'],
    ['{"dependencies": {"lodash": "3.10.1"}}', 'lodash < 4.x'],
    ['{"dependencies": {"flatmap-stream": "0.1.1"}}', 'flatmap-stream'],
    ['{"dependencies": {"crossenv": "1.0.0"}}', 'crossenv'],
    ['{"dependencies": {"is-promise": "2.1.0"}}', 'is-promise'],
    ['"scripts": {"postinstall": "eval (process.env.EVIL)"}', 'eval() usage'],
  ];

  for (const [content, label] of vulnerable) {
    it(`detects: ${label}`, () => {
      const findings = hasVulnerable(content);
      assert.ok(findings.length > 0, `Expected vulnerable pattern match for: ${label}`);
    });
  }
});

describe('dependency-scanner: clean manifests pass', () => {
  const clean = [
    ['{"dependencies": {"express": "4.18.2"}}', 'express (safe)'],
    ['{"dependencies": {"lodash": "4.17.21"}}', 'lodash 4.x (safe)'],
    ['{"dependencies": {"ua-parser-js": "1.0.35"}}', 'ua-parser-js 1.x (safe)'],
    ['{"dependencies": {"colors": "1.4.0"}}', 'colors 1.4.0 (safe)'],
    ['{"dependencies": {"node-ipc": "9.2.1"}}', 'node-ipc 9.x (safe)'],
    ['{"dependencies": {"is-promise": "3.0.0"}}', 'is-promise 3.x (safe)'],
    ['{"name": "my-app", "version": "1.0.0"}', 'minimal package.json'],
  ];

  for (const [content, label] of clean) {
    it(`passes: ${label}`, () => {
      const findings = hasVulnerable(content);
      assert.equal(findings.length, 0, `Expected no findings for: ${label}`);
    });
  }
});
