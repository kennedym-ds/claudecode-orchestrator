#!/usr/bin/env node
/**
 * Unit tests for Agent Teams hook scripts.
 * teammate-idle.js, task-created.js, task-completed.js
 * Uses node:test (built-in, zero deps). Run: node --test plugins/cc-sdlc-core/hooks/tests/
 */
const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const SCRIPTS_DIR = path.join(__dirname, '..', 'scripts');

function runHook(scriptName, input, env = {}) {
  const scriptPath = path.join(SCRIPTS_DIR, scriptName);
  const result = spawnSync('node', [scriptPath], {
    input: input ? JSON.stringify(input) : '',
    env: { ...process.env, ...env },
    encoding: 'utf8'
  });
  return {
    exitCode: result.status !== null ? result.status : 1,
    stdout: result.stdout || '',
    stderr: result.stderr || ''
  };
}

function makeProjectDir(env = {}) {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'cc-teams-test-'));
  fs.mkdirSync(path.join(tmpDir, 'artifacts', 'sessions'), { recursive: true });
  return { tmpDir, env: { CLAUDE_PROJECT_DIR: tmpDir, ...env } };
}

function readJsonl(file) {
  if (!fs.existsSync(file)) return [];
  return fs.readFileSync(file, 'utf8')
    .split('\n')
    .filter(Boolean)
    .map(l => JSON.parse(l));
}

function writeTeamState(tmpDir, state) {
  fs.writeFileSync(
    path.join(tmpDir, 'artifacts', 'sessions', 'team-state.json'),
    JSON.stringify(state, null, 2)
  );
}

function readTeamState(tmpDir) {
  const f = path.join(tmpDir, 'artifacts', 'sessions', 'team-state.json');
  return fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : null;
}

// ─── teammate-idle.js ─────────────────────────────────────────────────────────

describe('teammate-idle: logging and exit', () => {
  it('creates team-log.jsonl with teammate_idle entry', () => {
    const { tmpDir, env } = makeProjectDir();
    runHook('teammate-idle.js', {
      team_name: 'review-team',
      teammate_id: 'reviewer',
      idle_reason: 'task_complete',
      tasks_completed: 1
    }, env);

    const entries = readJsonl(path.join(tmpDir, 'artifacts', 'sessions', 'team-log.jsonl'));
    assert.equal(entries.length, 1);
    assert.equal(entries[0].event, 'teammate_idle');
    assert.equal(entries[0].idleReason, 'task_complete');
    assert.equal(entries[0].teamName, 'review-team');
    assert.equal(entries[0].teammateId, 'reviewer');
  });

  it('handles missing fields with defaults', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('teammate-idle.js', {}, env);
    assert.equal(result.exitCode, 0);

    const entries = readJsonl(path.join(tmpDir, 'artifacts', 'sessions', 'team-log.jsonl'));
    assert.equal(entries.length, 1);
    assert.equal(entries[0].event, 'teammate_idle');
    assert.equal(entries[0].teamName, 'unknown');
    assert.equal(entries[0].teammateId, 'unknown');
  });

  it('handles empty input (no stdin)', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('teammate-idle.js', null, env);
    assert.equal(result.exitCode, 0);
  });

  it('always exits 0', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('teammate-idle.js', {
      team_name: 'research-team',
      teammate_id: 'researcher-1',
      idle_reason: 'no_tasks',
      tasks_completed: 5
    }, env);
    assert.equal(result.exitCode, 0);
  });

  it('writes budget advisory when near task limit', () => {
    const { tmpDir, env } = makeProjectDir({ ORCH_TEAM_MAX_TASKS: '10' });
    writeTeamState(tmpDir, { totalTaskCount: 10, completedTaskCount: 9, status: 'in_progress' });

    const result = runHook('teammate-idle.js', {
      team_name: 'review-team',
      teammate_id: 'reviewer',
      idle_reason: 'task_complete',
      tasks_completed: 9
    }, env);

    assert.equal(result.exitCode, 0);
    assert.ok(result.stderr.includes('budget'), `Expected budget advisory in stderr: ${result.stderr}`);
  });
});

