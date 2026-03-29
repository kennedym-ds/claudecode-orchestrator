---
name: review-team
description: Parallel trilateral review — reviewer + security-reviewer + threat-modeler run concurrently on the same changeset. Each has an independent context window. Only justified for DEEP/ULTRADEEP complexity.
complexity: [DEEP, ULTRADEEP]
display_mode: auto
teammates:
  - role: reviewer
    model: opus
    maxTurns: 30
    permissionMode: plan
    task_type: quality_review
  - role: security-reviewer
    model: opus
    maxTurns: 30
    permissionMode: plan
    task_type: security_review
  - role: threat-modeler
    model: opus
    maxTurns: 30
    permissionMode: plan
    task_type: threat_model
success_criterion: all_tasks_complete
synthesis_agent: conductor
artifact_output: artifacts/reviews/team-review-{date}.md
---

# Review Team — Coordination Protocol

## Purpose

Run reviewer, security-reviewer, and threat-modeler simultaneously, each examining the same changeset from a different angle. Findings are independent (reviewers do not communicate during analysis), then synthesized by the conductor using the `pr-review` skill.

## Task Breakdown

Three tasks are injected simultaneously with no dependencies between them. All three start immediately.

**Task templates:**

| Task ID | Assigned To | Instructions |
|---------|-------------|--------------|
| `review-quality` | reviewer | Review the changed files in `{scope}` for correctness, code quality, test coverage, and maintainability. Use the `review-workflow` skill. Tag each finding with severity: CRITICAL / HIGH / MEDIUM / LOW / INFO. |
| `review-security` | security-reviewer | Conduct an OWASP-aligned security review of `{scope}`. Use the `security-review` skill. Rate each finding CRITICAL / HIGH / MEDIUM / LOW. Include CVSS score where applicable. |
| `review-threat` | threat-modeler | Build a STRIDE threat model for the changes in `{scope}`. Identify trust boundaries changed by this diff. Rate threats using DREAD. |

## Coordination

No inter-teammate messaging during review — independence of findings is intentional. Reviewers do not know what others are finding until synthesis.

## Completion Signal

When all three tasks complete, `task-completed.js` writes `artifacts/reviews/team-consensus-pending.md`. The conductor checks for this marker before proceeding to synthesis.

## Synthesis

Conductor invokes the `pr-review` skill against the three output reports. The skill applies confidence scoring and produces a consolidated verdict: APPROVED / APPROVED_WITH_NOTES / CHANGES_REQUIRED / BLOCKED.

## Cost

~7x a single session. Only assemble for DEEP/ULTRADEEP. Require user confirmation before assembly.
