#!/usr/bin/env node
/**
 * demo-teardown-guard.js
 * PreToolUse hook — blocks Edit/Write tool calls targeting files outside the demo workspace.
 * Reads DEMO_WORKSPACE from env (set by demo-session-start.js via CLAUDE_ENV_FILE).
 * Falls back to {os.tmpdir()}/cc-demo if the env var is not yet set.
 *
 * Input  (stdin): JSON tool call payload { tool_name, tool_input }
 * Output: exit 0 to allow, exit 2 with stderr message to block
 */

'use strict';

const fs   = require('fs');
const os   = require('os');
const path = require('path');

// Resolve workspace — env var takes precedence over default
const WORKSPACE = path.resolve(process.env.DEMO_WORKSPACE || path.join(os.tmpdir(), 'cc-demo'));
const SEP       = path.sep;

function isInsideWorkspace(filePath) {
  if (!filePath) return true;
  const resolved = path.resolve(filePath);
  return resolved === WORKSPACE || resolved.startsWith(WORKSPACE + SEP);
}

function main() {
  let raw = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => { raw += chunk; });
  process.stdin.on('end', () => {
    let payload;
    try {
      payload = JSON.parse(raw);
    } catch {
      process.exit(0);
    }

    const toolName  = payload.tool_name  || '';
    const toolInput = payload.tool_input || {};

    if (toolName !== 'Edit' && toolName !== 'Write') {
      process.exit(0);
    }

    const targetPath = toolInput.file_path || toolInput.path || null;

    if (targetPath && !isInsideWorkspace(targetPath)) {
      process.stderr.write(
        `[cc-demo] BLOCKED: ${toolName} to '${targetPath}' is outside the demo workspace.\n` +
        `Demo workspace: ${WORKSPACE}\n` +
        `All demo file operations must target the demo workspace only.\n`
      );
      process.exit(2);
    }

    process.exit(0);
  });
}

main();
