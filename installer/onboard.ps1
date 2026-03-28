<#
.SYNOPSIS
  cc-sdlc Interactive Onboarding — configure integrations and API keys.
.DESCRIPTION
  Walks the user through setting up credentials for GitHub, Jira, Confluence,
  and Jama integrations. Writes env vars to .claude/settings.json (project)
  or ~/.claude/settings.json (user). All steps are skippable.
.PARAMETER TargetPath
  Target project directory. Default: current directory.
.PARAMETER Scope
  Where to write credentials. 'project' (default) or 'user'.
.PARAMETER NonInteractive
  Skip prompts and only validate existing configuration.
.EXAMPLE
  pwsh -File onboard.ps1
  pwsh -File onboard.ps1 -TargetPath C:\projects\myapp -Scope user
#>
[CmdletBinding()]
param(
    [string]$TargetPath = (Get-Location).Path,
    [ValidateSet('project', 'user')]
    [string]$Scope = 'project',
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Write-Banner {
    Write-Host ''
    Write-Host '  ==============================================' -ForegroundColor Cyan
    Write-Host '   cc-sdlc Interactive Onboarding' -ForegroundColor Cyan
    Write-Host '   Configure integrations and API keys' -ForegroundColor Cyan
    Write-Host '  ==============================================' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Section {
    param([string]$Title, [string]$Desc)
    Write-Host ''
    Write-Host "  -- $Title --" -ForegroundColor Yellow
    Write-Host "  $Desc" -ForegroundColor DarkGray
    Write-Host ''
}

function Write-Status {
    param([string]$Label, [string]$Status)
    if ($Status -eq 'configured') {
        Write-Host "  [OK] $Label" -ForegroundColor Green
    }
    elseif ($Status -eq 'skipped') {
        Write-Host "  [SKIP] $Label" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  [FAIL] $Label (missing)" -ForegroundColor Red
    }
}

function Read-SecurePrompt {
    param([string]$Prompt, [string]$Default = '')
    Write-Host "  $Prompt" -NoNewline -ForegroundColor White
    if ($Default) {
        Write-Host " [$Default]" -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ': ' -NoNewline
    $value = Read-Host
    if ([string]::IsNullOrWhiteSpace($value) -and $Default) {
        return $Default
    }
    return $value.Trim()
}

function Read-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    $hint = if ($Default) { 'Y/n' } else { 'y/N' }
    Write-Host "  $Prompt [$hint]: " -NoNewline -ForegroundColor White
    $answer = Read-Host
    if ([string]::IsNullOrWhiteSpace($answer)) {
        return $Default
    }
    return $answer.Trim().ToLower().StartsWith('y')
}

function Get-SettingsPath {
    if ($Scope -eq 'user') {
        $dir = Join-Path $env:USERPROFILE '.claude'
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        return (Join-Path $dir 'settings.json')
    }
    else {
        $dir = Join-Path $TargetPath '.claude'
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        return (Join-Path $dir 'settings.json')
    }
}

function ConvertTo-Hashtable {
    param($InputObject)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = @{}
        foreach ($key in $InputObject.Keys) {
            $hash[$key] = ConvertTo-Hashtable -InputObject ($InputObject[$key])
        }
        return $hash
    }

    if ($InputObject -is [pscustomobject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $hash
    }

    if ($InputObject -is [System.Array]) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ,(ConvertTo-Hashtable -InputObject $item)
        }
        return $items
    }

    return $InputObject
}

function Read-Settings {
    param([string]$Path)

    if (Test-Path $Path) {
        try {
            $rawSettings = Get-Content -Path $Path -Raw
            $parsedSettings = ConvertFrom-Json -InputObject $rawSettings
            $settingsHash = ConvertTo-Hashtable -InputObject $parsedSettings
            return $settingsHash
        }
        catch {
            Write-Warning "  Could not parse $Path - starting fresh."
        }
    }

    return @{}
}

