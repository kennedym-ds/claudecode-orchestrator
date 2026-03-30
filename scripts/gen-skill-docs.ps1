<#
.SYNOPSIS
    Generates AGENTS.md, CLAUDE.md, README.md from .tmpl templates.
.DESCRIPTION
    Counts agents, skills, commands, and hooks from plugin directories,
    then replaces {{PLACEHOLDER}} tokens in .tmpl files to produce
    the corresponding .md files. Use -Check to verify freshness without writing.
.PARAMETER Check
    Compare generated output with committed files. Exit 1 on mismatch.
.PARAMETER Fix
    Also update known count patterns in docs/guides/ files in-place.
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Fix
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Push-Location $RepoRoot

# --- Count assets ---
$AgentCount      = @(Get-ChildItem "plugins\*\.claude\agents\*.md" -ErrorAction SilentlyContinue).Count
$SkillCount      = @(Get-ChildItem "plugins\*\.claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue).Count
$CommandCount    = @(Get-ChildItem "plugins\*\.claude\commands\*.md" -ErrorAction SilentlyContinue).Count
$HookCount       = @(Get-ChildItem "plugins\*\hooks\scripts\*.js" -ErrorAction SilentlyContinue).Count
$PluginCount     = @(Get-ChildItem "plugins" -Directory -ErrorAction SilentlyContinue).Count
$CoreAgentCount  = @(Get-ChildItem "plugins\cc-sdlc-core\.claude\agents\*.md" -ErrorAction SilentlyContinue).Count
$CoreSkillCount  = @(Get-ChildItem "plugins\cc-sdlc-core\.claude\skills\*\SKILL.md" -ErrorAction SilentlyContinue).Count
$CoreCommandCount = @(Get-ChildItem "plugins\cc-sdlc-core\.claude\commands\*.md" -ErrorAction SilentlyContinue).Count
$LangSkillCount  = @(Get-ChildItem "plugins\cc-sdlc-standards\.claude\skills\*-standards\SKILL.md" -ErrorAction SilentlyContinue).Count
$DomainSkillCount = @(Get-ChildItem "plugins\cc-sdlc-standards\.claude\skills\*-overlay\SKILL.md" -ErrorAction SilentlyContinue).Count
$IntegSkillCount = $SkillCount - $CoreSkillCount - $LangSkillCount - $DomainSkillCount

# --- Read VERSION ---
$VersionFile = "plugins\cc-sdlc-core\VERSION"
if (Test-Path $VersionFile) {
    $Version = (Get-Content $VersionFile -Raw).Trim()
} else {
    $Version = "0.0.0"
}

# --- Build placeholder map ---
$placeholders = @{
    '{{VERSION}}'            = $Version
    '{{AGENT_COUNT}}'        = [string]$AgentCount
    '{{SKILL_COUNT}}'        = [string]$SkillCount
    '{{COMMAND_COUNT}}'      = [string]$CommandCount
    '{{HOOK_COUNT}}'         = [string]$HookCount
    '{{PLUGIN_COUNT}}'       = [string]$PluginCount
    '{{CORE_AGENT_COUNT}}'   = [string]$CoreAgentCount
    '{{CORE_SKILL_COUNT}}'   = [string]$CoreSkillCount
    '{{CORE_COMMAND_COUNT}}' = [string]$CoreCommandCount
    '{{LANG_SKILL_COUNT}}'   = [string]$LangSkillCount
    '{{DOMAIN_SKILL_COUNT}}' = [string]$DomainSkillCount
    '{{INTEG_SKILL_COUNT}}'  = [string]$IntegSkillCount
}

Write-Host "[gen-skill-docs] Counts: agents=$AgentCount skills=$SkillCount commands=$CommandCount hooks=$HookCount plugins=$PluginCount"
Write-Host "[gen-skill-docs] Core: agents=$CoreAgentCount skills=$CoreSkillCount commands=$CoreCommandCount"
Write-Host "[gen-skill-docs] Standards: lang=$LangSkillCount domain=$DomainSkillCount integ=$IntegSkillCount"
Write-Host "[gen-skill-docs] Version: $Version"

# --- Process templates ---
$mismatches = 0
$templates = Get-ChildItem "*.tmpl" -ErrorAction SilentlyContinue

if ($templates.Count -eq 0) {
    Write-Host "[gen-skill-docs] No .tmpl files found in repo root"
    Pop-Location
    exit 0
}

foreach ($tmpl in $templates) {
    $outputName = $tmpl.Name -replace '\.tmpl$', ''
    $outputPath = Join-Path $RepoRoot $outputName
    $content = [System.IO.File]::ReadAllText($tmpl.FullName)

    foreach ($key in $placeholders.Keys) {
        $content = $content.Replace($key, $placeholders[$key])
    }

    if ($Check) {
        if (Test-Path $outputPath) {
            $existing = [System.IO.File]::ReadAllText($outputPath)
            if ($content -ne $existing) {
                Write-Host "[gen-skill-docs] MISMATCH: $outputName is stale" -ForegroundColor Yellow
                # Show first differing line
                $genLines = $content -split "`n"
                $curLines = $existing -split "`n"
                $maxLines = [Math]::Max($genLines.Count, $curLines.Count)
                for ($i = 0; $i -lt $maxLines; $i++) {
                    $gl = if ($i -lt $genLines.Count) { $genLines[$i] } else { '' }
                    $cl = if ($i -lt $curLines.Count) { $curLines[$i] } else { '' }
                    if ($gl -ne $cl) {
                        Write-Host "  Line $($i+1):" -ForegroundColor Yellow
                        Write-Host "    expected: $($gl.Trim())" -ForegroundColor Green
                        Write-Host "    actual:   $($cl.Trim())" -ForegroundColor Red
                        break
                    }
                }
                $mismatches++
            } else {
                Write-Host "[gen-skill-docs] OK: $outputName is fresh"
            }
        } else {
            Write-Host "[gen-skill-docs] MISSING: $outputName does not exist" -ForegroundColor Yellow
            $mismatches++
        }
    } else {
        [System.IO.File]::WriteAllText($outputPath, $content)
        Write-Host "[gen-skill-docs] Generated: $outputName"
    }
}

# --- Fix docs (optional) ---
if ($Fix -and -not $Check) {
    $docFiles = @(
        "docs\guides\installation.md",
        "docs\guides\creating-plugins.md"
    )
    foreach ($docFile in $docFiles) {
        $docPath = Join-Path $RepoRoot $docFile
        if (-not (Test-Path $docPath)) { continue }
        $docContent = [System.IO.File]::ReadAllText($docPath)
        $original = $docContent

        # Replace "N agents, N skills, N commands, N hooks" patterns for cc-sdlc-core
        $docContent = $docContent -replace '\d+ agents, \d+ skills, \d+ commands, \d+ hooks', "$CoreAgentCount agents, $CoreSkillCount skills, $CoreCommandCount commands, $HookCount hooks"
        # Replace "N agents" and "N skills" standalone in architecture blocks
        $docContent = $docContent -replace '(\|\s*\*\*cc-sdlc-core\*\*\s*\|[^|]*\|)\s*\d+ agents,\s*\d+ skills,\s*\d+ commands', "`$1 $CoreAgentCount agents, $CoreSkillCount skills, $CoreCommandCount commands"

        if ($docContent -ne $original) {
            [System.IO.File]::WriteAllText($docPath, $docContent)
            Write-Host "[gen-skill-docs] Fixed: $docFile"
        }
    }
}

Pop-Location

if ($Check -and $mismatches -gt 0) {
    Write-Host "[gen-skill-docs] $mismatches file(s) have stale counts" -ForegroundColor Yellow
    exit 1
}

exit 0
