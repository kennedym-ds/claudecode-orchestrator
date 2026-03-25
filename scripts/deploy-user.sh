#!/usr/bin/env bash
# deploy-user.sh — Deploy orchestrator assets to user-level ~/.claude/ folder
#
# Usage:
#   bash scripts/deploy-user.sh [options]
#
# Options:
#   --mode copy|symlink    Deployment mode (default: copy)
#   --dry-run              Preview changes without writing
#   --skip-hooks           Skip hook deployment
#   --skip-settings        Skip settings merge
#   --force                Overwrite without prompting
#   --uninstall            Remove deployed assets
#
# Examples:
#   bash scripts/deploy-user.sh
#   bash scripts/deploy-user.sh --mode symlink
#   bash scripts/deploy-user.sh --dry-run
#   bash scripts/deploy-user.sh --uninstall

set -euo pipefail

# --- Configuration ---
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
USER_CLAUDE="$HOME/.claude"
MANIFEST="$USER_CLAUDE/.orchestrator-manifest.json"
BACKUP_DIR="$USER_CLAUDE/.orchestrator-backup"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# --- Defaults ---
MODE="copy"
DRY_RUN=false
SKIP_HOOKS=false
SKIP_SETTINGS=false
FORCE=false
UNINSTALL=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)       MODE="$2"; shift 2 ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --skip-hooks) SKIP_HOOKS=true; shift ;;
        --skip-settings) SKIP_SETTINGS=true; shift ;;
        --force)      FORCE=true; shift ;;
        --uninstall)  UNINSTALL=true; shift ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate mode
if [[ "$MODE" != "copy" && "$MODE" != "symlink" ]]; then
    echo "Invalid mode: $MODE (use 'copy' or 'symlink')"
    exit 1
fi

# --- Logging ---
log()  { echo "[deploy] $1"; }
warn() { echo "[deploy] WARNING: $1" >&2; }
dry()  { echo "[deploy] (dry-run) $1"; }

action() {
    if $DRY_RUN; then dry "$1"; else log "$1"; fi
}

# --- Backup ---
backup_file() {
    local filepath="$1"
    if [[ -f "$filepath" ]] && ! $DRY_RUN; then
        local backup_path="$BACKUP_DIR/$TIMESTAMP"
        local rel_path="${filepath#$USER_CLAUDE/}"
        local backup_target="$backup_path/$rel_path"
        mkdir -p "$(dirname "$backup_target")"
        cp "$filepath" "$backup_target"
    fi
}

# --- Deploy directory ---
deploy_directory() {
    local src="$1"
    local dst="$2"
    local label="$3"
    local count=0

    if [[ ! -d "$src" ]]; then
        warn "Source not found: $src"
        return
    fi

    while IFS= read -r -d '' file; do
        local rel="${file#$src/}"
        local target="$dst/$rel"
        local target_dir
        target_dir="$(dirname "$target")"

        if ! $DRY_RUN; then
            mkdir -p "$target_dir"
        fi

        if [[ -f "$target" ]]; then
            backup_file "$target"
        fi

        action "  $rel"

        if ! $DRY_RUN; then
            if [[ "$MODE" == "symlink" ]]; then
                ln -sf "$file" "$target"
            else
                cp "$file" "$target"
            fi
        fi

        DEPLOYED_FILES+=("$target")
        ((count++)) || true
    done < <(find "$src" -type f -print0)

    action "$label: $count files ($MODE)"
}

