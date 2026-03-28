---
name: vba-standards
description: VBA coding standards with severity-tiered rules. Use when writing, reviewing, or generating VBA code for Excel, Access, or test automation.
---

# VBA Standards

## ERROR (mandatory)
- Use `Option Explicit` in every module — no implicit variable declarations
- Declare all variables with explicit types — no untyped `Dim x`
- Never use `On Error Resume Next` without restoring error handling within 5 lines
- Release all object references (`Set obj = Nothing`) when no longer needed
- No hardcoded file paths — use configuration cells, environment variables, or constants
- Validate all external data (file reads, worksheet ranges) before processing

## WARNING (recommended)
- Use meaningful names: `ByRef rngTestData As Range` not `ByRef r As Range`
- Prefix variables by scope: `m_` (module), `g_` (global), no prefix (local)
- Use `Long` instead of `Integer` (no 16-bit overflow risk on modern systems)
- Use `With...End With` blocks to reduce repeated object references
- Maximum procedure length: 50 lines (excluding declarations and comments)
- Use `Enum` for related constants — no magic numbers
- Use early binding (`Dim wb As Workbook`) over late binding where possible

## RECOMMENDATION (optional)
- Use class modules for encapsulation of test equipment interfaces
- Implement `ITestable` interface pattern for mockable hardware abstraction
- Use `Collection` or `Dictionary` over arrays for dynamic data
- Consider `Scripting.FileSystemObject` over VBA file I/O for reliability
- Use `Application.ScreenUpdating = False` / `Application.Calculation = xlCalculationManual` for performance

## Test Automation Specific
- Separate test logic from hardware communication
- Use status enums: `TestPassed`, `TestFailed`, `TestAborted`, `TestSkipped`
- Log all test steps with timestamps to traceable output
- Implement timeout protection for hardware communication
- Use configuration worksheets for test parameters — not hardcoded values
