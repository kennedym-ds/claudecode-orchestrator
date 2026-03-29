# cc-my-plugin

Brief description of what this plugin provides.

## Installation

```bash
# Load directly during development
claude --plugin-dir ./plugins/cc-my-plugin

# Install from GitHub repository
# /plugin marketplace add owner/repo
# /plugin install my-plugin@owner/repo
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
