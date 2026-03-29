# /help — Command Reference

Display available commands, agents, and quick-start guidance for cc-sdlc.

## Instructions

Output the reference below exactly. Do not read any files or start any work.

## Output

```
╔══════════════════════════════════════════════════════════════╗
║              cc-sdlc — Command Reference (v3.0.0)            ║
╚══════════════════════════════════════════════════════════════╝

ENTRY POINTS
  /conduct [--team]   Full lifecycle orchestration (recommended starting point)
  /plan               Multi-phase planning only
  /implement          TDD implementation only
  /review             Code review with severity tagging
  /route              Assess task complexity before choosing workflow

DISCOVERY & PLANNING
  /spec               Interactive specification builder
  /research           Evidence gathering and citation
  /estimate           T-shirt sizing and story point estimation
  /architect          Architecture design and ADR generation

CODING & TESTING
  /pair               Pair programming session
  /test               Write tests first (TDD)
  /test-arch          Test strategy and pyramid design
  /e2e                End-to-end acceptance tests

SECURITY & QUALITY
  /secure             OWASP security audit
  /threat-model       STRIDE/DREAD threat modeling
  /red-team           Adversarial testing and edge cases

OPERATIONS
  /deploy-check       Pre-deploy CI/CD readiness check
  /incident           Incident response and 5-why root cause analysis
  /doc                Documentation generation and sync

AGENT TEAMS (experimental — requires ORCH_TEAMS_ENABLED=true)
  /conduct --team     Enable team mode for DEEP/ULTRADEEP phases
  /team list          Show available teams and prerequisites
  /team assemble      Assemble a team for the current phase
  /team status        Check active team progress
  /team cancel        Cancel the active team

SESSION MANAGEMENT
  /status             Session state, budget usage, active context
  /audit              Quality audit of the orchestrator harness
  /compact            Strategic context compaction at milestones

COMPLEXITY ROUTING
  INSTANT    → Direct response          (trivial questions, small fixes)
  STANDARD   → Plan → Implement → Review  (single-file changes)
  DEEP       → Research → Plan → Implement → Review → Security
  ULTRADEEP  → Research → Plan → Implement → Trilateral Review

QUICK START
  New feature:      /conduct "add user authentication to the API"
  Bug fix:          /conduct "fix the race condition in the queue processor"
  Code review:      /review
  Security check:   /secure
  Just planning:    /plan "migrate from REST to GraphQL"
  Check complexity: /route "refactor the entire data layer"

AGENTS (19 core — available via /conduct or directly)
  Heavy (Opus):    conductor, planner, architect, reviewer,
                   security-reviewer, threat-modeler, red-team
  Default (Sonnet): implementer, researcher, spec-builder, pair-programmer,
                    test-architect, tdd-guide, e2e-tester, incident-responder, doc-updater
  Fast (Haiku):    req-analyst, estimator, deploy-engineer

CONFIGURATION
  Model tiers:  Edit ORCH_MODEL_HEAVY / ORCH_MODEL_DEFAULT / ORCH_MODEL_FAST in .claude/settings.json
  Team mode:    Set ORCH_TEAMS_ENABLED=true + CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
  Examples:     examples/settings-standard.json, settings-teams-enabled.json

DOCS
  guides/user-guide.md           Full user guide
  guides/using-agent-teams.md    Agent Teams setup and usage
  guides/installation.md         Installation and configuration
```
