# /audit — Orchestrator Self-Audit

Audit the orchestrator harness quality.

## Instructions

1. Validate all agent frontmatter (required fields, valid models, tool lists)
2. Validate all skill SKILL.md files (frontmatter, structure)
3. Validate all command files (structure, agent references)
4. Validate all rule files (frontmatter, path patterns)
5. Check hook configurations against handler scripts
6. Verify model tier configuration in settings
7. Run `bash scripts/validate-assets.sh` for automated checks
8. Report: PASS / FAIL with specific issues

## Checks

- Every agent has: name, description, model, permissionMode, maxTurns
- Every skill has: name, description in frontmatter
- Every hook script referenced in hooks.json exists
- Model identifiers in agent frontmatter are valid
- Settings.json env vars for model tiers are set