// ─── task-created.js ──────────────────────────────────────────────────────────

describe('task-created: validation and budget gate', () => {
  it('allows valid task and logs to team-log.jsonl', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', {
      task_id: 'task-1',
      team_name: 'review-team',
      title: 'Quality review',
      dependencies: [],
      created_by: 'conductor'
    }, env);

    assert.equal(result.exitCode, 0);
    const entries = readJsonl(path.join(tmpDir, 'artifacts', 'sessions', 'team-log.jsonl'));
    assert.equal(entries.length, 1);
    assert.equal(entries[0].event, 'task_created');
    assert.equal(entries[0].taskId, 'task-1');
  });

  it('updates team-state.json totalTaskCount and taskIds', () => {
    const { tmpDir, env } = makeProjectDir();
    runHook('task-created.js', {
      task_id: 'task-1',
      team_name: 'review-team',
      title: 'Quality review'
    }, env);

    const state = readTeamState(tmpDir);
    assert.equal(state.totalTaskCount, 1);
    assert.deepEqual(state.taskIds, ['task-1']);
  });

  it('blocks task missing required task_id', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', {
      team_name: 'review-team',
      title: 'Quality review'
    }, env);

    assert.equal(result.exitCode, 2);
    assert.ok(result.stderr.includes('task_id'), `Expected 'task_id' in stderr: ${result.stderr}`);
  });

  it('blocks task missing required title', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', {
      task_id: 'task-1',
      team_name: 'review-team'
    }, env);

    assert.equal(result.exitCode, 2);
    assert.ok(result.stderr.includes('title'), `Expected 'title' in stderr: ${result.stderr}`);
  });

  it('blocks task missing required team_name', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', {
      task_id: 'task-1',
      title: 'Quality review'
    }, env);

    assert.equal(result.exitCode, 2);
    assert.ok(result.stderr.includes('team_name'), `Expected 'team_name' in stderr: ${result.stderr}`);
  });

  it('blocks when task count equals ORCH_TEAM_MAX_TASKS', () => {
    const { tmpDir, env } = makeProjectDir({ ORCH_TEAM_MAX_TASKS: '3' });
    writeTeamState(tmpDir, { totalTaskCount: 3, completedTaskCount: 0, taskIds: ['t1', 't2', 't3'] });

    const result = runHook('task-created.js', {
      task_id: 'task-4',
      team_name: 'review-team',
      title: 'Extra task'
    }, env);

    assert.equal(result.exitCode, 2);
    assert.ok(result.stderr.includes('task limit'), `Expected 'task limit' in stderr: ${result.stderr}`);
  });

  it('allows task when count is below limit', () => {
    const { tmpDir, env } = makeProjectDir({ ORCH_TEAM_MAX_TASKS: '5' });
    writeTeamState(tmpDir, { totalTaskCount: 2, completedTaskCount: 0, taskIds: ['t1', 't2'] });

    const result = runHook('task-created.js', {
      task_id: 'task-3',
      team_name: 'review-team',
      title: 'Third task'
    }, env);

    assert.equal(result.exitCode, 0);
  });

  it('exits 0 with no input', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', null, env);
    assert.equal(result.exitCode, 0);
  });

  it('warns about unknown dependency IDs without blocking', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-created.js', {
      task_id: 'task-2',
      team_name: 'review-team',
      title: 'Dependent task',
      dependencies: ['task-99']
    }, env);

    assert.equal(result.exitCode, 0);
    assert.ok(result.stderr.includes('task-99'), `Expected dependency warning in stderr: ${result.stderr}`);
  });
});

// ─── task-completed.js ────────────────────────────────────────────────────────

