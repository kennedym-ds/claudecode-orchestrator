---
name: implement-team
description: Parallel implementation — 2 implementers work on independent modules simultaneously in isolated worktrees. ULTRADEEP only. Requires zero coupling between assigned modules and explicit user approval before assembly.
complexity: [ULTRADEEP]
display_mode: split-panes
teammates:
  - role: implementer
    instance: implementer-1
    model: sonnet
    maxTurns: 80
    permissionMode: acceptEdits
    isolation: worktree
    task_type: module_implementation
  - role: implementer
    instance: implementer-2
    model: sonnet
    maxTurns: 80
    permissionMode: acceptEdits
    isolation: worktree
    task_type: module_implementation
requires_worktree: true
requires_explicit_approval: true
max_teammates: 2
success_criterion: all_tasks_complete_verified
synthesis_agent: conductor
artifact_output: artifacts/plans/{feature}/team-implementation-summary.md
---

# Implement Team — Coordination Protocol

## Purpose

Run two implementers in parallel on independent modules, each in an isolated git worktree. Eliminates sequential bottleneck for ULTRADEEP features with clearly decomposable modules.

## Prerequisites (checked by conductor before assembly)

1. The planner has decomposed the work into modules with **zero coupling** — no shared imports, no shared state, no API contracts between modules being changed in this session.
2. Each module's file list is explicit and non-overlapping.
3. User has confirmed the ~7x cost estimate.

If coupling is detected, **do not assemble**. Use sequential subagent implementation instead.

## Task Breakdown

| Instance | Task | File Scope |
|----------|------|-----------|
| implementer-1 | Phase `{phase_1}` — `{module_1_title}` | `{file_list_1}` |
| implementer-2 | Phase `{phase_2}` — `{module_2_title}` | `{file_list_2}` |

Dependency rule: if there is a shared schema or interface, implementer-2's task gets a soft dependency on implementer-1's setup task. Encode via `dependencies` field at task injection time. The `task-created.js` hook validates dependency IDs exist.

## Task Template

> Implement phase `{phase_number}` of the approved plan: `{phase_title}`.
> Follow TDD — write tests first, then implementation (use `tdd-workflow` skill).
> Target files: `{file_list}`. Do NOT modify files outside this list.
> Use the `verification-loop` skill to confirm: build passes, tests pass, lint passes, type-check passes.
> Report: files changed, tests added, verification results (pass/fail per check).

## Coordination

Split-panes display mode is preferred (requires tmux or iTerm2). Each implementer operates in its own worktree. Implementers do not message each other.

## Completion and Merge

After `all_tasks_complete`:
1. Conductor merges both worktrees (uses `WorktreeRemove` hook flow).
2. Conductor runs `verification-loop` on the merged result.
3. If verification passes: assemble `review-team` against the combined output.
4. If verification fails: route failure to whichever implementer owns the failing file scope.

## Cost

~7x a single session. ULTRADEEP only. **Always require explicit user approval before assembly.** Present cost estimate and module partition plan before proceeding.
