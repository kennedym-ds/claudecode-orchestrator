---
name: domain-profiles
description: Domain-specific customization overlays — provides tailored conventions, patterns, and safety rules for embedded systems, semiconductor testing, safety-critical, edge AI, enterprise applications, web frontend, and UI/UX domains.
user-invocable: false
---

# Domain Profiles

## How Domain Profiles Work

Domain profiles are composable overlays that inject domain-specific knowledge into the SDLC workflow. They affect:
- **Coding standards** — additional rules and patterns for the domain
- **Review focus** — what the reviewer looks for beyond general quality
- **Testing strategy** — domain-appropriate test approaches
- **Safety gates** — additional checks for regulated or safety-critical work
- **Terminology** — domain-specific vocabulary and concepts

## Available Profiles

### embedded-systems
**Target:** Firmware, drivers, RTOS, bare-metal code (C, C++, Assembly)
- Memory management: no dynamic allocation in safety paths, stack budget tracking
- Timing: worst-case execution time (WCET) analysis, interrupt latency bounds
- Hardware: register access patterns, volatile correctness, memory-mapped I/O
- Testing: hardware-in-the-loop (HIL), emulator-based tests, coverage per MISRA
- Standards: MISRA C/C++, AUTOSAR, CERT C

### semiconductor-test
**Target:** ATE test programs, device characterization, yield analysis (VBA, C#, C++, Python)
- Test program patterns: initialize → configure → measure → compare → bin
- Measurement: uncertainty budgets, guard-banding, statistical correlation
- Data: lot/wafer/die traceability, parametric data formats (STDF, CSV)
- Safety: ESD handling, thermal limits, power sequencing
- Tools: Teradyne IG-XL, Advantest SmarTest, NI STS

### safety-critical
**Target:** DO-178C, IEC 61508, ISO 26262, IEC 62304 compliant systems
- Traceability: requirement → design → code → test (bidirectional)
- Coverage: MC/DC for safety-critical code, statement + branch for lower ASIL
- Analysis: static analysis (Polyspace, LDRA), formal verification where applicable
- Documentation: design rationale, safety case arguments
- Review: independent verification, dual sign-off

### edge-ai
**Target:** ML model deployment on edge devices, inference optimization
- Model: quantization awareness, ONNX/TFLite compatibility, operator support
- Memory: model size budgets, activation memory planning, weight compression
- Latency: inference time targets, pipeline scheduling, DMA optimization
- Validation: accuracy post-quantization, edge-case datasets, adversarial robustness
- Deployment: OTA update strategy, model versioning, A/B testing

### enterprise-app
**Target:** Business applications, SaaS, internal tools (Java, C#, TypeScript, SQL)
- Architecture: layered/hexagonal, dependency injection, repository pattern
- Data: schema migrations, ACID transactions, audit logging
- Auth: RBAC/ABAC, OAuth 2.0/OIDC, session management
- Compliance: GDPR data handling, audit trail, right to deletion
- Operations: health checks, structured logging, graceful degradation

### web-frontend
**Target:** Web applications, SPAs, component libraries (TypeScript, JavaScript, CSS)
- Components: composable, accessible, responsive by default
- State: predictable state management, server-state vs client-state separation
- Performance: bundle size budgets, Core Web Vitals targets, lazy loading
- Testing: visual regression, interaction testing, cross-browser
- Accessibility: WCAG 2.1 AA minimum, ARIA patterns, keyboard navigation

### uiux
**Target:** Design system work, user research, prototyping
- Consistency: design tokens, spacing/typography scales, component API conventions
- Accessibility: color contrast 4.5:1 minimum, focus indicators, screen reader testing
- Responsiveness: mobile-first, breakpoint strategy, touch targets (48px minimum)
- Feedback: loading states, error states, empty states, success confirmations
- Testing: usability testing criteria, analytics instrumentation points

## Activation

Profiles are activated via `sdlc-config.md`:
```yaml
domain:
  primary: embedded-systems
  secondary: safety-critical
```

Multiple profiles can be combined — secondary profiles add rules, they don't override primary.
