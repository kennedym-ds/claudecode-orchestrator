<#
.SYNOPSIS
    Install Git pre-commit hook for cc-sdlc asset validation.
.DESCRIPTION
    Creates a pre-commit hook in .git/hooks/ that validates staged plugin assets
    (agents, skills, commands, hooks, manifests) before allowing a commit.
.PARAMETER Uninstall
    Remove the installed pre-commit hook.
.EXAMPLE
    powershell -File scripts/install-git-hooks.ps1
    powershell -File scripts/install-git-hooks.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent $ScriptDir
$GitHooksDir = Join-Path $RepoRoot '.git\hooks'
$HookTarget = Join-Path $GitHooksDir 'pre-commit'

function Write-Log { param([string]$Message) Write-Host "[git-hooks] $Message" }

if ($Uninstall) {
    if ((Test-Path $HookTarget) -and (Select-String -Path $HookTarget -Pattern 'cc-sdlc' -Quiet)) {
        Remove-Item $HookTarget -Force
        Write-Log "Removed pre-commit hook."
    } else {
        Write-Log "No cc-sdlc pre-commit hook found."
    }
    exit 0
}

# Verify git repo
if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    throw "Not a git repository: $RepoRoot"
}

if (-not (Test-Path $GitHooksDir)) {
    New-Item -ItemType Directory -Path $GitHooksDir -Force | Out-Null
}

# Check for existing hook
if (Test-Path $HookTarget) {
    if (Select-String -Path $HookTarget -Pattern 'cc-sdlc' -Quiet) {
        Write-Log "Pre-commit hook already installed. Updating..."
    } else {
        $backupPath = "$HookTarget.bak"
        Copy-Item $HookTarget $backupPath -Force
        Write-Log "Existing pre-commit hook found. Backed up to pre-commit.bak"
    }
}

# Determine which shell wrapper to create
# On Windows, create a bash wrapper that calls the PowerShell script (Git runs hooks via bash)
$preCommitScript = Join-Path $RepoRoot 'scripts\pre-commit.ps1'
$preCommitBash = Join-Path $RepoRoot 'scripts\pre-commit'

# Git for Windows invokes hooks via bash, so write a bash wrapper
$hookContent = @"
#!/usr/bin/env bash
# cc-sdlc pre-commit hook — auto-installed by scripts/install-git-hooks.ps1
# Validates plugin assets before commit. Skip with: git commit --no-verify
REPO_ROOT="`$(git rev-parse --show-toplevel)"
PS_HOOK="`$REPO_ROOT/scripts/pre-commit.ps1"
BASH_HOOK="`$REPO_ROOT/scripts/pre-commit"

# Prefer PowerShell if available, fall back to bash
if command -v powershell &>/dev/null && [ -f "`$PS_HOOK" ]; then
  exec powershell -ExecutionPolicy Bypass -File "`$PS_HOOK"
elif command -v pwsh &>/dev/null && [ -f "`$PS_HOOK" ]; then
  exec pwsh -File "`$PS_HOOK"
elif [ -f "`$BASH_HOOK" ]; then
  exec bash "`$BASH_HOOK"
else
  echo "[pre-commit] Warning: No validation script found. Skipping."
  exit 0
fi
"@

# Write hook file — must be LF line endings and no BOM for bash to parse the shebang
$hookBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($hookContent.Replace("`r`n", "`n"))
[System.IO.File]::WriteAllBytes($HookTarget, $hookBytes)

Write-Log "Pre-commit hook installed at: $HookTarget"
Write-Log "Validates: agents, skills, commands, rules, hooks, JSON manifests"
Write-Log "To uninstall: powershell -File scripts/install-git-hooks.ps1 -Uninstall"
