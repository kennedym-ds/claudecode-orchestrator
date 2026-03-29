#!/usr/bin/env node
/**
 * Process-level tests for session-start.js, session-end.js, stop-summary.js hooks.
 * Uses node:test (built-in, zero deps). Spawns scripts with env vars and temp dirs.
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
    CLAUDE_SESSION_ID: 'test-session-123',
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

describe('session-start: initializes session', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates session log entry', () => {
    runHook('session-start.js', { cwd: tmpDir });
    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'session-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'session-log.jsonl should be created');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'session_start');
    assert.equal(entry.sessionId, 'test-session-123');
    assert.equal(entry.hasPriorState, false);
  });

  it('writes env vars to CLAUDE_ENV_FILE when provided', () => {
    const envFile = path.join(tmpDir, 'env-vars.txt');
    fs.writeFileSync(envFile, '');
    runHook('session-start.js', { cwd: tmpDir, env: { CLAUDE_ENV_FILE: envFile } });
    const content = fs.readFileSync(envFile, 'utf8');
    assert.ok(content.includes('ORCH_SESSION_ACTIVE=true'), 'Should set ORCH_SESSION_ACTIVE');
  });

  it('detects prior state when activeContext.md exists', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), '## Current Phase\nPlanning');

    const envFile = path.join(tmpDir, 'env-vars.txt');
    fs.writeFileSync(envFile, '');
    runHook('session-start.js', { cwd: tmpDir, env: { CLAUDE_ENV_FILE: envFile } });
    const content = fs.readFileSync(envFile, 'utf8');
    assert.ok(content.includes('ORCH_HAS_PRIOR_STATE=true'), 'Should detect prior state');
  });

  it('exits 0 always (non-blocking)', () => {
    const result = runHook('session-start.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('session-end: archives session', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates session archive file', () => {
    runHook('session-end.js', { cwd: tmpDir });
    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    assert.ok(fs.existsSync(sessionsDir), 'sessions dir should be created');
    const files = fs.readdirSync(sessionsDir).filter(f => f.startsWith('session-'));
    assert.ok(files.length > 0, 'Should create a session archive file');
    const data = JSON.parse(fs.readFileSync(path.join(sessionsDir, files[0]), 'utf8'));
    assert.equal(data.sessionId, 'test-session-123');
    assert.equal(data.status, 'completed');
  });

  it('exits 0 always', () => {
    const result = runHook('session-end.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('stop-summary: updates activeContext timestamp', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('appends timestamp when activeContext.md exists without Updated section', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), '## Current Phase\nPlanning\n');
    runHook('stop-summary.js', { cwd: tmpDir });
    const content = fs.readFileSync(path.join(memoryDir, 'activeContext.md'), 'utf8');
    assert.ok(content.includes('## Updated'), 'Should append Updated section');
  });

  it('replaces existing timestamp', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    fs.writeFileSync(path.join(memoryDir, 'activeContext.md'), '## Updated\n2020-01-01T00:00:00.000Z\n');
    runHook('stop-summary.js', { cwd: tmpDir });
    const content = fs.readFileSync(path.join(memoryDir, 'activeContext.md'), 'utf8');
    assert.ok(!content.includes('2020-01-01'), 'Should replace old timestamp');
  });

  it('does nothing when activeContext.md does not exist', () => {
    const memoryDir = path.join(tmpDir, 'artifacts', 'memory');
    fs.mkdirSync(memoryDir, { recursive: true });
    const result = runHook('stop-summary.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });

  it('exits 0 always', () => {
    const result = runHook('stop-summary.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});
