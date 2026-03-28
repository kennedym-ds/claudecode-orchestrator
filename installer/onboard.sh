#!/usr/bin/env bash
# cc-sdlc Interactive Onboarding
# Configures integrations and API keys for GitHub, Jira, Confluence, and Jama.
# All steps are skippable. Credentials are stored in Claude settings (not committed).
#
# Usage:
#   bash onboard.sh [--target /path/to/project] [--scope project|user] [--non-interactive]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
SCOPE="project"
NON_INTERACTIVE=false

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_DIR="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=true; shift ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--target DIR] [--scope project|user] [--non-interactive]"
      echo ""
      echo "  --target DIR           Target project directory (default: current directory)"
      echo "  --scope project|user   Where to store credentials (default: project)"
      echo "  --non-interactive      Skip prompts, only validate existing config"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

TARGET_DIR="${TARGET_DIR:-$(pwd)}"

# --- Helpers ---

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

banner() {
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║        cc-sdlc  Interactive  Onboarding      ║${NC}"
  echo -e "${CYAN}  ║    Configure integrations and API keys        ║${NC}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════════╝${NC}"
  echo ""
}

section() {
  echo ""
  echo -e "${YELLOW}  ── $1 ──${NC}"
  echo -e "${DIM}  $2${NC}"
  echo ""
}

status_ok()      { echo -e "${GREEN}  ✓ $1${NC}"; }
status_skip()    { echo -e "${DIM}  ○ $1 (skipped)${NC}"; }
status_missing() { echo -e "${RED}  ✗ $1 (missing)${NC}"; }

prompt_value() {
  local label="$1"
  local default="${2:-}"
  if [[ -n "$default" ]]; then
    echo -ne "${WHITE}  $label [$default]: ${NC}"
  else
    echo -ne "${WHITE}  $label: ${NC}"
  fi
  read -r value
  if [[ -z "$value" && -n "$default" ]]; then
    echo "$default"
  else
    echo "$value"
  fi
}

prompt_yn() {
  local label="$1"
  local default="${2:-y}"
  local hint
  if [[ "$default" == "y" ]]; then hint="Y/n"; else hint="y/N"; fi
  echo -ne "${WHITE}  $label [$hint]: ${NC}"
  read -r answer
  if [[ -z "$answer" ]]; then answer="$default"; fi
  [[ "${answer,,}" == y* ]]
}

# --- Settings file management ---

get_settings_path() {
  if [[ "$SCOPE" == "user" ]]; then
    local dir="$HOME/.claude"
    mkdir -p "$dir"
    echo "$dir/settings.json"
  else
    local dir="$TARGET_DIR/.claude"
    mkdir -p "$dir"
    echo "$dir/settings.json"
  fi
}

# Read a JSON settings file (or return empty object)
read_settings() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cat "$path"
  else
    echo '{}'
  fi
}

# Set an env var in the settings JSON
# Uses python if available, otherwise node, otherwise basic sed
set_env_var() {
  local settings_path="$1"
  local key="$2"
  local value="$3"

  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
path = sys.argv[1]
try:
    with open(path) as f: data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError): data = {}
data.setdefault('env', {})[sys.argv[2]] = sys.argv[3]
with open(path, 'w') as f: json.dump(data, f, indent=2)
" "$settings_path" "$key" "$value"
  elif command -v node &>/dev/null; then
    node -e "
const fs = require('fs');
const path = process.argv[1];
let data = {};
try { data = JSON.parse(fs.readFileSync(path, 'utf8')); } catch {}
if (!data.env) data.env = {};
data.env[process.argv[2]] = process.argv[3];
fs.writeFileSync(path, JSON.stringify(data, null, 2));
" "$settings_path" "$key" "$value"
  else
    echo "  WARNING: Neither python3 nor node found. Cannot write settings." >&2
    return 1
  fi
}

# --- Main ---

banner

SETTINGS_PATH="$(get_settings_path)"

echo -e "${DIM}  Scope:    $SCOPE${NC}"
echo -e "${DIM}  Settings: $SETTINGS_PATH${NC}"
echo -e "${DIM}  Target:   $TARGET_DIR${NC}"
echo ""
echo -e "${DIM}  Each integration is optional — press Enter to skip any step.${NC}"
echo -e "${DIM}  Credentials are stored in your Claude settings (not committed to git).${NC}"

