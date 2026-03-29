#!/usr/bin/env node
/**
 * TaskCreated hook — validates task creation and enforces task-count budget gate.
 * Exits 2 to block creation if the task is malformed or team task limit is exceeded.
 */
const fs = require('fs');
const path = require('path');

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (!input) {
    process.exit(0);
  }

  const data = JSON.parse(input);

  // Validate required fields
  const missing = ['task_id', 'team_name', 'title'].filter(f => !data[f]);
  if (missing.length > 0) {
    process.stderr.write(`[task-created] Blocked: missing required fields: ${missing.join(', ')}\n`);
    process.exit(2);
  }

  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  // Budget gate: enforce ORCH_TEAM_MAX_TASKS
  const maxTasks = parseInt(process.env.ORCH_TEAM_MAX_TASKS || '20', 10);
  const teamStateFile = path.join(sessionsDir, 'team-state.json');
  let state = { totalTaskCount: 0, completedTaskCount: 0, taskIds: [] };

  if (fs.existsSync(teamStateFile)) {
    state = JSON.parse(fs.readFileSync(teamStateFile, 'utf8'));
  }

  const currentCount = state.totalTaskCount || 0;
  if (currentCount >= maxTasks) {
    process.stderr.write(
      `[task-created] Blocked: team task limit reached (${currentCount}/${maxTasks}). ` +
      `Reduce scope or split sessions. Set ORCH_TEAM_MAX_TASKS to increase limit.\n`
    );
    process.exit(2);
  }

  // Log task creation
  const entry = {
    event: 'task_created',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    teamName: data.team_name,
    taskId: data.task_id,
    title: data.title,
    createdBy: data.created_by || 'unknown',
    dependencies: data.dependencies || []
  };

  fs.appendFileSync(path.join(sessionsDir, 'team-log.jsonl'), JSON.stringify(entry) + '\n');

  // Update team-state task count and taskIds
  state.totalTaskCount = currentCount + 1;
  state.taskIds = [...(state.taskIds || []), data.task_id];
  if (!state.teamName) state.teamName = data.team_name;
  fs.writeFileSync(teamStateFile, JSON.stringify(state, null, 2));

  // Advisory: warn if dependencies reference unknown task IDs
  if (data.dependencies && data.dependencies.length > 0) {
    const knownIds = new Set(state.taskIds);
    const unknown = data.dependencies.filter(id => !knownIds.has(id) && id !== data.task_id);
    if (unknown.length > 0) {
      process.stderr.write(
        `[task-created] Warning: task "${data.task_id}" depends on unknown IDs: ${unknown.join(', ')} ` +
        `(may be created in same batch — not blocking)\n`
      );
    }
  }
} catch (err) {
  process.stderr.write(`[task-created] Warning: ${err.message}\n`);
}

process.exit(0);
