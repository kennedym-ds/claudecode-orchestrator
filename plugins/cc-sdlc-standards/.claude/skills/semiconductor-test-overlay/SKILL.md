---
name: semiconductor-test-overlay
description: Domain overlay for semiconductor test engineering. Extends language standards with test program, instrument communication, and data collection rules.
---

# Semiconductor Test Overlay

> Activates when `sdlc-config.md` sets `domain.primary: semiconductor-test` or `domain.secondary` includes it.

## Additional ERROR Rules
- All instrument communication (GPIB/SCPI/serial) must have timeout protection
- Test measurements must log raw values before limit comparison
- Test limits must come from configuration (spec file/database) — never hardcoded in test code
- All test results must be traceable: DUT ID, timestamp, station ID, operator, program version
- Abort handlers must leave instruments in safe state (outputs disabled, relays open)
- Measurement units must be explicitly documented in variable names or comments

## Additional WARNING Rules
- Separate test flow logic from instrument driver code (layered architecture)
- Use enums for test status: `PASS`, `FAIL`, `ABORT`, `SKIP`, `NOT_TESTED`
- Implement retry logic with configurable count for transient failures
- Log instrument errors (query `SYST:ERR?` after commands)
- Use correlation IDs to link test results across multiple test insertions
- Document measurement uncertainty and guard-banding strategy

## Additional RECOMMENDATION Rules
- Use statistical process control (SPC) patterns for monitoring test health
- Implement Cpk calculation utilities for manufacturing readiness
- Use parallel test patterns where hardware supports it — document resource contention
- Cache calibration data with expiry — don't re-calibrate every DUT
- Use data compression for high-volume waveform capture storage

## Test Program Structure
```
TestProgram/
├── Config/           # Limits, flow definitions, station config
├── Drivers/          # Instrument abstraction layer
├── TestModules/      # Individual test implementations
├── DataLog/          # Result logging and formatting
├── Utilities/        # Shared helpers (math, string, file I/O)
└── Main/             # Flow control and sequencing
```

## Instrument Communication Pattern
1. Send command → 2. Wait for OPC (*OPC?) → 3. Query result → 4. Check SYST:ERR → 5. Parse and validate
