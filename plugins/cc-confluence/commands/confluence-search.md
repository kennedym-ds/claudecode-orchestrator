---
name: confluence-search
description: "Search Confluence for existing documentation relevant to the current task."
---

# Confluence Search

Search Confluence for documentation relevant to the current task context.

## Usage

```
/confluence-search
```

## Workflow

1. Analyze the current task context (active plan, feature name, component area)
2. Build CQL queries targeting relevant spaces
3. Retrieve and summarize the most relevant pages
4. Present findings with page links as citations
5. Note any documentation gaps found

## CLI Example

```bash
claude "/confluence-search"
```