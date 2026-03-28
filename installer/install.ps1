<#
.SYNOPSIS
  cc-sdlc Marketplace Installer (PowerShell)
.DESCRIPTION
  Installs selected plugins from the cc-sdlc marketplace to a Claude Code project.
.PARAMETER TargetPath
  Target project directory. Default: current directory.
.PARAMETER Plugins
  Comma-separated plugin list. Default: core,standards.
  Available: core, standards, github, jira, confluence, jama, all
.PARAMETER DryRun
  Preview what would be installed without making changes.
.EXAMPLE
  pwsh -File install.ps1 -TargetPath C:\projects\myapp
  pwsh -File install.ps1 -Plugins "core,standards,github"
  pwsh -File install.ps1 -Plugins all -DryRun
#>
[CmdletBinding()]
param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$Plugins = 'core,standards',
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Split-Path -Parent $ScriptDir

function Write-Log { param([string]$Message) Write-Host "[cc-sdlc] $Message" }
function Write-Warn { param([string]$Message) Write-Warning "[cc-sdlc] $Message" }

$PluginMap = @{
    'core'       = 'cc-sdlc-core'
    'standards'  = 'cc-sdlc-standards'
    'github'     = 'cc-github'
    'jira'       = 'cc-jira'
    'confluence' = 'cc-confluence'
    'jama'       = 'cc-jama'
}

# Resolve "all"
if ($Plugins -eq 'all') {
    $Plugins = 'core,standards,github,jira,confluence,jama'
}

$PluginList = $Plugins -split ',' | ForEach-Object { $_.Trim() }

# Validate target
if (-not (Test-Path -Path $TargetPath -PathType Container)) {
    throw "Target directory does not exist: $TargetPath"
}

Write-Log "Installing cc-sdlc plugins to: $TargetPath"
Write-Log "Plugins: $($PluginList -join ', ')"

if ($DryRun) {
    Write-Log "[DRY RUN] No files will be modified."
}

$Installed = 0

foreach ($PluginShort in $PluginList) {
    $PluginDir = $PluginMap[$PluginShort]
    if (-not $PluginDir) {
        Write-Warn "Unknown plugin: $PluginShort (skipping)"
        continue
    }

    $Src = Join-Path $RepoRoot "plugins\$PluginDir"
    if (-not (Test-Path $Src)) {
        Write-Warn "Plugin source not found: $Src (skipping)"
        continue
    }

    Write-Log "Installing $PluginDir..."

    # Copy .claude/ contents
    $ClaudeDir = Join-Path $Src '.claude'
    if (Test-Path $ClaudeDir) {
        Get-ChildItem -Path $ClaudeDir -Recurse -File | ForEach-Object {
            $RelPath = $_.FullName.Substring($Src.Length + 1)
            $DestPath = Join-Path $TargetPath $RelPath
            $DestDir = Split-Path $DestPath -Parent

            if ($DryRun) {
                Write-Host "  [copy] $RelPath"
            } else {
                if (-not (Test-Path $DestDir)) {
                    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $DestPath -Force
            }
        }
    }

    # Copy hooks
    $HooksDir = Join-Path $Src 'hooks'
    if (Test-Path $HooksDir) {
        Get-ChildItem -Path $HooksDir -Recurse -File | ForEach-Object {
            $RelPath = $_.FullName.Substring($Src.Length + 1)
            $DestPath = Join-Path $TargetPath $RelPath
            $DestDir = Split-Path $DestPath -Parent

            if ($DryRun) {
                Write-Host "  [copy] $RelPath"
            } else {
                if (-not (Test-Path $DestDir)) {
                    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $DestPath -Force
            }
        }
    }

    # Copy MCP server
    $McpDir = Join-Path $Src 'mcp'
    if (Test-Path $McpDir) {
        Get-ChildItem -Path $McpDir -Recurse -File | ForEach-Object {
            $RelPath = $_.FullName.Substring($Src.Length + 1)
            $DestPath = Join-Path $TargetPath $RelPath
            $DestDir = Split-Path $DestPath -Parent

            if ($DryRun) {
                Write-Host "  [copy] $RelPath"
            } else {
                if (-not (Test-Path $DestDir)) {
                    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $DestPath -Force
            }
        }
    }

    $Installed++
}

# Create sdlc-config.md if it doesn't exist
$ConfigFile = Join-Path $TargetPath 'sdlc-config.md'
$Template = Join-Path $RepoRoot 'installer\templates\sdlc-config.md'
if (-not (Test-Path $ConfigFile) -and (Test-Path $Template)) {
    if ($DryRun) {
        Write-Host "  [create] sdlc-config.md"
    } else {
        Copy-Item -Path $Template -Destination $ConfigFile
        Write-Log "Created sdlc-config.md - edit this to configure your project."
    }
}

# Create artifacts directory
$ArtifactsDir = Join-Path $TargetPath 'artifacts'
if (-not (Test-Path $ArtifactsDir)) {
    if ($DryRun) {
        Write-Host "  [create] artifacts/"
    } else {
        $Subdirs = @('plans', 'reviews', 'research', 'security', 'sessions', 'decisions', 'memory')
        foreach ($Sub in $Subdirs) {
            New-Item -ItemType Directory -Path (Join-Path $ArtifactsDir $Sub) -Force | Out-Null
        }
        Write-Log "Created artifacts/ directory."
    }
}

Write-Log "Done. Installed $Installed plugin(s)."
if (-not $DryRun) {
    Write-Log "Next steps:"
    Write-Log "  1. Run onboarding to configure integrations:"
    Write-Log "       pwsh -File installer/onboard.ps1 -TargetPath $TargetPath"
    Write-Log "  2. Edit sdlc-config.md to set your project profile"
    Write-Log "  3. Run 'claude --agent conductor' to start orchestrated workflow"
    Write-Log "  4. Or use /conduct for ad-hoc orchestration"
}
