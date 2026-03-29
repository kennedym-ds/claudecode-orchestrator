<#
.SYNOPSIS
    Initialize the local artifacts directory structure.
#>
param([string]$BasePath = (Get-Location).Path)

$artifactsRoot = Join-Path $BasePath 'artifacts'

foreach ($dir in @('plans', 'reviews', 'research', 'security', 'sessions', 'decisions', 'memory')) {
    $path = Join-Path $artifactsRoot $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

$indexPath = Join-Path $artifactsRoot 'artifact-index.md'
if (-not (Test-Path $indexPath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $templatePath = Join-Path (Join-Path (Join-Path (Join-Path $scriptDir '..') 'docs') 'templates') 'artifact-index.md'
    if (Test-Path $templatePath) {
        Copy-Item $templatePath $indexPath
    } else {
        @"
# Artifact Index

> Session artifacts organized by type. Updated automatically by hooks and manually by agents.

## Plans

| Date | Name | Status | Path |
|------|------|--------|------|

## Reviews

| Date | Scope | Verdict | Path |
|------|-------|---------|------|

## Research

| Date | Topic | Confidence | Path |
|------|-------|------------|------|

## Security

| Date | Scope | Verdict | Path |
|------|-------|---------|------|

## Decisions

| Date | Decision | Rationale | Path |
|------|----------|-----------|------|

## Sessions

Session logs are stored in ``artifacts/sessions/`` as JSONL files.
"@ | Set-Content -Path $indexPath -Encoding UTF8
    }
}

$contextPath = Join-Path (Join-Path $artifactsRoot 'memory') 'activeContext.md'
if (-not (Test-Path $contextPath)) {
    @"
# Active Context

> Current session focus, recent decisions, and open questions.

## Current Phase
Not started

## Recent Decisions
(none)

## Open Questions
(none)
"@ | Set-Content -Path $contextPath -Encoding UTF8
}

Write-Host "Artifacts initialized at $artifactsRoot" -ForegroundColor Green
