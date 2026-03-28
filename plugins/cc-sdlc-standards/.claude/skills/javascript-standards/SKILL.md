---
name: javascript-standards
description: JavaScript coding standards with severity-tiered rules. Use when writing, reviewing, or generating JavaScript code.
---

# JavaScript Standards

## ERROR (mandatory)
- Use `===` and `!==` — never `==` or `!=`
- Never use `eval()`, `new Function()`, or `document.write()`
- Always sanitize user input before DOM insertion — use `textContent` or DOMPurify
- Use `const` by default, `let` when rebinding is needed, never `var`
- Handle Promise rejections — no unhandled `.catch()` or missing `try/catch` in async
- No hardcoded secrets, API keys, or credentials

## WARNING (recommended)
- Use arrow functions for callbacks and short lambdas
- Prefer `async/await` over `.then()` chains
- Destructure objects and arrays at point of use
- Maximum function length: 40 lines
- Use `Array.from()` or spread for array-likes — no `Array.prototype.slice.call()`
- Use template literals over string concatenation
- Export named exports — default exports only for single-purpose modules

## RECOMMENDATION (optional)
- Use optional chaining (`?.`) and nullish coalescing (`??`)
- Prefer `Map`/`Set` over plain objects for collections
- Use `structuredClone()` for deep copies
- Use `AbortController` for cancellable async operations
- Consider `WeakRef`/`FinalizationRegistry` for cache invalidation

## Testing
- Use describe/it blocks with descriptive names
- One assertion per test where practical
- Mock external dependencies (fetch, timers, filesystem)
- Use `beforeEach` for setup — avoid shared mutable state
