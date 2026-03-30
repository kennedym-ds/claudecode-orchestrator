#!/usr/bin/env bash
# gen-skill-docs.sh — Generate AGENTS.md, CLAUDE.md, README.md from .tmpl templates
# Usage: bash scripts/gen-skill-docs.sh [--check] [--fix]
set -euo pipefail

CHECK=false
FIX=false
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=true ;;
    --fix)   FIX=true ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- Count assets ---
count_glob() { local n; n=$(find plugins -path "$1" 2>/dev/null | wc -l); echo "$n"; }

AGENT_COUNT=$(count_glob "*/.claude/agents/*.md")
SKILL_COUNT=$(count_glob "*/.claude/skills/*/SKILL.md")
COMMAND_COUNT=$(count_glob "*/.claude/commands/*.md")
HOOK_COUNT=$(count_glob "*/hooks/scripts/*.js")
PLUGIN_COUNT=$(find plugins -mindepth 1 -maxdepth 1 -type d | wc -l)
CORE_AGENT_COUNT=$(find plugins/cc-sdlc-core/.claude/agents -name '*.md' 2>/dev/null | wc -l)
CORE_SKILL_COUNT=$(find plugins/cc-sdlc-core/.claude/skills -name 'SKILL.md' 2>/dev/null | wc -l)
CORE_COMMAND_COUNT=$(find plugins/cc-sdlc-core/.claude/commands -name '*.md' 2>/dev/null | wc -l)
LANG_SKILL_COUNT=$(find plugins/cc-sdlc-standards/.claude/skills -maxdepth 1 -name '*-standards' -type d 2>/dev/null | wc -l)
DOMAIN_SKILL_COUNT=$(find plugins/cc-sdlc-standards/.claude/skills -maxdepth 1 -name '*-overlay' -type d 2>/dev/null | wc -l)
INTEG_SKILL_COUNT=$((SKILL_COUNT - CORE_SKILL_COUNT - LANG_SKILL_COUNT - DOMAIN_SKILL_COUNT))

# --- Read VERSION ---
VERSION_FILE="plugins/cc-sdlc-core/VERSION"
if [ -f "$VERSION_FILE" ]; then
  VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
  VERSION="0.0.0"
fi

echo "[gen-skill-docs] Counts: agents=$AGENT_COUNT skills=$SKILL_COUNT commands=$COMMAND_COUNT hooks=$HOOK_COUNT plugins=$PLUGIN_COUNT"
echo "[gen-skill-docs] Core: agents=$CORE_AGENT_COUNT skills=$CORE_SKILL_COUNT commands=$CORE_COMMAND_COUNT"
echo "[gen-skill-docs] Standards: lang=$LANG_SKILL_COUNT domain=$DOMAIN_SKILL_COUNT integ=$INTEG_SKILL_COUNT"
echo "[gen-skill-docs] Version: $VERSION"

# --- Replace placeholders in content ---
replace_placeholders() {
  local content="$1"
  content="${content//\{\{VERSION\}\}/$VERSION}"
  content="${content//\{\{AGENT_COUNT\}\}/$AGENT_COUNT}"
  content="${content//\{\{SKILL_COUNT\}\}/$SKILL_COUNT}"
  content="${content//\{\{COMMAND_COUNT\}\}/$COMMAND_COUNT}"
  content="${content//\{\{HOOK_COUNT\}\}/$HOOK_COUNT}"
  content="${content//\{\{PLUGIN_COUNT\}\}/$PLUGIN_COUNT}"
  content="${content//\{\{CORE_AGENT_COUNT\}\}/$CORE_AGENT_COUNT}"
  content="${content//\{\{CORE_SKILL_COUNT\}\}/$CORE_SKILL_COUNT}"
  content="${content//\{\{CORE_COMMAND_COUNT\}\}/$CORE_COMMAND_COUNT}"
  content="${content//\{\{LANG_SKILL_COUNT\}\}/$LANG_SKILL_COUNT}"
  content="${content//\{\{DOMAIN_SKILL_COUNT\}\}/$DOMAIN_SKILL_COUNT}"
  content="${content//\{\{INTEG_SKILL_COUNT\}\}/$INTEG_SKILL_COUNT}"
  printf '%s' "$content"
}

# --- Process templates ---
MISMATCHES=0

for tmpl in *.tmpl; do
  [ -f "$tmpl" ] || continue
  output_name="${tmpl%.tmpl}"
  content=$(cat "$tmpl")
  generated=$(replace_placeholders "$content")

  if $CHECK; then
    if [ -f "$output_name" ]; then
      existing=$(cat "$output_name")
      if [ "$generated" != "$existing" ]; then
        echo "[gen-skill-docs] MISMATCH: $output_name is stale"
        # Show first differing line
        diff_output=$(diff <(printf '%s\n' "$generated") <(printf '%s\n' "$existing") | head -10) || true
        echo "$diff_output"
        MISMATCHES=$((MISMATCHES + 1))
      else
        echo "[gen-skill-docs] OK: $output_name is fresh"
      fi
    else
      echo "[gen-skill-docs] MISSING: $output_name does not exist"
      MISMATCHES=$((MISMATCHES + 1))
    fi
  else
    printf '%s' "$generated" > "$output_name"
    echo "[gen-skill-docs] Generated: $output_name"
  fi
done

# --- Fix docs (optional) ---
if $FIX && ! $CHECK; then
  for doc in docs/guides/installation.md docs/guides/creating-plugins.md; do
    [ -f "$doc" ] || continue
    sed -i.bak -E \
      "s/[0-9]+ agents, [0-9]+ skills, [0-9]+ commands, [0-9]+ hooks/${CORE_AGENT_COUNT} agents, ${CORE_SKILL_COUNT} skills, ${CORE_COMMAND_COUNT} commands, ${HOOK_COUNT} hooks/g" \
      "$doc"
    rm -f "${doc}.bak"
    echo "[gen-skill-docs] Fixed: $doc"
  done
fi

if $CHECK && [ "$MISMATCHES" -gt 0 ]; then
  echo "[gen-skill-docs] $MISMATCHES file(s) have stale counts"
  exit 1
fi

exit 0
