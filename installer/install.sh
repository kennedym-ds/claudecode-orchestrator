#!/usr/bin/env bash
# cc-sdlc Marketplace Installer
# Installs selected plugins from the cc-sdlc marketplace to a Claude Code project.
# Usage: bash install.sh [--target /path/to/project] [--plugins core,standards,github]
#
# Available plugins: core, standards, github, jira, confluence, jama
# Default: core,standards

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_PLUGINS="core,standards"
TARGET_DIR=""
PLUGINS=""
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install cc-sdlc plugins to a Claude Code project.

Options:
  --target DIR       Target project directory (default: current directory)
  --plugins LIST     Comma-separated plugin list (default: core,standards)
                     Available: core, standards, github, jira, confluence, jama, all
  --dry-run          Preview what would be installed without making changes
  -h, --help         Show this help message

Examples:
  $(basename "$0") --target ~/projects/myapp
  $(basename "$0") --plugins core,standards,github
  $(basename "$0") --plugins all --dry-run
EOF
  exit 0
}

log() { echo "[cc-sdlc] $*"; }
warn() { echo "[cc-sdlc] WARNING: $*" >&2; }
err() { echo "[cc-sdlc] ERROR: $*" >&2; exit 1; }

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --plugins) PLUGINS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) err "Unknown option: $1. Use --help for usage." ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-$(pwd)}"
PLUGINS="${PLUGINS:-$DEFAULT_PLUGINS}"

# Resolve "all"
if [[ "$PLUGINS" == "all" ]]; then
  PLUGINS="core,standards,github,jira,confluence,jama"
fi

# Map short names to plugin directories (Bash 3.2 compatible — no associative arrays)
plugin_lookup() {
  case "$1" in
    core)        echo "cc-sdlc-core" ;;
    standards)   echo "cc-sdlc-standards" ;;
    github)      echo "cc-github" ;;
    jira)        echo "cc-jira" ;;
    confluence)  echo "cc-confluence" ;;
    jama)        echo "cc-jama" ;;
    *)           echo "" ;;
  esac
}

# Validate target
if [[ ! -d "$TARGET_DIR" ]]; then
  err "Target directory does not exist: $TARGET_DIR"
fi

log "Installing cc-sdlc plugins to: $TARGET_DIR"
log "Plugins: $PLUGINS"

if $DRY_RUN; then
  log "[DRY RUN] No files will be modified."
fi

IFS=',' read -ra PLUGIN_LIST <<< "$PLUGINS"

# Auto-include core dependency for integration plugins
needs_core=false
for p in "${PLUGIN_LIST[@]}"; do
  p=$(echo "$p" | tr -d ' ')
  case "$p" in
    github|jira|confluence|jama) needs_core=true ;;
  esac
done
if $needs_core; then
  has_core=false
  for p in "${PLUGIN_LIST[@]}"; do
    [ "$(echo "$p" | tr -d ' ')" = "core" ] && has_core=true
  done
  if ! $has_core; then
    log "Adding core (required dependency for integration plugins)"
    PLUGIN_LIST=("core" "${PLUGIN_LIST[@]}")
  fi
fi

INSTALLED=0

for plugin_short in "${PLUGIN_LIST[@]}"; do
  plugin_short=$(echo "$plugin_short" | tr -d ' ')
  plugin_dir=$(plugin_lookup "$plugin_short")

  if [[ -z "$plugin_dir" ]]; then
    warn "Unknown plugin: $plugin_short (skipping)"
    continue
  fi

  src="$REPO_ROOT/plugins/$plugin_dir"
  if [[ ! -d "$src" ]]; then
    warn "Plugin source not found: $src (skipping)"
    continue
  fi

  log "Installing $plugin_dir..."

  # Copy .claude-plugin/ (plugin manifest with mcpServers config)
  if [[ -d "$src/.claude-plugin" ]]; then
    find "$src/.claude-plugin" -type f | while read -r file; do
      rel="${file#$src/}"
      dest="$TARGET_DIR/$rel"
      dest_dir="$(dirname "$dest")"

      if $DRY_RUN; then
        echo "  [copy] $rel"
      else
        mkdir -p "$dest_dir"
        cp "$file" "$dest"
      fi
    done
  fi

  # Copy .claude/ contents (agents, commands, skills, rules)
  if [[ -d "$src/.claude" ]]; then
    find "$src/.claude" -type f | while read -r file; do
      rel="${file#$src/}"
      dest="$TARGET_DIR/$rel"
      dest_dir="$(dirname "$dest")"

      if $DRY_RUN; then
        echo "  [copy] $rel"
      else
        mkdir -p "$dest_dir"
        cp "$file" "$dest"
      fi
    done
  fi

  # Copy hooks
  if [[ -d "$src/hooks" ]]; then
    find "$src/hooks" -type f | while read -r file; do
      rel="${file#$src/}"
      dest="$TARGET_DIR/$rel"
      dest_dir="$(dirname "$dest")"

      if $DRY_RUN; then
        echo "  [copy] $rel"
      else
        mkdir -p "$dest_dir"
        cp "$file" "$dest"
      fi
    done
  fi

  # Copy MCP server
  if [[ -d "$src/mcp" ]]; then
    find "$src/mcp" -type f | while read -r file; do
      rel="${file#$src/}"
      dest="$TARGET_DIR/$rel"
      dest_dir="$(dirname "$dest")"

      if $DRY_RUN; then
        echo "  [copy] $rel"
      else
        mkdir -p "$dest_dir"
        cp "$file" "$dest"
      fi
    done
  fi

  INSTALLED=$((INSTALLED + 1))
done

# Create sdlc-config.md if it doesn't exist
CONFIG_FILE="$TARGET_DIR/sdlc-config.md"
if [[ ! -f "$CONFIG_FILE" ]]; then
  TEMPLATE="$REPO_ROOT/installer/templates/sdlc-config.md"
  if [[ -f "$TEMPLATE" ]]; then
    if $DRY_RUN; then
      echo "  [create] sdlc-config.md"
    else
      cp "$TEMPLATE" "$CONFIG_FILE"
      log "Created sdlc-config.md — edit this to configure your project."
    fi
  fi
fi

# Create artifacts directory
if [[ ! -d "$TARGET_DIR/artifacts" ]]; then
  if $DRY_RUN; then
    echo "  [create] artifacts/"
  else
    mkdir -p "$TARGET_DIR/artifacts/"{plans,reviews,research,security,sessions,decisions,memory}
    log "Created artifacts/ directory."
  fi
fi

log "Done. Installed $INSTALLED plugin(s)."
if ! $DRY_RUN; then
  log "Next steps:"
  log "  1. Run onboarding to configure integrations:"
  log "       bash installer/onboard.sh --target $TARGET_DIR"
  log "  2. Edit sdlc-config.md to set your project profile"
  log "  3. Run 'claude --agent conductor' to start orchestrated workflow"
  log "  4. Or use /conduct for ad-hoc orchestration"
fi
