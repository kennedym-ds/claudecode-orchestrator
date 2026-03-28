---
name: csharp-standards
description: C# coding standards with severity-tiered rules. Use when writing, reviewing, or generating C# code.
---

# C# Standards

## ERROR (mandatory)
- Enable nullable reference types (`<Nullable>enable</Nullable>`)
- Use parameterized queries — never interpolate SQL strings
- Dispose all `IDisposable` objects — use `using` statements/declarations
- Never catch `Exception` without re-throwing or specific handling
- Async methods must have `Async` suffix and return `Task`/`ValueTask`
- No hardcoded connection strings or secrets — use configuration/Key Vault

## WARNING (recommended)
- Use records for immutable data transfer objects
- Prefer `IReadOnlyList<T>` / `IReadOnlyCollection<T>` for return types
- Use pattern matching over type checking + casting
- Use file-scoped namespaces (C# 10+)
- Use primary constructors where appropriate (C# 12+)
- Maximum method length: 40 lines
- Use `StringComparison` parameter in string comparisons

## RECOMMENDATION (optional)
- Use `Span<T>` / `Memory<T>` for high-performance array operations
- Consider `record struct` for small immutable value types
- Use `System.Text.Json` source generators for AOT-compatible serialization
- Use `IAsyncEnumerable<T>` for streaming async sequences
- Consider `Channel<T>` for producer/consumer patterns

## Testing
- Use xUnit, NUnit, or MSTest
- Use `FluentAssertions` for readable assertions
- Mock interfaces with Moq or NSubstitute — never mock concrete classes
- Use `WebApplicationFactory<T>` for integration tests
- Test naming: `MethodName_Scenario_ExpectedResult`
