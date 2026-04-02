<#
.SYNOPSIS
    Deploy cc-sdlc assets to ~/.claude/ for global availability.
.PARAMETER Plugins
    Comma-separated plugin list. Default: all.
    Available: core, standards, github, jira, confluence, jama, demo, all
.PARAMETER Mode
    'copy' (default) or 'symlink'.
.PARAMETER DryRun
    Preview without deploying.
.PARAMETER Uninstall
    Remove previously deployed assets.
.EXAMPLE
    pwsh -File deploy-user.ps1
    pwsh -File deploy-user.ps1 -Plugins "core,standards,demo"
    pwsh -File deploy-user.ps1 -DryRun
    pwsh -File deploy-user.ps1 -Uninstall
#>
param(
    [string]$Plugins = 'all',
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
  delete settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL;
  delete settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL;
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

$PluginMap = @{
    'core'       = 'cc-sdlc-core'
    'standards'  = 'cc-sdlc-standards'
    'github'     = 'cc-github'
    'jira'       = 'cc-jira'
    'confluence' = 'cc-confluence'
    'jama'       = 'cc-jama'
    'demo'       = 'cc-demo'
}

if ($Plugins -eq 'all') { $Plugins = 'core,standards,github,jira,confluence,jama,demo' }
$PluginList = $Plugins -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

Write-Host "Deploying cc-sdlc assets to $Target (mode: $Mode)..."
Write-Host "Plugins: $($PluginList -join ', ')"

# Preflight: Node.js is required for settings merge (avoids PS 5.1 JSON issues)
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js is required for deployment (used for settings.json merge)." -ForegroundColor Red
    Write-Host "Install Node.js from https://nodejs.org/ and re-run." -ForegroundColor Red
    exit 1
}

$deployed = @()
$hooksTarget = Join-Path $Target 'hooks\scripts'

foreach ($PluginShort in $PluginList) {
    $PluginDir = $PluginMap[$PluginShort]
    if (-not $PluginDir) {
        Write-Warning "Unknown plugin: $PluginShort (skipping)"
        continue
    }
    $Src = Join-Path $RepoRoot "plugins\$PluginDir"
    if (-not (Test-Path $Src)) {
        Write-Warning "Plugin source not found: $Src (skipping)"
        continue
    }

    Write-Host "  Installing $PluginDir..."

    # Agents
    Get-ChildItem "$Src\.claude\agents\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $dst = Join-Path $Target "agents\$($_.Name)"
        Deploy-File -Src $_.FullName -Dst $dst
        $script:deployed += $dst
    }

    # Skills
    Get-ChildItem "$Src\.claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $skillName = $_.Directory.Name
        $dst = Join-Path $Target "skills\$skillName\SKILL.md"
        Deploy-File -Src $_.FullName -Dst $dst
        $script:deployed += $dst
    }

    # Commands
    Get-ChildItem "$Src\.claude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $dst = Join-Path $Target "commands\$($_.Name)"
        Deploy-File -Src $_.FullName -Dst $dst
        $script:deployed += $dst
    }

    # Rules
    Get-ChildItem "$Src\.claude\rules\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
        $dst = Join-Path $Target "rules\$($_.Name)"
        Deploy-File -Src $_.FullName -Dst $dst
        $script:deployed += $dst
    }

    # Hook scripts (core uses hooks/scripts/*.js; demo also has hooks but they are session-scoped)
    # Core hooks are wired into settings.json; demo hooks are copied for session-level activation only
    Get-ChildItem "$Src\hooks\scripts\*.js" -ErrorAction SilentlyContinue | ForEach-Object {
        $dst = Join-Path $hooksTarget $_.Name
        Deploy-File -Src $_.FullName -Dst $dst
        $script:deployed += $dst
    }

    # Presets (e.g. cc-demo replay scenarios) — copy to ~/.claude/presets/
    $presetsDir = Join-Path $Src 'presets'
    if (Test-Path $presetsDir) {
        Get-ChildItem -Path $presetsDir -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($presetsDir.Length + 1)
            $dst = Join-Path $Target "presets\$rel"
            Deploy-File -Src $_.FullName -Dst $dst
            $script:deployed += $dst
        }
    }
}

# Merge settings — backup existing, add core hooks with absolute paths
# Only runs when core plugin is included; demo hooks are session-scoped (activated by /demo command)
$settingsFile = Join-Path $Target 'settings.json'
if (-not $DryRun -and ($PluginList -contains 'core')) {
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
if (!settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL) settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL = 'claude-opus-4-6-20260320';
if (!settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL) settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL = 'claude-sonnet-4-6-20260320';
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
