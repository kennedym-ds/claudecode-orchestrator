#!/usr/bin/env node
/**
 * Process-level tests for stop-failure.js and pr-gate.js hooks.
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
    CLAUDE_SESSION_ID: 'test-session-stop',
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

describe('stop-failure: logs session failures', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates failure log entry', () => {
    const input = JSON.stringify({ error: 'API rate limit', stop_reason: 'error' });
    runHook('stop-failure.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'failure-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create failure log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'stop_failure');
    assert.equal(entry.error, 'API rate limit');
    assert.equal(entry.reason, 'error');
    assert.equal(entry.sessionId, 'test-session-stop');
  });

  it('creates markdown failure report', () => {
    const input = JSON.stringify({ error: 'token budget exceeded', stop_reason: 'budget' });
    runHook('stop-failure.js', { cwd: tmpDir, input });

    const sessionsDir = path.join(tmpDir, 'artifacts', 'sessions');
    const reports = fs.readdirSync(sessionsDir).filter(f => f.endsWith('-failure.md'));
    assert.ok(reports.length > 0, 'Should create failure report');
    const content = fs.readFileSync(path.join(sessionsDir, reports[0]), 'utf8');
    assert.ok(content.includes('token budget exceeded'), 'Report should contain error');
    assert.ok(content.includes('test-session-stop'), 'Report should contain session ID');
  });

  it('handles empty input', () => {
    runHook('stop-failure.js', { cwd: tmpDir });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'failure-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should still create log with defaults');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.error, 'unknown error');
    assert.equal(entry.reason, 'unknown');
  });

  it('exits 0 always', () => {
    const result = runHook('stop-failure.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('pr-gate: generates readiness summary', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
    // pr-gate requires a git repo with changes and an artifacts/reviews dir
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('exits 0 when not in a git repo', () => {
    const result = runHook('pr-gate.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });

  it('exits 0 when no reviews dir exists', () => {
    // Init a git repo with a commit and unstaged change
    try {
      execFileSync('git', ['init'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['config', 'user.email', 'test@test.com'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['config', 'user.name', 'Test'], { cwd: tmpDir, stdio: 'pipe' });
      fs.writeFileSync(path.join(tmpDir, 'file.txt'), 'initial');
      execFileSync('git', ['add', '.'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['commit', '-m', 'init'], { cwd: tmpDir, stdio: 'pipe' });
      fs.writeFileSync(path.join(tmpDir, 'file.txt'), 'changed');
    } catch {
      // Skip if git not available
      return;
    }

    const result = runHook('pr-gate.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });

  it('creates PR gate summary when reviews dir exists and changes present', () => {
    try {
      execFileSync('git', ['init'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['config', 'user.email', 'test@test.com'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['config', 'user.name', 'Test'], { cwd: tmpDir, stdio: 'pipe' });
      fs.writeFileSync(path.join(tmpDir, 'file.txt'), 'initial');
      execFileSync('git', ['add', '.'], { cwd: tmpDir, stdio: 'pipe' });
      execFileSync('git', ['commit', '-m', 'init'], { cwd: tmpDir, stdio: 'pipe' });
      fs.writeFileSync(path.join(tmpDir, 'file.txt'), 'changed');
    } catch {
      return; // Skip if git not available
    }

    const reviewsDir = path.join(tmpDir, 'artifacts', 'reviews');
    fs.mkdirSync(reviewsDir, { recursive: true });

    const result = runHook('pr-gate.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);

    const files = fs.readdirSync(reviewsDir).filter(f => f.startsWith('pr-gate-'));
    assert.ok(files.length > 0, 'Should create PR gate summary');
    const content = fs.readFileSync(path.join(reviewsDir, files[0]), 'utf8');
    assert.ok(content.includes('Changed Files'), 'Should list changed files');
    assert.ok(content.includes('file.txt'), 'Should include the changed file');
    assert.ok(content.includes('Readiness Checklist'), 'Should include checklist');
  });
});
