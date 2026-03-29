#!/usr/bin/env bash
# init-artifacts.sh — Create local artifacts directory structure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="${1:-.}/artifacts"

for dir in plans reviews research security sessions decisions memory; do
  mkdir -p "$BASE/$dir"
done

# Create initial files if missing
if [ -f "$SCRIPT_DIR/../docs/templates/artifact-index.md" ] && [ ! -f "$BASE/artifact-index.md" ]; then
  cp "$SCRIPT_DIR/../docs/templates/artifact-index.md" "$BASE/artifact-index.md"
elif [ ! -f "$BASE/artifact-index.md" ]; then
  cat > "$BASE/artifact-index.md" << 'EOF'
# Artifact Index

> Session artifacts organized by type. Updated automatically by hooks and manually by agents.

## Plans

| Date | Name | Status | Path |
|------|------|--------|------|

## Reviews

| Date | Scope | Verdict | Path |
|------|-------|---------|------|

## Research

| Date | Topic | Confidence | Path |
|------|-------|------------|------|

## Security

| Date | Scope | Verdict | Path |
|------|-------|---------|------|

## Decisions

| Date | Decision | Rationale | Path |
|------|----------|-----------|------|

## Sessions

Session logs are stored in `artifacts/sessions/` as JSONL files.
EOF
fi

[ -f "$BASE/memory/activeContext.md" ] || cat > "$BASE/memory/activeContext.md" << 'EOF'
# Active Context

> Current session focus, recent decisions, and open questions.

## Current Phase
Not started

## Recent Decisions
(none)

## Open Questions
(none)
EOF

echo "Artifacts initialized at $BASE"
