<#
.SYNOPSIS
    Deploy cc-sdlc assets to ~/.claude/ for global availability.
.PARAMETER Mode
    'copy' (default) or 'symlink'.
.PARAMETER DryRun
    Preview without deploying.
.PARAMETER Uninstall
    Remove previously deployed assets.
#>
param(
    [ValidateSet('copy', 'symlink')]
    [string]$Mode = 'copy',
    [switch]$DryRun,
    [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$Target = Join-Path $env:USERPROFILE '.claude'
$Manifest = Join-Path $Target '.cc-sdlc-manifest.json'

function Deploy-File {
    param([string]$Src, [string]$Dst)
    $dir = Split-Path $Dst -Parent
    if ($DryRun) {
        Write-Host "[dry-run] $Src -> $Dst"
        return
    }
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if ($Mode -eq 'symlink') {
        New-Item -ItemType SymbolicLink -Path $Dst -Target $Src -Force | Out-Null
    } else {
        Copy-Item -Path $Src -Destination $Dst -Force
    }
}

if ($Uninstall) {
    if (Test-Path $Manifest) {
        Write-Host "Removing deployed cc-sdlc assets..."
        $manifest = Get-Content $Manifest -Raw | ConvertFrom-Json
        foreach ($file in $manifest.files) {
            if (Test-Path $file) {
                Remove-Item $file -Force
                Write-Host "  Removed $file"
            }
        }
        Remove-Item $Manifest -Force

        # Restore backed-up settings if available
        $backupDir = Join-Path $Target '.orchestrator-backup'
        $settingsFile = Join-Path $Target 'settings.json'
        if (Test-Path $backupDir) {
            $latestBackup = Get-ChildItem "$backupDir\settings.json.*" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestBackup -and (Test-Path $settingsFile)) {
                Copy-Item $latestBackup.FullName $settingsFile -Force
                Write-Host "  Restored settings.json from backup: $($latestBackup.Name)"
            } elseif ($latestBackup) {
                Copy-Item $latestBackup.FullName $settingsFile -Force
                Write-Host "  Restored settings.json from backup: $($latestBackup.Name)"
            }
        }

        Write-Host "Uninstall complete."
    } else {
        Write-Host "No manifest found — nothing to uninstall."
    }
    return
}

Write-Host "Deploying cc-sdlc assets to $Target (mode: $Mode)..."

# Preflight: Node.js is required for settings merge (avoids PS 5.1 JSON issues)
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js is required for deployment (used for settings.json merge)." -ForegroundColor Red
    Write-Host "Install Node.js from https://nodejs.org/ and re-run." -ForegroundColor Red
    exit 1
}

$deployed = @()

# Core agents
Get-ChildItem "$RepoRoot\plugins\cc-sdlc-core\.claude\agents\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $dst = Join-Path $Target "agents\$($_.Name)"
    Deploy-File -Src $_.FullName -Dst $dst
    $script:deployed += $dst
}

# Core skills
Get-ChildItem "$RepoRoot\plugins\cc-sdlc-core\.claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $skillName = $_.Directory.Name
    $dst = Join-Path $Target "skills\$skillName\SKILL.md"
    Deploy-File -Src $_.FullName -Dst $dst
    $script:deployed += $dst
}

# Core commands
Get-ChildItem "$RepoRoot\plugins\cc-sdlc-core\.claude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $dst = Join-Path $Target "commands\$($_.Name)"
    Deploy-File -Src $_.FullName -Dst $dst
    $script:deployed += $dst
}

# Core rules
Get-ChildItem "$RepoRoot\plugins\cc-sdlc-core\.claude\rules\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $dst = Join-Path $Target "rules\$($_.Name)"
    Deploy-File -Src $_.FullName -Dst $dst
    $script:deployed += $dst
}

# Hook scripts — deploy to ~/.claude/hooks/scripts/
$hooksTarget = Join-Path $Target 'hooks\scripts'
Get-ChildItem "$RepoRoot\plugins\cc-sdlc-core\hooks\scripts\*.js" -ErrorAction SilentlyContinue | ForEach-Object {
    $dst = Join-Path $hooksTarget $_.Name
    Deploy-File -Src $_.FullName -Dst $dst
    $script:deployed += $dst
}

