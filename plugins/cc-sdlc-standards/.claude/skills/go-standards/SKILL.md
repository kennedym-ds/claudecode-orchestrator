---
name: go-standards
description: Go coding standards with severity-tiered rules. Use when writing, reviewing, or generating Go code.
---

# Go Standards

## ERROR (mandatory)
- Check all errors — no `_` for error returns unless explicitly justified
- Use `context.Context` as the first parameter for functions that do I/O
- No goroutine leaks — every goroutine must have a termination path
- Use `crypto/rand` not `math/rand` for security-sensitive randomness
- Validate all external input at package boundaries
- No global mutable state — use dependency injection

## WARNING (recommended)
- Accept interfaces, return structs
- Keep interfaces small (1-3 methods)
- Use table-driven tests
- Use `errors.Is()` / `errors.As()` — not string matching on error messages
- Wrap errors with `fmt.Errorf("context: %w", err)` for chain
- Maximum function length: 50 lines
- Use `sync.Once` for one-time initialization

## RECOMMENDATION (optional)
- Use `slog` (Go 1.21+) for structured logging
- Consider `errgroup` for parallel goroutine error handling
- Use generics (Go 1.18+) when they simplify code for 3+ concrete types
- Use `sync.Pool` for frequently allocated objects
- Consider `iter.Seq` (Go 1.23+) for iterator patterns

## Testing
- Use `testing` package with subtests (`t.Run`)
- Use `testify/assert` or `testify/require` for readable assertions
- Use `httptest` for HTTP handler tests
- Use `-race` flag in CI for data race detection
- Benchmark with `b.N` loop pattern
