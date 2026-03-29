#!/usr/bin/env node
/**
 * TeammateIdle hook — logs when a teammate goes idle.
 * Informational only: always exits 0 (CC does not support exit 2 blocking for TeammateIdle).
 * Checks overall team task state and writes advisory messages to stderr.
 */
const fs = require('fs');
const path = require('path');

try {
  let input = '';
  if (!process.stdin.isTTY) {
    input = fs.readFileSync(0, 'utf8');
  }

  const data = input ? JSON.parse(input) : {};

  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  const entry = {
    event: 'teammate_idle',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    teamName: data.team_name || 'unknown',
    teammateId: data.teammate_id || 'unknown',
    idleReason: data.idle_reason || 'unknown',
    tasksCompleted: data.tasks_completed || 0
  };

  fs.appendFileSync(path.join(sessionsDir, 'team-log.jsonl'), JSON.stringify(entry) + '\n');

  // Advisory messages — visible in Claude UI but non-blocking
  const teamStateFile = path.join(sessionsDir, 'team-state.json');
  if (fs.existsSync(teamStateFile)) {
    const state = JSON.parse(fs.readFileSync(teamStateFile, 'utf8'));

    if (entry.idleReason === 'no_tasks' && state.status === 'all_tasks_complete') {
      process.stderr.write(`[teams] ${entry.teammateId} idle — all tasks complete for ${entry.teamName}\n`);
    } else if (entry.idleReason === 'waiting_dependency') {
      process.stderr.write(`[teams] ${entry.teammateId} idle — waiting on a dependency in ${entry.teamName}\n`);
    } else if (entry.idleReason === 'no_tasks') {
      const pending = (state.totalTaskCount || 0) - (state.completedTaskCount || 0);
      if (pending > 0) {
        process.stderr.write(`[teams] ${entry.teammateId} idle — ${pending} tasks remain (may have unresolved dependencies)\n`);
      }
    }

    // Budget advisory if teammate count is high
    const maxTasks = parseInt(process.env.ORCH_TEAM_MAX_TASKS || '20', 10);
    if ((state.completedTaskCount || 0) >= maxTasks * 0.9) {
      process.stderr.write(`[teams] Warning: ${state.completedTaskCount}/${maxTasks} task budget consumed\n`);
    }
  }
} catch (err) {
  process.stderr.write(`[teammate-idle] Warning: ${err.message}\n`);
}

process.exit(0);
