# Guide: Security Engineer

Threat modeling, OWASP reviews, adversarial testing, and security gate enforcement.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| OWASP security review | `/secure <scope>` | security-reviewer |
| Threat model a feature | `/threat-model <feature>` | threat-modeler |
| Adversarial / edge case testing | `/red-team <scope>` | red-team |
| Full lifecycle with security gates | `/conduct <task>` | conductor (DEEP/ULTRADEEP) |

## Threat Modeling (Pre-Implementation)

Run this before developers build any security-sensitive feature. It costs far less to catch threats at design time than after implementation.

```bash
claude --agent threat-modeler
/threat-model The new file upload API with presigned S3 URLs

# STRIDE analysis per component crossing trust boundaries:
# S — Spoofing: Can a user forge another's upload URL?
# T — Tampering: Can the file be modified in transit?
# R — Repudiation: Are uploads logged for audit trail?
# I — Information Disclosure: Can URLs leak to other users?
# D — Denial of Service: Can upload endpoint be flooded?
# E — Elevation of Privilege: Can a low-priv user access admin uploads?

# Output: threat table with DREAD risk scores + recommended mitigations
```

Share the output with the planner so mitigations are built into the implementation plan — not bolted on afterward.

## OWASP Security Review

```bash
# Review changed files against OWASP Top 10
claude --agent security-reviewer
/secure src/api/

# For specific changed files (e.g., post-PR review)
claude -p "audit src/api/auth/login.ts and src/api/payments/ for OWASP Top 10 vulnerabilities" \
  --agent security-reviewer
```

### What the Security Reviewer Checks

| Category | Examples |
|----------|---------|
| Injection | SQL injection, command injection, LDAP injection |
| Broken authentication | Weak token validation, session fixation, missing expiry |
| Sensitive data exposure | Secrets in logs, unencrypted PII, weak crypto |
| Broken access control | Privilege escalation, IDOR, missing auth checks |
| Security misconfiguration | Debug mode in prod, default credentials, open S3 buckets |
| XSS | Unsanitized output in HTML, JS, URL contexts |
| SSRF | User-controlled URLs fetched server-side |

### Verdict Levels

| Verdict | Meaning |
|---------|---------|
| SECURE | No critical or high findings — safe to proceed |
| NEEDS_REMEDIATION | Must fix critical/high findings before merge |
| ESCALATE | Requires human security review (compliance, PII, production access) |

## Adversarial Testing (Red Team)

The red team challenges assumptions and finds what reviewers miss:

```bash
claude --agent red-team
/red-team src/payments/processor.ts

# Specifically looks for:
# - Logic flaws (off-by-one, state inconsistency, race conditions)
# - Failure modes (what happens when Stripe API times out?)
# - Performance traps (unbounded queries, missing pagination)
# - Security gaps (can a user trigger another's refund?)
# - Usability issues (confusing error messages that leak internal state)
```

Each finding is rated HIGH/MEDIUM/LOW with a realistic reproduction scenario.

## Security Gate Enforcement

The conductor automatically includes security review in DEEP and ULTRADEEP complexity tiers:

```bash
/conduct Add OAuth2 authorization server
# Routes as DEEP → includes security-reviewer after implementation
# Routes as ULTRADEEP for architectural changes → trilateral review:
#   - reviewer (code quality)
#   - red-team (adversarial)
#   - security-reviewer (OWASP compliance)
```

You can also manually gate at the security review stage:

```bash
# After implementation, before merge
claude --agent security-reviewer
/secure src/

# If findings are CRITICAL — block merge
# If NEEDS_REMEDIATION — route back to implementer
# If SECURE — approve
```

## Secrets Detection

The `pre-bash-safety.js` hook and the `secret-detector.js` hook run automatically on every edit. They flag:
- Hardcoded API keys, tokens, passwords
- Connection strings with credentials
- Private keys in committed files

If a secret is detected, the hook blocks the operation and reports the file + line.

## Security Workflow for Regulated Projects

For DO-178C, IEC 61508, ISO 26262, IEC 62304 projects using the `safety-critical` domain:

1. **Threat model** the feature before planning (`/threat-model`)
2. **Review mitigations** are built into the implementation plan
3. **Security review** each phase as it completes (`/secure`)
4. **Red team** the completed feature before release (`/red-team`)
5. **Trace** security findings to requirements via Jama (`/jama-trace`)
6. **Publish** security audit to Confluence (`/confluence-publish`)

## Output Artifacts

| Artifact | Location |
|---------|---------|
| Threat models | `artifacts/security/threat-model-{feature}.md` |
| Security audit reports | `artifacts/security/audit-{date}.md` |
| Red team findings | `artifacts/reviews/red-team-{feature}.md` |
