#!/usr/bin/env bash
# validate-assets.sh — Validates all orchestrator assets
# Usage: bash scripts/validate-assets.sh [--verbose]
set -euo pipefail

VERBOSE="${1:-}"
ERRORS=0
WARNINGS=0

log() { echo "[validate] $1"; }
err() { echo "[ERROR] $1" >&2; ((ERRORS++)); }
warn() { echo "[WARN] $1" >&2; ((WARNINGS++)); }

# --- Agents ---
log "Checking agents..."
for f in .claude/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  # Check for required frontmatter fields
  if ! head -1 "$f" | grep -q '^---'; then
    err "Agent $name: missing YAML frontmatter"
  fi
  for field in name description model; do
    if ! grep -q "^${field}:" "$f"; then
      err "Agent $name: missing required field '$field'"
    fi
  done
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Skills ---
log "Checking skills..."
for f in .claude/skills/*/SKILL.md; do
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
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Commands ---
log "Checking commands..."
for f in .claude/commands/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  if ! grep -q '^\$ARGUMENTS' "$f" && ! grep -q '\$ARGUMENTS' "$f"; then
    warn "Command $name: no \$ARGUMENTS reference (may be intentional)"
  fi
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Rules ---
log "Checking rules..."
for f in .claude/rules/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  if [ ! -s "$f" ]; then
    err "Rule $name: file is empty"
  fi
  [ -n "$VERBOSE" ] && log "  ✓ $name"
done

# --- Hooks ---
log "Checking hooks..."
if [ -f hooks/hooks.json ]; then
  # Validate JSON syntax
  if command -v node &>/dev/null; then
    if ! node -e "JSON.parse(require('fs').readFileSync('hooks/hooks.json','utf8'))" 2>/dev/null; then
      err "hooks/hooks.json: invalid JSON"
    fi
  fi
  # Check that referenced scripts exist
  for script in $(grep -oP '"command":\s*"node\s+\K[^"]+' hooks/hooks.json 2>/dev/null || true); do
    if [ ! -f "$script" ]; then
      err "Hook script missing: $script"
    fi
  done
else
  err "hooks/hooks.json not found"
fi

# --- Settings ---
log "Checking settings..."
if [ -f .claude/settings.json ]; then
  if command -v node &>/dev/null; then
    if ! node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" 2>/dev/null; then
      err ".claude/settings.json: invalid JSON"
    fi
  fi
  # Check model tier env vars
  for var in ORCH_MODEL_HEAVY ORCH_MODEL_DEFAULT ORCH_MODEL_FAST; do
    if ! grep -q "$var" .claude/settings.json; then
      warn "settings.json: missing env var $var"
    fi
  done
else
  warn ".claude/settings.json not found"
fi

# --- Summary ---
echo ""
echo "=== Validation Summary ==="
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  echo "RESULT: FAIL"
  exit 1
else
  echo "RESULT: PASS"
  exit 0
fi
