#!/usr/bin/env node
/**
 * TaskCreated hook — validates task creation and enforces task-count budget gate.
 * Exits 2 to block creation if the task is malformed or team task limit is exceeded.
 * Fail-closed: any unexpected error exits 2 to prevent unvalidated task creation.
 */
const fs = require('fs');
const path = require('path');

const VALID_TEAMS = new Set(['review-team', 'research-team', 'implement-team']);

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  if (!input) {
    process.exit(0);
  }

  const data = JSON.parse(input);

  // Validate required fields exist and are strings
  const missing = ['task_id', 'team_name', 'title'].filter(f => !data[f] || typeof data[f] !== 'string');
  if (missing.length > 0) {
    process.stderr.write(`[task-created] Blocked: missing or invalid required fields: ${missing.join(', ')}\n`);
    process.exit(2);
  }

  // Validate team_name against allowlist
  if (!VALID_TEAMS.has(data.team_name)) {
    process.stderr.write(`[task-created] Blocked: unknown team_name "${data.team_name}". Valid: ${[...VALID_TEAMS].join(', ')}\n`);
    process.exit(2);
  }

  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  // Budget gate: enforce ORCH_TEAM_MAX_TASKS
  let maxTasks = parseInt(process.env.ORCH_TEAM_MAX_TASKS || '20', 10);
  if (isNaN(maxTasks) || maxTasks < 1) maxTasks = 20;

  const teamStateFile = path.join(sessionsDir, 'team-state.json');
  let state = { totalTaskCount: 0, completedTaskCount: 0, taskIds: [], completedTaskIds: [] };

  if (fs.existsSync(teamStateFile)) {
    state = JSON.parse(fs.readFileSync(teamStateFile, 'utf8'));
    if (!state.completedTaskIds) state.completedTaskIds = [];
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

  process.exit(0);
} catch (err) {
  process.stderr.write(`[task-created] Blocked (fail-closed): ${err.message}\n`);
  process.exit(2);
}
