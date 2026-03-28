---
name: php-standards
description: PHP coding standards with severity-tiered rules. Use when writing, reviewing, or generating PHP code.
---

# PHP Standards

## ERROR (mandatory)
- Use `declare(strict_types=1)` in every file
- Use prepared statements (PDO/MySQLi) — never interpolate SQL
- Escape all output: `htmlspecialchars()` with `ENT_QUOTES` for HTML
- Use `password_hash()`/`password_verify()` — never MD5/SHA1 for passwords
- Type-declare all function parameters and return types
- No `extract()`, `compact()`, or `$$variable` (variable variables)

## WARNING (recommended)
- Follow PSR-12 coding style
- Use constructor promotion (PHP 8.0+)
- Use `match` expressions over `switch` (PHP 8.0+)
- Use named arguments for clarity at call sites (PHP 8.0+)
- Maximum method length: 40 lines
- Use `readonly` properties (PHP 8.1+) for immutable fields
- Use enums (PHP 8.1+) instead of class constants for finite sets

## RECOMMENDATION (optional)
- Use first-class callable syntax (PHP 8.1+)
- Consider fibers for cooperative multitasking (PHP 8.1+)
- Use intersection types (PHP 8.1+) for strict contracts
- Use `readonly class` (PHP 8.2+) for pure data objects
- Consider `#[\Override]` attribute (PHP 8.3+)

## Testing
- Use PHPUnit with data providers for parameterized tests
- Use Mockery or PHPUnit mocks for test doubles
- Use PHPStan/Psalm at level 8+ for static analysis
- Test HTTP endpoints with feature/integration tests
