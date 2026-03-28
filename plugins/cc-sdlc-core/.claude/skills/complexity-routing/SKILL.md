---
name: complexity-routing
description: Complexity assessment and agent routing — classifies tasks by complexity tier and selects the optimal agent roster and model tier. Use when routing tasks, assessing complexity, or selecting agents.
user-invocable: false
---

# Complexity Routing

## Tier Classification

Assess every incoming request against these signals:

### INSTANT (handle directly)
- Single factual question
- Clarification of existing decision
- Status check or summary request
- No code changes needed

### STANDARD (plan → implement → review)
- Single-file or few-file change
- Well-understood pattern
- Clear requirements, no ambiguity
- No security or architectural implications

### DEEP (research → plan → implement → review → security)
- Multi-file or multi-module change
- Requires investigation or research first
- Security-sensitive components involved
- New integration or API surface
- Performance-critical path

### ULTRADEEP (research → plan → architect → implement → trilateral review)
- Architectural change or new system design
- Cross-cutting concerns (auth, data model, API contract)
- Compliance or regulatory implications
- Irreversible changes (data migration, public API)
- Multiple team/role involvement needed

## Agent Roster by Tier

| Tier | Required Agents | Optional Support |
|------|----------------|-----------------|
| INSTANT | Conductor only | — |
| STANDARD | Planner → Implementer → Reviewer | Doc-Updater |
| DEEP | Researcher → Planner → Implementer → Reviewer → Security-Reviewer | Test-Architect, Deploy-Engineer |
| ULTRADEEP | Researcher → Planner → Architect → Implementer → Reviewer + Red-Team + Security-Reviewer | Threat-Modeler, Test-Architect, Deploy-Engineer |

## Model Tier Selection

| Agent Role | STANDARD | DEEP | ULTRADEEP |
|-----------|----------|------|-----------|
| Orchestration | sonnet | opus | opus |
| Planning | sonnet | opus | opus |
| Implementation | sonnet | sonnet | sonnet |
| Review | sonnet | opus | opus |
| Security | — | opus | opus |
| Support | haiku | haiku | sonnet |

## Signal Detection Keywords

- **INSTANT:** "what is", "how do I", "explain", "show me", "status"
- **STANDARD:** "fix", "add", "update", "change", "implement"
- **DEEP:** "integrate", "secure", "migrate", "refactor", "optimize"
- **ULTRADEEP:** "redesign", "architect", "rebuild", "replace", "new system"
