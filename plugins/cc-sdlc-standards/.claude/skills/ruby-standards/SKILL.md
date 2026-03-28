---
name: ruby-standards
description: Ruby coding standards with severity-tiered rules. Use when writing, reviewing, or generating Ruby code.
---

# Ruby Standards

## ERROR (mandatory)
- Use parameterized queries — never string interpolation in SQL
- Sanitize all user input before rendering in views (XSS prevention)
- Never use `eval`, `send`, or `instance_eval` with untrusted input
- Use `Bundler` for dependency management — no global gem installs in production
- Handle exceptions specifically — no bare `rescue` without exception class

## WARNING (recommended)
- Use frozen string literals: `# frozen_string_literal: true`
- Prefer `Symbol#to_proc` for simple blocks: `items.map(&:name)`
- Use keyword arguments for methods with 3+ parameters
- Maximum method length: 30 lines
- Use `private`/`protected` explicitly — minimize public API surface
- Prefer `each_with_object` over `inject`/`reduce` for building collections
- Use guard clauses over nested conditionals

## RECOMMENDATION (optional)
- Use `Struct` or `Data` (Ruby 3.2+) for simple value objects
- Consider `Ractor` for thread-safe parallelism (Ruby 3.0+)
- Use `pattern matching` (Ruby 3.0+) for complex conditionals
- Use `Enumerable#tally` for counting, `#filter_map` for transform+filter

## Testing
- Use RSpec with descriptive `describe`/`context`/`it` blocks
- Use FactoryBot for test data — no fixtures for complex models
- Use VCR or WebMock for HTTP stubbing
- Test behavior, not implementation
