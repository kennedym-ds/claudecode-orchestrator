# SDLC Stage: Security Review

OWASP compliance, adversarial testing, and threat validation before merge.

## Agents at This Stage

| Agent | Role | Model | Permission |
|-------|------|-------|------------|
| `security-reviewer` | OWASP Top 10 audit, secrets, input validation | Opus | `plan` |
| `red-team` | Adversarial testing, edge cases, failure modes | Opus | `plan` |
| `threat-modeler` | STRIDE/DREAD analysis (pre-implementation) | Opus | `plan` |

## When Security Review Runs

| Complexity | Security Involvement |
|-----------|---------------------|
| INSTANT | None (trivial changes) |
| STANDARD | Optional — run `/secure` if touching auth, data, or APIs |
| DEEP | Security-reviewer runs after implementation (automatic via conductor) |
| ULTRADEEP | Trilateral review: reviewer + red-team + security-reviewer in parallel |

## OWASP Security Review

```bash
claude --agent security-reviewer
/secure src/api/

# Checks against OWASP Top 10:
# A01 Broken Access Control     — missing auth checks, IDOR, privilege escalation
# A02 Cryptographic Failures    — weak crypto, plaintext secrets, bad key management
# A03 Injection                 — SQL, command, LDAP, XSS, SSTI
# A04 Insecure Design           — missing threat model, insecure defaults
# A05 Security Misconfiguration — debug mode in prod, default credentials, open buckets
# A06 Vulnerable Components     — known CVEs in dependencies
# A07 Auth Failures             — session fixation, weak passwords, missing MFA
# A08 Software/Data Integrity   — unsigned packages, insecure CI/CD
# A09 Logging/Monitoring Gaps   — no audit trail for security events
# A10 SSRF                      — user-controlled URLs fetched server-side
```

### Finding Format

```
Severity: CRITICAL
Category: A03 Injection (CWE-89)
Location: src/api/search.ts:47
Description: User input from query.term is concatenated directly into SQL query
Recommendation: Use parameterized queries — db.query('SELECT * FROM products WHERE name = ?', [term])
```

### Verdict

| Verdict | Meaning | Action |
|---------|---------|--------|
| SECURE | No critical or high findings | Proceed to deployment |
| NEEDS_REMEDIATION | Critical/high findings present | Fix before merge |
| ESCALATE | Compliance, PII, or production access concerns | Human security review required |

## Red Team Review

The red team goes beyond checklists — it thinks adversarially:

```bash
claude --agent red-team
/red-team src/api/payments/

# Analysis categories:
# Logic flaws     — incorrect assumptions, off-by-one, state inconsistency
# Failure modes   — unhandled errors, missing retries, cascading failures
# Performance     — hidden O(n²) loops, unbounded memory, missing pagination
# Security gaps   — privilege escalation, injection, information disclosure
# Usability       — error messages that leak internal state, data loss risks
```

Each finding includes:
- **Risk:** HIGH / MEDIUM / LOW
- **Scenario:** Specific steps to reproduce
- **Impact:** What goes wrong
- **Recommendation:** How to mitigate

The red team will say "no findings" if the code is solid — it doesn't fabricate issues.

## Trilateral Review (ULTRADEEP)

For high-risk or architectural changes, the conductor runs three reviews in parallel and requires consensus:

```
┌─────────────┐   ┌──────────────────┐   ┌─────────────┐
│   Reviewer   │   │ Security Reviewer │   │  Red Team   │
│ (correctness)│   │  (OWASP/threats) │   │(adversarial)│
└──────┬──────┘   └────────┬─────────┘   └──────┬──────┘
       │                   │                      │
       └───────────────────┼──────────────────────┘
                           ▼
                   Conductor aggregates
                   Consensus score required
                   PAUSE → human approval
```

A trilateral review is triggered automatically for ULTRADEEP complexity tasks or can be requested explicitly:

```bash
/conduct Rewrite the authentication system
# Conductor routes ULTRADEEP → runs all three reviewers
```

## Pre-Implementation: Threat Modeling

If threat modeling wasn't done in the design stage, run it before security review of the implemented code:

```bash
claude --agent threat-modeler
/threat-model <feature>

# STRIDE threat table + DREAD risk scores
# Identifies threats the security review should specifically check for
```

## Handling Findings

### After NEEDS_REMEDIATION

```bash
# Fix the issues in a new implementer session
claude --agent implementer
# Implement the specific fixes from the security review

# Re-run security review after fixes
claude --agent security-reviewer
/secure src/api/  # Same scope as before
```

The security-reviewer has `memory: project` — it remembers previous findings and will verify they were addressed.

### After ESCALATE

Stop automated processing. A human security engineer must review before proceeding. Document the escalation in `artifacts/security/escalation-{date}.md`.

## Secrets and Credentials

The `secret-detector.js` hook runs on every file edit and blocks commits containing:
- Hardcoded API keys, tokens, passwords
- Private keys or certificates
- Connection strings with embedded credentials

If triggered, the session reports the file and line. Fix it before continuing — there is no bypass.

## Security Artifacts

| Artifact | Location |
|---------|---------|
| Security audit reports | `artifacts/security/audit-{feature}.md` |
| Threat models | `artifacts/security/threat-model-{feature}.md` |
| Red team findings | `artifacts/reviews/red-team-{feature}.md` |
| Escalation records | `artifacts/security/escalation-{date}.md` |

## Handoff to Deployment

Security review must reach `SECURE` verdict before deployment. The `deploy-check` agent verifies no critical/high security findings are open before issuing a `READY` verdict.
