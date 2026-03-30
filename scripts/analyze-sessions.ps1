<#
.SYNOPSIS
    Analyze session logs and produce a usage summary.
.DESCRIPTION
    Reads JSONL files from artifacts/sessions/ and reports:
    - Session count and date range
    - Delegation counts by agent
    - File edit frequency
.PARAMETER BasePath
    Project root containing artifacts/sessions/. Defaults to current directory.
#>
param([string]$BasePath = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sessionsDir = Join-Path $BasePath 'artifacts' 'sessions'

function Read-JsonlFile {
    param([string]$FilePath)
    $results = @()
    if (-not (Test-Path $FilePath)) { return $results }
    foreach ($line in (Get-Content $FilePath -ErrorAction SilentlyContinue)) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '') { continue }
        try {
            $results += ($trimmed | ConvertFrom-Json)
        } catch {
            # Skip malformed lines
        }
    }
    return $results
}

# --- Session Data ---
$sessionLog = Read-JsonlFile (Join-Path $sessionsDir 'session-log.jsonl')
$delegationLog = Read-JsonlFile (Join-Path $sessionsDir 'delegation-log.jsonl')
$auditLog = Read-JsonlFile (Join-Path $sessionsDir 'audit-log.jsonl')

if ($sessionLog.Count -eq 0 -and $delegationLog.Count -eq 0 -and $auditLog.Count -eq 0) {
    Write-Host 'No session data found. Run some sessions first.'
    exit 0
}

# --- Session Summary ---
$sessionStarts = @($sessionLog | Where-Object { $_.event -eq 'session_start' })
$sessionCount = $sessionStarts.Count
$dateRange = 'N/A'
if ($sessionCount -gt 0) {
    $timestamps = @($sessionStarts | ForEach-Object { $_.timestamp })
    $sorted = $timestamps | Sort-Object
    $first = ($sorted | Select-Object -First 1).Substring(0, 10)
    $last = ($sorted | Select-Object -Last 1).Substring(0, 10)
    if ($first -eq $last) { $dateRange = $first } else { $dateRange = "$first to $last" }
}

Write-Host ''
Write-Host '--- Session Metrics ---'
Write-Host "Sessions:    $sessionCount ($dateRange)"

# --- Delegation Summary ---
$delegationStarts = @($delegationLog | Where-Object { $_.event -eq 'subagent_start' })
$totalDelegations = $delegationStarts.Count

if ($totalDelegations -gt 0) {
    $agentCounts = @{}
    foreach ($entry in $delegationStarts) {
        $agent = if ($entry.agent) { $entry.agent } else { 'unknown' }
        if ($agentCounts.ContainsKey($agent)) {
            $agentCounts[$agent]++
        } else {
            $agentCounts[$agent] = 1
        }
    }

    $uniqueAgents = $agentCounts.Keys.Count
    Write-Host "Delegations: $totalDelegations total across $uniqueAgents agents"
    Write-Host ''
    Write-Host '--- Agent Usage ---'
    Write-Host '| Agent | Delegations | % of Total |'
    Write-Host '|-------|-------------|------------|'

    $sorted = $agentCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
    foreach ($item in $sorted) {
        $pct = [math]::Round(($item.Value / $totalDelegations) * 100, 1)
        Write-Host "| $($item.Key) | $($item.Value) | $pct% |"
    }

    # Avg delegations per session
    if ($sessionCount -gt 0) {
        $avg = [math]::Round($totalDelegations / $sessionCount, 1)
        Write-Host ''
        Write-Host "Avg delegations/session: $avg"
    }
} else {
    Write-Host 'Delegations: 0'
}

# --- File Activity ---
$totalEdits = $auditLog.Count
if ($totalEdits -gt 0) {
    $fileCounts = @{}
    foreach ($entry in $auditLog) {
        $file = if ($entry.file) { $entry.file } else { 'unknown' }
        if ($fileCounts.ContainsKey($file)) {
            $fileCounts[$file]++
        } else {
            $fileCounts[$file] = 1
        }
    }

    Write-Host ''
    Write-Host '--- Most Edited Files ---'
    Write-Host "| File | Edits |"
    Write-Host '|------|-------|'

    $sorted = $fileCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10
    foreach ($item in $sorted) {
        Write-Host "| $($item.Key) | $($item.Value) |"
    }
    Write-Host ''
    Write-Host "Total file edits: $totalEdits"
} else {
    Write-Host ''
    Write-Host 'File edits: 0'
}

Write-Host ''
