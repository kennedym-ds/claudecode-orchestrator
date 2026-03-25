# cc-jama — Jama Connect Plugin for Claude Code Orchestrator

MCP-based plugin that integrates Jama Connect with the Claude Code orchestrator. Trace requirements, map test coverage, and pull SDLC data from Jama into Claude Code sessions.

## Setup

### 1. Environment Variables

Set these before starting Claude Code:

```bash
export JAMA_BASE_URL="https://your-instance.jamacloud.com"
export JAMA_CLIENT_ID="your-client-id"
export JAMA_CLIENT_SECRET="your-client-secret"
```

**Windows (PowerShell):**
```powershell
$env:JAMA_BASE_URL = "https://your-instance.jamacloud.com"
$env:JAMA_CLIENT_ID = "your-client-id"
$env:JAMA_CLIENT_SECRET = "your-client-secret"
```

### 2. Create API Credentials

1. In Jama Connect, go to **Administration > API Keys** (or ask your admin)
2. Create an **OAuth 2.0 Client Credentials** grant
3. Copy the Client ID and Client Secret
4. Set them as `JAMA_CLIENT_ID` and `JAMA_CLIENT_SECRET`

### 3. Install Dependencies

```bash
cd plugins/cc-jama
npm install
```

### 4. Configure MCP Server

The `.mcp.json` file is pre-configured. Install the plugin:

```bash
claude plugin install ./plugins/cc-jama
```

## Tools

| Tool | Description |
|------|-------------|
| `get_items` | Get items from a project, optionally filtered by type |
| `search_items` | Text search across all items (name, description, fields) |
| `get_item` | Get a single item with full details |
| `get_item_children` | Navigate the item hierarchy (parent/child) |
| `get_relationships` | Trace upstream and downstream relationships (traceability) |
| `get_test_runs` | Get test execution results for a test cycle |
| `get_projects` | List accessible projects |
| `get_item_types` | List item types (requirements, test cases, etc.) |

## Skills

| Skill | Description |
|-------|-------------|
| `req-tracing` | Trace requirements through Jama's relationship graph |
| `test-coverage-map` | Map test results to requirements, showing coverage gaps |

## Agent

**jama-sync** — Handles all Jama data retrieval and traceability tasks. Uses Sonnet model tier.

## Commands

| Command | Description |
|---------|-------------|
| `/jama-trace` | Trace a requirement through upstream/downstream relationships |
| `/jama-context` | Pull Jama item details into the current session |

## CLI Examples

```bash
# List projects
claude -p "list all Jama projects I have access to" \
  --tool mcp__cc_jama__get_projects

# Search for requirements about authentication
claude -p "search Jama for requirements related to authentication" \
  --tool mcp__cc_jama__search_items

# Get full item details
claude -p "get Jama item 1234 with all fields" \
  --tool mcp__cc_jama__get_item

# Trace a requirement
claude -p "trace Jama item 1234 — show upstream stakeholder needs and downstream test cases" \
  --tool mcp__cc_jama__get_item --tool mcp__cc_jama__get_relationships

# Map test coverage
claude -p "build a test coverage map for Jama test cycle 567" \
  --tool mcp__cc_jama__get_test_runs --tool mcp__cc_jama__get_relationships

# Navigate item hierarchy
claude -p "show the children of Jama item 100" \
  --tool mcp__cc_jama__get_item_children

# Full traceability workflow
claude "/jama-trace"

# Pull item context into session
claude "/jama-context"
```

## Authentication

This plugin uses **OAuth 2.0 Client Credentials** flow:
- Client ID + Client Secret are exchanged for a Bearer token
- Tokens are cached in memory and refreshed automatically before expiry
- HTTPS is enforced for all non-localhost connections
- No credentials are logged or stored in artifacts

## Jama REST API Reference

- Base URL: `https://your-instance.jamacloud.com/rest/v1/`
- Auth: Bearer token (OAuth 2.0 client credentials)
- Docs: https://dev.jamasoftware.com/rest
- Item types vary by project configuration — use `get_item_types` to discover