#!/usr/bin/env bash
# install-git-hooks.sh — Install Git pre-commit hook for cc-sdlc asset validation
# Usage: bash scripts/install-git-hooks.sh [--uninstall]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"
HOOK_TARGET="$GIT_HOOKS_DIR/pre-commit"

log() { echo "[git-hooks] $1"; }
err() { echo "[git-hooks] ERROR: $1" >&2; exit 1; }

if [[ "${1:-}" == "--uninstall" ]]; then
  if [ -f "$HOOK_TARGET" ] && grep -q 'cc-sdlc' "$HOOK_TARGET" 2>/dev/null; then
    rm "$HOOK_TARGET"
    log "Removed pre-commit hook."
  else
    log "No cc-sdlc pre-commit hook found."
  fi
  exit 0
fi

# Verify we're in a git repo
if [ ! -d "$REPO_ROOT/.git" ]; then
  err "Not a git repository: $REPO_ROOT"
fi

mkdir -p "$GIT_HOOKS_DIR"

# Check for existing hook
if [ -f "$HOOK_TARGET" ]; then
  if grep -q 'cc-sdlc' "$HOOK_TARGET" 2>/dev/null; then
    log "Pre-commit hook already installed. Updating..."
  else
    log "Existing pre-commit hook found. Backing up to pre-commit.bak"
    cp "$HOOK_TARGET" "$HOOK_TARGET.bak"
  fi
fi

# Create a wrapper that invokes the repo script
cat > "$HOOK_TARGET" << 'HOOKEOF'
#!/usr/bin/env bash
# cc-sdlc pre-commit hook — auto-installed by scripts/install-git-hooks.sh
# Validates plugin assets before commit. Skip with: git commit --no-verify
REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOK_SCRIPT="$REPO_ROOT/scripts/pre-commit"

if [ -f "$HOOK_SCRIPT" ]; then
  exec bash "$HOOK_SCRIPT"
else
  echo "[pre-commit] Warning: $HOOK_SCRIPT not found. Skipping validation."
  exit 0
fi
HOOKEOF

chmod +x "$HOOK_TARGET"
log "Pre-commit hook installed at: $HOOK_TARGET"
log "Validates: agents, skills, commands, rules, hooks, JSON manifests"
log "To uninstall: bash scripts/install-git-hooks.sh --uninstall"
