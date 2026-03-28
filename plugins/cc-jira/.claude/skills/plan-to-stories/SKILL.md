---
name: plan-to-stories
description: Convert orchestrator plan phases into Jira stories with acceptance criteria. Use after plan approval to create trackable work items.
argument-hint: <plan-path>
---

# Plan to Jira Stories

## Process

1. **Read the plan** from the provided path or `artifacts/plans/`
2. **For each phase**, create a Jira story:
   - Summary: Phase title from the plan
   - Description: Phase scope, deliverables, and acceptance criteria
   - Issue type: Story (or Epic for the overall plan)
   - Labels: `orchestrator`, `phase-{N}`
   - Priority: Map from plan risk register (HIGH risk = High priority)
3. **Create an Epic** for the overall plan if it has 3+ phases
4. **Link stories** to the Epic as children
5. **Report** created issue keys mapped to plan phases

## Mapping Rules

| Plan Element | Jira Field |
|-------------|------------|
| Plan title | Epic summary |
| Phase title | Story summary |
| Phase scope + deliverables | Story description |
| Acceptance criteria | Story acceptance criteria (description section) |
| Risk severity HIGH | Priority: High |
| Risk severity MEDIUM | Priority: Medium |
| Risk severity LOW | Priority: Low |
| Model tier recommendation | Label: `tier-{heavy\|default\|fast}` |

## Usage

```
claude /cc-jira:plan-to-stories artifacts/plans/my-feature/plan.md
```