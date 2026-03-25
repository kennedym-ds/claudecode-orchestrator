#!/usr/bin/env bash
# install.sh — Install orchestrator to a target project
# Usage: bash scripts/install.sh [target-directory]
set -euo pipefail

TARGET="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

log() { echo "[install] $1"; }

log "Installing claudecode-orchestrator to: $TARGET"

# Create directories
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/skills"
mkdir -p "$TARGET/.claude/commands"
mkdir -p "$TARGET/.claude/rules"
mkdir -p "$TARGET/hooks/scripts"

# Copy agents
cp -r "$SCRIPT_DIR/.claude/agents/"* "$TARGET/.claude/agents/"
log "Copied 9 agents"

# Copy skills
cp -r "$SCRIPT_DIR/.claude/skills/"* "$TARGET/.claude/skills/"
log "Copied 10 skills"

# Copy commands
cp -r "$SCRIPT_DIR/.claude/commands/"* "$TARGET/.claude/commands/"
log "Copied 12 commands"

# Copy rules
cp -r "$SCRIPT_DIR/.claude/rules/"* "$TARGET/.claude/rules/"
log "Copied 6 rules"

# Copy hooks
cp "$SCRIPT_DIR/hooks/hooks.json" "$TARGET/hooks/"
cp -r "$SCRIPT_DIR/hooks/scripts/"* "$TARGET/hooks/scripts/"
log "Copied hooks configuration and 9 handler scripts"

# Copy settings (don't overwrite if exists)
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/settings.json"
  log "Copied default settings (standard profile)"
else
  log "Settings already exist — skipping (check examples/ for profiles)"
fi

# Initialize artifacts
bash "$SCRIPT_DIR/scripts/init-artifacts.sh" "$TARGET"

log "Installation complete!"
log ""
log "Next steps:"
log "  1. Review .claude/settings.json — customize model tiers"
log "  2. Copy examples/CLAUDE.md to your project root and customize"
log "  3. Run: bash scripts/validate-assets.sh"
log ""
log "Model tier profiles available in examples/:"
log "  settings-budget.json   — Haiku default (low cost)"
log "  settings-standard.json — Sonnet default (recommended)"
log "  settings-premium.json  — Opus default (max quality)"
