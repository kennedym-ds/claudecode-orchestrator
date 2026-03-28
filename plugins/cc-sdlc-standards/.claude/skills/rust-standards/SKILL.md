---
name: rust-standards
description: Rust coding standards with severity-tiered rules. Use when writing, reviewing, or generating Rust code.
---

# Rust Standards

## ERROR (mandatory)
- No `unsafe` blocks without a `// SAFETY:` comment explaining the invariant
- Handle all `Result` values — no `.unwrap()` in library or production code
- Use `#[deny(clippy::all, clippy::pedantic)]` in CI
- No `.clone()` to silence borrow checker — fix the ownership model
- Use `SecretString`/`Zeroize` for sensitive data
- No panicking in library code (`.expect()` only in binary entry points or tests)

## WARNING (recommended)
- Use `thiserror` for library error types, `anyhow` for application errors
- Prefer `&str` over `&String` in function parameters
- Use `impl Trait` over generics when the concrete type isn't needed by callers
- Maximum function length: 50 lines
- Use `#[must_use]` on functions that return important values
- Prefer iterators over index-based loops
- Use `Cow<'_, str>` when a function may or may not allocate

## RECOMMENDATION (optional)
- Use `derive_more` for boilerplate trait implementations
- Consider `tokio` for async runtime, `rayon` for parallel computation
- Use `tracing` over `log` for structured, hierarchical logging
- Use `criterion` for benchmarking
- Consider `serde` with `#[deny(unknown_fields)]` for strict deserialization

## Testing
- Unit tests in `mod tests` at bottom of each module
- Integration tests in `tests/` directory
- Use `proptest` or `quickcheck` for property-based testing
- Use `insta` for snapshot testing of complex outputs
- Use Miri for detecting undefined behavior in unsafe code
