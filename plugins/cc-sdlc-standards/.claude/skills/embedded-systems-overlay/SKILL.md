---
name: embedded-systems-overlay
description: Domain overlay for embedded and firmware development. Extends language standards with memory-constrained, real-time, and hardware-interface rules.
---

# Embedded Systems Overlay

> Activates when `sdlc-config.md` sets `domain.primary: embedded-systems` or `domain.secondary` includes it.

## Additional ERROR Rules
- No dynamic memory allocation (`malloc`/`new`) after initialization phase
- All ISR (Interrupt Service Routines) must complete within documented time budget
- No blocking calls in ISR context — use flags and deferred processing
- Peripheral registers accessed only through defined HAL (Hardware Abstraction Layer)
- All DMA buffers must be cache-aligned and use memory barriers
- Watchdog timer must be configured and fed — no infinite loops without WDT reset

## Additional WARNING Rules
- Use `volatile` for all hardware-mapped registers and shared ISR variables
- Document worst-case execution time (WCET) for time-critical paths
- Stack usage must be analyzed and documented per task/thread
- Use fixed-point arithmetic over floating-point when FPU is unavailable
- Minimize global state — use module-scoped statics with accessor functions
- Power state transitions must be documented in state machine diagrams

## Additional RECOMMENDATION Rules
- Use static memory pools over dynamic allocation
- Consider MISRA C (or C++) subset for safety-related code
- Use `__attribute__((packed))` or `#pragma pack` only when protocol requires it
- Implement ring buffers for producer/consumer patterns
- Use compile-time assertions for struct size and alignment validation

## Build & Debug
- Enable `-Wstack-usage=N` to catch deep stack usage
- Use `objdump` / `size` to verify memory footprint fits target
- Use logic analyzer / oscilloscope for timing verification
- Flash memory layout documented and verified against linker script
