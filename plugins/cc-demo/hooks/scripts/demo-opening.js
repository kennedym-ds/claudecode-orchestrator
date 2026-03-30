#!/usr/bin/env node
/**
 * demo-opening.js
 * SessionStart hook — prints the cc-demo opening sequence with ASCII art,
 * pipeline overview, and workspace info. Fires once per session.
 *
 * Uses ANSI escape codes for colour and formatting.
 * Falls back to plain text if NO_COLOR env var is set.
 */

'use strict';

const os   = require('os');
const path = require('path');
const fs   = require('fs');

const WORKSPACE = process.env.DEMO_WORKSPACE || path.join(os.tmpdir(), 'cc-demo');
const USE_COLOR = !process.env.NO_COLOR && process.stdout.isTTY !== false;

const C = USE_COLOR ? {
  reset:   '\x1b[0m',
  bold:    '\x1b[1m',
  dim:     '\x1b[2m',
  cyan:    '\x1b[36m',
  bCyan:   '\x1b[96m',
  green:   '\x1b[32m',
  bGreen:  '\x1b[92m',
  yellow:  '\x1b[33m',
  bYellow: '\x1b[93m',
  magenta: '\x1b[35m',
  bMagenta:'\x1b[95m',
  white:   '\x1b[37m',
  bWhite:  '\x1b[97m',
  red:     '\x1b[31m',
} : Object.fromEntries(
  ['reset','bold','dim','cyan','bCyan','green','bGreen','yellow','bYellow',
   'magenta','bMagenta','white','bWhite','red'].map(k => [k, ''])
);

function c(color, str) { return `${C[color]}${str}${C.reset}`; }
function bold(str)     { return `${C.bold}${str}${C.reset}`; }

// ─── ASCII Art Logo ───────────────────────────────────────────────────────────
const LOGO = `
${c('bCyan',`  ██████╗ ██████╗      ██████╗ ███████╗███╗   ███╗ ██████╗ `)}
${c('bCyan',` ██╔════╝██╔════╝      ██╔══██╗██╔════╝████╗ ████║██╔═══██╗`)}
${c('bCyan',` ██║     ██║     █████╗██║  ██║█████╗  ██╔████╔██║██║   ██║`)}
${c('bCyan',` ██║     ██║     ╚════╝██║  ██║██╔══╝  ██║╚██╔╝██║██║   ██║`)}
${c('bCyan',` ╚██████╗╚██████╗      ██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝`)}
${c('bCyan',`  ╚═════╝ ╚═════╝      ╚═════╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝ `)}`;

// ─── Pipeline Diagram ─────────────────────────────────────────────────────────
function pipeline() {
  const phases = [
    { n: '①', label: 'SPEC',   model: 'interview' },
    { n: '②', label: 'PLAN',   model: 'opus'      },
    { n: '③', label: 'ARCH',   model: 'opus'      },
    { n: '④', label: 'IMPL',   model: 'sonnet'    },
    { n: '⑤', label: 'REVIEW', model: '3×opus'    },
    { n: '⑥', label: 'E2E',    model: 'sonnet'    },
    { n: '⑦', label: 'DOC',    model: 'sonnet'    },
    { n: '⑧', label: 'DEPLOY', model: 'haiku'     },
  ];
  return phases.map(p => c('dim', `${p.n} ${p.label}`)).join(c('dim', ' → '));
}

// ─── Model Tier Legend ────────────────────────────────────────────────────────
function tierLegend() {
  return [
    `${c('red',    '●')} ${bold('Opus')}    planning, review, architecture (judgment tier)`,
    `${c('yellow', '●')} ${bold('Sonnet')}  implementation, testing, docs   (execution tier)`,
    `${c('green',  '●')} ${bold('Haiku')}   deployment, triage              (fast tier)`,
  ].join('\n  ');
}

// ─── Box Drawing ──────────────────────────────────────────────────────────────
const W = 73;
function hline(ch = '═') { return c('cyan', '╠' + ch.repeat(W) + '╣'); }
function top()            { return c('cyan', '╔' + '═'.repeat(W) + '╗'); }
function bot()            { return c('cyan', '╚' + '═'.repeat(W) + '╝'); }
function row(text, pad = ' ') {
  const stripped = text.replace(/\x1b\[[0-9;]*m/g, '');
  const spaces   = Math.max(0, W - stripped.length - 2);
  return `${c('cyan','║')} ${text}${' '.repeat(spaces)}${c('cyan','║')}`;
}

// ─── Main Output ──────────────────────────────────────────────────────────────
function main() {
  const lines = [
    '',
    top(),
    row(''),
    ...LOGO.trim().split('\n').map(l => row(l)),
    row(''),
    row(c('bWhite', bold('  Autonomous SDLC Showcase')) + c('dim', '  ·  Powered by cc-sdlc-core  ·  idea → git commit')),
    row(''),
    hline(),
    row(bold('  PIPELINE')),
    row('  ' + pipeline()),
    row(c('dim', '  spec-interview → plan → architect → implement → trilateral-review → e2e → doc → deploy')),
    hline(),
    row(bold('  MODEL TIERS')),
    row('  ' + tierLegend().split('\n').join('\n' + '  ')),
    hline(),
    row(`  ${c('yellow','Workspace')}  ${c('bWhite', WORKSPACE)}`),
    row(`  ${c('yellow','Mode')}       ${c('red', '--dangerously-skip-permissions')} ${c('dim','(demo only — temporary workspace)')}`),
    row(''),
    row(c('dim', '  After you confirm the spec, the full pipeline runs autonomously.')),
    row(c('dim', '  Run /demo-teardown when done.')),
    row(''),
    bot(),
    '',
  ];

  process.stdout.write(lines.join('\n') + '\n');
}

try {
  main();
  process.exit(0);
} catch (err) {
  process.stderr.write(`[cc-demo] demo-opening warning: ${err.message}\n`);
  process.exit(0);
}
