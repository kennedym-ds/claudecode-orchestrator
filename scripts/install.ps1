<#
.SYNOPSIS
    Install orchestrator to a target project.
.PARAMETER TargetPath
    Path to the target project directory. Defaults to current directory.
#>
[CmdletBinding()]
param(
    [string]$TargetPath = "."
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Write-Log { param([string]$Message) Write-Host "[install] $Message" }

Write-Log "Installing claudecode-orchestrator to: $TargetPath"

# Create directories
$dirs = @(
    "$TargetPath\.claude\agents",
    "$TargetPath\.claude\skills",
    "$TargetPath\.claude\commands",
    "$TargetPath\.claude\rules",
    "$TargetPath\hooks\scripts"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Copy assets
Copy-Item -Path "$ScriptDir\.claude\agents\*" -Destination "$TargetPath\.claude\agents\" -Recurse -Force
Write-Log "Copied 9 agents"

Copy-Item -Path "$ScriptDir\.claude\skills\*" -Destination "$TargetPath\.claude\skills\" -Recurse -Force
Write-Log "Copied 10 skills"

Copy-Item -Path "$ScriptDir\.claude\commands\*" -Destination "$TargetPath\.claude\commands\" -Recurse -Force
Write-Log "Copied 12 commands"

Copy-Item -Path "$ScriptDir\.claude\rules\*" -Destination "$TargetPath\.claude\rules\" -Recurse -Force
Write-Log "Copied 6 rules"

Copy-Item -Path "$ScriptDir\hooks\hooks.json" -Destination "$TargetPath\hooks\" -Force
Copy-Item -Path "$ScriptDir\hooks\scripts\*" -Destination "$TargetPath\hooks\scripts\" -Recurse -Force
Write-Log "Copied hooks configuration and 9 handler scripts"

# Copy settings (don't overwrite)
$settingsPath = "$TargetPath\.claude\settings.json"
if (-not (Test-Path $settingsPath)) {
    Copy-Item -Path "$ScriptDir\.claude\settings.json" -Destination $settingsPath
    Write-Log "Copied default settings (standard profile)"
} else {
    Write-Log "Settings already exist - skipping (check examples/ for profiles)"
}

# Initialize artifacts
& pwsh -File "$ScriptDir\scripts\init-artifacts.ps1" -TargetPath $TargetPath

Write-Log "Installation complete!"
Write-Log ""
Write-Log "Next steps:"
Write-Log "  1. Review .claude\settings.json - customize model tiers"
Write-Log "  2. Copy examples\CLAUDE.md to your project root and customize"
Write-Log "  3. Run: pwsh -File scripts\validate-assets.ps1"
Write-Log ""
Write-Log "Model tier profiles available in examples\:"
Write-Log "  settings-budget.json   - Haiku default (low cost)"
Write-Log "  settings-standard.json - Sonnet default (recommended)"
Write-Log "  settings-premium.json  - Opus default (max quality)"
