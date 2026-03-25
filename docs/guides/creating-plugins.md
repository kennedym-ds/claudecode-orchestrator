# Creating Plugins

Plugins package skills, agents, hooks, MCP servers, and LSP servers for distribution across projects and teams.

## When to Use Plugins vs Standalone

| Approach | Skill namespace | Best for |
|----------|----------------|----------|
| Standalone (`.claude/`) | `/hello` | Personal workflows, project-specific, quick experiments |
| Plugin | `/plugin-name:hello` | Sharing with teams, cross-project reuse, versioned distribution |

**Start standalone, convert to plugin when ready to share.**

## Quick Start

### 1. Create the plugin structure

```bash
mkdir -p my-plugin/.claude-plugin
```

### 2. Create the manifest

**`my-plugin/.claude-plugin/plugin.json`:**
```json
{
  "name": "my-plugin",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

### 3. Add components

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: plugin manifest
├── skills/                  # Optional: skills (SKILL.md in subdirs)
│   └── code-review/
│       └── SKILL.md
├── agents/                  # Optional: custom agents
│   └── reviewer.md
├── commands/                # Optional: slash commands
│   └── review.md
├── hooks/                   # Optional: hook handlers
│   ├── hooks.json
│   └── scripts/
│       └── lint.js
├── .mcp.json                # Optional: MCP server configs
├── .lsp.json                # Optional: LSP server configs
├── settings.json            # Optional: default settings
└── README.md                # Recommended: documentation
```

**Important:** Don't put `skills/`, `agents/`, `commands/`, or `hooks/` inside `.claude-plugin/`. Only `plugin.json` goes there.

### 4. Test locally

```bash
claude --plugin-dir ./my-plugin
```

Then try your skills: `/my-plugin:code-review`

## Plugin Manifest Schema

**`.claude-plugin/plugin.json`:**
```json
{
  "name": "my-plugin",
  "description": "Concise description shown in plugin manager",
  "version": "1.0.0",
  "author": {
    "name": "Author Name",
    "url": "https://github.com/author"
  },
  "homepage": "https://github.com/author/my-plugin",
  "repository": {
    "type": "git",
    "url": "https://github.com/author/my-plugin.git"
  },
  "license": "MIT"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier and skill namespace prefix |
| `description` | Yes | Shown in plugin manager |
| `version` | Yes | Semantic version for tracking releases |
| `author` | No | Attribution |
| `homepage` | No | Plugin documentation URL |
| `repository` | No | Source code location |
| `license` | No | License identifier |

## Plugin Components

### Skills

Same format as standalone skills. Namespace is automatic:
- Folder `skills/review/SKILL.md` → `/my-plugin:review`

```markdown
---
name: code-review
description: Reviews code for best practices and potential issues
---

When reviewing code, check for:
1. Code organization and structure
2. Error handling
3. Security concerns
```

### Agents

Same format as standalone agents. **Security restriction:** Plugin agents cannot use `hooks`, `mcpServers`, or `permissionMode` fields. These are ignored when loading plugin agents.

If you need these capabilities, instruct users to copy the agent into `.claude/agents/` or `~/.claude/agents/`.

```markdown
---
name: reviewer
description: Expert code reviewer. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a code reviewer...
```

### Hooks

Plugin hooks go in `hooks/hooks.json` with a `"hooks"` wrapper:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "node hooks/scripts/lint.js"
          }
        ]
      }
    ]
  }
}
```

### MCP Servers

Plugin MCP servers are defined in `.mcp.json` at the plugin root:

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp/server.js"]
    }
  }
}
```

### LSP Servers

For code intelligence in languages not covered by built-in plugins:

**`.lsp.json`:**
```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

### Default Settings

**`settings.json`** at plugin root applies when the plugin is enabled. Currently only `agent` is supported:

```json
{
  "agent": "my-plugin-agent"
}
```

## Converting Standalone to Plugin

### 1. Create plugin structure
```bash
mkdir -p my-plugin/.claude-plugin
```

### 2. Create manifest
```bash
cat > my-plugin/.claude-plugin/plugin.json << 'EOF'
{
  "name": "my-plugin",
  "description": "Migrated from standalone configuration",
  "version": "1.0.0"
}
EOF
```

### 3. Copy files
```bash
cp -r .claude/skills my-plugin/
cp -r .claude/agents my-plugin/
cp -r .claude/commands my-plugin/
```

### 4. Migrate hooks

Copy the `hooks` object from `.claude/settings.json` into `my-plugin/hooks/hooks.json`:

```json
{
  "hooks": {
    ...copied hook configuration...
  }
}
```

### 5. Test
```bash
claude --plugin-dir ./my-plugin
```

## Distribution

### Git repository
Share the plugin directory as a git repository. Users install via:
```
/plugin marketplace add owner/repo
/plugin install my-plugin@owner/repo
```

### Local directory
Load directly during development:
```bash
claude --plugin-dir ./my-plugin
```

### Multiple plugins
```bash
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

### Official marketplace
Submit at [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit) or [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit).

## Development Workflow

1. **Edit files** in the plugin directory
2. **Run `/reload-plugins`** in Claude Code to pick up changes
3. **Test components:**
   - Skills: `/my-plugin:skill-name`
   - Agents: Check in `/agents`
   - Hooks: Trigger the events they handle
4. **Validate** with `bash scripts/validate-assets.sh`

## Best Practices

1. **Name carefully** — The plugin `name` becomes the namespace prefix for all skills
2. **Include README.md** — Document installation, usage, and configuration
3. **Version semantically** — Track breaking changes in version numbers
4. **Keep skills focused** — Each skill should do one thing well
5. **Document security limitations** — Plugin agents can't use hooks/mcpServers/permissionMode
6. **Test with `--plugin-dir`** before distributing
7. **Use `/reload-plugins`** during development instead of restarting sessions
