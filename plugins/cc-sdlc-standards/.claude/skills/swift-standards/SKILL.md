---
name: swift-standards
description: Swift coding standards with severity-tiered rules. Use when writing, reviewing, or generating Swift code.
---

# Swift Standards

## ERROR (mandatory)
- Use `let` by default — `var` only when mutation is required
- Handle all errors with `do/catch` or propagate with `throws` — no force-try `try!`
- Never force-unwrap optionals (`!`) in production code — use `guard let`, `if let`, or `??`
- Use `Sendable` conformance for types shared across concurrency domains (Swift 6)
- No retain cycles — use `[weak self]` or `[unowned self]` in closures capturing `self`

## WARNING (recommended)
- Use Swift Concurrency (`async/await`, actors) over GCD/completion handlers
- Use `struct` by default — `class` only when identity semantics or inheritance needed
- Prefer `guard` for early returns over nested `if` statements
- Use `Result` type for functions that can fail without throwing
- Maximum function length: 40 lines
- Use access control: `private` by default, widen only as needed
- Prefer `some Protocol` (opaque types) over concrete types in returns

## RECOMMENDATION (optional)
- Use `@MainActor` for UI-mutating code
- Consider `AsyncSequence` for streaming data
- Use `Codable` with custom `CodingKeys` for API models
- Consider property wrappers for cross-cutting concerns
- Use `nonisolated` explicitly when actor isolation isn't needed

## Testing
- Use XCTest or Swift Testing framework (Swift 5.9+)
- Use `#expect` macro (Swift Testing) over `XCTAssert`
- Test async code with `await` — no `XCTestExpectation` unless necessary
- Use protocols for dependency injection in tests
