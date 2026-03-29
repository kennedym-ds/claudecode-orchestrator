# MCP Plugin Development

Build MCP (Model Context Protocol) server plugins for Claude Code. This guide covers the full lifecycle from design to distribution.

## Architecture

```
your-plugin/
+-- .claude-plugin/
|   +-- plugin.json        # Plugin manifest (includes mcpServers config)
+-- package.json           # Node.js dependencies
+-- mcp/
|   +-- server.js          # MCP server implementation
+-- skills/                # Workflow skills that use the MCP tools
|   +-- your-skill/
|       +-- SKILL.md
+-- agents/                # Agents that orchestrate MCP tool usage
|   +-- your-agent.md
+-- commands/              # Slash commands as entry points
|   +-- your-command.md
+-- README.md
```

## Step 1: Design Your Tools

Define what operations your plugin exposes. Each tool has a name, description, input schema, and handler.

**Design principles:**
- Each tool does one thing well (Unix philosophy)
- Tool names are verbs: `get_issue`, `search_pages`, `create_item`
- Return structured JSON, not raw HTML or binary
- Include pagination for list operations
- Validate inputs: required fields, type checks, max limits

**Example tool inventory for a GitHub plugin:**

| Tool | Description | Key Inputs |
|------|-------------|-----------|
| `search_repos` | Search repositories | query, language, max_results |
| `get_repo` | Get repo details | owner, repo |
| `list_issues` | List issues with filters | owner, repo, state, labels |
| `create_issue` | Create a new issue | owner, repo, title, body |

## Step 2: Create the Plugin Structure

```bash
mkdir -p my-plugin/.claude-plugin my-plugin/mcp my-plugin/skills my-plugin/agents my-plugin/commands
```

### plugin.json — MCP Server Configuration

MCP servers are declared inside the plugin manifest at `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "What this plugin integrates with and why.",
  "author": "your-name",
  "repository": "your-repo",
  "mcpServers": {
    "my-plugin": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp/server.js"],
      "env": {
        "MY_API_URL": "",
        "MY_API_TOKEN": ""
      }
    }
  },
  "skills": ["skill-one", "skill-two"],
  "agents": ["my-agent"],
  "commands": ["my-command"]
}
```

### package.json

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "private": true,
  "description": "MCP server for My Service",
  "main": "mcp/server.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

## Step 3: Implement the MCP Server

### Server Template

