#!/usr/bin/env node
/**
 * Process-level tests for worktree-create.js and worktree-remove.js hooks.
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
    CLAUDE_SESSION_ID: 'test-session-worktree',
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

describe('worktree-create: seeds worktree with context', () => {
  let tmpDir;
  let worktreeDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
    worktreeDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
    cleanTempDir(worktreeDir);
  });

  it('copies activeContext.md to worktree', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), '## Phase\nImplementation\n');

    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    fs.mkdirSync(sessionsDir, { recursive: true });

    const input = JSON.stringify({ worktree_path: worktreeDir });
    runHook('worktree-create.js', { cwd: tmpDir, input });

    const destFile = path.join(worktreeDir, 'artifacts', 'memory', 'activeContext.md');
    assert.ok(fs.existsSync(destFile), 'Should copy context to worktree');
    const content = fs.readFileSync(destFile, 'utf8');
    assert.ok(content.includes('Implementation'), 'Should preserve content');
  });

  it('logs worktree creation event', () => {
    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    fs.mkdirSync(sessionsDir, { recursive: true });

    const input = JSON.stringify({ worktree_path: worktreeDir });
    runHook('worktree-create.js', { cwd: tmpDir, input });

    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create delegation log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'worktree_create');
    assert.equal(entry.worktreePath, worktreeDir);
  });

  it('skips when no worktree_path provided', () => {
    const input = JSON.stringify({});
    const result = runHook('worktree-create.js', { cwd: tmpDir, input });
    assert.equal(result.exitCode, 0);
  });

  it('exits 0 always', () => {
    const result = runHook('worktree-create.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('worktree-remove: logs worktree teardown', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('logs worktree removal event', () => {
    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    fs.mkdirSync(sessionsDir, { recursive: true });

    const input = JSON.stringify({ worktree_path: '/tmp/worktree-abc' });
    runHook('worktree-remove.js', { cwd: tmpDir, input });

    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create delegation log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'worktree_remove');
    assert.equal(entry.worktreePath, '/tmp/worktree-abc');
  });

  it('handles missing worktree_path', () => {
    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    fs.mkdirSync(sessionsDir, { recursive: true });

    const input = JSON.stringify({});
    runHook('worktree-remove.js', { cwd: tmpDir, input });

    const logFile = path.join(sessionsDir, 'delegation-log.jsonl');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.worktreePath, 'unknown');
  });

  it('exits 0 always', () => {
    const result = runHook('worktree-remove.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});
