<#
.SYNOPSIS
    Deploy orchestrator assets to user-level ~/.claude/ folder.
.DESCRIPTION
    Copies or symlinks agents, skills, commands, rules, and hooks to the
    user's ~/.claude/ directory so they are available in all Claude Code
    projects. Settings are merged (not overwritten).
.PARAMETER Mode
    Copy or Symlink. Copy is portable; Symlink auto-updates but needs
    elevated privileges on Windows.
.PARAMETER DryRun
    Preview what would change without writing anything.
.PARAMETER SkipHooks
    Skip hook script deployment and settings hook entries.
.PARAMETER SkipSettings
    Skip settings.json merge entirely.
.PARAMETER Force
    Overwrite existing files without prompting.
.PARAMETER Uninstall
    Remove previously deployed orchestrator assets.
.EXAMPLE
    pwsh -File scripts/deploy-user.ps1
    pwsh -File scripts/deploy-user.ps1 -Mode Symlink
    pwsh -File scripts/deploy-user.ps1 -DryRun
    pwsh -File scripts/deploy-user.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [ValidateSet('Copy', 'Symlink')]
    [string]$Mode = 'Copy',
    [switch]$DryRun,
    [switch]$SkipHooks,
    [switch]$SkipSettings,
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$UserClaude = Join-Path $env:USERPROFILE ".claude"
$ManifestFile = Join-Path $UserClaude ".orchestrator-manifest.json"
$BackupDir = Join-Path $UserClaude ".orchestrator-backup"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# --- Logging ---
function Write-Log { param([string]$Message, [string]$Level = 'INFO')
    $prefix = switch ($Level) {
        'INFO'  { '[deploy]' }
        'WARN'  { '[deploy] WARNING:' }
        'ERROR' { '[deploy] ERROR:' }
        'DRY'   { '[deploy] (dry-run)' }
    }
    if ($Level -eq 'ERROR') { Write-Error "$prefix $Message" }
    elseif ($Level -eq 'WARN') { Write-Warning "$prefix $Message" }
    else { Write-Host "$prefix $Message" }
}

function Write-Action { param([string]$Message)
    if ($DryRun) { Write-Log $Message -Level 'DRY' }
    else { Write-Log $Message }
}

# --- Manifest tracking ---
# Tracks which files were deployed so Uninstall knows what to remove
function Get-Manifest {
    if (Test-Path $ManifestFile) {
        return (Get-Content $ManifestFile -Raw | ConvertFrom-Json)
    }
    return @{ version = '1.0'; deployedAt = ''; mode = ''; files = @(); repoRoot = '' }
}

function Save-Manifest { param($Manifest)
    if (-not $DryRun) {
        $Manifest | ConvertTo-Json -Depth 10 | Set-Content $ManifestFile -Encoding UTF8
    }
}

# --- Backup ---
function Backup-File { param([string]$Path)
    if ((Test-Path $Path) -and -not $DryRun) {
        $backupPath = Join-Path $BackupDir $Timestamp
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        $relativePath = $Path.Replace($UserClaude, '').TrimStart('\', '/')
        $backupTarget = Join-Path $backupPath $relativePath
        $backupTargetDir = Split-Path -Parent $backupTarget
        New-Item -ItemType Directory -Path $backupTargetDir -Force | Out-Null
        Copy-Item -Path $Path -Destination $backupTarget -Force
    }
}

# --- Deploy helpers ---
function Deploy-Directory {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$Label,
        [ref]$FileList
    )

    if (-not (Test-Path $SourceDir)) {
        Write-Log "Source not found: $SourceDir" -Level 'WARN'
        return
    }

    $items = Get-ChildItem -Path $SourceDir -Recurse -File
    $count = 0

    foreach ($item in $items) {
        $relativePath = $item.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
        $targetPath = Join-Path $TargetDir $relativePath
        $targetDir = Split-Path -Parent $targetPath

        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (Test-Path $targetPath) {
            Backup-File -Path $targetPath
        }

        Write-Action "  $relativePath"

        if (-not $DryRun) {
            if ($Mode -eq 'Symlink') {
                if (Test-Path $targetPath) { Remove-Item $targetPath -Force }
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $item.FullName -Force | Out-Null
            } else {
                Copy-Item -Path $item.FullName -Destination $targetPath -Force
            }
        }

        $FileList.Value += $targetPath
        $count++
    }

    Write-Action "${Label}: $count files ($Mode)"
}

