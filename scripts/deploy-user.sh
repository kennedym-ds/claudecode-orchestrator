#!/usr/bin/env bash
# deploy-user.sh — Deploy cc-sdlc assets to ~/.claude/ for global availability
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET="$HOME/.claude"

MODE="copy"
DRY_RUN=false
UNINSTALL=false

usage() {
  echo "Usage: $0 [--mode symlink|copy] [--dry-run] [--uninstall]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    *) usage ;;
  esac
done

MANIFEST="$TARGET/.cc-sdlc-manifest.json"

deploy_file() {
  local src="$1" dst="$2"
  local dir; dir="$(dirname "$dst")"
  if $DRY_RUN; then
    echo "[dry-run] $src -> $dst"
    return
  fi
  mkdir -p "$dir"
  if [ "$MODE" = "symlink" ]; then
    ln -sf "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
}

if $UNINSTALL; then
  if [ -f "$MANIFEST" ]; then
    echo "Removing deployed cc-sdlc assets..."
    # Read manifest and remove files (simple line-based)
    while IFS= read -r file; do
      [ -f "$file" ] && rm "$file" && echo "  Removed $file"
    done < <(python3 -c "import json,sys; [print(f) for f in json.load(open('$MANIFEST'))['files']]" 2>/dev/null || true)
    rm "$MANIFEST"
    echo "Uninstall complete."
  else
    echo "No manifest found — nothing to uninstall."
  fi
  exit 0
fi

echo "Deploying cc-sdlc assets to $TARGET (mode: $MODE)..."

DEPLOYED=()

# Core agents
for f in "$REPO_ROOT"/plugins/cc-sdlc-core/.claude/agents/*.md; do
  [ -f "$f" ] || continue
  dst="$TARGET/agents/$(basename "$f")"
  deploy_file "$f" "$dst"
  DEPLOYED+=("$dst")
done

# Core skills
for f in "$REPO_ROOT"/plugins/cc-sdlc-core/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  skill_name="$(basename "$(dirname "$f")")"
  dst="$TARGET/skills/$skill_name/SKILL.md"
  deploy_file "$f" "$dst"
  DEPLOYED+=("$dst")
done

# Core commands
for f in "$REPO_ROOT"/plugins/cc-sdlc-core/.claude/commands/*.md; do
  [ -f "$f" ] || continue
  dst="$TARGET/commands/$(basename "$f")"
  deploy_file "$f" "$dst"
  DEPLOYED+=("$dst")
done

# Core rules
for f in "$REPO_ROOT"/plugins/cc-sdlc-core/.claude/rules/*.md; do
  [ -f "$f" ] || continue
  dst="$TARGET/rules/$(basename "$f")"
  deploy_file "$f" "$dst"
  DEPLOYED+=("$dst")
done

# Hook scripts — deploy to ~/.claude/hooks/scripts/
HOOKS_TARGET="$TARGET/hooks/scripts"
mkdir -p "$HOOKS_TARGET" 2>/dev/null || true
for f in "$REPO_ROOT"/plugins/cc-sdlc-core/hooks/scripts/*.js; do
  [ -f "$f" ] || continue
  dst="$HOOKS_TARGET/$(basename "$f")"
  deploy_file "$f" "$dst"
  DEPLOYED+=("$dst")
done

# Merge settings — backup existing, merge hooks with absolute paths
SETTINGS_FILE="$TARGET/settings.json"
if ! $DRY_RUN; then
  if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_DIR="$TARGET/.orchestrator-backup"
    mkdir -p "$BACKUP_DIR"
    cp "$SETTINGS_FILE" "$BACKUP_DIR/settings.json.$(date +%Y%m%d%H%M%S)"
  fi

  # Build hook config with absolute paths to deployed scripts
  if command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const path = require('path');
const settingsPath = '$SETTINGS_FILE';
const hooksDir = '$HOOKS_TARGET';

let settings = {};
if (fs.existsSync(settingsPath)) {
  try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}
}

// Ensure env block with model tiers
if (!settings.env) settings.env = {};
if (!settings.env.ORCH_MODEL_HEAVY) settings.env.ORCH_MODEL_HEAVY = 'claude-opus-4-6-20260320';
if (!settings.env.ORCH_MODEL_DEFAULT) settings.env.ORCH_MODEL_DEFAULT = 'claude-sonnet-4-6-20260320';
if (!settings.env.ORCH_MODEL_FAST) settings.env.ORCH_MODEL_FAST = 'claude-haiku-4-5-20250315';

// Build hooks with absolute paths
const absHook = (script) => ({ type: 'command', command: 'node ' + path.join(hooksDir, script) });
settings.hooks = {
  SessionStart: [{ hooks: [{ ...absHook('session-start.js'), once: true }] }],
  UserPromptSubmit: [{ hooks: [absHook('secret-detector.js')] }],
  PreToolUse: [{ matcher: 'Bash', hooks: [absHook('pre-bash-safety.js')] }],
  PostToolUse: [{ matcher: 'Edit|Write', hooks: [{ ...absHook('post-edit-validate.js'), async: true }] }],
  SubagentStart: [{ hooks: [absHook('subagent-start-log.js')] }],
  SubagentStop: [{ hooks: [absHook('subagent-stop-gate.js')] }],
  PreCompact: [{ hooks: [absHook('pre-compact.js')] }],
  PostCompact: [{ hooks: [absHook('post-compact.js')] }],
  Stop: [{ hooks: [absHook('stop-summary.js')] }],
  SessionEnd: [{ hooks: [absHook('session-end.js')] }],
};

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
" 2>/dev/null && echo "Settings merged at $SETTINGS_FILE" || echo "Warning: settings merge skipped (node required)"
  else
    echo "Warning: settings merge skipped (node not found — install Node.js for full deployment)"
  fi
fi

# Write manifest
if ! $DRY_RUN; then
  python3 -c "
import json
files = $(printf '%s\n' "${DEPLOYED[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
json.dump({'files': files, 'mode': '$MODE'}, open('$MANIFEST', 'w'), indent=2)
" 2>/dev/null || true
fi

echo "Deployed ${#DEPLOYED[@]} files."
