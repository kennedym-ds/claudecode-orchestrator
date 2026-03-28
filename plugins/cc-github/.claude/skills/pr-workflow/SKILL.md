---
name: pr-workflow
description: Pull request creation, review, and merge workflow patterns for GitHub integration.
---

# PR Workflow Skill

## PR Title Convention

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `build`

## PR Body Template

```markdown
## Summary
[1-2 sentence summary of changes]

## Changes
- [Change 1]
- [Change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed

## Breaking Changes
[None / describe breaking changes]

## Related Issues
Closes #[issue-number]
```

## Review Checklist

1. **Security**: Auth, input validation, secrets, dependencies
2. **Correctness**: Logic, edge cases, error handling
3. **Testing**: Coverage, meaningful assertions, boundary conditions
4. **Performance**: N+1 queries, unbounded loops, memory leaks
5. **Style**: Naming, consistency, dead code

## Merge Strategy

| Branch Pattern | Strategy |
|---------------|----------|
| `main` ← feature | Squash and merge |
| `main` ← release | Merge commit |
| `develop` ← feature | Squash and merge |
| Hotfix | Merge commit (preserves history) |

## Label Automation

| Change Type | Labels |
|------------|--------|
| New feature | `enhancement`, `needs-review` |
| Bug fix | `bug`, `needs-review` |
| Breaking change | `breaking-change`, `needs-review`, `major` |
| Documentation | `documentation` |
| Dependencies | `dependencies` |
