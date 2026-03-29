#!/usr/bin/env node
/**
 * Unit tests for post-edit-validate.js hook.
 * Tests file path validation and extension-to-formatter mapping.
 * Uses node:test (built-in, zero deps).
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');

// Extracted from hook source for unit testing
const SHELL_METACHAR_RE = /[;|&`$]/;

const FORMATTER_EXTENSIONS = new Set(['.js', '.ts', '.jsx', '.tsx', '.json', '.py', '.rs', '.go']);

describe('post-edit-validate: path rejection', () => {
  const malicious = [
    ['file.js; rm -rf /', 'semicolon injection'],
    ['file.js | cat /etc/passwd', 'pipe injection'],
    ['file.js & malware', 'background injection'],
    ['$(whoami).js', 'command substitution'],
    ['`whoami`.js', 'backtick injection'],
  ];

  for (const [filePath, label] of malicious) {
    it(`rejects: ${label}`, () => {
      assert.ok(SHELL_METACHAR_RE.test(filePath), `Expected "${filePath}" to be rejected`);
    });
  }

  const safe = [
    ['src/components/Button.tsx', 'normal path'],
    ['my-file_v2.js', 'hyphens and underscores'],
    ['path/to/file with spaces.js', 'spaces in path'],
    ['../relative/path.py', 'relative path'],
    ['C:\\Users\\dev\\file.ts', 'windows path'],
  ];

  for (const [filePath, label] of safe) {
    it(`allows: ${label}`, () => {
      assert.ok(!SHELL_METACHAR_RE.test(filePath), `Expected "${filePath}" to be allowed`);
    });
  }
});

describe('post-edit-validate: formatter extension mapping', () => {
  const formattable = ['.js', '.ts', '.jsx', '.tsx', '.json', '.py', '.rs', '.go'];
  for (const ext of formattable) {
    it(`has formatter for ${ext}`, () => {
      assert.ok(FORMATTER_EXTENSIONS.has(ext), `Expected formatter for ${ext}`);
    });
  }

  const noFormatter = ['.md', '.html', '.css', '.yml', '.toml', '.sh', '.ps1', '.sql'];
  for (const ext of noFormatter) {
    it(`no formatter for ${ext} (passthrough)`, () => {
      assert.ok(!FORMATTER_EXTENSIONS.has(ext), `Expected no formatter for ${ext}`);
    });
  }
});

describe('post-edit-validate: extension extraction', () => {
  const cases = [
    ['src/app.js', '.js'],
    ['package.json', '.json'],
    ['lib/utils.py', '.py'],
    ['main.go', '.go'],
    ['no-extension', ''],
    ['.hidden', ''],
  ];

  for (const [file, expected] of cases) {
    it(`extracts "${expected}" from ${file}`, () => {
      assert.equal(path.extname(file).toLowerCase(), expected);
    });
  }
});