declare -A RESULTS

# ────────────────────────────────────────
# GitHub
# ────────────────────────────────────────
section "GitHub Integration" "Required for PR workflows, issue management, and CI/CD checks."

if $NON_INTERACTIVE; then
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then RESULTS[GitHub]="configured"; else RESULTS[GitHub]="missing"; fi
elif prompt_yn "Configure GitHub?" "y"; then
  echo ""
  echo -e "${DIM}  Create a token at: https://github.com/settings/tokens${NC}"
  echo -e "${DIM}  Required scopes: repo, read:org, read:user${NC}"
  echo ""
  GH_TOKEN=$(prompt_value "GitHub Personal Access Token (PAT)")
  if [[ -n "$GH_TOKEN" ]]; then
    set_env_var "$SETTINGS_PATH" "GITHUB_TOKEN" "$GH_TOKEN"
    RESULTS[GitHub]="configured"
  else
    RESULTS[GitHub]="skipped"
  fi
else
  RESULTS[GitHub]="skipped"
fi

# ────────────────────────────────────────
# Jira
# ────────────────────────────────────────
section "Jira Integration" "Required for issue context, sprint planning, and story generation."

if $NON_INTERACTIVE; then
  if [[ -n "${JIRA_BASE_URL:-}" ]]; then RESULTS[Jira]="configured"; else RESULTS[Jira]="missing"; fi
elif prompt_yn "Configure Jira?" "n"; then
  echo ""
  echo -e "${DIM}  Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens${NC}"
  echo ""
  JIRA_URL=$(prompt_value "Jira base URL (e.g., https://yourorg.atlassian.net)")
  JIRA_EMAIL=$(prompt_value "Jira account email")
  JIRA_TOKEN=$(prompt_value "Jira API token")

  if [[ -n "$JIRA_URL" && -n "$JIRA_EMAIL" && -n "$JIRA_TOKEN" ]]; then
    set_env_var "$SETTINGS_PATH" "JIRA_BASE_URL" "$JIRA_URL"
    set_env_var "$SETTINGS_PATH" "JIRA_USER_EMAIL" "$JIRA_EMAIL"
    set_env_var "$SETTINGS_PATH" "JIRA_API_TOKEN" "$JIRA_TOKEN"
    RESULTS[Jira]="configured"
  else
    echo -e "${YELLOW}  Incomplete — skipping Jira setup.${NC}"
    RESULTS[Jira]="skipped"
  fi
else
  RESULTS[Jira]="skipped"
fi

# ────────────────────────────────────────
# Confluence
# ────────────────────────────────────────
section "Confluence Integration" "Required for publishing plans/reviews and searching knowledge base."

if $NON_INTERACTIVE; then
  if [[ -n "${CONFLUENCE_BASE_URL:-}" ]]; then RESULTS[Confluence]="configured"; else RESULTS[Confluence]="missing"; fi
elif prompt_yn "Configure Confluence?" "n"; then
  echo ""
  echo -e "${DIM}  Uses the same Atlassian API token as Jira.${NC}"
  echo ""
  CONF_URL=$(prompt_value "Confluence base URL (e.g., https://yourorg.atlassian.net/wiki)")
  CONF_EMAIL=$(prompt_value "Confluence account email" "${JIRA_EMAIL:-}")
  CONF_TOKEN=$(prompt_value "Confluence API token" "${JIRA_TOKEN:-}")

  if [[ -n "$CONF_URL" && -n "$CONF_EMAIL" && -n "$CONF_TOKEN" ]]; then
    set_env_var "$SETTINGS_PATH" "CONFLUENCE_BASE_URL" "$CONF_URL"
    set_env_var "$SETTINGS_PATH" "CONFLUENCE_USER_EMAIL" "$CONF_EMAIL"
    set_env_var "$SETTINGS_PATH" "CONFLUENCE_API_TOKEN" "$CONF_TOKEN"
    RESULTS[Confluence]="configured"
  else
    echo -e "${YELLOW}  Incomplete — skipping Confluence setup.${NC}"
    RESULTS[Confluence]="skipped"
  fi
else
  RESULTS[Confluence]="skipped"
fi

# ────────────────────────────────────────
# Jama Connect
# ────────────────────────────────────────
section "Jama Connect Integration" "Required for requirements tracing and test coverage mapping."

