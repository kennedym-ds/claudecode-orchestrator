---
name: typescript-standards
description: TypeScript coding standards with severity-tiered rules. Use when writing, reviewing, or generating TypeScript code.
---

# TypeScript Standards

## ERROR (mandatory)
- Enable `strict: true` in tsconfig — no exceptions
- Never use `any` — use `unknown` and narrow with type guards
- Use discriminated unions over type assertions
- All public APIs must have explicit return types
- Never use `@ts-ignore` — use `@ts-expect-error` with explanation if absolutely necessary
- No hardcoded secrets or credentials

## WARNING (recommended)
- Use `interface` for object shapes, `type` for unions/intersections/utilities
- Prefer `readonly` for properties that don't change
- Use `satisfies` operator for type-checked object literals
- Use `const` assertions for literal types
- Maximum function length: 40 lines
- Use `Record<K, V>` over `{ [key: string]: V }`
- Generic parameters should be descriptive: `TItem` not `T` when meaning matters

## RECOMMENDATION (optional)
- Use `branded types` for domain identifiers (UserId, OrderId)
- Prefer `Map<K, V>` over `Record` for dynamic key sets
- Use `infer` in conditional types for complex type computation
- Consider `zod`/`valibot` for runtime validation at system boundaries
- Use `using` declarations for disposable resources (TypeScript 5.2+)

## Testing
- Type tests with `expectTypeOf` (vitest) or `tsd`
- Test public API contracts, not implementation details
- Use type-safe mocking libraries (vitest mock, ts-mockito)
- Assert error types specifically, not just "throws"
