# cc-github MCP

This plugin uses the official [GitHub MCP Server](https://github.com/github/github-mcp-server) Docker image (`ghcr.io/github/github-mcp-server`) — no custom server required.

The MCP server is configured in `.claude-plugin/plugin.json` via `mcpServers.github` and launched automatically by Claude Code at session start.

## Prerequisites

- [Docker](https://www.docker.com/) installed and running
- `GITHUB_TOKEN` environment variable set to a [GitHub Personal Access Token](https://github.com/settings/tokens) with appropriate scopes (`repo` for private repositories, `public_repo` for public only)
