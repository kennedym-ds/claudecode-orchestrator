# Creating Plugins

Plugins package skills, agents, hooks, MCP servers, and LSP servers for distribution across projects and teams.

**Template:** [`docs/templates/plugin/`](../templates/plugin/) — copy-paste scaffold with manifest, agent, skill, and hook starters

## Table of Contents

- [When to Use Plugins vs Standalone](#when-to-use-plugins-vs-standalone)
- [Quick Start](#quick-start)
- [Plugin Manifest Schema](#plugin-manifest-schema)
- [Plugin Components](#plugin-components)
- [Converting Standalone to Plugin](#converting-standalone-to-plugin)
- [Distribution](#distribution)
- [Development Workflow](#development-workflow)
- [Adding Plugins to cc-sdlc Marketplace](#adding-plugins-to-cc-sdlc-marketplace)
- [Multi-Plugin Architecture](#multi-plugin-architecture)
- [Plugin Security Model](#plugin-security-model)
- [Debugging Plugins](#debugging-plugins)
- [Best Practices](#best-practices)

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

Same format as standalone agents. **Security restriction:** Plugin agents cannot use `hooks` or `mcpServers` fields. These are ignored when loading plugin agents. `permissionMode` is supported.

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

Plugin MCP servers are declared in the plugin manifest at `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "description": "My plugin",
  "version": "1.0.0",
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
5. **Document security limitations** — Plugin agents can't use hooks/mcpServers
6. **Test with `--plugin-dir`** before distributing
7. **Use `/reload-plugins`** during development instead of restarting sessions

## Adding Plugins to cc-sdlc Marketplace

To add a new integration plugin to the cc-sdlc suite:

### 1. Create the plugin structure

```bash
mkdir -p plugins/cc-myintegration/.claude-plugin
mkdir -p plugins/cc-myintegration/.claude/{agents,skills,commands}
mkdir -p plugins/cc-myintegration/mcp
```

### 2. Create the manifest

**`plugins/cc-myintegration/.claude-plugin/plugin.json`:**
```json
{
  "name": "cc-myintegration",
  "version": "1.0.0",
  "description": "MyIntegration — brief description of what this plugin provides.",
  "author": "kennedym-ds",
  "license": "MIT",
  "components": {
    "agents": ".claude/agents/",
    "skills": ".claude/skills/",
    "commands": ".claude/commands/"
  },
  "mcpServers": {
    "myintegration": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp/server.js"],
      "env": {
        "MY_API_TOKEN": "${MY_API_TOKEN}"
      }
    }
  }
}
```

### 3. Register in marketplace.json

Add the plugin to `.claude-plugin/marketplace.json`:

```json
{
  "name": "cc-myintegration",
  "path": "plugins/cc-myintegration",
  "description": "MyIntegration — brief description"
}
```

### 4. Register in the installer

Add short name mapping to both `installer/install.sh` and `installer/install.ps1`:

```bash
# install.sh — add to PLUGIN_MAP
[myintegration]="cc-myintegration"
```

```powershell
# install.ps1 — add to $PluginMap
'myintegration' = 'cc-myintegration'
```

### 5. Register with conductor

Add the plugin's agent(s) to the conductor's `tools` list in `plugins/cc-sdlc-core/.claude/agents/conductor.md`.

### 6. Add to onboarding

If your integration needs credentials, add it to `installer/onboard.ps1` and `installer/onboard.sh`.

### 7. Validate

```bash
pwsh -File scripts/validate-assets.ps1 -ShowDetails
```

## Multi-Plugin Architecture

The cc-sdlc suite uses a multi-plugin architecture where plugins are composed at runtime:

```
┌────────────────────────────────────────────────────────────┐
│                    Global Namespace                         │
│  All agents, skills, commands merged from installed plugins │
├────────────┬────────────┬────────────────┬─────────────────┤
│ cc-sdlc-   │ cc-sdlc-   │ cc-github      │ cc-jira         │
│ core       │ standards  │ cc-confluence  │ cc-jama         │
│            │            │                │                 │
│ 19 agents  │ 27 skills  │ 2 agents       │ 1 agent each    │
│ 18 skills  │ (20 lang + │ 2 skills       │ 2 skills each   │
│ 22 cmds    │  7 domain) │ 2 cmds         │ 2 cmds each     │
│ 14 hooks   │            │ GitHub MCP     │ Custom MCPs     │
│ 6 rules    │            │                │                 │
└────────────┴────────────┴────────────────┴─────────────────┘
```

**Key principle:** Plugins don't call each other directly. Instead:
- All components flatten into a single namespace when installed
- The conductor can delegate to any agent from any plugin
- Any agent can reference skills from any installed plugin
- MCP tools are available to any agent with appropriate tool access

### Cross-plugin dependencies

If plugin B depends on plugin A being installed:
1. Document the dependency in the plugin's README.md
2. Check for the dependency at runtime (e.g., check if an agent name resolves)
3. Gracefully degrade — inform the user which plugin is missing

## Plugin Security Model

| Capability | Standalone (.claude/) | Plugin |
|-----------|----------------------|--------|
| `hooks` in agent frontmatter | ✅ Allowed | ❌ Ignored |
| `mcpServers` in agent frontmatter | ✅ Allowed | ❌ Ignored |
| `permissionMode` in agent frontmatter | ✅ Allowed | ✅ Allowed |
| `tools` / `disallowedTools` | ✅ Allowed | ✅ Allowed |
| `model` / `effort` / `memory` | ✅ Allowed | ✅ Allowed |
| Plugin-level MCP servers | N/A | ✅ Via plugin.json |
| Plugin-level hooks | N/A | ✅ Via hooks/hooks.json |

**Why the restriction?** Plugin agents are distributed code. Allowing them to define arbitrary hooks or MCP servers would be a security risk. `permissionMode` is allowed because it restricts agent capabilities rather than expanding them. `hooks` and `mcpServers` are only trusted from the project owner's `.claude/` directory.

**Workaround:** If a plugin agent needs these capabilities, instruct users to copy it to their local `.claude/agents/` directory.

## Debugging Plugins

### Plugin not loading

1. **Check manifest** — `plugin.json` must be valid JSON with `name` and `description`
2. **Check directory structure** — `.claude-plugin/plugin.json` must be at the correct location
3. **Check `--plugin-dir`** — Path must point to the plugin root, not the `.claude-plugin/` subdirectory
4. **Run `/reload-plugins`** — Plugin changes require reload

### Skills not found

1. **Check namespace** — Plugin skills use `/plugin-name:skill-name`
2. **Check directory** — Must be `skills/skill-name/SKILL.md` (not just `skills/SKILL.md`)
3. **Check frontmatter** — `name` field must match the directory name

### Agents not delegated to

1. **Check name conflicts** — If multiple plugins define the same agent name, higher-priority wins
2. **Check conductor tools** — Integration agents need to be listed in the conductor's `Agent(...)` tool list
3. **Check security restrictions** — Plugin agents can't use hooks or mcpServers

### MCP server not connecting

1. **Check env vars** — Credentials must be set in the environment
2. **Check command** — Verify the MCP server command runs independently
3. **Check plugin.json** — `mcpServers` must be a top-level key with correct structure
4. **Test manually** — Run the MCP server directly to see error output
