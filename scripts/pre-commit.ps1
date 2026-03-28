<#
.SYNOPSIS
    cc-sdlc Git pre-commit hook (PowerShell).
.DESCRIPTION
    Validates plugin assets (agents, skills, commands, hooks, manifests) for staged files.
    Install: powershell -File scripts/install-git-hooks.ps1
    Skip:    git commit --no-verify (emergency only)
#>
$ErrorActionPreference = 'Continue'

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { exit 0 }

# Gather staged files
$staged = git diff --cached --name-only --diff-filter=ACM
if (-not $staged) { exit 0 }

$stagedList = $staged -split "`n" | Where-Object { $_ -ne '' }

# Decide what to validate
$checkAgents   = $false
$checkSkills   = $false
$checkCommands = $false
$checkRules    = $false
$checkHooks    = $false
$checkJson     = $false

foreach ($file in $stagedList) {
    $f = $file -replace '/', '\'
    if ($f -match '^plugins\\[^\\]+\\\.claude\\agents\\.*\.md$')         { $checkAgents   = $true }
    if ($f -match '^plugins\\[^\\]+\\\.claude\\skills\\[^\\]+\\SKILL\.md$') { $checkSkills = $true }
    if ($f -match '^plugins\\[^\\]+\\\.claude\\commands\\.*\.md$')       { $checkCommands = $true }
    if ($f -match '^plugins\\[^\\]+\\\.claude\\rules\\.*\.md$')          { $checkRules    = $true }
    if ($f -match '^plugins\\[^\\]+\\hooks\\')                            { $checkHooks    = $true }
    if ($f -match '\.json$' -and ($f -match '\.claude-plugin\\' -or $f -match 'hooks\\')) { $checkJson = $true }
}

if (-not ($checkAgents -or $checkSkills -or $checkCommands -or $checkRules -or $checkHooks -or $checkJson)) {
    exit 0
}

Write-Host "[pre-commit] Validating cc-sdlc assets..."

$errors = 0

# Helper: check frontmatter and required fields
function Test-AgentOrSkill {
    param([string]$FilePath, [string]$Label)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return }
    if (-not $content.StartsWith('---')) {
        Write-Host "  ERROR: $Label $name - missing YAML frontmatter"
        $script:errors++
    }
    foreach ($field in @('name', 'description')) {
        if ($content -notmatch "(?m)^${field}:") {
            Write-Host "  ERROR: $Label $name - missing required field '$field'"
            $script:errors++
        }
    }
}

foreach ($file in $stagedList) {
    $absPath = Join-Path $RepoRoot $file
    if (-not (Test-Path $absPath)) { continue }

    $f = $file -replace '/', '\'

    # Agents
    if ($checkAgents -and $f -match '^plugins\\[^\\]+\\\.claude\\agents\\.*\.md$') {
        Test-AgentOrSkill -FilePath $absPath -Label 'Agent'
    }

    # Skills
    if ($checkSkills -and $f -match '^plugins\\[^\\]+\\\.claude\\skills\\[^\\]+\\SKILL\.md$') {
        $skillName = Split-Path (Split-Path $absPath -Parent) -Leaf
        $content = Get-Content $absPath -Raw -ErrorAction SilentlyContinue
        if ($content -and -not $content.StartsWith('---')) {
            Write-Host "  ERROR: Skill $skillName - missing YAML frontmatter"
            $errors++
        }
        foreach ($field in @('name', 'description')) {
            if ($content -and $content -notmatch "(?m)^${field}:") {
                Write-Host "  ERROR: Skill $skillName - missing required field '$field'"
                $errors++
            }
        }
    }

    # Commands
    if ($checkCommands -and $f -match '^plugins\\[^\\]+\\\.claude\\commands\\.*\.md$') {
        if ((Get-Item $absPath).Length -eq 0) {
            $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($absPath)
            Write-Host "  ERROR: Command $cmdName - file is empty"
            $errors++
        }
    }

    # Rules
    if ($checkRules -and $f -match '^plugins\\[^\\]+\\\.claude\\rules\\.*\.md$') {
        if ((Get-Item $absPath).Length -eq 0) {
            $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($absPath)
            Write-Host "  ERROR: Rule $ruleName - file is empty"
            $errors++
        }
    }

    # JSON
    if (($checkJson -or $checkHooks) -and $f -match '\.json$') {
        try {
            Get-Content $absPath -Raw | ConvertFrom-Json | Out-Null
        } catch {
            Write-Host "  ERROR: $file - invalid JSON"
            $errors++
        }
    }

    # Hook scripts
    if ($checkHooks -and $f -match '^plugins\\[^\\]+\\hooks\\scripts\\.*\.js$') {
        if ((Get-Item $absPath).Length -eq 0) {
            Write-Host "  ERROR: Hook script empty - $file"
            $errors++
        }
        # Basic syntax check if node is available
        $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
        if ($nodeCmd) {
            $result = & node --check $absPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "  ERROR: $file - JavaScript syntax error"
                $errors++
            }
        }
    }
}

if ($errors -gt 0) {
    Write-Host "[pre-commit] BLOCKED - $errors error(s) found. Fix them before committing."
    Write-Host "[pre-commit] Use 'git commit --no-verify' to bypass (emergency only)."
    exit 1
}

Write-Host "[pre-commit] All staged assets valid."
exit 0
