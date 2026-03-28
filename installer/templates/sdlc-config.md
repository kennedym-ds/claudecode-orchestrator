---
version: "1.0"
---

# SDLC Configuration

> Edit this file to configure cc-sdlc for your project. The conductor and agents read this at session start.

## Project

```yaml
project:
  name: "My Project"
  description: "Brief description of the project"
  language: "typescript"         # Primary language
  languages:                     # All languages used
    - typescript
    - python
  framework: ""                  # e.g., react, django, spring-boot, express
  repo: ""                       # e.g., https://github.com/org/repo
```

## Domain Profile

```yaml
domain:
  primary: "enterprise-app"      # embedded-systems | semiconductor-test | safety-critical | edge-ai | enterprise-app | web-frontend | uiux
  secondary: []                  # Additional overlays, e.g., ["uiux", "safety-critical"]
```

## Workflow Preferences

```yaml
workflow:
  default_complexity: "STANDARD" # INSTANT | STANDARD | DEEP | ULTRADEEP
  require_plan_approval: true    # Pause after planning for human review
  require_review: true           # Run reviewer after implementation
  auto_test: true                # Run tests automatically after changes
  tdd: false                     # Enforce test-first development
```

## Model Preferences

```yaml
models:
  heavy: "opus"                  # For reviews, planning, security
  default: "sonnet"              # For implementation, research
  fast: "haiku"                  # For triage, routing, simple tasks
```

## Review Settings

```yaml
review:
  confidence_threshold: 80       # 0-100, findings below this are suppressed
  severity_filter: "WARNING"     # ERROR | WARNING | RECOMMENDATION
  auto_skip_generated: true      # Skip review of generated/vendored files
```

## Integrations

```yaml
integrations:
  github:
    enabled: true
    default_branch: "main"
    pr_template: true
  jira:
    enabled: false
    project_key: ""
    server_url: ""
  confluence:
    enabled: false
    space_key: ""
    server_url: ""
  jama:
    enabled: false
    project_id: ""
    server_url: ""
```

## Custom Rules

```yaml
custom:
  # Add project-specific rules that override defaults
  max_function_length: 50
  max_file_length: 500
  naming_convention: "camelCase"  # camelCase | snake_case | PascalCase
  test_pattern: "**/*.test.*"
  ignore_patterns:
    - "node_modules/**"
    - "dist/**"
    - "*.generated.*"
```
