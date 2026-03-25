<#
.SYNOPSIS
    Creates the artifacts directory structure.
.PARAMETER TargetPath
    Path to the target project directory. Defaults to current directory.
#>
[CmdletBinding()]
param(
    [string]$TargetPath = "."
)

function Write-Log { param([string]$Message) Write-Host "[init-artifacts] $Message" }

Write-Log "Initializing artifacts structure in: $TargetPath"

$dirs = @(
    "artifacts\plans",
    "artifacts\reviews",
    "artifacts\research",
    "artifacts\security",
    "artifacts\sessions",
    "artifacts\decisions",
    "artifacts\memory"
)

foreach ($dir in $dirs) {
    $fullPath = Join-Path $TargetPath $dir
    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
}

# Create activeContext.md
$contextFile = Join-Path $TargetPath "artifacts\memory\activeContext.md"
if (-not (Test-Path $contextFile)) {
    @"
# Active Context

## Current Task
No active task.

## Phase
Idle

## Plan Progress
0 of 0 phases

## Last 3 Decisions
(none)

## Open Questions
(none)

## Active Files
(none)

## Model Tiers Active
- Heavy: (none)
- Default: (none)
- Fast: (none)

## Next Action
Start a new task with /conduct or /plan.

## Updated
(not yet)
"@ | Set-Content -Path $contextFile -Encoding UTF8
    Write-Log "Created activeContext.md"
}

# Create artifact-index.md
$indexFile = Join-Path $TargetPath "artifacts\artifact-index.md"
if (-not (Test-Path $indexFile)) {
    @"
# Artifact Index

Auto-generated inventory of session artifacts.

| Date | Type | Path | Status |
|------|------|------|--------|
| (empty) | - | - | - |
"@ | Set-Content -Path $indexFile -Encoding UTF8
    Write-Log "Created artifact-index.md"
}

Write-Log "Artifacts structure initialized."