if $NON_INTERACTIVE; then
  if [[ -n "${JAMA_BASE_URL:-}" ]]; then RESULTS[Jama]="configured"; else RESULTS[Jama]="missing"; fi
elif prompt_yn "Configure Jama Connect?" "n"; then
  echo ""
  echo -e "${DIM}  Uses OAuth 2.0 client credentials (client_id + client_secret).${NC}"
  echo -e "${DIM}  Get these from your Jama admin under API Keys.${NC}"
  echo ""
  JAMA_URL=$(prompt_value "Jama base URL (e.g., https://yourorg.jamacloud.com)")
  JAMA_ID=$(prompt_value "Jama client ID")
  JAMA_SECRET=$(prompt_value "Jama client secret")

  if [[ -n "$JAMA_URL" && -n "$JAMA_ID" && -n "$JAMA_SECRET" ]]; then
    set_env_var "$SETTINGS_PATH" "JAMA_BASE_URL" "$JAMA_URL"
    set_env_var "$SETTINGS_PATH" "JAMA_CLIENT_ID" "$JAMA_ID"
    set_env_var "$SETTINGS_PATH" "JAMA_CLIENT_SECRET" "$JAMA_SECRET"
    RESULTS[Jama]="configured"
  else
    echo -e "${YELLOW}  Incomplete — skipping Jama setup.${NC}"
    RESULTS[Jama]="skipped"
  fi
else
  RESULTS[Jama]="skipped"
fi

# ────────────────────────────────────────
# Model Configuration
# ────────────────────────────────────────
section "Model Configuration" "Set default AI model tiers for the orchestrator."

if $NON_INTERACTIVE; then
  RESULTS[Models]="skipped"
elif prompt_yn "Configure model tiers? (defaults are recommended)" "n"; then
  echo ""
  echo -e "${DIM}  Profiles: standard (recommended), budget (cost-saving), premium (max quality)${NC}"
  echo ""
  PROFILE=$(prompt_value "Profile [standard/budget/premium]" "standard")

  case "${PROFILE,,}" in
    budget)
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_HEAVY" "claude-sonnet-4-6-20260320"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_DEFAULT" "claude-haiku-4-5-20250315"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_FAST" "claude-haiku-4-5-20250315"
      ;;
    premium)
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_HEAVY" "claude-opus-4-6-20260320"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_DEFAULT" "claude-opus-4-6-20260320"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_FAST" "claude-sonnet-4-6-20260320"
      ;;
    *)
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_HEAVY" "claude-opus-4-6-20260320"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_DEFAULT" "claude-sonnet-4-6-20260320"
      set_env_var "$SETTINGS_PATH" "ORCH_MODEL_FAST" "claude-haiku-4-5-20250315"
      ;;
  esac
  RESULTS[Models]="configured"
else
  RESULTS[Models]="skipped"
fi

# ────────────────────────────────────────
# Summary
# ────────────────────────────────────────
echo ""
echo -e "${YELLOW}  ── Summary ──${NC}"
echo ""

for key in GitHub Jira Confluence Jama Models; do
  status="${RESULTS[$key]:-missing}"
  case "$status" in
    configured) status_ok "$key" ;;
    skipped)    status_skip "$key" ;;
    *)          status_missing "$key" ;;
  esac
done

echo ""

any_configured=false
for key in "${!RESULTS[@]}"; do
  if [[ "${RESULTS[$key]}" == "configured" ]]; then any_configured=true; break; fi
done

if $any_configured; then
  echo -e "${GREEN}  Settings saved to: $SETTINGS_PATH${NC}"
  echo ""
fi

skipped=0
for key in "${!RESULTS[@]}"; do
  if [[ "${RESULTS[$key]}" == "skipped" ]]; then skipped=$((skipped + 1)); fi
done

if [[ $skipped -gt 0 ]]; then
  echo -e "${DIM}  Skipped integrations can be configured later by re-running:${NC}"
  echo -e "${DIM}    bash installer/onboard.sh --scope $SCOPE${NC}"
  echo ""
fi

echo -e "${WHITE}  Next steps:${NC}"
echo -e "${DIM}    1. Edit sdlc-config.md to set your project profile${NC}"
echo -e "${DIM}    2. Run: claude --agent conductor${NC}"
echo -e "${DIM}    3. Or use: /conduct <your task>${NC}"
echo ""
