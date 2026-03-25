---
name: coding-standards
description: Universal code quality standards for any language
argument-hint: <file-or-module>
user-invocable: true
---

# Coding Standards

## Naming

- Names describe intent, not type (`userCount` not `n`, `isValid` not `flag`)
- Consistent casing per language convention (camelCase, snake_case, PascalCase)
- Abbreviations only if universally understood (`url`, `id`, `http`)
- No single-letter variables except loop counters and lambdas

## Structure

- Functions do one thing — if you need "and" to describe it, split it
- Maximum function length: ~30 lines (guideline, not dogma)
- Maximum file length: ~300 lines — split when it gets hard to navigate
- Group related code together, separate unrelated code
- No circular dependencies

## Error Handling

- Handle errors at the appropriate level — not too early, not too late
- Use language-idiomatic error patterns (exceptions, Result types, error returns)
- Error messages include: what happened, why, and what the user can do about it
- Don't swallow errors silently — log or propagate

## Comments

- Code should be self-documenting — comment the "why", not the "what"
- Delete commented-out code — that's what version control is for
- Document public APIs with purpose, parameters, return values, and examples
- TODOs include a name or ticket reference

## Dependencies

- Prefer standard library over third-party when functionality is equivalent
- Pin dependency versions explicitly
- Evaluate maintenance status before adding new dependencies
- One dependency per concern — don't add a framework for one utility function

## Testing

- Tests live adjacent to the code they test
- Test behavior, not implementation details
- Each test is independent and can run in any order
- Test names describe the scenario and expected outcome
