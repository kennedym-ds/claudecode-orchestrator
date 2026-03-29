#!/usr/bin/env node
/**
 * Stop hook — generates a PR readiness summary when session ends.
 * Non-blocking. Logs changed files and review status to artifacts if available.
 */
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

try {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const artifactsDir = path.join(projectDir, 'artifacts', 'reviews');

  // Get git diff summary
  let diffSummary = '';
  try {
    diffSummary = execFileSync('git', ['diff', '--stat', 'HEAD'], {
      cwd: projectDir,
      timeout: 5000,
      encoding: 'utf8',
    }).trim();
  } catch {
    // Not a git repo or no changes
    process.exit(0);
  }

  if (!diffSummary) {
    process.exit(0);
  }

  // Count changed files
  let changedFiles = [];
  try {
    changedFiles = execFileSync('git', ['diff', '--name-only', 'HEAD'], {
      cwd: projectDir,
      timeout: 5000,
      encoding: 'utf8',
    }).trim().split('\n').filter(Boolean);
  } catch {
    process.exit(0);
  }

  if (changedFiles.length === 0) {
    process.exit(0);
  }

  // Check if artifacts directory exists
  if (!fs.existsSync(artifactsDir)) {
    process.exit(0);
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const summary = [
    `# PR Gate Summary — ${timestamp}`,
    '',
    `## Changed Files (${changedFiles.length})`,
    '',
    ...changedFiles.map(f => `- ${f}`),
    '',
    '## Diff Stats',
    '```',
    diffSummary,
    '```',
    '',
    '## Readiness Checklist',
    '- [ ] Tests passing',
    '- [ ] Lint clean',
    '- [ ] Review completed',
    '- [ ] Documentation updated',
    '',
  ].join('\n');

  fs.writeFileSync(
    path.join(artifactsDir, `pr-gate-${timestamp}.md`),
    summary
  );
} catch (err) {
  process.stderr.write(`[pr-gate] Warning: ${err.message}\n`);
}

process.exit(0);
