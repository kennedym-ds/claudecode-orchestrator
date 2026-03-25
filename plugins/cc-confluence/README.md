# cc-confluence — Confluence Cloud Plugin for Claude Code Orchestrator

MCP-based plugin that integrates Confluence Cloud with the Claude Code orchestrator. Publish plans, reviews, and research findings as Confluence pages. Search existing documentation during research phases.

## Setup

### 1. Environment Variables

Set these before starting Claude Code:

```bash
export CONFLUENCE_BASE_URL="https://your-domain.atlassian.net"
export CONFLUENCE_USER_EMAIL="you@company.com"
export CONFLUENCE_API_TOKEN="your-api-token"
```

**Windows (PowerShell):**
```powershell
$env:CONFLUENCE_BASE_URL = "https://your-domain.atlassian.net"
$env:CONFLUENCE_USER_EMAIL = "you@company.com"
$env:CONFLUENCE_API_TOKEN = "your-api-token"
```

### 2. Get an API Token

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Name it (e.g., "Claude Code") and copy the value
4. Set it as `CONFLUENCE_API_TOKEN`

### 3. Install Dependencies

```bash
cd plugins/cc-confluence
npm install
```

### 4. Configure MCP Server

The `.mcp.json` file is pre-configured. Ensure it is referenced in your project or user-level Claude Code settings, or install the plugin:

```bash
claude plugin install ./plugins/cc-confluence
```

## Tools

| Tool | Description |
|------|-------------|
| `search_pages` | Search pages by text or CQL (Confluence Query Language) |
| `get_page` | Get page content by ID or by title + space key |
| `create_page` | Create a new page in a space with optional parent and labels |
| `update_page` | Update an existing page (requires version number for locking) |
| `get_space` | Get space metadata (name, homepage, description) |
| `get_page_children` | List child pages of a given page |

## Skills

| Skill | Description |
|-------|-------------|
| `publish-plan` | Convert orchestrator plan artifacts to Confluence pages |
| `publish-review` | Publish review findings with severity-tagged formatting |
| `research-confluence` | Search Confluence for existing docs during research phases |

## Agent

**confluence-sync** — Handles all Confluence synchronization tasks. Uses Sonnet model tier.

## Commands

| Command | Description |
|---------|-------------|
| `/confluence-publish` | Publish artifacts (plans, reviews) to Confluence |
| `/confluence-search` | Search Confluence for relevant documentation |

## CLI Examples

```bash
# Search Confluence for auth documentation
claude -p "search Confluence for pages about authentication in space DEV" \
  --tool mcp__cc_confluence__search_pages

# Get a specific page
claude -p "get the content of Confluence page 12345" \
  --tool mcp__cc_confluence__get_page

# Create a page from a plan
claude -p "publish the plan in artifacts/plans/auth-refactor/ to Confluence space DEV" \
  --tool mcp__cc_confluence__create_page

# Update an existing page
claude -p "update Confluence page 12345 with the latest review findings" \
  --tool mcp__cc_confluence__get_page --tool mcp__cc_confluence__update_page

# Search then publish workflow
claude "/confluence-publish"

# Research existing docs
claude "/confluence-search"
```

## CQL Query Examples

The `search_pages` tool accepts CQL (Confluence Query Language):

```
# Pages in a specific space
type = page AND space = DEV

# Pages modified recently
type = page AND lastModified > now("-7d")

# Pages with specific label
type = page AND label = "architecture"

# Full-text search in a space
type = page AND space = DEV AND text ~ "authentication"

# Pages by title pattern
type = page AND title ~ "RFC*"
```

## Security

- API tokens are passed via environment variables, never hardcoded
- HTTPS is enforced for all non-localhost connections
- Tokens are Base64-encoded for Basic Auth (Atlassian Cloud standard)
- No credentials are logged or stored in artifacts