---
name: java-standards
description: Java coding standards with severity-tiered rules. Use when writing, reviewing, or generating Java code.
---

# Java Standards

## ERROR (mandatory)
- Use try-with-resources for all `AutoCloseable` resources
- Use parameterized queries (PreparedStatement) — never string concatenation for SQL
- Never catch and swallow exceptions silently
- Use `Objects.requireNonNull()` at public API boundaries
- No mutable static fields (thread safety)
- Use `SecureRandom` for cryptographic randomness

## WARNING (recommended)
- Use records (Java 16+) for immutable data carriers
- Use sealed classes/interfaces (Java 17+) for restricted hierarchies
- Prefer `Optional<T>` over null returns for public methods
- Use `var` for local variables when the type is obvious
- Maximum method length: 40 lines
- Use `Stream` API over manual iteration for collection transforms
- Use `switch` expressions (Java 14+) over if-else chains

## RECOMMENDATION (optional)
- Use virtual threads (Java 21+) for I/O-bound concurrency
- Consider `Pattern.compile()` at class level for reused patterns
- Use `String.formatted()` (Java 15+) over `String.format()`
- Use `SequencedCollection` (Java 21+) for ordered access
- Consider `jspecify` annotations for nullability contracts

## Testing
- Use JUnit 5 with `@Nested` classes for organization
- Use AssertJ for fluent assertions
- Use Mockito for mocking — never mock value objects
- Use Testcontainers for integration tests with external dependencies
- Test naming: `methodName_scenario_expectedResult`
