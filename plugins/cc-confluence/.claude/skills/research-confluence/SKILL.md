---
name: "research-confluence"
description: "Searches Confluence for existing documentation, architecture decisions, and prior art."
---

# Research Confluence

## When to Use

During the Research phase of DEEP/ULTRADEEP workflows, or whenever existing documentation might inform the current task.

## Workflow

1. Build CQL queries from the task description and known keywords
2. Search across relevant spaces for matching pages
3. Retrieve full content of the most relevant pages
4. Summarize findings with page links as citations

## Search Strategy

1. **Exact title match** — search for the feature/component name
2. **Keyword search** — extract key terms and search page body content
3. **Label search** — search by relevant labels (architecture, design, RFC, ADR)
4. **Space-scoped search** — limit to engineering/project spaces

## Output Format

```markdown
## Confluence Research Findings

### Relevant Pages Found: {count}

#### [Page Title](confluence-url)
- **Space:** {space_key}
- **Last Updated:** {date} by {author}
- **Relevance:** {why this page matters}
- **Key Content:** {summary of relevant sections}

### Gaps
- {topics with no existing documentation}
```

## CLI Example

```bash
# Research existing docs about authentication
claude -p "search Confluence for any existing documentation about authentication, auth flows, and SSO in spaces DEV and ARCH" --tool mcp__cc_confluence__search_pages --tool mcp__cc_confluence__get_page
```