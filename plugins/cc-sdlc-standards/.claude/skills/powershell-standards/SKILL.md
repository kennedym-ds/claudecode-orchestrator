---
name: powershell-standards
description: PowerShell coding standards with severity-tiered rules. Use when writing, reviewing, or generating PowerShell code.
---

# PowerShell Standards

## ERROR (mandatory)
- Use `Set-StrictMode -Version Latest` in scripts
- Use `[CmdletBinding()]` on all functions — enables `-Verbose`, `-Debug`, `-ErrorAction`
- Validate parameters with `[ValidateNotNullOrEmpty()]`, `[ValidateSet()]`, `[ValidateRange()]`
- Never use `Invoke-Expression` with user input
- Use `-ErrorAction Stop` with `try/catch` for error handling — not `$ErrorActionPreference` alone
- Never store credentials in scripts — use `Get-Credential`, `SecretManagement`, or environment variables

## WARNING (recommended)
- Use approved verbs from `Get-Verb` for function names
- Use `PascalCase` for function names, `camelCase` for local variables
- Use full cmdlet names — no aliases in scripts (`Get-ChildItem` not `gci`)
- Use `[OutputType()]` attribute on functions
- Maximum function length: 60 lines (excluding parameter block and help)
- Use splatting for cmdlets with 3+ parameters
- Use `Write-Verbose`/`Write-Debug` over `Write-Host` for operational messages

## RECOMMENDATION (optional)
- Use `PSScriptAnalyzer` for static analysis
- Use `classes` for complex domain objects (PowerShell 5.0+)
- Use `ForEach-Object -Parallel` for parallel processing (PowerShell 7+)
- Use `$PSDefaultParameterValues` for session defaults
- Consider Pester v5 for test infrastructure

## Testing
- Use Pester 5+ with `Describe`/`Context`/`It` blocks
- Use `Should -Invoke` for mock verification
- Use `TestDrive:` for file system tests
- Mock external cmdlets — never hit real systems in unit tests
