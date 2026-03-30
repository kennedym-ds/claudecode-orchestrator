#!/usr/bin/env node
/**
 * demo-agent-ticker.js
 * SubagentStart / SubagentStop hook — prints a live coloured agent dispatch
 * and completion feed so the audience can watch the pipeline in real time.
 *
 * Hook input arrives as JSON on stdin (Claude Code hook payload).
 * Gracefully degrades if payload is absent or malformed.
 *
 * Uses ANSI escape codes. Falls back to plain text if NO_COLOR is set.
 */

'use strict';

const USE_COLOR = !process.env.NO_COLOR && process.stdout.isTTY !== false;

const C = USE_COLOR ? {
  reset:    '\x1b[0m',
  bold:     '\x1b[1m',
  dim:      '\x1b[2m',
  cyan:     '\x1b[36m',
  bCyan:    '\x1b[96m',
  green:    '\x1b[32m',
  bGreen:   '\x1b[92m',
  yellow:   '\x1b[33m',
  bYellow:  '\x1b[93m',
  magenta:  '\x1b[35m',
  bMagenta: '\x1b[95m',
  red:      '\x1b[31m',
  bRed:     '\x1b[91m',
  white:    '\x1b[37m',
  bWhite:   '\x1b[97m',
} : Object.fromEntries(
  ['reset','bold','dim','cyan','bCyan','green','bGreen','yellow','bYellow',
   'magenta','bMagenta','red','bRed','white','bWhite'].map(k => [k, ''])
);

function c(color, str) { return `${C[color]}${str}${C.reset}`; }
function bold(str)     { return `${C.bold}${str}${C.reset}`; }
function dim(str)      { return `${C.dim}${str}${C.reset}`; }

// ─── Model tier detection ─────────────────────────────────────────────────────
// Map agent names to tiers so we can colour-code them in the feed.
const TIER_MAP = {
  // heavy / Opus
  'demo-conductor':    'heavy',
  'planner':           'heavy',
  'architect':         'heavy',
  'reviewer':          'heavy',
  'security-reviewer': 'heavy',
  'threat-modeler':    'heavy',
  'red-team':          'heavy',
  'conductor':         'heavy',
  // fast / Haiku
  'deploy-engineer':   'fast',
  'req-analyst':       'fast',
  'estimator':         'fast',
};

function tierInfo(agentName) {
  const tier = TIER_MAP[agentName] || 'default';
  switch (tier) {
    case 'heavy':   return { label: 'Opus',   dot: c('red',    '●'), tier };
    case 'fast':    return { label: 'Haiku',  dot: c('green',  '●'), tier };
    default:        return { label: 'Sonnet', dot: c('yellow', '●'), tier };
  }
}

// ─── Timestamp ────────────────────────────────────────────────────────────────
function timestamp() {
  const d = new Date();
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  const ss = String(d.getSeconds()).padStart(2, '0');
  return dim(`${hh}:${mm}:${ss}`);
}

// ─── State file for tracking dispatch times ───────────────────────────────────
// We record the dispatch epoch in a lightweight JSON file per agent so that
// SubagentStop can compute a duration without in-process state.
const os   = require('os');
const path = require('path');
const fs   = require('fs');

const STATE_DIR  = path.join(os.tmpdir(), 'cc-demo', 'artifacts', 'memory');
const STATE_FILE = path.join(STATE_DIR, 'ticker-state.json');

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function saveState(state) {
  try {
    fs.mkdirSync(STATE_DIR, { recursive: true });
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  } catch { /* non-fatal */ }
}

// ─── Parse hook payload from stdin ───────────────────────────────────────────
function readStdin() {
  return new Promise(resolve => {
    let data = '';
    if (process.stdin.isTTY) { resolve(''); return; }
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => { data += chunk; });
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', () => resolve(''));
    // Safety timeout
    setTimeout(() => resolve(data), 500);
  });
}

// ─── Status colour ────────────────────────────────────────────────────────────
function statusTag(status) {
  if (!status) return dim('DONE');
  const s = String(status).toUpperCase();
  if (s === 'DONE')              return c('bGreen',   'DONE');
  if (s === 'DONE_WITH_CONCERNS')return c('bYellow',  'DONE_WITH_CONCERNS');
  if (s === 'BLOCKED')           return c('bRed',     'BLOCKED');
  if (s === 'NEEDS_CLARIFICATION')return c('bYellow', 'NEEDS_CLARIFICATION');
  return dim(s);
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  const raw = await readStdin();

  let payload = {};
  try { payload = raw ? JSON.parse(raw) : {}; } catch { /* ignore */ }

  const event     = payload.event || process.env.CLAUDE_HOOK_EVENT || '';
  const agentName = payload.agent_name || payload.agentName || payload.name || 'agent';
  const status    = payload.status || payload.result?.status || '';

  const { label, dot } = tierInfo(agentName);
  const ts = timestamp();

  if (event === 'SubagentStart' || event === 'subagent_start') {
    // Record dispatch time
    const state = loadState();
    state[agentName] = Date.now();
    saveState(state);

    const line = [
      ts,
      c('bCyan', '⚡'),
      bold(c('bWhite', 'DISPATCHING')),
      c('bCyan', agentName),
      dim('·'),
      dot,
      dim(label),
    ].join(' ');

    process.stdout.write(line + '\n');

  } else if (event === 'SubagentStop' || event === 'subagent_stop') {
    // Compute duration
    const state   = loadState();
    const started = state[agentName];
    let duration  = '';
    if (started) {
      const secs = Math.round((Date.now() - started) / 1000);
      duration = secs >= 60
        ? dim(` (${Math.floor(secs / 60)}m ${secs % 60}s)`)
        : dim(` (${secs}s)`);
      delete state[agentName];
      saveState(state);
    }

    const isBlocked  = String(status).toUpperCase() === 'BLOCKED';
    const icon       = isBlocked ? c('bRed', '✗') : c('bGreen', '✓');
    const returnWord = isBlocked ? c('bRed', 'RETURNED') : c('bGreen', 'RETURNED');

    const line = [
      ts,
      icon,
      bold(returnWord),
      c('bCyan', agentName),
      dim('→'),
      statusTag(status),
      duration,
    ].join(' ');

    process.stdout.write(line + '\n');

  } else {
    // Unknown event — silent pass-through
  }

  process.exit(0);
}

main().catch(err => {
  process.stderr.write(`[cc-demo] ticker warning: ${err.message}\n`);
  process.exit(0);
});
