# cc-jira — Jira Cloud Integration for Claude Code

MCP-based Jira Cloud integration that connects the orchestrator's SDLC workflow to Jira issue tracking.

## Setup

### 1. Install MCP SDK

```bash
cd plugins/cc-jira
npm install
```

### 2. Configure Environment

Set these environment variables (or add to `.claude/settings.local.json`):

```bash
export JIRA_BASE_URL="https://your-domain.atlassian.net"
export JIRA_USER_EMAIL="your-email@example.com"
export JIRA_API_TOKEN="your-api-token"
```

**Generate an API token:** [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)

### 3. Load the Plugin

```bash
claude --plugin-dir ./plugins/cc-jira
```

Or add to settings for permanent use:

```json
{
  "mcpServers": {
    "jira": {
      "type": "stdio",
      "command": "node",
      "args": ["plugins/cc-jira/mcp/server.js"],
      "env": {
        "JIRA_BASE_URL": "https://your-domain.atlassian.net",
        "JIRA_USER_EMAIL": "your-email@example.com",
        "JIRA_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `search_issues` | Search with JQL — returns key, summary, status, assignee |
| `get_issue` | Full issue details — description, comments, links |
| `create_issue` | Create story, task, bug, epic, or sub-task |
| `update_issue` | Update summary, description, priority, labels, assignee |
| `transition_issue` | Move issue to new status (or list available transitions) |
| `add_comment` | Add a comment to an issue |
| `get_sprint` | Get active sprint and its issues |
| `get_project` | Project metadata — issue types, components, lead |

## Skills

| Skill | Description |
|-------|-------------|
| `plan-to-stories` | Convert orchestrator plan phases into Jira stories |
| `issue-context` | Pull issue details into session for implementation context |

## Commands

```bash
claude /cc-jira:jira-sync artifacts/plans/my-feature/plan.md   # Sync plan to Jira
claude /cc-jira:jira-context PROJ-123                          # Pull issue context
```

## CLI Examples

```bash
# Search for open bugs in a project
claude "Use the jira search_issues tool with JQL: project = MYPROJ AND type = Bug AND status != Done"

# Create a story from the current plan
claude /cc-jira:jira-sync

# Get context before implementing
claude /cc-jira:jira-context MYPROJ-456

# Transition an issue after implementation
claude "Transition MYPROJ-456 to Done using the jira transition_issue tool"

# Add review findings as a comment
claude "Add a comment to MYPROJ-456 summarizing the review findings from artifacts/reviews/latest.md"
```

## Security

- API tokens are passed via environment variables, never hardcoded
- HTTPS enforced for all non-localhost connections
- Issue keys are URL-encoded to prevent injection
- Read-only operations (search, get) have no side effects