# --- Deploy hooks ---
deploy_hooks() {
    local src="$REPO_ROOT/hooks/scripts"
    local dst="$USER_CLAUDE/hooks/scripts"

    if [[ ! -d "$src" ]]; then
        warn "Hook scripts not found: $src"
        return
    fi

    local count=0
    for file in "$src"/*.js; do
        [[ -f "$file" ]] || continue
        local name
        name="$(basename "$file")"
        local target="$dst/$name"

        if ! $DRY_RUN; then
            mkdir -p "$dst"
        fi

        if [[ -f "$target" ]]; then
            backup_file "$target"
        fi

        action "  hooks/scripts/$name"

        if ! $DRY_RUN; then
            if [[ "$MODE" == "symlink" ]]; then
                ln -sf "$file" "$target"
            else
                cp "$file" "$target"
            fi
        fi

        DEPLOYED_FILES+=("$target")
        ((count++)) || true
    done

    action "Hooks: $count script files ($MODE)"
}

# --- Merge settings ---
merge_settings() {
    local user_settings="$USER_CLAUDE/settings.json"
    local repo_settings="$REPO_ROOT/.claude/settings.json"

    if [[ ! -f "$repo_settings" ]]; then
        warn "Repo settings not found"
        return
    fi

    # Check for jq (required for JSON merge)
    if ! command -v jq &>/dev/null; then
        warn "jq not found — cannot merge settings.json"
        warn "Install jq or manually copy settings from: $repo_settings"
        return
    fi

    if [[ -f "$user_settings" ]]; then
        backup_file "$user_settings"
        action "Merging into existing user settings.json"
    else
        action "Creating new user settings.json"
    fi

    if $DRY_RUN; then
        action "Would merge env vars, permissions, and hooks into $user_settings"
        DEPLOYED_FILES+=("$user_settings")
        return
    fi

    local existing='{}'
    if [[ -f "$user_settings" ]]; then
        existing=$(cat "$user_settings")
    fi

    local repo_json
    repo_json=$(cat "$repo_settings")

    # Compute absolute hooks path
    local hooks_dir="$USER_CLAUDE/hooks/scripts"

    # Build merged JSON with jq
    local merged
    merged=$(jq -n \
        --argjson existing "$existing" \
        --argjson repo "$repo_json" \
        --arg hooks_dir "$hooks_dir" \
    '
    # Start with existing
    $existing

    # Merge env vars (repo values as defaults, existing takes precedence)
    | .env = (($repo.env // {}) + (.env // {}))

    # Merge permissions (union of arrays)
    | .permissions.allow = (
        ((.permissions.allow // []) + ($repo.permissions.allow // []))
        | unique
    )
    | .permissions.ask = (
        ((.permissions.ask // []) + ($repo.permissions.ask // []))
        | unique
    )
    | .permissions.deny = (
        ((.permissions.deny // []) + ($repo.permissions.deny // []))
        | unique
    )

    # Set model only if not already set
    | .model = (.model // $repo.model)

    # Rewrite hook paths to absolute and deploy
    | .hooks = (
        $repo.hooks
        | to_entries
        | map(
            .value = (.value | map(
                .hooks = (.hooks | map(
                    if .command then
                        .command = (.command
                            | gsub("node hooks/scripts/"; "node " + $hooks_dir + "/")
                            | gsub("bash hooks/scripts/"; "bash " + $hooks_dir + "/")
                        )
                    else . end
                ))
            ))
        )
        | from_entries
    )
    ')

    # Remove hooks if --skip-hooks
    if $SKIP_HOOKS; then
        merged=$(echo "$merged" | jq 'del(.hooks)')
    fi

    echo "$merged" | jq '.' > "$user_settings"
    action "Settings merged successfully"

    DEPLOYED_FILES+=("$user_settings")
}

# --- Uninstall ---
do_uninstall() {
    log "Uninstalling orchestrator assets from $USER_CLAUDE"

    if [[ ! -f "$MANIFEST" ]]; then
        warn "No manifest found. Nothing to uninstall."
        warn "Manual cleanup: remove agents, skills, commands, rules, hooks from $USER_CLAUDE"
        return
    fi

    local removed=0
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            if $DRY_RUN; then
                dry "  Would remove: $file"
            else
                rm -f "$file"
                ((removed++)) || true
            fi
        fi
    done < <(jq -r '.files[]' "$MANIFEST" 2>/dev/null)

    # Clean empty directories
    for subdir in agents skills commands rules hooks/scripts; do
        local dirpath="$USER_CLAUDE/$subdir"
        if [[ -d "$dirpath" ]] && [[ -z "$(ls -A "$dirpath" 2>/dev/null)" ]]; then
            if ! $DRY_RUN; then rmdir "$dirpath" 2>/dev/null || true; fi
            action "  Removed empty directory: $subdir"
        fi
    done

    # Remove manifest
    if ! $DRY_RUN && [[ -f "$MANIFEST" ]]; then
        rm -f "$MANIFEST"
    fi

    log "Removed $removed files"

    # Restore settings backup
    if [[ -d "$BACKUP_DIR" ]]; then
        local latest_backup
        latest_backup=$(ls -1d "$BACKUP_DIR"/*/ 2>/dev/null | sort -r | head -1)
        if [[ -n "$latest_backup" && -f "$latest_backup/settings.json" ]]; then
            if ! $DRY_RUN; then
                cp "$latest_backup/settings.json" "$USER_CLAUDE/settings.json"
            fi
            log "Restored settings.json from backup"
        fi
    fi

    log "Uninstall complete. Backups preserved in $BACKUP_DIR"
}

