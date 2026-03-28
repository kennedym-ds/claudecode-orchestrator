# cc-my-plugin

Brief description of what this plugin provides.

## Installation

```bash
# Via cc-sdlc installer
pwsh -File installer/install.ps1 -Plugins my-plugin

# Or load directly
claude --plugin-dir ./plugins/cc-my-plugin
```

## Components

| Type | Name | Description |
|------|------|-------------|
| Agent | `my-agent` | What the agent does |
| Skill | `my-skill` | What the skill does |
| Command | `/my-command` | What the command does |

## Configuration

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MY_API_TOKEN` | Yes | API token for authentication |

### Setup

```bash
export MY_API_TOKEN="your-token-here"
```

## Usage

```
/my-command <arguments>
```

## Dependencies

- Requires `cc-sdlc-core` for conductor integration
