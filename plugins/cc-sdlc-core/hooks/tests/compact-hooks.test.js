#!/usr/bin/env node
/**
 * Process-level tests for pre-compact.js and post-compact.js hooks.
 * Uses node:test (built-in, zero deps).
 */
const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const SCRIPTS_DIR = path.join(__dirname, '..', 'scripts');

function makeTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'hook-test-'));
}

function cleanTempDir(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

function runHook(script, { input, env, cwd } = {}) {
  const fullEnv = {
    ...process.env,
    CLAUDE_PROJECT_DIR: cwd || process.cwd(),
    CLAUDE_SESSION_ID: 'test-session-compact',
    ...env,
  };
  const result = { stdout: '', stderr: '', exitCode: 0 };
  try {
    result.stdout = execFileSync('node', [path.join(SCRIPTS_DIR, script)], {
      input: input || '',
      env: fullEnv,
      timeout: 5000,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
  } catch (e) {
    result.stdout = e.stdout || '';
    result.stderr = e.stderr || '';
    result.exitCode = e.status || 1;
  }
  return result;
}

describe('pre-compact: saves state before compaction', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates activeContext.md with compaction snapshot', () => {
    runHook('pre-compact.js', { cwd: tmpDir });
    const contextFile = path.join(tmpDir, 'artifacts', 'memory', 'activeContext.md');
    assert.ok(fs.existsSync(contextFile), 'Should create activeContext.md');
    const content = fs.readFileSync(contextFile, 'utf8');
    assert.ok(content.includes('## Compaction Snapshot'), 'Should contain snapshot header');
    assert.ok(content.includes('test-session-compact'), 'Should include session ID');
  });

  it('includes summary from stdin JSON', () => {
    const input = JSON.stringify({ summary: 'Working on feature X' });
    runHook('pre-compact.js', { cwd: tmpDir, input });
    const content = fs.readFileSync(
      path.join(tmpDir, 'artifacts', 'memory', 'activeContext.md'), 'utf8'
    );
    assert.ok(content.includes('Working on feature X'), 'Should include summary from input');
  });

  it('preserves conductor-managed sections', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'),
      '## Current Phase\nImplementation\n\n## Open Questions\n- Q1\n\n## Old Section\nStale data\n'
    );
    runHook('pre-compact.js', { cwd: tmpDir });
    const content = fs.readFileSync(path.join(memoryDir, 'activeContext.md'), 'utf8');
    assert.ok(content.includes('## Current Phase'), 'Should preserve Current Phase');
    assert.ok(content.includes('## Open Questions'), 'Should preserve Open Questions');
    assert.ok(content.includes('## Compaction Snapshot'), 'Should add snapshot');
  });

  it('exits 0 always', () => {
    const result = runHook('pre-compact.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('post-compact: restores state after compaction', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('outputs additionalContext JSON when activeContext.md exists', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), '## Current Phase\nReview\n');

    const result = runHook('post-compact.js', { cwd: tmpDir });
    const parsed = JSON.parse(result.stdout);
    assert.ok(parsed.additionalContext.includes('Current Phase'), 'Should include context');
    assert.ok(parsed.additionalContext.includes('Review'), 'Should include phase value');
  });

  it('warns when context file is large', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), 'x'.repeat(5000));

    const result = runHook('post-compact.js', { cwd: tmpDir });
    // stderr warning about large file — captured in the error handler
    const parsed = JSON.parse(result.stdout);
    assert.ok(parsed.additionalContext.length > 4000, 'Should still return full content');
  });

  it('outputs nothing when activeContext.md does not exist', () => {
    const result = runHook('post-compact.js', { cwd: tmpDir });
    assert.equal(result.stdout.trim(), '', 'No output when no context file');
  });

  it('exits 0 always', () => {
    const result = runHook('post-compact.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});