describe('task-completed: logging, state, and synthesis', () => {
  it('creates team-log.jsonl with task_completed entry', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'review-team', totalTaskCount: 3, completedTaskCount: 0, status: 'in_progress', taskIds: ['t1', 't2', 't3'] });

    runHook('task-completed.js', {
      task_id: 'task-1',
      team_name: 'review-team',
      title: 'Quality review',
      completed_by: 'reviewer',
      duration_ms: 5000
    }, env);

    const entries = readJsonl(path.join(tmpDir, 'artifacts', 'sessions', 'team-log.jsonl'));
    assert.equal(entries.length, 1);
    assert.equal(entries[0].event, 'task_completed');
    assert.equal(entries[0].completedBy, 'reviewer');
    assert.equal(entries[0].durationMs, 5000);
  });

  it('appends to delegation-log.jsonl for budget tracking', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'review-team', totalTaskCount: 3, completedTaskCount: 0, status: 'in_progress', taskIds: [] });

    runHook('task-completed.js', {
      task_id: 'task-1',
      team_name: 'review-team',
      completed_by: 'reviewer'
    }, env);

    const entries = readJsonl(path.join(tmpDir, 'artifacts', 'sessions', 'delegation-log.jsonl'));
    assert.ok(entries.length >= 1);
    assert.equal(entries[0].event, 'teammate_task_complete');
  });

  it('increments completedTaskCount in team-state.json', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'review-team', totalTaskCount: 3, completedTaskCount: 1, status: 'in_progress', taskIds: [] });

    runHook('task-completed.js', {
      task_id: 'task-2',
      team_name: 'review-team',
      completed_by: 'security-reviewer'
    }, env);

    const state = readTeamState(tmpDir);
    assert.equal(state.completedTaskCount, 2);
    assert.equal(state.status, 'in_progress');
  });

  it('sets status to all_tasks_complete when all tasks done', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'review-team', totalTaskCount: 3, completedTaskCount: 2, status: 'in_progress', taskIds: [] });

    const result = runHook('task-completed.js', {
      task_id: 'task-3',
      team_name: 'review-team',
      completed_by: 'threat-modeler'
    }, env);

    const state = readTeamState(tmpDir);
    assert.equal(state.completedTaskCount, 3);
    assert.equal(state.status, 'all_tasks_complete');
    assert.ok(result.stderr.includes('synthesis'), `Expected synthesis signal in stderr: ${result.stderr}`);
  });

  it('writes team-consensus-pending.md for review-team on final completion', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'review-team', totalTaskCount: 3, completedTaskCount: 2, status: 'in_progress', taskIds: [] });

    runHook('task-completed.js', {
      task_id: 'task-3',
      team_name: 'review-team',
      completed_by: 'threat-modeler'
    }, env);

    const markerFile = path.join(tmpDir, 'artifacts', 'reviews', 'team-consensus-pending.md');
    assert.ok(fs.existsSync(markerFile), 'Expected team-consensus-pending.md to exist');
    const content = fs.readFileSync(markerFile, 'utf8');
    assert.ok(content.includes('review-team'));
  });

  it('does not write consensus marker for non-review teams', () => {
    const { tmpDir, env } = makeProjectDir();
    writeTeamState(tmpDir, { teamName: 'research-team', totalTaskCount: 2, completedTaskCount: 1, status: 'in_progress', taskIds: [] });

    runHook('task-completed.js', {
      task_id: 'task-2',
      team_name: 'research-team',
      completed_by: 'researcher-1'
    }, env);

    const markerFile = path.join(tmpDir, 'artifacts', 'reviews', 'team-consensus-pending.md');
    assert.ok(!fs.existsSync(markerFile), 'Expected no consensus marker for research-team');
  });

  it('always exits 0', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-completed.js', {
      task_id: 'task-1',
      team_name: 'review-team',
      completed_by: 'reviewer'
    }, env);
    assert.equal(result.exitCode, 0);
  });

  it('handles empty input gracefully', () => {
    const { tmpDir, env } = makeProjectDir();
    const result = runHook('task-completed.js', null, env);
    assert.equal(result.exitCode, 0);
  });
});
