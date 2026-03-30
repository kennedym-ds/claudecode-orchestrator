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
    [switch]$Uninstall,
    [switch]$InjectRouting
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

        # Strip orchestrator hooks and env from settings.json
        $settingsFile = Join-Path $Target 'settings.json'
        $hooksTarget = (Join-Path $Target 'hooks\scripts') -replace '\\', '/'
        if ((Test-Path $settingsFile) -and (Get-Command node -ErrorAction SilentlyContinue)) {
            $cleanScript = @'
const fs = require('fs');
const settingsPath = process.argv[2];
const hooksDir = process.argv[3];
let settings;
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8').replace(/^\uFEFF/, '')); } catch { process.exit(0); }
if (settings.hooks) {
  for (const [event, groups] of Object.entries(settings.hooks)) {
    if (!Array.isArray(groups)) continue;
    settings.hooks[event] = groups.filter(group => {
      const hooks = group.hooks || [];
      return !hooks.some(h => {
        if (!h.command) return false;
        const normalized = h.command.replace(/\\/g, '/');
        return normalized.includes(hooksDir);
      });
    });
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
}
if (settings.env) {
  delete settings.env.ORCH_MODEL_HEAVY;
  delete settings.env.ORCH_MODEL_DEFAULT;
  delete settings.env.ORCH_MODEL_FAST;
  if (Object.keys(settings.env).length === 0) delete settings.env;
}
if (Object.keys(settings).length === 0) {
  fs.unlinkSync(settingsPath);
  console.log('  Removed empty settings.json');
} else {
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
  console.log('  Cleaned orchestrator entries from settings.json');
}
'@
            $cleanScript | node - ($settingsFile -replace '\\', '/') $hooksTarget
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

    # Build hook config — merge with existing user hooks, quote paths
    # Use Node.js for JSON to avoid PowerShell 5.1 array unwrapping and UTF-8 BOM issues
    $hooksAbs = ($hooksTarget -replace '\\', '/')
    $nodeScript = @'
const fs = require('fs');
const path = require('path');
const settingsPath = process.argv[2];
const hooksDir = process.argv[3];

let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8').replace(/^\uFEFF/, '')); } catch {}

// Ensure env block with model tiers
if (!settings.env) settings.env = {};
if (!settings.env.ORCH_MODEL_HEAVY) settings.env.ORCH_MODEL_HEAVY = 'claude-opus-4-6-20260320';
if (!settings.env.ORCH_MODEL_DEFAULT) settings.env.ORCH_MODEL_DEFAULT = 'claude-sonnet-4-6-20260320';
if (!settings.env.ORCH_MODEL_FAST) settings.env.ORCH_MODEL_FAST = 'claude-haiku-4-5-20250315';

// Build hooks with absolute paths (quoted for paths with spaces)
const absHook = (script) => {
  const p = path.join(hooksDir, script).replace(/\\/g, '/');
  return { type: 'command', command: 'node "' + p + '"' };
};
const orchHooks = {
  SessionStart: [{ hooks: [{ ...absHook('session-start.js'), once: true }] }],
  UserPromptSubmit: [{ hooks: [absHook('secret-detector.js')] }],
  PreToolUse: [
    { matcher: 'Bash', hooks: [absHook('pre-bash-safety.js'), absHook('deploy-guard.js')] },
    { matcher: 'Edit|Write', hooks: [absHook('freeze-guard.js')] }
  ],
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
  SessionEnd: [{ hooks: [absHook('session-end.js')] }],
  TeammateIdle: [{ hooks: [absHook('teammate-idle.js')] }],
  TaskCreated: [{ hooks: [absHook('task-created.js')] }],
  TaskCompleted: [{ hooks: [{ ...absHook('task-completed.js'), async: true }] }]
};

// Merge: preserve user hooks, replace orchestrator hooks (identified by hooksDir in command)
if (!settings.hooks) settings.hooks = {};
for (const [event, orchGroups] of Object.entries(orchHooks)) {
  const existing = settings.hooks[event] || [];
  const userGroups = existing.filter(group => {
    const hooks = group.hooks || [];
    return !hooks.some(h => {
      if (!h.command) return false;
      const normalized = h.command.replace(/\\/g, '/');
      return normalized.includes(hooksDir);
    });
  });
  settings.hooks[event] = [...userGroups, ...orchGroups];
}

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
'@
    $nodeScript | node - ($settingsFile -replace '\\', '/') ($hooksAbs)
    Write-Host "Settings merged at $settingsFile"
}

# Write manifest (avoid BOM)
if (-not $DryRun -and $deployed.Count -gt 0) {
    $json = @{ files = $deployed; mode = $Mode } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($Manifest, $json, (New-Object System.Text.UTF8Encoding $false))
}

# Write version file
$versionSrc = Join-Path $RepoRoot 'plugins\cc-sdlc-core\VERSION'
if (Test-Path $versionSrc) {
    $versionDst = Join-Path $Target '.cc-sdlc-version'
    if ($DryRun) {
        Write-Host "[dry-run] Would write version to $versionDst"
    } else {
        Copy-Item $versionSrc $versionDst -Force
        Write-Host "Version file written to $versionDst"
    }
}

Write-Host "Deployed $($deployed.Count) files." -ForegroundColor Green

# Inject skill routing into CLAUDE.md if requested
if ($InjectRouting) {
    $claudeMd = Join-Path $Target 'CLAUDE.md'
    $routingTemplate = Join-Path $RepoRoot 'installer\templates\skill-routing.md'
    if (Test-Path $routingTemplate) {
        $routingContent = Get-Content $routingTemplate -Raw
        if (Test-Path $claudeMd) {
            $existing = Get-Content $claudeMd -Raw
            if ($existing -match '## Skill Routing') {
                Write-Host 'Skill routing section already exists in CLAUDE.md — skipping.' -ForegroundColor Yellow
            } else {
                if ($DryRun) {
                    Write-Host '[dry-run] Would append skill routing to CLAUDE.md'
                } else {
                    Add-Content -Path $claudeMd -Value "`n$routingContent"
                    Write-Host 'Appended skill routing rules to CLAUDE.md' -ForegroundColor Green
                }
            }
        } else {
            if ($DryRun) {
                Write-Host '[dry-run] Would create CLAUDE.md with skill routing'
            } else {
                Set-Content -Path $claudeMd -Value $routingContent
                Write-Host 'Created CLAUDE.md with skill routing rules' -ForegroundColor Green
            }
        }
    } else {
        Write-Host 'WARNING: skill-routing.md template not found — skipping routing injection.' -ForegroundColor Yellow
    }
}
