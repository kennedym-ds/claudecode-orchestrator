# Changelog

All notable changes to the Claude Code Orchestrator.

## [1.0.0] — 2026-03-25

### Added
- 6 plugins: cc-sdlc-core, cc-sdlc-standards, cc-github, cc-jira, cc-confluence, cc-jama
- 24 agents: conductor, planner, implementer, reviewer, researcher, security-reviewer, tdd-guide, red-team, doc-updater, and integration agents
- 54 skills: 18 core workflow, 20 language coding standards, 7 domain overlays, 9 integration
- 30 slash commands: /conduct, /plan, /implement, /review, /research, /secure, /test, /deploy-check, /doc, /red-team, /audit, /route, /status, /compact, and plugin commands
- 6 behavioral rules: persona, quality, security, lifecycle, delegation, budget
- 17 hook scripts: session lifecycle, safety checks, quality gates, secret detection, deploy guard, dependency scanning, pre/post-compact state persistence
- 3 MCP plugins: cc-jira (8 tools), cc-confluence (6 tools), cc-jama (8 tools)
- Three-tier model configuration (heavy/default/fast) with env var overrides
- 3 settings profiles: budget, standard, premium
- Validation and smoke test scripts (bash + PowerShell, 66 checks)
- Deployment scripts for user-level and project-level install
- Plugin manifest for marketplace distribution
- Documentation: onboarding, model configuration, CLI reference, workflows, troubleshooting, MCP plugin development

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
