# Changelog

All notable changes to the Claude Code Orchestrator.

## [3.2.0] — 2026-03-30

### Added
- **Cross-Session Learnings** (`/learn`) — manage persistent lessons learned via `add`, `list`, `search`, `remove`, `export` subcommands; stored in `artifacts/memory/learnings.jsonl` with soft-delete
- **Invertible Safety Commands** — `/careful` toggles enhanced confirmation mode; `/freeze <path>` restricts all edits to a directory; `/unfreeze` removes the restriction
- **Freeze Guard Hook** (`freeze-guard.js`) — PreToolUse hook for Edit|Write that hard-blocks file edits outside frozen path (exit 2)
- **Safety Mode Rule** (`safety-mode.md`) — behavioral guardrails when careful mode or freeze is active
- **Session Analytics** (`/metrics`) — inline session analytics from JSONL logs; agent usage, file edits, delegation counts
- **Analytics Scripts** — `scripts/analyze-sessions.ps1` and `scripts/analyze-sessions.sh` for terminal-based session analytics
- 1 new skill: learnings-mgmt
- 5 new commands: learn, careful, freeze, unfreeze, metrics

### Changed
- hooks.json: added PreToolUse matcher for Edit|Write with freeze-guard hook (22 hook entries total)
- help.md: added Session Management and Safety Controls sections with all new commands
- AGENTS.md, CLAUDE.md, README.md: regenerated from templates (57 skills, 37 commands, 21 hooks)

## [3.1.0] — 2026-03-30

### Added
- **Completion Protocol** — standardized subagent return format with 4 statuses (DONE, DONE_WITH_CONCERNS, BLOCKED, NEEDS_CONTEXT) and structured fields (STATUS, SUMMARY, DELIVERABLES, VERIFICATION, CONCERNS, REASON, ATTEMPTED, QUESTIONS, RECOMMENDATION)
- **Structured Escalation** — 3-attempt retry limit in delegation.md; failed agents emit BLOCKED with documented attempts
- **Proactive Skill Routing** — `--inject-routing` / `-InjectRouting` flag on all installers appends keyword-to-command routing table into target CLAUDE.md (opt-in, idempotent)
- **Template System** — `.tmpl` files for AGENTS.md, CLAUDE.md, README.md with `{{PLACEHOLDER}}` tokens; `gen-skill-docs.ps1` / `.sh` counts assets from plugin dirs and generates output; `--check` mode detects stale counts
- **Version Check + Auto-Update** — `plugins/cc-sdlc-core/VERSION` file; `session-start.js` compares deployed vs source version, runs `git pull --ff-only` + redeploy when stale; deploy scripts write `.cc-sdlc-version` to target
- 1 new skill: completion-protocol
- `installer/templates/skill-routing.md` — 18-row routing table mapping keyword patterns to commands
- `scripts/gen-skill-docs.ps1` and `scripts/gen-skill-docs.sh` — template generation with `--check` and `--fix` modes
- `validate-assets.ps1` / `.sh` — template freshness check (warning-level)

### Changed
- conductor.md, implementer.md, reviewer.md, researcher.md, security-reviewer.md, planner.md: added completion-protocol skill + structured completion output sections
- delegation.md: added escalation counter rule (3-attempt limit)
- deploy-user.ps1/sh: added `-InjectRouting` flag + version file write
- install.ps1/sh: added `-InjectRouting` flag
- session-start.js: added version comparison + auto-update logic
- AGENTS.md, CLAUDE.md, README.md: regenerated from templates (56 skills, 20 core skills)

### Fixed
- Stale skill counts across documentation (55→56 skills, 19→20 core skills)

## [3.0.0] — 2026-03-29

### Added
- **Agent Teams** — optional parallel execution for DEEP/ULTRADEEP tasks (~7x cost, opt-in)
- 3 team definitions: review-team (trilateral review), research-team (parallel research), implement-team (worktree-isolated)
- 3 hook scripts: task-created.js (validation + budget gate), task-completed.js (state tracking + synthesis), teammate-idle.js (advisory logging)
- 1 skill: team-routing (assembly, cost estimation, task injection, fallback decision tree)
- 1 command: /team (list, assemble, status, cancel)
- /help command with full reference card
- 3 settings profiles: settings-teams-disabled.json, settings-teams-enabled.json, settings-teams-premium.json
- 6 team env vars: ORCH_TEAMS_ENABLED, ORCH_TEAM_MAX_TASKS, ORCH_TEAM_SIZE_MAX, ORCH_TEAM_DISPLAY_MODE, ORCH_TEAM_AUTO_ROUTE, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
- Guide: docs/guides/using-agent-teams.md

### Changed
- conductor.md: added team-routing skill, team assembly sequence, Agent(review-team, research-team, implement-team) tools
- delegation.md: added team delegation guardrails
- budget-gatekeeper SKILL.md: added team mode limits
- delegation-routing SKILL.md: added team recommendation to /route output
- conduct.md, route.md, help.md: updated for --team flag and team commands
- hooks.json: added TeammateIdle, TaskCreated, TaskCompleted events
- AGENTS.md, CLAUDE.md: updated counts (55 skills, 32 commands, 20 hooks), added Teams docs
- installation.md: updated cc-sdlc-core counts (19 skills, 24 commands, 20 hooks)
- Validation scripts: added teams asset checks
- Smoke tests: added budget/premium profile checks + help command check
- settings-budget.json, settings-premium.json: added team env vars

## [2.0.0] — 2026-03-25

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
- Validation and smoke test scripts (bash + PowerShell, 67 checks)
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
