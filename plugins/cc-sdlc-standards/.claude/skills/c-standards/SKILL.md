---
name: c-standards
description: C coding standards with severity-tiered rules. Use when writing, reviewing, or generating C code.
---

# C Standards

## ERROR (mandatory)
- Check all return values from system calls and memory allocations
- No buffer overflows — validate all array indices and string operations
- Use `snprintf` over `sprintf`, `strncpy` over `strcpy`
- Free all dynamically allocated memory — no leaks
- No undefined behavior: no signed integer overflow, null pointer dereference, or use-after-free
- Initialize all variables before use
- No `gets()` — ever

## WARNING (recommended)
- Use `const` for parameters and variables that don't change
- Prefer `static` for file-scoped functions and variables
- Use `sizeof(variable)` not `sizeof(type)` for allocations
- Maximum function length: 60 lines (excluding declarations)
- Use `enum` for related constants — avoid magic numbers
- Use `static_assert` (C11) for compile-time invariants
- Prefer `stdint.h` types (`uint32_t`) over platform-dependent types

## RECOMMENDATION (optional)
- Use compound literals for struct initialization
- Consider `_Generic` for type-safe macros (C11)
- Use `restrict` qualifier for non-aliasing pointer parameters
- Structure packing: align members to minimize padding
- Use `__attribute__((cleanup))` or RAII-like patterns for resource management

## Memory Safety Checklist
- Every `malloc`/`calloc`/`realloc` has a corresponding `free`
- Pointers set to `NULL` after `free`
- Array bounds checked before access
- String buffers sized for content + null terminator
- No stack-allocated large arrays (>4KB on stack)

## Testing
- Test boundary conditions: empty, max, off-by-one
- Memory leak detection: Valgrind, AddressSanitizer
- Undefined behavior: `-fsanitize=undefined`
- Fuzz testing for input parsing functions
