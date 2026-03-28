# SDLC Stage: Deployment

Readiness validation, CI/CD verification, and release execution.

## Agents at This Stage

| Agent | Role | Model | Permission |
|-------|------|-------|------------|
| `deploy-engineer` | Pre-deploy checklist, CI/CD validation | Haiku | `default` |
| `doc-updater` | Sync docs to match what was shipped | Sonnet | `acceptEdits` |

## Pre-Deploy Readiness Check

Run this before every release. It is a blocking gate — do not deploy if this returns NOT READY.

```bash
claude --agent deploy-engineer
/deploy-check
```

### Checklist

| Check | Blocking? | What It Verifies |
|-------|-----------|-----------------|
| Build passes | Yes | No compile errors, no warnings-as-errors |
| Tests pass | Yes | Full suite: unit + integration + e2e |
| Lint clean | Yes | No style violations |
| Security scan | Yes | No critical/high CVEs in dependencies |
| Version bumped | Yes | Semver applied correctly |
| Changelog updated | Warn | Notable changes documented |
| DB migrations reviewed | Yes (if applicable) | Migration scripts validated, rollback path exists |
| Env vars documented | Warn | All required vars documented in `.env.example` |
| Rollback plan | Warn | Steps to revert if deployment fails |

### Output

```
## Deploy Readiness: v2.4.1
Date: 2026-03-28
Environment: staging → production

| Check        | Status | Notes |
|--------------|--------|-------|
| Build        | PASS   | |
| Tests        | PASS   | 147/147 passing |
| Lint         | PASS   | |
| Security     | PASS   | No critical/high CVEs |
| Version      | PASS   | 2.4.0 → 2.4.1 (patch) |
| Changelog    | WARN   | Entry missing for PROJ-456 fix |
| Migrations   | PASS   | 2 migrations, rollback scripts verified |
| Rollback     | READY  | See runbooks/rollback-v2.4.1.md |

Verdict: READY
Blockers: none
Warnings: Update CHANGELOG before publishing release notes
```

## CI/CD Pipeline Validation

```bash
claude -p "validate the GitHub Actions pipeline in .github/workflows/ — verify all required stages are present, env secrets are referenced correctly (not hardcoded), and environment gates are configured for staging → production promotion" \
  --agent deploy-engineer
```

Expected pipeline stages: Build → Test → Lint → Security Scan → Deploy (with env gates)

## Documentation Sync

After implementation and before release, update documentation to match what was shipped:

```bash
claude --agent doc-updater
/doc src/auth/

# Automatically identifies and updates:
# - README.md (if public interfaces changed)
# - AGENTS.md (if agents/skills/commands/hooks changed)
# - CLAUDE.md (if project context or routing changed)
# - docs/guides/ (if workflows or setup changed)
# - CHANGELOG.md (new entry for this release)
```

The `doc-updater` runs with `background: true` and `permissionMode: acceptEdits` — it will update documentation files automatically without prompting.

## Publishing to Confluence

If your team uses Confluence for operational documentation:

```bash
/confluence-publish
# Choose what to publish:
# - Release notes
# - Updated architecture docs
# - Post-implementation spec
```

## Environment Configuration Checks

```bash
# Verify required env vars exist in target environment
claude -p "check that all required env vars from .env.example are configured in the staging environment — report any missing vars without printing their values" \
  --agent deploy-engineer
```

**Rules:**
- Secrets come from vault or secrets manager — never from committed config files
- Feature flags must be set correctly per environment
- External service endpoints must point to the correct environment (not staging endpoints in prod)

## Rollback Criteria

Define these before deploying, not after:

```
Automatic rollback triggers:
- Error rate > 5% for 2 consecutive minutes
- p99 latency > 2x baseline for 5 minutes
- Health check failures for > 2 minutes
- Any CRITICAL security alert

Manual rollback procedure:
1. Revert to previous release tag
2. Re-run database migration rollback script (if applicable)
3. Verify health endpoints return 200
4. Confirm error rate returns to baseline
```

Document this in `runbooks/rollback-{version}.md` before deployment.

## GitHub Integration: Create Release PR

```bash
/github-pr
# Creates a pull request with:
# - Structured description from plan artifacts
# - Review findings summary
# - Link to security audit
# - Checklist of acceptance criteria
```

## Post-Deploy Verification

After deploying:

```bash
claude -p "verify the v2.4.1 deployment to production is healthy — check health endpoints, compare current error rate and latency to pre-deploy baseline, confirm the new password reset flow is accessible" \
  --agent deploy-engineer
```

If anything is outside expected bounds, initiate the rollback procedure immediately.

## Handoff to Incident Response

If a deployment causes a production issue, see [Incident Response](incident-response.md).

The `incident-responder` agent can read `artifacts/plans/{feature}/plan-complete.md` and `artifacts/reviews/` to understand what changed — giving it immediate context without you having to reconstruct the history.
