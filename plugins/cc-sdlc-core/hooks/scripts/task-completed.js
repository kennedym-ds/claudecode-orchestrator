#!/usr/bin/env node
/**
 * TaskCompleted hook — logs task completion, updates team-state.json, triggers synthesis signals.
 * Async post-completion event: always exits 0 (cannot block a completed task).
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

  // Idempotency: check for duplicate completion before logging
  const taskId = data.task_id || 'unknown';
  const teamStateFile = path.join(sessionsDir, 'team-state.json');
  if (taskId !== 'unknown' && fs.existsSync(teamStateFile)) {
    const preCheck = JSON.parse(fs.readFileSync(teamStateFile, 'utf8'));
    if (preCheck.completedTaskIds && preCheck.completedTaskIds.includes(taskId)) {
      process.stderr.write(`[task-completed] Skipped duplicate completion for task "${taskId}"\n`);
      process.exit(0);
    }
  }

  // Log to team-log.jsonl
  const teamEntry = {
    event: 'task_completed',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    teamName: data.team_name || 'unknown',
    taskId: taskId,
    title: data.title || 'unknown',
    completedBy: data.completed_by || 'unknown',
    durationMs: data.duration_ms || 0,
    outputSummary: data.output_summary || ''
  };

  fs.appendFileSync(path.join(sessionsDir, 'team-log.jsonl'), JSON.stringify(teamEntry) + '\n');

  // Also log to delegation-log.jsonl for budget-gatekeeper tracking
  const budgetEntry = {
    event: 'teammate_task_complete',
    timestamp: teamEntry.timestamp,
    sessionId: teamEntry.sessionId,
    teamName: teamEntry.teamName,
    taskId: teamEntry.taskId,
    completedBy: teamEntry.completedBy,
    durationMs: teamEntry.durationMs
  };

  fs.appendFileSync(path.join(sessionsDir, 'delegation-log.jsonl'), JSON.stringify(budgetEntry) + '\n');

  // Update team-state.json
  if (fs.existsSync(teamStateFile)) {
    const state = JSON.parse(fs.readFileSync(teamStateFile, 'utf8'));

    if (!state.completedTaskIds) state.completedTaskIds = [];
    state.completedTaskIds.push(taskId);
    state.completedTaskCount = (state.completedTaskCount || 0) + 1;

    const allDone = state.completedTaskCount >= (state.totalTaskCount || 0) && state.totalTaskCount > 0;

    if (allDone) {
      state.status = 'all_tasks_complete';
      process.stderr.write(`[teams] All tasks complete for ${state.teamName} — ready for synthesis\n`);

      // Write synthesis marker for review-team
      if (state.teamName === 'review-team') {
        const reviewsDir = path.join(projectDir, 'artifacts', 'reviews');
        if (!fs.existsSync(reviewsDir)) {
          fs.mkdirSync(reviewsDir, { recursive: true });
        }
        fs.writeFileSync(
          path.join(reviewsDir, 'team-consensus-pending.md'),
          `# Team Review Consensus Pending\n\nAll review-team tasks complete. Conductor should run pr-review skill synthesis.\n\n- Completed: ${new Date().toISOString()}\n- Session: ${teamEntry.sessionId}\n`
        );
        process.stderr.write(`[teams] Synthesis marker written to artifacts/reviews/team-consensus-pending.md\n`);
      }
    } else {
      state.status = 'in_progress';
    }

    fs.writeFileSync(teamStateFile, JSON.stringify(state, null, 2));
  }
} catch (err) {
  process.stderr.write(`[task-completed] Warning: ${err.message}\n`);
}

process.exit(0);
