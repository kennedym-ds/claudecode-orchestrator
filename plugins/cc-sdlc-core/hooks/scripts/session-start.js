#!/usr/bin/env node
/**
 * SessionStart hook — loads previous session state and sets orchestrator env vars.
 * Uses CLAUDE_ENV_FILE to persist environment variables for the session.
 * Checks deployed version against source VERSION and auto-updates if stale.
 * See: https://code.claude.com/docs/en/hooks#sessionstart
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const contextFile = path.join(projectDir, 'artifacts', 'memory', 'activeContext.md');

/**
 * Compare deployed version with source VERSION file.
 * If stale and source is a git repo, pull latest and re-deploy.
 */
function checkVersion() {
  try {
    // Source version: relative to this script's location
    const sourceVersionFile = path.resolve(__dirname, '..', '..', 'VERSION');
    if (!fs.existsSync(sourceVersionFile)) return;
    const sourceVersion = fs.readFileSync(sourceVersionFile, 'utf8').trim();

    // Deployed version: in user's ~/.claude/
    const homeDir = process.env.HOME || process.env.USERPROFILE || '';
    if (!homeDir) return;
    const deployedVersionFile = path.join(homeDir, '.claude', '.cc-sdlc-version');
    if (!fs.existsSync(deployedVersionFile)) return;
    const deployedVersion = fs.readFileSync(deployedVersionFile, 'utf8').trim();

    if (sourceVersion === deployedVersion) return;

    process.stderr.write(
      `[cc-sdlc] Version mismatch: deployed=${deployedVersion}, source=${sourceVersion}\n`
    );

    // Attempt auto-update: git pull in the repo, then re-deploy
    const repoRoot = path.resolve(__dirname, '..', '..', '..', '..');
    const gitDir = path.join(repoRoot, '.git');
    if (fs.existsSync(gitDir)) {
      process.stderr.write('[cc-sdlc] Auto-updating: git pull + redeploy...\n');
      try {
        execSync('git pull --ff-only', { cwd: repoRoot, stdio: 'pipe', timeout: 30000 });

        // Re-read source version after pull
        const updatedVersion = fs.readFileSync(sourceVersionFile, 'utf8').trim();

        // Re-deploy: detect platform and run appropriate script
        const deployPs1 = path.join(repoRoot, 'scripts', 'deploy-user.ps1');
        const deploySh = path.join(repoRoot, 'scripts', 'deploy-user.sh');
        if (process.platform === 'win32' && fs.existsSync(deployPs1)) {
          execSync(`powershell -File "${deployPs1}"`, { cwd: repoRoot, stdio: 'pipe', timeout: 60000 });
        } else if (fs.existsSync(deploySh)) {
          execSync(`bash "${deploySh}"`, { cwd: repoRoot, stdio: 'pipe', timeout: 60000 });
        }
        process.stderr.write(`[cc-sdlc] Updated to ${updatedVersion}\n`);
      } catch (updateErr) {
        process.stderr.write(`[cc-sdlc] Auto-update failed: ${updateErr.message}\n`);
        process.stderr.write('[cc-sdlc] Run deploy-user manually to update.\n');
      }
    } else {
      process.stderr.write('[cc-sdlc] Run deploy-user.ps1 or deploy-user.sh to update.\n');
    }
  } catch (err) {
    // Version check is non-blocking
    process.stderr.write(`[cc-sdlc] Version check warning: ${err.message}\n`);
  }
}

try {
  // Write orchestrator env vars to CLAUDE_ENV_FILE if available
  const envFile = process.env.CLAUDE_ENV_FILE;
  if (envFile) {
    const envVars = [];

    // Mark that we're running in orchestrator mode
    envVars.push('ORCH_SESSION_ACTIVE=true');

    // Check if activeContext.md exists (session has prior state)
    if (fs.existsSync(contextFile)) {
      envVars.push('ORCH_HAS_PRIOR_STATE=true');
    }

    fs.appendFileSync(envFile, envVars.join('\n') + '\n');
  }

  // Log session start for observability
  const sessionsDir = path.join(projectDir, 'artifacts', 'sessions');

  // Check version and auto-update if stale
  checkVersion();
  if (!fs.existsSync(sessionsDir)) {
    fs.mkdirSync(sessionsDir, { recursive: true });
  }

  const logFile = path.join(sessionsDir, 'session-log.jsonl');
  const entry = {
    event: 'session_start',
    timestamp: new Date().toISOString(),
    sessionId: process.env.CLAUDE_SESSION_ID || 'unknown',
    hasPriorState: fs.existsSync(contextFile)
  };
  fs.appendFileSync(logFile, JSON.stringify(entry) + '\n');
} catch (err) {
  // Non-blocking — session starts even if hook fails
  process.stderr.write(`[session-start] Warning: ${err.message}\n`);
}

process.exit(0);
