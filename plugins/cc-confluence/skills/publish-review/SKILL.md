---
name: "publish-review"
description: "Publishes code review findings to Confluence as a structured review page."
---

# Publish Review to Confluence

## When to Use

After a review is complete and findings need to be shared with the team.

## Workflow

1. Read the review from `artifacts/reviews/{feature}-review.md`
2. Convert severity-tagged findings to Confluence status macros
3. Search for existing review page in the target space
4. Create or update the page

## Severity Mapping

| Review Severity | Confluence Format |
|---|---|
| CRITICAL | `<ac:structured-macro ac:name="error">` red panel |
| HIGH | `<ac:structured-macro ac:name="warning">` yellow panel |
| MEDIUM | `<ac:structured-macro ac:name="note">` blue panel |
| LOW | `<ac:structured-macro ac:name="info">` grey panel |

## Labels

- `orchestrator-review`
- `auto-generated`
- Severity label: `has-critical`, `has-high`, etc.

## CLI Example

```bash
# Publish review findings
claude -p "publish the review in artifacts/reviews/auth-review.md to Confluence space DEV under 'Code Reviews'" --tool mcp__cc_confluence__create_page --tool mcp__cc_confluence__get_page
```