function Deploy-Hooks {
    param([ref]$FileList)

    $sourceScripts = Join-Path $RepoRoot "hooks\scripts"
    $targetScripts = Join-Path $UserClaude "hooks\scripts"

    if (-not (Test-Path $sourceScripts)) {
        Write-Log "Hook scripts not found: $sourceScripts" -Level 'WARN'
        return
    }

    # Deploy hook scripts
    $items = Get-ChildItem -Path $sourceScripts -File -Filter "*.js"
    $count = 0

    foreach ($item in $items) {
        $targetPath = Join-Path $targetScripts $item.Name
        $targetDir = Split-Path -Parent $targetPath

        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (Test-Path $targetPath) {
            Backup-File -Path $targetPath
        }

        Write-Action "  hooks/scripts/$($item.Name)"

        if (-not $DryRun) {
            if ($Mode -eq 'Symlink') {
                if (Test-Path $targetPath) { Remove-Item $targetPath -Force }
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $item.FullName -Force | Out-Null
            } else {
                Copy-Item -Path $item.FullName -Destination $targetPath -Force
            }
        }

        $FileList.Value += $targetPath
        $count++
    }

    Write-Action "Hooks: $count script files ($Mode)"
}

function Get-HooksWithAbsolutePaths {
    # Read the repo's settings.json hooks and rewrite paths to absolute user-level paths
    $settingsPath = Join-Path $RepoRoot ".claude\settings.json"
    if (-not (Test-Path $settingsPath)) { return $null }

    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    if (-not $settings.hooks) { return $null }

    $hooksScriptsDir = Join-Path $UserClaude "hooks\scripts"
    # Normalize to forward slashes for cross-platform compat
    $hooksScriptsDir = $hooksScriptsDir.Replace('\', '/')

    $hooksJson = $settings.hooks | ConvertTo-Json -Depth 10
    # Rewrite relative hook paths to absolute user-level paths
    $hooksJson = $hooksJson -replace 'node hooks/scripts/', "node $hooksScriptsDir/"
    $hooksJson = $hooksJson -replace 'bash hooks/scripts/', "bash $hooksScriptsDir/"

    return ($hooksJson | ConvertFrom-Json)
}

function Merge-Settings {
    param([ref]$FileList)

    $userSettingsPath = Join-Path $UserClaude "settings.json"
    $repoSettingsPath = Join-Path $RepoRoot ".claude\settings.json"

    if (-not (Test-Path $repoSettingsPath)) {
        Write-Log "Repo settings not found" -Level 'WARN'
        return
    }

    $repoSettings = Get-Content $repoSettingsPath -Raw | ConvertFrom-Json

    # Start with existing user settings or empty object
    if (Test-Path $userSettingsPath) {
        Backup-File -Path $userSettingsPath
        $userSettings = Get-Content $userSettingsPath -Raw | ConvertFrom-Json
        Write-Action "Merging into existing user settings.json"
    } else {
        $userSettings = [PSCustomObject]@{}
        Write-Action "Creating new user settings.json"
    }

    # --- Merge env vars ---
    if ($repoSettings.env) {
        if (-not $userSettings.env) {
            $userSettings | Add-Member -NotePropertyName 'env' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        foreach ($prop in $repoSettings.env.PSObject.Properties) {
            if (-not $userSettings.env.PSObject.Properties[$prop.Name]) {
                $userSettings.env | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
                Write-Action "  Added env: $($prop.Name)=$($prop.Value)"
            } else {
                Write-Action "  Skipped env: $($prop.Name) (already set)"
            }
        }
    }

    # --- Merge permissions ---
    if ($repoSettings.permissions) {
        if (-not $userSettings.permissions) {
            $userSettings | Add-Member -NotePropertyName 'permissions' -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        foreach ($level in @('allow', 'ask', 'deny')) {
            $repoPerms = $repoSettings.permissions.$level
            if (-not $repoPerms) { continue }

            if (-not $userSettings.permissions.$level) {
                $userSettings.permissions | Add-Member -NotePropertyName $level -NotePropertyValue @() -Force
            }

            $existing = @($userSettings.permissions.$level)
            $added = 0
            foreach ($perm in $repoPerms) {
                if ($perm -notin $existing) {
                    $existing += $perm
                    $added++
                }
            }
            $userSettings.permissions.$level = $existing
            if ($added -gt 0) {
                Write-Action "  Added $added permissions to '$level'"
            }
        }
    }

    # --- Merge model (only if not set) ---
    if ($repoSettings.model -and -not $userSettings.model) {
        $userSettings | Add-Member -NotePropertyName 'model' -NotePropertyValue $repoSettings.model -Force
        Write-Action "  Set default model: $($repoSettings.model)"
    }

    # --- Merge hooks (rewritten to absolute paths) ---
    if (-not $SkipHooks) {
        $absHooks = Get-HooksWithAbsolutePaths
        if ($absHooks) {
            $userSettings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue $absHooks -Force
            Write-Action "  Deployed hooks with absolute paths"
        }
    }

    # Write merged settings
    if (-not $DryRun) {
        $userSettings | ConvertTo-Json -Depth 20 | Set-Content $userSettingsPath -Encoding UTF8
    }

    $FileList.Value += $userSettingsPath
}

# --- Uninstall ---
function Invoke-Uninstall {
    Write-Log "Uninstalling orchestrator assets from $UserClaude"

    $manifest = Get-Manifest
    if (-not $manifest.files -or $manifest.files.Count -eq 0) {
        Write-Log "No manifest found. Nothing to uninstall." -Level 'WARN'
        Write-Log "Manual cleanup: remove agents, skills, commands, rules, hooks from $UserClaude"
        return
    }

    $removed = 0
    foreach ($file in $manifest.files) {
        if (Test-Path $file) {
            if ($DryRun) {
                Write-Action "  Would remove: $file"
            } else {
                Remove-Item $file -Force
                $removed++
            }
        }
    }

    # Clean up empty directories
    foreach ($subdir in @('agents', 'skills', 'commands', 'rules', 'hooks\scripts')) {
        $dirPath = Join-Path $UserClaude $subdir
        if ((Test-Path $dirPath) -and (Get-ChildItem $dirPath -Force | Measure-Object).Count -eq 0) {
            if (-not $DryRun) { Remove-Item $dirPath -Recurse -Force }
            Write-Action "  Removed empty directory: $subdir"
        }
    }

    # Remove manifest
    if (-not $DryRun -and (Test-Path $ManifestFile)) {
        Remove-Item $ManifestFile -Force
    }

    Write-Log "Removed $removed files"

    # Restore settings backup
    if (Test-Path $BackupDir) {
        $latestBackup = Get-ChildItem $BackupDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($latestBackup) {
            $backupSettings = Join-Path $latestBackup.FullName "settings.json"
            if (Test-Path $backupSettings) {
                $targetSettings = Join-Path $UserClaude "settings.json"
                if (-not $DryRun) {
                    Copy-Item $backupSettings -Destination $targetSettings -Force
                }
                Write-Log "Restored settings.json from backup"
            }
        }
    }

    Write-Log "Uninstall complete. Backups preserved in $BackupDir"
}

# ============================================================
# Main
# ============================================================

Write-Log "Claude Code Orchestrator - User Deployment"
Write-Log "Repository: $RepoRoot"
Write-Log "Target:     $UserClaude"
Write-Log "Mode:       $Mode"
if ($DryRun) { Write-Log "DRY RUN - no files will be modified" -Level 'WARN' }
Write-Host ""

if ($Uninstall) {
    Invoke-Uninstall
    exit 0
}

# Verify repo structure
if (-not (Test-Path (Join-Path $RepoRoot ".claude\agents"))) {
    Write-Log "Not a valid orchestrator repo: $RepoRoot" -Level 'ERROR'
    exit 1
}

# Create user .claude directory
if (-not $DryRun) {
    New-Item -ItemType Directory -Path $UserClaude -Force | Out-Null
}

# Track deployed files for manifest
[System.Collections.ArrayList]$deployedFiles = @()

# Deploy asset groups
Write-Log "Deploying agents..."
Deploy-Directory `
    -SourceDir (Join-Path $RepoRoot ".claude\agents") `
    -TargetDir (Join-Path $UserClaude "agents") `
    -Label "Agents" `
    -FileList ([ref]$deployedFiles)

Write-Host ""
Write-Log "Deploying skills..."
Deploy-Directory `
    -SourceDir (Join-Path $RepoRoot ".claude\skills") `
    -TargetDir (Join-Path $UserClaude "skills") `
    -Label "Skills" `
    -FileList ([ref]$deployedFiles)

Write-Host ""
Write-Log "Deploying commands..."
Deploy-Directory `
    -SourceDir (Join-Path $RepoRoot ".claude\commands") `
    -TargetDir (Join-Path $UserClaude "commands") `
    -Label "Commands" `
    -FileList ([ref]$deployedFiles)

Write-Host ""
Write-Log "Deploying rules..."
Deploy-Directory `
    -SourceDir (Join-Path $RepoRoot ".claude\rules") `
    -TargetDir (Join-Path $UserClaude "rules") `
    -Label "Rules" `
    -FileList ([ref]$deployedFiles)

if (-not $SkipHooks) {
    Write-Host ""
    Write-Log "Deploying hooks..."
    Deploy-Hooks -FileList ([ref]$deployedFiles)
}

if (-not $SkipSettings) {
    Write-Host ""
    Write-Log "Merging settings..."
    Merge-Settings -FileList ([ref]$deployedFiles)
}

# Save deployment manifest
$manifest = @{
    version    = '1.0'
    deployedAt = $Timestamp
    mode       = $Mode
    repoRoot   = $RepoRoot
    files      = @($deployedFiles)
}

Save-Manifest -Manifest $manifest

# Summary
Write-Host ""
Write-Log "Deployment complete!"
Write-Log "  Deployed: $($deployedFiles.Count) files"
Write-Log "  Manifest: $ManifestFile"
if (-not $DryRun -and (Test-Path $BackupDir)) {
    Write-Log "  Backups:  $BackupDir\$Timestamp"
}
Write-Host ""
Write-Log "Verify with:"
Write-Log "  claude --agent conductor 'Hello, verify agents and hooks are loaded'"
Write-Host ""
if ($Mode -eq 'Copy') {
    Write-Log "Note: Re-run this script after updating the orchestrator repo to sync changes."
} else {
    Write-Log "Note: Symlinks auto-update when repo files change. Re-run only for new files."
}
