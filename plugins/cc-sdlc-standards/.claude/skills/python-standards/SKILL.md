---
name: python-standards
description: Python coding standards with severity-tiered rules. Use when writing, reviewing, or generating Python code.
---

# Python Standards

## ERROR (mandatory — blocks merge)
- Use type hints on all public function signatures
- Never use `eval()`, `exec()`, or `pickle.loads()` with untrusted input
- Always use parameterized queries for database access — never string interpolation
- Handle all exceptions specifically — no bare `except:` clauses
- Use `pathlib.Path` for file operations — no string concatenation for paths
- Secrets must come from environment variables or secret managers, never hardcoded

## WARNING (recommended — reviewer flags)
- Use dataclasses or Pydantic models for structured data — avoid raw dicts for domain objects
- Prefer `with` statements for all resource management (files, connections, locks)
- Use `logging` module — never `print()` for operational output
- Maximum function length: 50 lines (excluding docstrings)
- Maximum cyclomatic complexity per function: 10
- Use f-strings over `.format()` or `%` formatting
- Imports grouped: stdlib → third-party → local, alphabetized within groups

## RECOMMENDATION (optional — informational)
- Use `__slots__` on frequently instantiated classes
- Prefer comprehensions over `map()`/`filter()` for readability
- Use `functools.lru_cache` for expensive pure function calls
- Consider `asyncio` for I/O-bound concurrency
- Use `enum.Enum` for finite sets of constants

## Testing
- Use `pytest` as the test framework
- Test naming: `test_{function}_{scenario}_{expected_result}`
- Use fixtures for shared setup — no test inheritance hierarchies
- Mock at boundaries (I/O, network, clock) — never mock internal functions