# ============================================================
# Main
# ============================================================

log "Claude Code Orchestrator — User Deployment"
log "Repository: $REPO_ROOT"
log "Target:     $USER_CLAUDE"
log "Mode:       $MODE"
if $DRY_RUN; then warn "DRY RUN — no files will be modified"; fi
echo ""

if $UNINSTALL; then
    do_uninstall
    exit 0
fi

# Verify repo structure
if [[ ! -d "$REPO_ROOT/.claude/agents" ]]; then
    echo "[deploy] ERROR: Not a valid orchestrator repo: $REPO_ROOT" >&2
    exit 1
fi

# Create user .claude directory
if ! $DRY_RUN; then
    mkdir -p "$USER_CLAUDE"
fi

# Track deployed files
DEPLOYED_FILES=()

# Deploy asset groups
log "Deploying agents..."
deploy_directory "$REPO_ROOT/.claude/agents" "$USER_CLAUDE/agents" "Agents"

echo ""
log "Deploying skills..."
deploy_directory "$REPO_ROOT/.claude/skills" "$USER_CLAUDE/skills" "Skills"

echo ""
log "Deploying commands..."
deploy_directory "$REPO_ROOT/.claude/commands" "$USER_CLAUDE/commands" "Commands"

echo ""
log "Deploying rules..."
deploy_directory "$REPO_ROOT/.claude/rules" "$USER_CLAUDE/rules" "Rules"

if ! $SKIP_HOOKS; then
    echo ""
    log "Deploying hooks..."
    deploy_hooks
fi

if ! $SKIP_SETTINGS; then
    echo ""
    log "Merging settings..."
    merge_settings
fi

# Save deployment manifest
if ! $DRY_RUN; then
    # Build manifest JSON
    files_json=$(printf '%s\n' "${DEPLOYED_FILES[@]}" | jq -R . | jq -s .)
    jq -n \
        --arg version "1.0" \
        --arg deployedAt "$TIMESTAMP" \
        --arg mode "$MODE" \
        --arg repoRoot "$REPO_ROOT" \
        --argjson files "$files_json" \
        '{version: $version, deployedAt: $deployedAt, mode: $mode, repoRoot: $repoRoot, files: $files}' \
        > "$MANIFEST"
fi

# Summary
echo ""
log "Deployment complete!"
log "  Deployed: ${#DEPLOYED_FILES[@]} files"
log "  Manifest: $MANIFEST"
if ! $DRY_RUN && [[ -d "$BACKUP_DIR" ]]; then
    log "  Backups:  $BACKUP_DIR/$TIMESTAMP"
fi
echo ""
log "Verify with:"
log "  claude --agent conductor 'Hello, verify agents and hooks are loaded'"
echo ""
if [[ "$MODE" == "copy" ]]; then
    log "Note: Re-run this script after updating the orchestrator repo to sync changes."
else
    log "Note: Symlinks auto-update when repo files change. Re-run only for new files."
fi