```javascript
#!/usr/bin/env node
const https = require('https');
const http = require('http');

// --- Configuration ---
const BASE_URL = (process.env.MY_API_URL || '').replace(/\/+$/, '');
const API_TOKEN = process.env.MY_API_TOKEN || '';

if (!BASE_URL || !API_TOKEN) {
  process.stderr.write('[my-plugin] Missing env vars: MY_API_URL, MY_API_TOKEN\n');
}

// --- HTTP Client ---
function apiFetch(method, path, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);

    // Enforce HTTPS for non-localhost
    const isLocalhost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    if (url.protocol !== 'https:' && !isLocalhost) {
      reject(new Error('API URL must use HTTPS for non-localhost connections'));
      return;
    }

    const options = {
      method,
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      headers: {
        'Authorization': `Bearer ${API_TOKEN}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    };

    const transport = url.protocol === 'https:' ? https : http;
    const req = transport.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(data ? JSON.parse(data) : {}); }
          catch { resolve({ raw: data }); }
        } else {
          reject(new Error(`API ${res.statusCode}: ${data.slice(0, 500)}`));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// --- Tool Definitions ---
const TOOLS = [
  {
    name: 'get_item',
    description: 'Get a single item by ID.',
    inputSchema: {
      type: 'object',
      properties: {
        item_id: { type: 'string', description: 'Item ID' },
      },
      required: ['item_id'],
    },
  },
  // Add more tools here
];

// --- Tool Handlers ---
async function handleTool(name, args) {
  switch (name) {
    case 'get_item': {
      // Use encodeURIComponent for all user-provided path params
      const result = await apiFetch('GET',
        `/api/items/${encodeURIComponent(args.item_id)}`
      );
      return { id: result.id, name: result.name };
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

// --- MCP Server Bootstrap ---
async function main() {
  try {
    const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
    const { StdioServerTransport } =
      require('@modelcontextprotocol/sdk/server/stdio.js');

    const server = new McpServer({ name: 'my-plugin', version: '0.1.0' });

    for (const tool of TOOLS) {
      server.tool(
        tool.name,
        tool.description,
        tool.inputSchema.properties,
        async (args) => {
          try {
            const result = await handleTool(tool.name, args);
            return {
              content: [{ type: 'text', text: JSON.stringify(result, null, 2) }],
            };
          } catch (err) {
            return {
              content: [{ type: 'text', text: `Error: ${err.message}` }],
              isError: true,
            };
          }
        }
      );
    }

    const transport = new StdioServerTransport();
    await server.connect(transport);
  } catch (err) {
    process.stderr.write(
      `[my-plugin] MCP SDK not found. Install: npm install\n`
    );
    process.exit(1);
  }
}

main();
```

### Security Checklist

- [ ] Credentials from environment variables only (never hardcoded)
- [ ] HTTPS enforced for non-localhost URLs
- [ ] Request timeout set (30s recommended)
- [ ] `encodeURIComponent()` on all user-provided URL path/query params
- [ ] Response data truncated in error messages (`.slice(0, 500)`)
- [ ] No `eval()` or dynamic code execution
- [ ] No shell command construction from user inputs

### Authentication Patterns

**Bearer Token (most APIs):**
```javascript
headers: { 'Authorization': `Bearer ${API_TOKEN}` }
```

**Basic Auth (Atlassian Cloud):**
```javascript
const auth = Buffer.from(`${EMAIL}:${TOKEN}`).toString('base64');
headers: { 'Authorization': `Basic ${auth}` }
```

**OAuth 2.0 Client Credentials (Jama, enterprise APIs):**
```javascript
// Exchange client_id:client_secret for a bearer token
// Cache the token, refresh before expiry
// See plugins/cc-jama/mcp/server.js for full implementation
```

## Step 4: Add Skills

Skills teach Claude Code how to use your tools in structured workflows.

**`skills/your-skill/SKILL.md`:**
```markdown
---
name: "your-skill"
description: "What this skill does with the MCP tools."
---

# Skill Name

## When to Use
When the user wants to {accomplish X}.

## Workflow
1. Step one using mcp__my_plugin__tool_a
2. Step two using mcp__my_plugin__tool_b
3. Format output as structured table

## Output Format
Describe the expected output structure.

## CLI Example
\`\`\`bash
claude -p "do the thing" --tool mcp__my_plugin__tool_a --tool mcp__my_plugin__tool_b
\`\`\`
```

## Step 5: Add an Agent

Agents orchestrate tool usage with behavioral rules.

**`agents/your-agent.md`:**
```markdown
---
name: your-agent
description: "Handles {domain} tasks using {service} integration."
model: sonnet
tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Your Agent

You manage {domain} tasks. You can:

1. **Action A** using `mcp__my_plugin__tool_a`
2. **Action B** using `mcp__my_plugin__tool_b`

## Rules
- Always search before creating to avoid duplicates
- Format output as structured tables
- Include relevant IDs for cross-referencing
```

## Step 6: Add Commands

Commands are user-facing entry points.

**`commands/your-command.md`:**
```markdown
---
name: your-command
description: "One-line description for command picker."
---

# Your Command

## Usage
\`\`\`
/your-command
\`\`\`

## Workflow
1. What the command does step by step.

## CLI Example
\`\`\`bash
claude "/your-command"
\`\`\`
```

## Step 7: Test

### Syntax Validation

```bash
# Check JavaScript syntax
node --check plugins/my-plugin/mcp/server.js

# Install deps
cd plugins/my-plugin && npm install

# Start server manually (it waits for stdio input)
node plugins/my-plugin/mcp/server.js
# Press Ctrl+C to exit
```

### Integration Test

```bash
# Test a tool via Claude Code
claude -p "test: list items using the my-plugin integration" \
  --tool mcp__my_plugin__get_item
```

### Add to Smoke Tests

Update `scripts/run-smoke-tests.ps1` and `scripts/run-smoke-tests.sh`:
```powershell
# In the Plugins section
foreach ($plugin in @('cc-jira','cc-confluence','cc-jama','my-plugin')) {
    # ...
}
```

## Step 8: Document

Create a `README.md` covering:
1. What the plugin does
2. Setup (env vars, npm install, plugin install)
3. Tool reference table
4. Skills and agents
5. Commands
6. CLI examples for every tool
7. Authentication details
8. Security notes

## Reference: Existing Plugins

Study these working plugins as templates:

| Plugin | Auth | Tools | Path |
|--------|------|-------|------|
| cc-jira | Basic Auth | 8 tools | `plugins/cc-jira/` |
| cc-confluence | Basic Auth | 6 tools | `plugins/cc-confluence/` |
| cc-jama | OAuth 2.0 | 8 tools | `plugins/cc-jama/` |

## Common Pitfalls

1. **BOM encoding** — PowerShell's `-Encoding UTF8` adds a BOM. Strip it for `.js` files or use `[System.IO.File]::WriteAllText()` with `UTF8NoBOM`.
2. **Missing `encodeURIComponent`** — Always encode user input in URLs to prevent injection.
3. **No timeout** — HTTP requests without timeouts hang indefinitely.
4. **Hardcoded credentials** — Never put tokens in source code. Always use env vars.
5. **HTTP in production** — Always enforce HTTPS for non-localhost connections.