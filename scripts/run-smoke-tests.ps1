<#
.SYNOPSIS
    Basic smoke tests for orchestrator assets.
.DESCRIPTION
    Verifies all expected files exist without deep validation.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$pass = 0
$fail = 0

$isRepoLayout = Test-Path "plugins\cc-sdlc-core\.claude\agents"
if ($isRepoLayout) {
    $agentBase = "plugins\cc-sdlc-core\.claude\agents"
    $skillBase = "plugins\cc-sdlc-core\.claude\skills"
    $commandBase = "plugins\cc-sdlc-core\.claude\commands"
    $ruleBase = "plugins\cc-sdlc-core\.claude\rules"
    $hooksJsonPath = "plugins\cc-sdlc-core\hooks\hooks.json"
    $hookScriptBase = "plugins\cc-sdlc-core\hooks\scripts"
} else {
    $agentBase = ".claude\agents"
    $skillBase = ".claude\skills"
    $commandBase = ".claude\commands"
    $ruleBase = ".claude\rules"
    $hooksJsonPath = "hooks\hooks.json"
    $hookScriptBase = "hooks\scripts"
}

function Test-Pass { param([string]$Name) Write-Host "  + $Name" -ForegroundColor Green; $script:pass++ }
function Test-Fail { param([string]$Name) Write-Host "  - $Name" -ForegroundColor Red; $script:fail++ }

Write-Host "=== Smoke Tests ==="

# Agents
Write-Host "Agents:"
foreach ($agent in @('conductor','planner','implementer','reviewer','researcher','security-reviewer','tdd-guide','red-team','doc-updater')) {
    if (Test-Path (Join-Path $agentBase "$agent.md")) { Test-Pass $agent }
    else { Test-Fail "$agent - missing" }
}

# Skills
Write-Host "Skills:"
foreach ($skill in @('tdd-workflow','security-review','coding-standards','plan-workflow','review-workflow','delegation-routing','budget-gatekeeper','strategic-compact','verification-loop','session-continuity')) {
    if (Test-Path (Join-Path (Join-Path $skillBase $skill) 'SKILL.md')) { Test-Pass $skill }
    else { Test-Fail "$skill - missing SKILL.md" }
}

# Commands
Write-Host "Commands:"
foreach ($cmd in @('conduct','plan','implement','review','research','secure','test','deploy-check','doc','red-team','audit','route','status','compact')) {
    if (Test-Path (Join-Path $commandBase "$cmd.md")) { Test-Pass $cmd }
    else { Test-Fail "$cmd - missing" }
}

# Rules
Write-Host "Rules:"
foreach ($rule in @('persona','quality','security','lifecycle','delegation','budget')) {
    if (Test-Path (Join-Path $ruleBase "$rule.md")) { Test-Pass $rule }
    else { Test-Fail "$rule - missing" }
}

# Hooks
Write-Host "Hooks:"
if (Test-Path $hooksJsonPath) { Test-Pass "hooks.json exists" }
else { Test-Fail "hooks.json missing" }

foreach ($script in @('session-start','session-end','pre-compact','post-compact','pre-bash-safety','post-edit-validate','subagent-stop-gate','stop-summary','secret-detector','subagent-start-log','deploy-guard','dependency-scanner','compliance-logger','stop-failure','pr-gate','worktree-create','worktree-remove')) {
    if (Test-Path (Join-Path $hookScriptBase "$script.js")) { Test-Pass "$script.js" }
    else { Test-Fail "$script.js - missing" }
}

# Settings
Write-Host "Settings:"
if (Test-Path ".claude\settings.json") {
    Test-Pass "settings.json exists"
    $settingsContent = Get-Content ".claude\settings.json" -Raw
    if ($settingsContent -match "ORCH_MODEL_HEAVY") { Test-Pass "model tier config present" }
    else { Test-Fail "model tier config missing" }
} else {
    Test-Fail "settings.json missing"
}

# Plugins
Write-Host "Plugins:"
foreach ($plugin in @('cc-jira','cc-confluence','cc-jama')) {
    if (Test-Path "plugins\$plugin\.claude-plugin\plugin.json") { Test-Pass "$plugin plugin" }
    else { Test-Fail "$plugin plugin - missing" }
}

# Templates
Write-Host "Templates:"
foreach ($tmpl in @('plan','plan-complete','phase-complete','artifact-index')) {
    if (Test-Path "docs\templates\$tmpl.md") { Test-Pass "$tmpl.md" }
    else { Test-Fail "$tmpl.md - missing" }
}

# Summary
Write-Host ""
Write-Host "=== Results ==="
Write-Host "Passed: $pass"
Write-Host "Failed: $fail"

if ($fail -gt 0) {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host "ALL SMOKE TESTS PASSED" -ForegroundColor Green
    exit 0
}