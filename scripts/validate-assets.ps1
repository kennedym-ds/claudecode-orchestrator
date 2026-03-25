<#
.SYNOPSIS
    Validates all orchestrator assets (agents, skills, commands, rules, hooks, settings).
.DESCRIPTION
    Checks frontmatter, required fields, JSON validity, and referential integrity.
.PARAMETER Verbose
    Show passing checks in addition to errors.
#>
[CmdletBinding()]
param(
    [switch]$ShowDetails
)

$ErrorActionPreference = 'Continue'
$errors = 0
$warnings = 0

function Write-Log { param([string]$Message) Write-Host "[validate] $Message" }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red; $script:errors++ }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow; $script:warnings++ }

# --- Agents ---
Write-Log "Checking agents..."
Get-ChildItem -Path ".claude\agents\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    $content = Get-Content $_.FullName -Raw
    if (-not $content.StartsWith('---')) {
        Write-Err "Agent $name`: missing YAML frontmatter"
    }
    foreach ($field in @('name', 'description', 'model')) {
        if ($content -notmatch "(?m)^${field}:") {
            Write-Err "Agent $name`: missing required field '$field'"
        }
    }
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Skills ---
Write-Log "Checking skills..."
Get-ChildItem -Path ".claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue | ForEach-Object {
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
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Commands ---
Write-Log "Checking commands..."
Get-ChildItem -Path ".claude\commands\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch '\$ARGUMENTS') {
        Write-Warn "Command $name`: no `$ARGUMENTS reference (may be intentional)"
    }
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Rules ---
Write-Log "Checking rules..."
Get-ChildItem -Path ".claude\rules\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.BaseName
    if ($_.Length -eq 0) {
        Write-Err "Rule $name`: file is empty"
    }
    if ($ShowDetails) { Write-Log "  OK $name" }
}

# --- Hooks ---
Write-Log "Checking hooks..."
$hooksFile = "hooks\hooks.json"
if (Test-Path $hooksFile) {
    try {
        $hooksJson = Get-Content $hooksFile -Raw | ConvertFrom-Json
    } catch {
        Write-Err "hooks\hooks.json: invalid JSON - $_"
    }

    # Check referenced scripts exist
    $scriptRefs = Select-String -Path $hooksFile -Pattern '"command":\s*"node\s+([^"]+)"' -AllMatches |
        ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value }
    foreach ($ref in $scriptRefs) {
        if (-not (Test-Path $ref)) {
            Write-Err "Hook script missing: $ref"
        }
    }
} else {
    Write-Err "hooks\hooks.json not found"
}

# --- Settings ---
Write-Log "Checking settings..."
$settingsFile = ".claude\settings.json"
if (Test-Path $settingsFile) {
    try {
        Get-Content $settingsFile -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Write-Err ".claude\settings.json: invalid JSON - $_"
    }
    $settingsContent = Get-Content $settingsFile -Raw
    foreach ($var in @('ORCH_MODEL_HEAVY', 'ORCH_MODEL_DEFAULT', 'ORCH_MODEL_FAST')) {
        if ($settingsContent -notmatch $var) {
            Write-Warn "settings.json: missing env var $var"
        }
    }
} else {
    Write-Warn ".claude\settings.json not found"
}

# --- Summary ---
Write-Host ""
Write-Host "=== Validation Summary ==="
Write-Host "Errors:   $errors"
Write-Host "Warnings: $warnings"

if ($errors -gt 0) {
    Write-Host "RESULT: FAIL" -ForegroundColor Red
    exit 1
} else {
    Write-Host "RESULT: PASS" -ForegroundColor Green
    exit 0
}
