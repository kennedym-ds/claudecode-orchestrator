# Guide: DevOps / Platform Engineer

CI/CD validation, deploy readiness, infrastructure changes, and incident response.

## Your Core Commands

| Task | Command | Agent |
|------|---------|-------|
| Pre-deploy readiness check | `/deploy-check` | deploy-engineer |
| Incident investigation | `/incident <issue>` | incident-responder |
| Review infrastructure changes | `/review <scope>` | reviewer |
| Security scan on pipeline changes | `/secure <scope>` | security-reviewer |
| Plan infrastructure migration | `/plan <task>` | planner |

## Pre-Deploy Readiness Check

Run before every release:

```bash
claude --agent deploy-engineer
/deploy-check

# Validates:
# ✓ Build passes (no compile errors)
# ✓ Full test suite passes
# ✓ Lint clean
# ✓ Dependency security scan clean (no critical/high CVEs)
# ✓ Version bumped (semver applied correctly)
# ✓ Changelog updated
# ✓ DB migrations reviewed
# ✓ Environment variables documented (no hardcoded values)
# ✓ Rollback plan documented

# Output: Deploy Readiness Report
# Verdict: READY / NOT READY
# Blockers: [list of must-fix items]
```

## CI/CD Pipeline Validation

```bash
claude -p "validate the GitHub Actions pipeline in .github/workflows/ — check all required stages are present (build, test, lint, security scan, deploy) and verify environment-specific gates" \
  --agent deploy-engineer
```

Expected pipeline stages:
1. Build/compile
2. Unit + integration tests
3. Lint/format
4. SAST/dependency security scan
5. Environment-gated deploy

## Infrastructure Change Reviews

When modifying IaC (Terraform, CDK, Helm, etc.):

```bash
# Quality review
claude --agent reviewer
/review infra/terraform/

# Security review — especially for IAM, network, storage changes
claude --agent security-reviewer
/secure infra/terraform/
# Flags: overly permissive IAM, open security groups, unencrypted storage, missing audit logs
```

## Incident Response

### Investigating a Production Issue

```bash
claude --agent incident-responder
/incident Payment processing failures since 14:30 UTC — error rate 18%, timeout on Stripe API calls

# Agent follows the 4-phase protocol:
# 1. Observe — gather all available evidence (logs, metrics, stack traces)
# 2. Hypothesize — form testable theories
# 3. Experiment — test each hypothesis with minimal changes
# 4. Conclude — verify fix resolves without side effects

# Uses 5-Why root cause analysis:
# Why did the service fail? → Stripe API timeout
# Why did that happen? → Connection pool exhausted
# Why wasn't it caught? → No circuit breaker on external calls
# Why wasn't it prevented? → No load testing for payment flows
# Systemic fix? → Circuit breaker + load test suite for payment paths
```

### Escalation Rule

If 3 fix attempts fail → incident-responder automatically escalates to architecture review. It won't keep trying random changes.

### Post-Mortem Output

```markdown
## Incident: Payment timeout cascade
Severity: SEV2
Duration: 14:30 → 15:15 UTC
Impact: 18% of payment requests failed

Timeline:
- 14:30 — Error rate spike detected
- 14:35 — Stripe API latency increased to 8s
...

Root Cause: Missing circuit breaker on Stripe API calls

Action Items:
- [ ] Add circuit breaker with 500ms timeout — Owner: {name} — Due: {date}
- [ ] Add load test for payment flows — Owner: {name} — Due: {date}
```

## Environment Configuration

```bash
# Verify environment variables are set correctly (not the values — just that they exist)
claude -p "check that all required env vars from .env.example are present in the staging environment" \
  --agent deploy-engineer
```

Hooks automatically flag secrets in committed files via `secret-detector.js` on every edit.

## Monitoring Infrastructure Changes

When an agent modifies files, the `post-edit-validate.js` hook runs linting and basic validation automatically. You don't need to trigger this manually.

For infrastructure-specific validation (e.g., `terraform validate`, `helm lint`), add these to the deploy-check routine:

```bash
claude -p "run terraform validate and terraform plan for infra/terraform/ — report any errors or planned destructive changes" \
  --agent deploy-engineer
```

## Deployment Gate: Hook Integration

The `pre-bash-safety.js` hook blocks patterns like `rm -rf /`, `DROP TABLE`, force pushes to main, and destructive SSH commands. If a hook blocks an operation, the session reports the specific pattern that triggered it.

For deployment commands that need to pass through (e.g., `kubectl apply`, `terraform apply`), these are reviewed by the user through normal `permissionMode: default` approval flow — they're never auto-approved.

## Common Infrastructure Patterns

### Database Migration

```bash
/conduct Run the pending database migrations for the v2.4 release
# Planner: validates migration scripts, checks for destructive operations
# Implementer: runs migrations with rollback checkpoints
# Post-migration: verifies row counts and index health
```

### Blue/Green Deploy Validation

```bash
claude -p "validate that the blue environment at v2.4.1 is healthy and ready for traffic cutover — check health endpoints, error rates, and latency vs the green environment" \
  --agent deploy-engineer
```
