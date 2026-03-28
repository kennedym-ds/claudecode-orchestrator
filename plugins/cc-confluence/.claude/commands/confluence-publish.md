---
name: confluence-publish
description: "Publish orchestrator artifacts (plans, reviews) to Confluence."
---

# Confluence Publish

Publish artifacts from the current session to Confluence.

## Usage

```
/confluence-publish
```

## Workflow

1. Identify what artifacts exist in `artifacts/` (plans, reviews, research, decisions)
2. Ask which artifact to publish and to which Confluence space
3. Search for existing pages to decide between create vs. update
4. Convert markdown content to Confluence storage format (XHTML)
5. Create or update the page with appropriate labels
6. Report the page URL on completion

## Requirements

- cc-confluence MCP server must be running (configured in `.mcp.json`)
- Target Confluence space must exist and user must have write access
- Environment variables: `CONFLUENCE_BASE_URL`, `CONFLUENCE_USER_EMAIL`, `CONFLUENCE_API_TOKEN`

## CLI Example

```bash
claude "/confluence-publish"
```