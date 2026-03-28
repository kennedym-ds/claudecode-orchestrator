---
name: deploy-check
description: Deployment readiness verification — pre-deploy checklist, CI/CD validation, environment config, and rollback planning.
user-invocable: false
---

# Deploy Check

## Pre-Deploy Checklist

Every deployment must verify:

| Check | Tool | Blocking |
|-------|------|----------|
| Build passes | build command | Yes |
| All tests pass | test command | Yes |
| Lint clean | lint command | Yes |
| No critical security findings | security scanner | Yes |
| Version bumped | semver check | Yes |
| Changelog updated | file check | No (warn) |
| DB migrations reviewed | manual check | Yes (if applicable) |
| Environment variables documented | config check | No (warn) |
| Rollback plan documented | file check | No (warn) |

## CI/CD Pipeline Validation

Verify the pipeline has these stages:
1. **Build** — compile/transpile
2. **Test** — unit + integration
3. **Lint** — code style
4. **Security** — SAST/dependency scan
5. **Deploy** — with environment gates

## Environment Configuration

For each target environment, verify:
- All required env vars are set (not the values, just existence)
- Secrets come from vault/secrets manager, not config files
- Feature flags configured correctly
- External service endpoints point to correct environment

## Rollback Criteria

Define rollback triggers:
- Error rate exceeds {threshold}% (default: 5%)
- Latency exceeds {threshold}ms at p99 (default: 2x baseline)
- Health check failures for {duration} (default: 2 minutes)
- Critical security alert

## Output

```
## Deploy Readiness: {version}
Date: {timestamp}
Environment: {target}

| Check | Status | Details |
|-------|--------|---------|
...

Verdict: READY | NOT READY
Blockers: {list or "none"}
```
