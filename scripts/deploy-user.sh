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
    # Read manifest and remove files using node (already a required dependency)
    if command -v node &>/dev/null; then
      node -e "
        const m = JSON.parse(require('fs').readFileSync('$MANIFEST', 'utf8'));
        (m.files || []).forEach(f => {
          try { require('fs').unlinkSync(f); console.log('  Removed ' + f); } catch {}
        });
      " 2>/dev/null
    fi
    rm "$MANIFEST"

    # Strip orchestrator hooks and env from settings.json
    SETTINGS_FILE="$TARGET/settings.json"
    HOOKS_TARGET="$TARGET/hooks/scripts"
    if [ -f "$SETTINGS_FILE" ] && command -v node &>/dev/null; then
      node - "$SETTINGS_FILE" "$HOOKS_TARGET" <<'CLEAN_SETTINGS'
const fs = require('fs');
const settingsPath = process.argv[1];
const hooksDir = process.argv[2];
let settings;
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch { process.exit(0); }
if (settings.hooks) {
  for (const [event, groups] of Object.entries(settings.hooks)) {
    if (!Array.isArray(groups)) continue;
    settings.hooks[event] = groups.filter(group => {
      const hooks = group.hooks || [];
      return !hooks.some(h => h.command && h.command.includes(hooksDir));
    });
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
}
if (settings.env) {
  delete settings.env.ORCH_MODEL_HEAVY;
  delete settings.env.ORCH_MODEL_DEFAULT;
  delete settings.env.ORCH_MODEL_FAST;
  if (Object.keys(settings.env).length === 0) delete settings.env;
}
if (Object.keys(settings).length === 0) {
  fs.unlinkSync(settingsPath);
  console.log('  Removed empty settings.json');
} else {
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
  console.log('  Cleaned orchestrator entries from settings.json');
}
CLEAN_SETTINGS
    fi

    echo "Uninstall complete."
  else
    echo "No manifest found — nothing to uninstall."
  fi
  exit 0
fi

echo "Deploying cc-sdlc assets to $TARGET (mode: $MODE)..."

# Preflight: Node.js is required for settings merge and manifest writing
if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js is required for deployment (used for settings.json merge)."
  echo "Install Node.js from https://nodejs.org/ and re-run."
  exit 1
fi

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

  # Build hook config — merge with existing user hooks, quote paths
  if command -v node &>/dev/null; then
    node - "$SETTINGS_FILE" "$HOOKS_TARGET" <<'MERGE_SETTINGS'
const fs = require('fs');
const path = require('path');
const settingsPath = process.argv[1];
const hooksDir = process.argv[2];

let settings = {};
if (fs.existsSync(settingsPath)) {
  try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}
}

// Ensure env block with model tiers
if (!settings.env) settings.env = {};
if (!settings.env.ORCH_MODEL_HEAVY) settings.env.ORCH_MODEL_HEAVY = 'claude-opus-4-6-20260320';
if (!settings.env.ORCH_MODEL_DEFAULT) settings.env.ORCH_MODEL_DEFAULT = 'claude-sonnet-4-6-20260320';
if (!settings.env.ORCH_MODEL_FAST) settings.env.ORCH_MODEL_FAST = 'claude-haiku-4-5-20250315';

// Build hooks with absolute paths (quoted for paths with spaces)
const absHook = (script) => {
  const p = path.join(hooksDir, script);
  return { type: 'command', command: 'node "' + p + '"' };
};
const orchHooks = {
  SessionStart: [{ hooks: [{ ...absHook('session-start.js'), once: true }] }],
  UserPromptSubmit: [{ hooks: [absHook('secret-detector.js')] }],
  PreToolUse: [{ matcher: 'Bash', hooks: [absHook('pre-bash-safety.js'), absHook('deploy-guard.js')] }],
  PostToolUse: [{ matcher: 'Edit|Write', hooks: [
    { ...absHook('post-edit-validate.js'), async: true },
    { ...absHook('dependency-scanner.js'), if: 'Edit(*package*.json)', async: true },
    { ...absHook('dependency-scanner.js'), if: 'Write(*package*.json)', async: true },
    { ...absHook('compliance-logger.js'), async: true }
  ]}],
  SubagentStart: [{ hooks: [absHook('subagent-start-log.js')] }],
  SubagentStop: [{ hooks: [absHook('subagent-stop-gate.js')] }],
  PreCompact: [{ hooks: [absHook('pre-compact.js')] }],
  PostCompact: [{ hooks: [absHook('post-compact.js')] }],
  Stop: [{ hooks: [absHook('stop-summary.js'), absHook('pr-gate.js')] }],
  StopFailure: [{ hooks: [absHook('stop-failure.js')] }],
  WorktreeCreate: [{ hooks: [absHook('worktree-create.js')] }],
  WorktreeRemove: [{ hooks: [absHook('worktree-remove.js')] }],
  SessionEnd: [{ hooks: [absHook('session-end.js')] }],
};

// Merge: preserve user hooks, replace orchestrator hooks (identified by hooksDir in command)
if (!settings.hooks) settings.hooks = {};
for (const [event, orchGroups] of Object.entries(orchHooks)) {
  const existing = settings.hooks[event] || [];
  const userGroups = existing.filter(group => {
    const hooks = group.hooks || [];
    return !hooks.some(h => h.command && h.command.includes(hooksDir));
  });
  settings.hooks[event] = [...userGroups, ...orchGroups];
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
MERGE_SETTINGS
    echo "Settings merged at $SETTINGS_FILE"
  else
    echo "Warning: settings merge skipped (node not found — install Node.js for full deployment)"
  fi
fi

# Write manifest
if ! $DRY_RUN; then
  # Build JSON array of deployed files
  DEPLOYED_JSON="["
  for i in "${!DEPLOYED[@]}"; do
    [ "$i" -gt 0 ] && DEPLOYED_JSON+=","
    DEPLOYED_JSON+="\"${DEPLOYED[$i]}\""
  done
  DEPLOYED_JSON+="]"

  node -e "
    const fs = require('fs');
    const manifest = { files: JSON.parse(process.argv[1]), mode: process.argv[2] };
    fs.writeFileSync(process.argv[3], JSON.stringify(manifest, null, 2) + '\n');
  " -- "$DEPLOYED_JSON" "$MODE" "$MANIFEST" 2>/dev/null || echo "Warning: manifest write failed"
fi

echo "Deployed ${#DEPLOYED[@]} files."
