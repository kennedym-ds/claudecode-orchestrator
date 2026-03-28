#!/usr/bin/env bash
# validate-assets.sh — Validates all cc-sdlc marketplace plugin assets
# Usage: bash scripts/validate-assets.sh [--verbose]
set -euo pipefail

VERBOSE="${1:-}"
ERRORS=0
WARNINGS=0
AGENTS=0
SKILLS=0
COMMANDS=0

log() { echo "[validate] $1"; }
err() { echo "[ERROR] $1" >&2; ERRORS=$((ERRORS + 1)); }
warn() { echo "[WARN] $1" >&2; WARNINGS=$((WARNINGS + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- Marketplace ---
log "Checking marketplace..."
if [ -f .claude-plugin/marketplace.json ]; then
  if command -v node &>/dev/null; then
    if ! node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/marketplace.json','utf8'))" 2>/dev/null; then
      err "marketplace.json: invalid JSON"
    fi
  fi
else
  err ".claude-plugin/marketplace.json not found"
fi

# --- Plugin manifests ---
log "Checking plugin manifests..."
for manifest in plugins/*/.claude-plugin/plugin.json; do
  [ -f "$manifest" ] || continue
  plugin_dir=$(dirname "$(dirname "$manifest")")
  plugin_name=$(basename "$plugin_dir")
  if command -v node &>/dev/null; then
    if ! node -e "JSON.parse(require('fs').readFileSync('$manifest','utf8'))" 2>/dev/null; then
      err "Plugin $plugin_name: invalid plugin.json"
    fi
  fi
  [ -n "$VERBOSE" ] && log "  ✓ $plugin_name manifest"
done

# --- Agents (across all plugins) ---
log "Checking agents..."
for f in plugins/*/.claude/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  if ! head -1 "$f" | grep -q '^---'; then
    err "Agent $name: missing YAML frontmatter"
  fi
  for field in name description; do
    if ! grep -q "^${field}:" "$f"; then
      err "Agent $name: missing required field '$field'"
    fi
  done
  if ! grep -q '^model:' "$f"; then
    warn "Agent $name: missing 'model' field"
  fi
  if grep -Eq '^tools:[ \t]+\S.*,' "$f"; then
    warn "Agent $name: 'tools' appears to be inline format (should be YAML array)"
  fi
  AGENTS=$((AGENTS + 1))
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Skills (across all plugins) ---
log "Checking skills..."
for f in plugins/*/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  skill_dir=$(dirname "$f")
  name=$(basename "$skill_dir")
  if ! head -1 "$f" | grep -q '^---'; then
    err "Skill $name: missing YAML frontmatter"
  fi
  for field in name description; do
    if ! grep -q "^${field}:" "$f"; then
      err "Skill $name: missing required field '$field'"
    fi
  done
  SKILLS=$((SKILLS + 1))
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Commands (across all plugins) ---
log "Checking commands..."
for f in plugins/*/.claude/commands/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  if ! grep -q '\$ARGUMENTS' "$f"; then
    warn "Command $name: no \$ARGUMENTS reference (may be intentional)"
  fi
  COMMANDS=$((COMMANDS + 1))
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Rules ---
log "Checking rules..."
for f in plugins/*/.claude/rules/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  if [ ! -s "$f" ]; then
    err "Rule $name: file is empty"
  fi
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Hooks ---
log "Checking hooks..."
for hooks_json in plugins/*/hooks/hooks.json; do
  [ -f "$hooks_json" ] || continue
  plugin_dir=$(dirname "$(dirname "$hooks_json")")
  plugin_name=$(basename "$plugin_dir")
  if command -v node &>/dev/null; then
    if ! node -e "JSON.parse(require('fs').readFileSync('$hooks_json','utf8'))" 2>/dev/null; then
      err "Plugin $plugin_name: invalid hooks.json"
    fi
  fi
  [ -n "$VERBOSE" ] && log "  ✓ $plugin_name hooks.json"
done

# Check hook scripts exist
for script in plugins/*/hooks/scripts/*.js; do
  [ -f "$script" ] || continue
  if [ ! -s "$script" ]; then
    err "Hook script empty: $script"
  fi
done

# --- Installer ---
log "Checking installer..."
for f in installer/install.sh installer/install.ps1; do
  if [ ! -f "$f" ]; then
    warn "Installer missing: $f"
  fi
done
if [ ! -f installer/templates/sdlc-config.md ]; then
  warn "sdlc-config.md template missing"
fi

# --- Summary ---
echo ""
echo "=== Validation Summary ==="
echo "Agents:   $AGENTS"
echo "Skills:   $SKILLS"
echo "Commands: $COMMANDS"
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
