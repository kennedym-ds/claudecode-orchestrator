# Changelog

All notable changes to the Claude Code Orchestrator.

## [1.1.0] -- 2026-03-25

### Added
- 3 MCP plugins: cc-jira (8 tools), cc-confluence (6 tools), cc-jama (8 tools)
- /status command for session state and budget overview
- /compact command for strategic context compaction
- artifact-index.md template for session artifact tracking
- Windows smoke tests (scripts/run-smoke-tests.ps1) -- 59 checks
- 4 new documentation guides:
  - CLI Quick Reference (docs/guides/cli-quick-reference.md)
  - Common Workflows (docs/guides/common-workflows.md)
  - Troubleshooting (docs/guides/troubleshooting.md)
  - MCP Plugin Development (docs/guides/mcp-plugin-development.md)

### Fixed
- validate-assets.ps1: renamed $Verbose to $ShowDetails to avoid CmdletBinding conflict
- subagent-stop-gate.js: added missing event: 'subagent_stop' field to JSONL log
- settings.local.json.example: replaced duplicate // keys with single _comment key
- Stripped UTF-8 BOM from all new files (PowerShell encoding issue)

### Changed
- Updated onboarding guide with new commands, plugins, project layout, and cross-references
- Commands count: 12 -> 14 (added status, compact)

### Plugin Details

#### cc-jira
- MCP tools: search_issues, get_issue, create_issue, update_issue, transition_issue, add_comment, get_sprint, get_project
- Skills: plan-to-stories, issue-context
- Agent: jira-sync (Sonnet tier)
- Commands: /jira-sync, /jira-context
- Auth: Basic Auth (email + API token) over HTTPS

#### cc-confluence
- MCP tools: search_pages, get_page, create_page, update_page, get_space, get_page_children
- Skills: publish-plan, publish-review, research-confluence
- Agent: confluence-sync (Sonnet tier)
- Commands: /confluence-publish, /confluence-search
- Auth: Basic Auth (email + API token) over HTTPS

#### cc-jama
- MCP tools: get_items, search_items, get_item, get_item_children, get_relationships, get_test_runs, get_projects, get_item_types
- Skills: req-tracing, test-coverage-map
- Agent: jama-sync (Sonnet tier)
- Commands: /jama-trace, /jama-context
- Auth: OAuth 2.0 client credentials with token caching

## [1.0.0] — 2026-03-25

### Added
- 9 focused agents: conductor, planner, implementer, reviewer, researcher, security-reviewer, tdd-guide, red-team, doc-updater
- 10 workflow skills: tdd-workflow, security-review, coding-standards, plan-workflow, review-workflow, delegation-routing, budget-gatekeeper, strategic-compact, verification-loop, session-continuity
- 12 slash commands: /conduct, /plan, /implement, /review, /research, /secure, /test, /deploy-check, /doc, /red-team, /audit, /route
- 6 behavioral rules: persona, quality, security, lifecycle, delegation, budget
- 9 hook event handlers: session lifecycle, safety checks, quality gates, secret detection
- Three-tier model configuration (heavy/default/fast) with env var overrides
- 3 settings profiles: budget, standard, premium
- Validation and smoke test scripts (bash + PowerShell)
- Installation scripts for manual setup
- Plugin manifest for marketplace distribution
- Documentation: onboarding guide, model configuration guide, templates
