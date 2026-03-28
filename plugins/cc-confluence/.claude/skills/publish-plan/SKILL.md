---
name: "publish-plan"
description: "Publishes orchestrator plan artifacts to Confluence as structured pages."
---

# Publish Plan to Confluence

## When to Use

After a plan is approved and you need to share it with the broader team via Confluence.

## Workflow

1. Read the plan from `artifacts/plans/{feature}/plan.md`
2. Search Confluence for an existing page with the plan title in the target space
3. If exists: update the page with the new content (use current version number)
4. If new: create a page under the project's planning parent page

## Content Mapping

Convert plan markdown to Confluence storage format (XHTML):

| Plan Section | Confluence Element |
|---|---|
| Title | `<h1>` page title |
| Overview | `<p>` introduction section |
| Phases | `<h2>` per phase with `<ac:task-list>` for tasks |
| Risk Analysis | `<ac:structured-macro ac:name="warning">` panel |
| Open Questions | `<ac:structured-macro ac:name="info">` panel |

## Labels

Apply these labels automatically:
- `orchestrator-plan`
- `auto-generated`
- Feature-specific label from plan metadata

## CLI Example

```bash
# Publish plan to Confluence
claude -p "publish the plan in artifacts/plans/auth-refactor/ to Confluence space DEV under page 'Architecture Plans'" --tool mcp__cc_confluence__create_page --tool mcp__cc_confluence__search_pages --tool mcp__cc_confluence__update_page
```