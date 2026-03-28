---
name: jama-trace
description: "Trace requirements through Jama — show upstream needs and downstream test cases."
---

# Jama Trace

Trace a requirement or item through Jama's relationship graph.

## Usage

```
/jama-trace
```

## Workflow

1. Ask for the target item (ID, document key, or search term)
2. Get the item details from Jama
3. Trace upstream relationships (stakeholder needs, parent requirements)
4. Trace downstream relationships (test cases, design elements)
5. Present a traceability matrix with coverage summary

## Requirements

- cc-jama MCP server must be running
- Environment variables: `JAMA_BASE_URL`, `JAMA_CLIENT_ID`, `JAMA_CLIENT_SECRET`

## CLI Example

```bash
claude "/jama-trace"
```