#!/usr/bin/env node
/**
 * Process-level tests for subagent-start-log.js and subagent-stop-gate.js hooks.
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
    CLAUDE_SESSION_ID: 'test-session-subagent',
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

describe('subagent-start-log: logs delegation launches', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates delegation log entry', () => {
    const input = JSON.stringify({ agent_name: 'implementer' });
    runHook('subagent-start-log.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'delegation-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create delegation log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'subagent_start');
    assert.equal(entry.agent, 'implementer');
    assert.equal(entry.sessionId, 'test-session-subagent');
  });

  it('handles missing agent_name', () => {
    const input = JSON.stringify({});
    runHook('subagent-start-log.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'delegation-log.jsonl');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.agent, 'unknown');
  });

  it('exits 0 always', () => {
    const result = runHook('subagent-start-log.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});

describe('subagent-stop-gate: logs delegation completion', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates stop entry with agent name and reason', () => {
    const input = JSON.stringify({ agent_name: 'reviewer', stop_reason: 'completed' });
    runHook('subagent-stop-gate.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'delegation-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create delegation log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.event, 'subagent_stop');
    assert.equal(entry.agent, 'reviewer');
    assert.equal(entry.stopReason, 'completed');
  });

  it('defaults stop_reason to completed', () => {
    const input = JSON.stringify({ agent_name: 'planner' });
    runHook('subagent-stop-gate.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'delegation-log.jsonl');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.stopReason, 'completed');
  });

  it('exits 0 always', () => {
    const result = runHook('subagent-stop-gate.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});
