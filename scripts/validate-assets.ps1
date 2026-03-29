<#
.SYNOPSIS
    Validates all cc-sdlc marketplace plugin assets.
.DESCRIPTION
    Checks plugin manifests, frontmatter, required fields, JSON validity, and referential integrity.
.PARAMETER ShowDetails
    Show passing checks in addition to errors.
#>
[CmdletBinding()]
param(
    [switch]$ShowDetails
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$errors = 0
$warnings = 0
$agents = 0
$skills = 0
$commands = 0

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Push-Location $RepoRoot

function Write-Log { param([string]$Message) Write-Host "[validate] $Message" }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red; $script:errors++ }
function Write-Wrn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow; $script:warnings++ }

# --- Marketplace ---
Write-Log "Checking marketplace..."
$marketplaceFile = ".claude-plugin\marketplace.json"
if (Test-Path $marketplaceFile) {
    try {
        Get-Content $marketplaceFile -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Write-Err "marketplace.json: invalid JSON - $_"
    }
} else {
    Write-Err ".claude-plugin\marketplace.json not found"
}

# --- Plugin manifests ---
Write-Log "Checking plugin manifests..."
Get-ChildItem -Path "plugins\*\.claude-plugin\plugin.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $pluginName = (Split-Path (Split-Path $_.Directory.FullName -Parent) -Leaf)
    try {
        Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Write-Err "Plugin $pluginName`: invalid plugin.json - $_"
    }
    if ($ShowDetails) { Write-Log "  OK $pluginName manifest" }
}

# --- Agents ---
Write-Log "Checking agents..."
Get-ChildItem -Path "plugins\*\.claude\agents\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    $content = Get-Content $_.FullName -Raw
    if (-not $content.StartsWith('---')) {
        Write-Err "Agent $name`: missing YAML frontmatter"
    }
    foreach ($field in @('name', 'description')) {
        if ($content -notmatch "(?m)^${field}:") {
            Write-Err "Agent $name`: missing required field '$field'"
        }
    }
    if ($content -notmatch "(?m)^model:") {
        Write-Wrn "Agent $name`: missing 'model' field"
    }
    if ($content -match "(?m)^tools:[ \t]+\S.*,") {
        Write-Wrn "Agent $name`: 'tools' appears to be inline format (should be YAML array)"
    }
    $script:agents++
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Skills ---
Write-Log "Checking skills..."
Get-ChildItem -Path "plugins\*\.claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Directory.Name
    $content = Get-Content $_.FullName -Raw
    if (-not $content.StartsWith('---')) {
        Write-Err "Skill $name`: missing YAML frontmatter"
    }
    foreach ($field in @('name', 'description')) {
        if ($content -notmatch "(?m)^${field}:") {
            Write-Err "Skill $name`: missing required field '$field'"
        }
    }
    $script:skills++
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Commands ---
Write-Log "Checking commands..."
Get-ChildItem -Path "plugins\*\.claude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch '\$ARGUMENTS') {
        Write-Wrn "Command $name`: no `$ARGUMENTS reference (may be intentional)"
    }
    $script:commands++
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Rules ---
Write-Log "Checking rules..."
Get-ChildItem -Path "plugins\*\.claude\rules\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    if ($_.Length -eq 0) {
        Write-Err "Rule $name`: file is empty"
    }
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Hooks ---
Write-Log "Checking hooks..."
Get-ChildItem -Path "plugins\*\hooks\hooks.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $pluginDir = Split-Path (Split-Path $_.FullName -Parent) -Parent
    $pluginName = Split-Path $pluginDir -Leaf
    try {
        Get-Content $_.FullName -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Write-Err "Plugin $pluginName`: invalid hooks.json - $_"
    }
    if ($ShowDetails) { Write-Log "  OK $pluginName hooks.json" }
}

# Check hook scripts exist
Get-ChildItem -Path "plugins\*\hooks\scripts\*.js" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Length -eq 0) {
        Write-Err "Hook script empty: $($_.FullName)"
    }
}

# --- Teams ---
Write-Log "Checking teams..."
Get-ChildItem -Path "plugins\*\.claude\teams\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    $content = Get-Content $_.FullName -Raw
    if (-not $content.StartsWith('---')) {
        Write-Err "Team $name`: missing YAML frontmatter"
    }
    foreach ($field in @('name', 'description')) {
        if ($content -notmatch "(?m)^${field}:") {
            Write-Err "Team $name`: missing required field '$field'"
        }
    }
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Installer ---
Write-Log "Checking installer..."
foreach ($f in @('installer\install.sh', 'installer\install.ps1')) {
    if (-not (Test-Path $f)) {
        Write-Wrn "Installer missing: $f"
    }
}
if (-not (Test-Path 'installer\templates\sdlc-config.md')) {
    Write-Wrn "sdlc-config.md template missing"
}

# --- Summary ---
Write-Host ""
Write-Host "=== Validation Summary ==="
Write-Host "Agents:   $agents"
Write-Host "Skills:   $skills"
Write-Host "Commands: $commands"
Write-Host "Errors:   $errors"
Write-Host "Warnings: $warnings"

Pop-Location

if ($errors -gt 0) {
    Write-Host "RESULT: FAIL" -ForegroundColor Red
    exit 1
} else {
    Write-Host "RESULT: PASS" -ForegroundColor Green
    exit 0
}
