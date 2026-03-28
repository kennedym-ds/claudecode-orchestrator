---
name: safety-critical-overlay
description: Domain overlay for safety-critical systems (DO-178C, IEC 61508, ISO 26262). Extends language standards with traceability, defensive coding, and certification rules.
---

# Safety-Critical Overlay

> Activates when `sdlc-config.md` sets `domain.primary: safety-critical` or `domain.secondary` includes it.

## Additional ERROR Rules
- Every requirement must trace to test cases (bidirectional traceability)
- No dead code — all code must be reachable and justified
- No compiler warnings — treat all warnings as errors
- Defensive programming: validate all inputs, check all return values, assert invariants
- No dynamic memory allocation after initialization (DO-178C DAL A-C)
- Single entry, single exit for functions (structural coverage requirement)
- All safety-critical decisions must have independent verification (diverse redundancy)

## Additional WARNING Rules
- Maximum cyclomatic complexity: 7 per function (MISRA recommendation)
- Maximum function length: 30 lines (excluding guards and assertions)
- Use static analysis tools (Polyspace, Coverity, LDRA) — zero findings policy
- Document all deviations from coding standard with rationale
- Modified Condition/Decision Coverage (MC/DC) required for DAL A
- Use assertions for internal invariants — document which are active in production

## Additional RECOMMENDATION Rules
- Use formal methods (model checking, proof) for critical algorithms
- Consider N-version programming for highest integrity levels
- Use certified compilers/libraries where available
- Maintain a Problem Report database with impact analysis
- Conduct Failure Mode and Effects Analysis (FMEA) for new subsystems

## Certification Artifacts
- Requirements specification (traced to parent requirements)
- Design description (architecture + detailed design)
- Test procedures + results (traced to requirements)
- Configuration index (every file version tracked)
- Compliance matrix (standard section → evidence)

## Review Protocol
- All code changes require independent review by qualified reviewer
- Safety impact analysis required for any change to certified baseline
- Regression test suite must pass completely — no partial acceptance
