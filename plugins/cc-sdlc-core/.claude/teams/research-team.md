---
name: research-team
description: Parallel research — 2-3 researchers investigate orthogonal aspects of a problem simultaneously. Use before DEEP/ULTRADEEP planning to front-load knowledge gathering.
complexity: [DEEP, ULTRADEEP]
display_mode: auto
teammates:
  - role: researcher
    instance: researcher-1
    model: sonnet
    maxTurns: 40
    permissionMode: plan
    task_type: domain_research
  - role: researcher
    instance: researcher-2
    model: sonnet
    maxTurns: 40
    permissionMode: plan
    task_type: prior_art_research
  - role: researcher
    instance: researcher-3
    model: sonnet
    maxTurns: 40
    permissionMode: plan
    task_type: risk_research
    optional: true
success_criterion: all_required_tasks_complete
synthesis_agent: planner
artifact_output: artifacts/research/team-research-{date}.md
---

# Research Team — Coordination Protocol

## Purpose

Front-load knowledge gathering before planning by running 2-3 researchers in parallel on orthogonal sub-questions. Eliminates sequential research bottleneck for DEEP/ULTRADEEP tasks.

## Task Breakdown

The conductor decomposes the research question into 2-3 orthogonal sub-questions at injection time:

| Instance | Focus | Task Type |
|----------|-------|-----------|
| researcher-1 | Domain/technology research — how does X work, what are the established patterns | `domain_research` |
| researcher-2 | Prior art and alternatives — what have others done, what tools/libraries exist, community patterns | `prior_art_research` |
| researcher-3 _(optional)_ | Risks and failure modes — what can go wrong, known anti-patterns, operational concerns | `risk_research` |

researcher-3 is only spawned when `ORCH_TEAM_SIZE_MAX >= 3` (check before assembly) and complexity is ULTRADEEP.

## Task Templates

**domain_research:**
> Research `{domain_question}`. Provide key findings with citations. State your confidence level for each finding. Save output to `artifacts/research/{slug}-domain.md`.

**prior_art_research:**
> Investigate prior art and alternatives for `{topic}`. Survey existing solutions, libraries, frameworks, and community-accepted patterns. Cite sources. Save to `artifacts/research/{slug}-prior-art.md`.

**risk_research:**
> Identify risks, known failure modes, and anti-patterns for `{topic}`. Focus on operational, security, and maintenance risks. Save to `artifacts/research/{slug}-risks.md`.

## Coordination

No inter-teammate messaging. Researchers self-claim tasks (all pending, no dependencies). Tasks complete independently.

## Completion

Required tasks (researcher-1 and researcher-2) must reach `completed` state. researcher-3 completion is logged but not blocking.

## Synthesis

The `planner` agent (not the conductor) synthesizes research outputs into a planning brief before the conductor proceeds to plan creation. Planner reads all `artifacts/research/{slug}-*.md` files.

## Cost

~5-7x a single session. Only assemble for DEEP/ULTRADEEP. Require user confirmation before assembly.
