#!/usr/bin/env bash
# init-artifacts.sh — Creates the artifacts directory structure
# Usage: bash scripts/init-artifacts.sh [target-directory]
set -euo pipefail

TARGET="${1:-.}"

log() { echo "[init-artifacts] $1"; }

log "Initializing artifacts structure in: $TARGET"

dirs=(
  "artifacts/plans"
  "artifacts/reviews"
  "artifacts/research"
  "artifacts/security"
  "artifacts/sessions"
  "artifacts/decisions"
  "artifacts/memory"
)

for dir in "${dirs[@]}"; do
  mkdir -p "$TARGET/$dir"
done

# Create activeContext.md if it doesn't exist
CONTEXT_FILE="$TARGET/artifacts/memory/activeContext.md"
if [ ! -f "$CONTEXT_FILE" ]; then
  cat > "$CONTEXT_FILE" << 'EOF'
# Active Context

## Current Task
No active task.

## Phase
Idle

## Plan Progress
0 of 0 phases

## Last 3 Decisions
(none)

## Open Questions
(none)

## Active Files
(none)

## Model Tiers Active
- Heavy: (none)
- Default: (none)
- Fast: (none)

## Next Action
Start a new task with /conduct or /plan.

## Updated
(not yet)
EOF
  log "Created activeContext.md"
fi

# Create artifact-index.md if it doesn't exist
INDEX_FILE="$TARGET/artifacts/artifact-index.md"
if [ ! -f "$INDEX_FILE" ]; then
  cat > "$INDEX_FILE" << 'EOF'
# Artifact Index

Auto-generated inventory of session artifacts.

| Date | Type | Path | Status |
|------|------|------|--------|
| (empty) | — | — | — |
EOF
  log "Created artifact-index.md"
fi

# Create .gitkeep in empty directories
for dir in "${dirs[@]}"; do
  if [ -z "$(ls -A "$TARGET/$dir" 2>/dev/null)" ]; then
    touch "$TARGET/$dir/.gitkeep"
  fi
done

log "Artifacts structure initialized."
