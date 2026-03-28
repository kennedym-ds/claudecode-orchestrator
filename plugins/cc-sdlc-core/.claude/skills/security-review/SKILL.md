---
name: security-review
description: Security analysis checklist aligned with OWASP Top 10
argument-hint: <scope-description>
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Security Review

## Checklist (OWASP Top 10 2021)

### A01 — Broken Access Control
- [ ] Authorization checked on every sensitive endpoint/operation
- [ ] Default deny — access requires explicit grant
- [ ] No path traversal, no direct object reference without auth check
- [ ] Rate limiting on authentication endpoints

### A02 — Cryptographic Failures
- [ ] No secrets in source code, environment variables, or logs
- [ ] TLS for all external communication
- [ ] Strong hashing for passwords (bcrypt/argon2, not MD5/SHA1)
- [ ] Proper key management (rotation, separation)

### A03 — Injection
- [ ] Parameterized queries for all database access
- [ ] Output encoding for HTML/JS/CSS contexts
- [ ] No shell command construction from user input
- [ ] No eval/exec of dynamic strings

### A04 — Insecure Design
- [ ] Threat model exists for sensitive features
- [ ] Business logic validated server-side
- [ ] Error messages don't leak internal details
- [ ] Logging covers security-relevant events

### A05 — Security Misconfiguration
- [ ] Debug mode disabled in production
- [ ] Default credentials removed
- [ ] CORS configured restrictively
- [ ] Security headers present (CSP, HSTS, X-Frame-Options)

### A06 — Vulnerable Components
- [ ] Dependencies pinned to specific versions
- [ ] No known CVEs in direct dependencies
- [ ] Lockfile committed and reviewed

### A07 — Authentication Failures
- [ ] Session tokens are unpredictable and expire
- [ ] Multi-factor available for sensitive operations
- [ ] Account lockout after repeated failures

### A08 — Data Integrity Failures
- [ ] Input validated at system boundaries
- [ ] Deserialization of untrusted data avoided or sandboxed
- [ ] CI/CD pipeline integrity (signed commits, protected branches)

### A09 — Logging & Monitoring
- [ ] Security events logged (auth failures, access denials, input validation failures)
- [ ] No sensitive data in logs (passwords, tokens, PII)
- [ ] Alerts configured for anomalous patterns

### A10 — SSRF
- [ ] URL/hostname validation for outbound requests
- [ ] No user-controlled URLs in server-side fetches without allowlist
- [ ] Internal network access blocked from user-initiated requests

## Severity Classification

| Severity | Criteria |
|----------|----------|
| CRITICAL | Remotely exploitable, high impact, no auth required |
| HIGH | Exploitable with moderate effort, significant data exposure |
| MEDIUM | Requires specific conditions, limited impact |
| LOW | Informational, defense in depth improvement |
