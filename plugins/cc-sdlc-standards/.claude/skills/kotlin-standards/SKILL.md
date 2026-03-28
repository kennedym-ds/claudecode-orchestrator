---
name: kotlin-standards
description: Kotlin coding standards with severity-tiered rules. Use when writing, reviewing, or generating Kotlin code.
---

# Kotlin Standards

## ERROR (mandatory)
- Use `val` by default — `var` only when mutation is required
- Null safety: never use `!!` except in tests — use `?.`, `?:`, or `requireNotNull()`
- Use coroutines for async work — no callback hell or raw threads
- Use `sealed class`/`sealed interface` for restricted type hierarchies with `when`
- All public API parameters validated at entry points

## WARNING (recommended)
- Use data classes for DTOs and value objects
- Prefer extension functions over utility classes
- Use `scope functions` appropriately: `let`, `run`, `with`, `apply`, `also`
- Use `sequence` for lazy evaluation of large collections
- Maximum function length: 40 lines
- Use `object` for singletons — no manual singleton patterns
- Prefer `buildList`/`buildMap` over mutable collection creation

## RECOMMENDATION (optional)
- Use `value class` (inline class) for type-safe wrappers
- Consider `Flow` for reactive streams
- Use `context receivers` for dependency injection patterns
- Use `DeepRecursiveFunction` for stack-safe recursion
- Consider multiplatform expect/actual for cross-platform code

## Testing
- Use JUnit 5 or KoTest
- Use MockK for mocking
- Use `runTest` for coroutine tests
- Use `Turbine` for Flow testing
