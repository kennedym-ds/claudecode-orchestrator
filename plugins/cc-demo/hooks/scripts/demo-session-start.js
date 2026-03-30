#!/usr/bin/env node
/**
 * demo-session-start.js
 * SessionStart hook — resolves the demo workspace to the OS temp directory,
 * creates the directory structure, initialises demo-state.json (if not present),
 * and exports DEMO_WORKSPACE to the session env file so all agents can use it.
 *
 * Workspace path: {os.tmpdir()}/cc-demo
 * This makes the demo location-agnostic — it runs identically from any terminal.
 *
 * Env vars consumed:
 *   CLAUDE_SESSION_ID  — injected by Claude Code
 *   CLAUDE_ENV_FILE    — writable session env file (for exporting DEMO_WORKSPACE)
 */

'use strict';

const fs   = require('fs');
const os   = require('os');
const path = require('path');

const WORKSPACE    = path.join(os.tmpdir(), 'cc-demo');
const ARTIFACTS    = path.join(WORKSPACE, 'artifacts');
const MEMORY_DIR   = path.join(ARTIFACTS, 'memory');
const SESSIONS_DIR = path.join(ARTIFACTS, 'sessions');
const PRESETS_DIR  = path.join(ARTIFACTS, 'presets');
const STATE_FILE   = path.join(MEMORY_DIR, 'demo-state.json');

// Resolve the plugin root so we can copy preset files into the workspace.
// Primary: CLAUDE_PLUGIN_ROOT env var (set by the hooks runner).
// Fallback: two directories up from this script (hooks/scripts/ → hooks/ → plugin root).
const PLUGIN_ROOT = process.env.CLAUDE_PLUGIN_ROOT
  || path.resolve(__dirname, '..', '..');

const SESSION_ID = process.env.CLAUDE_SESSION_ID || 'unknown';

const DIRS = [
  WORKSPACE,
  ARTIFACTS,
  MEMORY_DIR,
  SESSIONS_DIR,
  PRESETS_DIR,
  path.join(ARTIFACTS, 'plans'),
  path.join(ARTIFACTS, 'reviews'),
  path.join(ARTIFACTS, 'decisions'),
  path.join(ARTIFACTS, 'research'),
];

function initialState() {
  return {
    projectName: null,
    projectSlug: null,
    specConfirmed: false,
    specPath: null,
    sessionId: SESSION_ID,
    workspace: WORKSPACE,
    startedAt: new Date().toISOString(),
    completedAt: null,
    teamModeActive: false,
    phases: {
      plan:      { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'planner',         teamMode: false, concerns: [] },
      architect: { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'architect',       teamMode: false, concerns: [] },
      implement: { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'implementer',     teamMode: false, concerns: [] },
      review:    { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'review-team',     teamMode: true,  concerns: [] },
      e2e:       { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'e2e-tester',      teamMode: false, concerns: [] },
      doc:       { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'doc-updater',     teamMode: false, concerns: [] },
      deploy:    { status: 'pending', startedAt: null, completedAt: null, artifact: null, agentUsed: 'deploy-engineer', teamMode: false, concerns: [] },
    },
  };
}

function main() {
  DIRS.forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });

  // Preserve existing state — supports resume across sessions
  if (!fs.existsSync(STATE_FILE)) {
    fs.writeFileSync(STATE_FILE, JSON.stringify(initialState(), null, 2));
  }

  // Export DEMO_WORKSPACE so every agent and subagent can resolve the path
  const envFile = process.env.CLAUDE_ENV_FILE;
  if (envFile) {
    // Overwrite any stale value from a previous session
    let existing = '';
    try { existing = fs.readFileSync(envFile, 'utf8'); } catch {}
    const filtered = existing.split('\n').filter(l => !l.startsWith('DEMO_WORKSPACE=')).join('\n');
    fs.writeFileSync(envFile, `${filtered}\nDEMO_WORKSPACE=${WORKSPACE}\n`);
  }

  // Copy preset bundles (spec.md + replay.json) into the workspace so
  // demo-conductor can always reach them via $DEMO_WORKSPACE/artifacts/presets/
  copyPresets();

  process.stdout.write(`[cc-demo] workspace: ${WORKSPACE}\n`);
}

/**
 * Recursively copies plugin/presets/{name}/ → workspace/artifacts/presets/{name}/
 * Only copies if the source file is newer than the destination (supports re-runs).
 */
function copyPresets() {
  const src = path.join(PLUGIN_ROOT, 'presets');
  if (!fs.existsSync(src)) return;

  const presetNames = fs.readdirSync(src).filter(n => {
    return fs.statSync(path.join(src, n)).isDirectory();
  });

  presetNames.forEach(name => {
    const srcDir  = path.join(src, name);
    const destDir = path.join(PRESETS_DIR, name);
    fs.mkdirSync(destDir, { recursive: true });

    fs.readdirSync(srcDir).forEach(file => {
      const srcFile  = path.join(srcDir, file);
      const destFile = path.join(destDir, file);
      if (!fs.statSync(srcFile).isFile()) return;

      const srcMtime  = fs.statSync(srcFile).mtimeMs;
      const destMtime = fs.existsSync(destFile) ? fs.statSync(destFile).mtimeMs : 0;
      if (srcMtime > destMtime) {
        fs.copyFileSync(srcFile, destFile);
      }
    });
  });
}

try {
  main();
  process.exit(0);
} catch (err) {
  // Never fail the session start
  process.stderr.write(`[cc-demo] demo-session-start warning: ${err.message}\n`);
  process.exit(0);
}
