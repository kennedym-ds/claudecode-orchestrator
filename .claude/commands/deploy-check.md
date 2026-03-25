# /deploy-check — CI/CD Readiness

Check deployment readiness for: $ARGUMENTS

## Instructions

1. Run the full verification loop (build, test, lint, typecheck)
2. Check for uncommitted changes
3. Verify branch is up to date with main
4. Review CI configuration for issues
5. Check for breaking changes in public APIs
6. Report readiness: READY / NOT_READY with blockers listed