function Write-Settings {
    param([hashtable]$Settings, [string]$Path)
    $json = $Settings | ConvertTo-Json -Depth 10
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

function Set-EnvVar {
    param([hashtable]$Settings, [string]$Key, [string]$Value)
    if (-not $Settings.ContainsKey('env')) {
        $Settings['env'] = @{}
    }
    $Settings['env'][$Key] = $Value
}

function Get-SettingsEnvValue {
    param(
        [hashtable]$Settings,
        [string]$Key,
        [string]$Fallback = ''
    )

    if ($Settings.ContainsKey('env')) {
        $envSettings = $Settings['env']
        if ($envSettings -is [hashtable] -or $envSettings -is [System.Collections.IDictionary]) {
            if ($envSettings.Contains($Key)) {
                return [string]$envSettings[$Key]
            }
        }
    }

    return $Fallback
}

# --- Main ---

Write-Banner

$settingsPath = Get-SettingsPath
$settings = Read-Settings -Path $settingsPath

Write-Host "  Scope: $Scope" -ForegroundColor DarkGray
Write-Host "  Settings: $settingsPath" -ForegroundColor DarkGray
Write-Host "  Target:   $TargetPath" -ForegroundColor DarkGray
Write-Host ''
Write-Host '  Each integration is optional — press Enter to skip any step.' -ForegroundColor DarkGray
Write-Host '  Credentials are stored in your Claude settings (not committed to git).' -ForegroundColor DarkGray

$results = @{}

# ────────────────────────────────────────
# GitHub
# ────────────────────────────────────────
Write-Section -Title 'GitHub Integration' -Desc 'Required for PR workflows, issue management, and CI/CD checks.'

if ($NonInteractive) {
    $ghToken = Get-SettingsEnvValue -Settings $settings -Key 'GITHUB_TOKEN' -Fallback $env:GITHUB_TOKEN
    $results['GitHub'] = if ($ghToken) { 'configured' } else { 'missing' }
}
else {
    $configGH = Read-YesNo -Prompt 'Configure GitHub?' -Default $true
    if ($configGH) {
        Write-Host ''
        Write-Host '  Create a token at: https://github.com/settings/tokens' -ForegroundColor DarkGray
        Write-Host '  Required scopes: repo, read:org, read:user' -ForegroundColor DarkGray
        Write-Host ''
        $ghToken = Read-SecurePrompt -Prompt 'GitHub Personal Access Token (PAT)'
        if ($ghToken) {
            Set-EnvVar -Settings $settings -Key 'GITHUB_TOKEN' -Value $ghToken
            $results['GitHub'] = 'configured'
        }
        else {
            $results['GitHub'] = 'skipped'
        }
    }
    else {
        $results['GitHub'] = 'skipped'
    }
}

# ────────────────────────────────────────
# Jira
# ────────────────────────────────────────
Write-Section -Title 'Jira Integration' -Desc 'Required for issue context, sprint planning, and story generation.'

if ($NonInteractive) {
    $jiraUrl = Get-SettingsEnvValue -Settings $settings -Key 'JIRA_BASE_URL' -Fallback $env:JIRA_BASE_URL
    $results['Jira'] = if ($jiraUrl) { 'configured' } else { 'missing' }
}
else {
    $configJira = Read-YesNo -Prompt 'Configure Jira?' -Default $false
    if ($configJira) {
        Write-Host ''
        Write-Host "  Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor DarkGray
        Write-Host ''
        $jiraUrl = Read-SecurePrompt -Prompt "Jira base URL (e.g., https://yourorg.atlassian.net)"
        $jiraEmail = Read-SecurePrompt -Prompt 'Jira account email'
        $jiraToken = Read-SecurePrompt -Prompt 'Jira API token'

        if ($jiraUrl -and $jiraEmail -and $jiraToken) {
            Set-EnvVar -Settings $settings -Key 'JIRA_BASE_URL' -Value $jiraUrl
            Set-EnvVar -Settings $settings -Key 'JIRA_USER_EMAIL' -Value $jiraEmail
            Set-EnvVar -Settings $settings -Key 'JIRA_API_TOKEN' -Value $jiraToken
            $results['Jira'] = 'configured'
        }
        else {
            Write-Host '  Incomplete — skipping Jira setup.' -ForegroundColor DarkYellow
            $results['Jira'] = 'skipped'
        }
    }
    else {
        $results['Jira'] = 'skipped'
    }
}

# ────────────────────────────────────────
# Confluence
# ────────────────────────────────────────
Write-Section -Title 'Confluence Integration' -Desc 'Required for publishing plans/reviews and searching knowledge base.'

if ($NonInteractive) {
    $confUrl = Get-SettingsEnvValue -Settings $settings -Key 'CONFLUENCE_BASE_URL' -Fallback $env:CONFLUENCE_BASE_URL
    $results['Confluence'] = if ($confUrl) { 'configured' } else { 'missing' }
}
else {
    $configConf = Read-YesNo -Prompt 'Configure Confluence?' -Default $false
    if ($configConf) {
        Write-Host ''
        Write-Host '  Uses the same Atlassian API token as Jira.' -ForegroundColor DarkGray
        Write-Host ''
        $confUrl = Read-SecurePrompt -Prompt "Confluence base URL (e.g., https://yourorg.atlassian.net/wiki)"
        $confEmail = Read-SecurePrompt -Prompt 'Confluence account email' -Default (Get-SettingsEnvValue -Settings $settings -Key 'CONFLUENCE_USER_EMAIL')
        $confToken = Read-SecurePrompt -Prompt 'Confluence API token' -Default (Get-SettingsEnvValue -Settings $settings -Key 'CONFLUENCE_API_TOKEN')

        if ($confUrl -and $confEmail -and $confToken) {
            Set-EnvVar -Settings $settings -Key 'CONFLUENCE_BASE_URL' -Value $confUrl
            Set-EnvVar -Settings $settings -Key 'CONFLUENCE_USER_EMAIL' -Value $confEmail
            Set-EnvVar -Settings $settings -Key 'CONFLUENCE_API_TOKEN' -Value $confToken
            $results['Confluence'] = 'configured'
        }
        else {
            Write-Host '  Incomplete — skipping Confluence setup.' -ForegroundColor DarkYellow
            $results['Confluence'] = 'skipped'
        }
    }
    else {
        $results['Confluence'] = 'skipped'
    }
}

# ────────────────────────────────────────
# Jama Connect
# ────────────────────────────────────────
Write-Section -Title 'Jama Connect Integration' -Desc 'Required for requirements tracing and test coverage mapping.'

if ($NonInteractive) {
    $jamaUrl = Get-SettingsEnvValue -Settings $settings -Key 'JAMA_BASE_URL' -Fallback $env:JAMA_BASE_URL
    $results['Jama'] = if ($jamaUrl) { 'configured' } else { 'missing' }
}
else {
    $configJama = Read-YesNo -Prompt 'Configure Jama Connect?' -Default $false
    if ($configJama) {
        Write-Host ''
        Write-Host '  Uses OAuth 2.0 client credentials (client_id + client_secret).' -ForegroundColor DarkGray
        Write-Host '  Get these from your Jama admin under API Keys.' -ForegroundColor DarkGray
        Write-Host ''
        $jamaUrl = Read-SecurePrompt -Prompt "Jama base URL (e.g., https://yourorg.jamacloud.com)"
        $jamaId = Read-SecurePrompt -Prompt 'Jama client ID'
        $jamaSecret = Read-SecurePrompt -Prompt 'Jama client secret'

        if ($jamaUrl -and $jamaId -and $jamaSecret) {
            Set-EnvVar -Settings $settings -Key 'JAMA_BASE_URL' -Value $jamaUrl
            Set-EnvVar -Settings $settings -Key 'JAMA_CLIENT_ID' -Value $jamaId
            Set-EnvVar -Settings $settings -Key 'JAMA_CLIENT_SECRET' -Value $jamaSecret
            $results['Jama'] = 'configured'
        }
        else {
            Write-Host '  Incomplete — skipping Jama setup.' -ForegroundColor DarkYellow
            $results['Jama'] = 'skipped'
        }
    }
    else {
        $results['Jama'] = 'skipped'
    }
}

# ────────────────────────────────────────
# Model Configuration
# ────────────────────────────────────────
Write-Section -Title 'Model Configuration' -Desc 'Set default AI model tiers for the orchestrator.'

if ($NonInteractive) {
    $hasModels = Get-SettingsEnvValue -Settings $settings -Key 'ORCH_MODEL_DEFAULT'
    $results['Models'] = if ($hasModels) { 'configured' } else { 'missing' }
}
else {
    $configModels = Read-YesNo -Prompt 'Configure model tiers? (defaults are recommended)' -Default $false
    if ($configModels) {
        Write-Host ''
        Write-Host '  Profiles: standard (recommended), budget (cost-saving), premium (max quality)' -ForegroundColor DarkGray
        Write-Host ''
        $selectedModelTier = Read-SecurePrompt -Prompt 'Profile [standard/budget/premium]' -Default 'standard'

        switch ($selectedModelTier.ToLower()) {
            'budget' {
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_HEAVY' -Value 'claude-sonnet-4-6-20260320'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_DEFAULT' -Value 'claude-haiku-4-5-20250315'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_FAST' -Value 'claude-haiku-4-5-20250315'
            }
            'premium' {
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_HEAVY' -Value 'claude-opus-4-6-20260320'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_DEFAULT' -Value 'claude-opus-4-6-20260320'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_FAST' -Value 'claude-sonnet-4-6-20260320'
            }
            default {
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_HEAVY' -Value 'claude-opus-4-6-20260320'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_DEFAULT' -Value 'claude-sonnet-4-6-20260320'
                Set-EnvVar -Settings $settings -Key 'ORCH_MODEL_FAST' -Value 'claude-haiku-4-5-20250315'
            }
        }
        $results['Models'] = 'configured'
    }
    else {
        $results['Models'] = 'skipped'
    }
}

# ────────────────────────────────────────
# Save settings
# ────────────────────────────────────────
$anyConfigured = $results.Values -contains 'configured'
$shouldWriteSettings = -not $NonInteractive -and $anyConfigured
if ($shouldWriteSettings) {
    Write-Settings -Settings $settings -Path $settingsPath
}

# ────────────────────────────────────────
# Summary
# ────────────────────────────────────────
Write-Host ''
Write-Host '  -- Summary --' -ForegroundColor Yellow
Write-Host ''

foreach ($key in @('GitHub', 'Jira', 'Confluence', 'Jama', 'Models')) {
    $status = $results[$key]
    if (-not $status) { $status = 'missing' }
    Write-Status -Label $key -Status $status
}

Write-Host ''

if ($shouldWriteSettings) {
    Write-Host "  Settings saved to: $settingsPath" -ForegroundColor Green
    Write-Host ''
}

$skippedItems = @($results.GetEnumerator() | Where-Object { $_.Value -eq 'skipped' }).Count
if ($skippedItems -gt 0) {
    Write-Host '  Skipped integrations can be configured later by re-running:' -ForegroundColor DarkGray
    Write-Host "    pwsh -File installer/onboard.ps1 -Scope $Scope" -ForegroundColor DarkGray
    Write-Host ''
}

Write-Host '  Next steps:' -ForegroundColor White
Write-Host '    1. Edit sdlc-config.md to set your project profile' -ForegroundColor DarkGray
Write-Host '    2. Run: claude --agent conductor' -ForegroundColor DarkGray
Write-Host '    3. Or use: /conduct <your task>' -ForegroundColor DarkGray
Write-Host ''
