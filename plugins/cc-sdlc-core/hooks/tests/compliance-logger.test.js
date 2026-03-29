#!/usr/bin/env node
/**
 * Process-level tests for compliance-logger.js hook.
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
    CLAUDE_SESSION_ID: 'test-session-compliance',
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

describe('compliance-logger: logs file edits', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = makeTempDir();
  });

  afterEach(() => {
    cleanTempDir(tmpDir);
  });

  it('creates audit log entry for Edit tool', () => {
    const input = JSON.stringify({
      tool_name: 'Edit',
      tool_input: { file_path: path.join(tmpDir, 'src', 'app.js') }
    });
    runHook('compliance-logger.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'audit-log.jsonl');
    assert.ok(fs.existsSync(logFile), 'Should create audit log');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.tool, 'Edit');
    assert.equal(entry.action, 'edit');
    assert.equal(entry.sessionId, 'test-session-compliance');
  });

  it('creates audit log entry for Write tool', () => {
    const input = JSON.stringify({
      tool_name: 'Write',
      tool_input: { file_path: path.join(tmpDir, 'new-file.js') }
    });
    runHook('compliance-logger.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'audit-log.jsonl');
    const entry = JSON.parse(fs.readFileSync(logFile, 'utf8').trim());
    assert.equal(entry.tool, 'Write');
    assert.equal(entry.action, 'create');
  });

  it('skips logging when no file path', () => {
    const input = JSON.stringify({ tool_name: 'Edit', tool_input: {} });
    runHook('compliance-logger.js', { cwd: tmpDir, input });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'audit-log.jsonl');
    assert.ok(!fs.existsSync(logFile), 'Should not create log for empty path');
  });

  it('appends multiple entries', () => {
    const edit1 = JSON.stringify({
      tool_name: 'Edit',
      tool_input: { file_path: path.join(tmpDir, 'file1.js') }
    });
    const edit2 = JSON.stringify({
      tool_name: 'Write',
      tool_input: { file_path: path.join(tmpDir, 'file2.js') }
    });
    runHook('compliance-logger.js', { cwd: tmpDir, input: edit1 });
    runHook('compliance-logger.js', { cwd: tmpDir, input: edit2 });

    const logFile = path.join(tmpDir, 'artifacts', 'sessions', 'audit-log.jsonl');
    const lines = fs.readFileSync(logFile, 'utf8').trim().split('\n');
    assert.equal(lines.length, 2, 'Should have 2 log entries');
  });

  it('exits 0 always (non-blocking)', () => {
    const result = runHook('compliance-logger.js', { cwd: tmpDir });
    assert.equal(result.exitCode, 0);
  });
});
