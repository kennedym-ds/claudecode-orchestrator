---
name: cpp-standards
description: C++ coding standards with severity-tiered rules. Use when writing, reviewing, or generating C++ code.
---

# C++ Standards

## ERROR (mandatory)
- Use RAII for all resource management — no naked `new`/`delete`
- Use smart pointers: `unique_ptr` by default, `shared_ptr` only when ownership is shared
- No raw owning pointers — raw pointers are non-owning observers only
- Enable compiler warnings: `-Wall -Wextra -Werror` (GCC/Clang) or `/W4 /WX` (MSVC)
- No undefined behavior: no dangling references, use-after-move, or data races
- Never catch exceptions by value — catch by `const&`

## WARNING (recommended)
- Prefer `auto` for complex types, explicit types for clarity at API boundaries
- Use `std::string_view` for non-owning string parameters
- Use `std::span` for non-owning array parameters (C++20)
- Prefer `constexpr` over `const` for compile-time constants
- Use `enum class` over unscoped `enum`
- Rule of Zero: prefer compiler-generated constructors/destructors
- Rule of Five: if you define any special member, define all five
- Maximum function length: 50 lines

## RECOMMENDATION (optional)
- Use `std::optional` for nullable values — no sentinel values
- Use `std::variant` over union types
- Use `std::expected` (C++23) or equivalent for error handling
- Consider `std::ranges` (C++20) over raw iterators
- Use structured bindings for multiple return values
- Prefer `std::array` over C-style arrays

## Testing
- Use GoogleTest, Catch2, or doctest
- Test RAII correctness: resource cleanup on exception paths
- Use AddressSanitizer, ThreadSanitizer, UndefinedBehaviorSanitizer
- Benchmark performance-critical code with google/benchmark