# Merge settings — backup existing, add hooks with absolute paths
$settingsFile = Join-Path $Target 'settings.json'
if (-not $DryRun) {
    if (Test-Path $settingsFile) {
        $backupDir = Join-Path $Target '.orchestrator-backup'
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        Copy-Item $settingsFile (Join-Path $backupDir "settings.json.$(Get-Date -Format 'yyyyMMddHHmmss')")
    }

    $settings = @{}
    if (Test-Path $settingsFile) {
        try {
            $raw = Get-Content $settingsFile -Raw | ConvertFrom-Json
            $raw.PSObject.Properties | ForEach-Object { $settings[$_.Name] = $_.Value }
        } catch {}
    }

    # Ensure env block with model tiers
    if (-not $settings.ContainsKey('env')) { $settings['env'] = @{} }
    $env = $settings['env']
    if ($env -is [pscustomobject]) {
        $envHash = @{}
        $env.PSObject.Properties | ForEach-Object { $envHash[$_.Name] = $_.Value }
        $settings['env'] = $envHash
        $env = $envHash
    }
    if (-not $env.ContainsKey('ORCH_MODEL_HEAVY')) { $env['ORCH_MODEL_HEAVY'] = 'claude-opus-4-6-20260320' }
    if (-not $env.ContainsKey('ORCH_MODEL_DEFAULT')) { $env['ORCH_MODEL_DEFAULT'] = 'claude-sonnet-4-6-20260320' }
    if (-not $env.ContainsKey('ORCH_MODEL_FAST')) { $env['ORCH_MODEL_FAST'] = 'claude-haiku-4-5-20250315' }

    # Build hooks with absolute paths — use Node.js for JSON to avoid
    # PowerShell 5.1 single-element array unwrapping and UTF-8 BOM issues
    $hooksAbs = ($hooksTarget -replace '\\', '/')
    $existingEnvJson = ($settings['env'] | ConvertTo-Json -Compress)
    $nodeScript = @"
const fs = require('fs');
const path = require('path');
const settingsFile = process.argv[1];
const hooksDir = process.argv[2];

let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8').replace(/^\uFEFF/, '')); } catch {}

// Preserve existing env vars, add defaults
if (!settings.env) settings.env = {};
if (!settings.env.ORCH_MODEL_HEAVY) settings.env.ORCH_MODEL_HEAVY = 'claude-opus-4-6-20260320';
if (!settings.env.ORCH_MODEL_DEFAULT) settings.env.ORCH_MODEL_DEFAULT = 'claude-sonnet-4-6-20260320';
if (!settings.env.ORCH_MODEL_FAST) settings.env.ORCH_MODEL_FAST = 'claude-haiku-4-5-20250315';

// Merge any env from PowerShell layer
const psEnv = $existingEnvJson;
Object.assign(settings.env, psEnv);

const absHook = (script) => ({ type: 'command', command: 'node ' + path.join(hooksDir, script).replace(/\\\\/g, '/') });
settings.hooks = {
  SessionStart: [{ hooks: [{ ...absHook('session-start.js'), once: true }] }],
  UserPromptSubmit: [{ hooks: [absHook('secret-detector.js')] }],
  PreToolUse: [{ matcher: 'Bash', hooks: [absHook('pre-bash-safety.js'), absHook('deploy-guard.js')] }],
  PostToolUse: [{ matcher: 'Edit|Write', hooks: [
    { ...absHook('post-edit-validate.js'), async: true },
    { ...absHook('dependency-scanner.js'), if: 'Edit(*package*.json)', async: true },
    { ...absHook('dependency-scanner.js'), if: 'Write(*package*.json)', async: true },
    { ...absHook('compliance-logger.js'), async: true }
  ]}],
  SubagentStart: [{ hooks: [absHook('subagent-start-log.js')] }],
  SubagentStop: [{ hooks: [absHook('subagent-stop-gate.js')] }],
  PreCompact: [{ hooks: [absHook('pre-compact.js')] }],
  PostCompact: [{ hooks: [absHook('post-compact.js')] }],
  Stop: [{ hooks: [absHook('stop-summary.js'), absHook('pr-gate.js')] }],
  StopFailure: [{ hooks: [absHook('stop-failure.js')] }],
  WorktreeCreate: [{ hooks: [absHook('worktree-create.js')] }],
  WorktreeRemove: [{ hooks: [absHook('worktree-remove.js')] }],
  SessionEnd: [{ hooks: [absHook('session-end.js')] }]
};

fs.writeFileSync(settingsFile, JSON.stringify(settings, null, 2) + '\n');
"@
    $nodeScript | node - ($settingsFile -replace '\\', '/') ($hooksAbs)
    Write-Host "Settings merged at $settingsFile"
}

# Write manifest (avoid BOM)
if (-not $DryRun -and $deployed.Count -gt 0) {
    $json = @{ files = $deployed; mode = $Mode } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($Manifest, $json, (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "Deployed $($deployed.Count) files." -ForegroundColor Green
