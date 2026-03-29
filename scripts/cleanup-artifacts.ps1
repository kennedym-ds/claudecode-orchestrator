<#
.SYNOPSIS
    Clean old artifacts from the local artifacts directory.
.DESCRIPTION
    Removes session artifacts older than a configurable retention period.
    Keeps recent sessions and the active context file intact.
.PARAMETER BasePath
    Root of the project (default: current directory).
.PARAMETER RetentionDays
    Number of days to retain artifacts (default: 30).
.PARAMETER DryRun
    Preview what would be removed without deleting anything.
#>
param(
    [string]$BasePath = (Get-Location).Path,
    [int]$RetentionDays = 30,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$artifactsRoot = Join-Path $BasePath 'artifacts'

if (-not (Test-Path $artifactsRoot)) {
    Write-Host "No artifacts directory found at $artifactsRoot" -ForegroundColor Yellow
    exit 0
}

$removedCount = 0
$removedSize = 0

# Per-directory retention aligned with artifact-management skill
$dirRetention = @{
    'plans'    = $RetentionDays   # default 30; skill says "until project complete"
    'reviews'  = $RetentionDays   # skill: 30 days
    'research' = $RetentionDays   # skill: 30 days
    'security' = 90               # skill: 90 days
    'sessions' = 7                # skill: 7 days
}

# Files/dirs to always preserve
$preservePaths = @(
    (Join-Path $artifactsRoot 'artifact-index.md'),
    (Join-Path $artifactsRoot 'memory'),
    (Join-Path $artifactsRoot 'decisions')
)

foreach ($dir in $dirRetention.Keys) {
    $dirPath = Join-Path $artifactsRoot $dir
    if (-not (Test-Path $dirPath)) { continue }

    $cutoff = (Get-Date).AddDays(-$dirRetention[$dir])
    Get-ChildItem -Path $dirPath -Recurse -File | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | ForEach-Object {
        $removedSize += $_.Length
        $removedCount++
        if ($DryRun) {
            Write-Host "[DRY RUN] Would remove: $($_.FullName) (last modified $($_.LastWriteTime.ToString('yyyy-MM-dd')))" -ForegroundColor Cyan
        } else {
            Remove-Item -Path $_.FullName -Force
            Write-Host "Removed: $($_.FullName)" -ForegroundColor Gray
        }
    }

    # Remove empty subdirectories (bottom-up)
    if (-not $DryRun) {
        Get-ChildItem -Path $dirPath -Recurse -Directory |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { (Get-ChildItem -Path $_.FullName -Force | Measure-Object).Count -eq 0 } |
            ForEach-Object { Remove-Item -Path $_.FullName -Force }
    }
}

$sizeKB = [math]::Round($removedSize / 1KB, 1)
$verb = if ($DryRun) { 'Would remove' } else { 'Removed' }
Write-Host "$verb $removedCount file(s) ($sizeKB KB) older than $RetentionDays days." -ForegroundColor $(if ($DryRun) { 'Cyan' } else { 'Green' })
