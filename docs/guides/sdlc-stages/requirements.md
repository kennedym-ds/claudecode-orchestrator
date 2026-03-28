# SDLC Stage: Requirements

Turning ideas and business needs into structured, testable specifications.

## Agents at This Stage

| Agent | Role | Model |
|-------|------|-------|
| `spec-builder` | Interactive requirements dialogue | Sonnet |
| `req-analyst` | Story decomposition (INVEST) | Haiku |
| `estimator` | Effort sizing | Haiku |
| `researcher` | Background research on problem space | Sonnet |

## Entry Points

**You have an idea, no spec yet:**
```bash
claude --agent spec-builder
/spec <feature name or problem description>
```

**You have a spec, need stories:**
```bash
claude --agent req-analyst
# Provide the spec and ask for INVEST-compliant story decomposition
```

**You have stories, need estimates:**
```bash
claude --agent estimator
/estimate <list of stories or path to plan>
```

## The Spec-Builder Dialogue

The spec-builder runs a 5-phase structured elicitation. It asks 3-5 questions per phase and waits for your answers before moving on.

```
Phase 1: Problem Discovery
  → What problem is being solved and why?
  → Who are the users?
  → What does success look like?
  → What are the hard constraints?

Phase 2: Scope Definition
  → What is explicitly in scope?
  → What is explicitly out of scope?
  → Functional requirements (MUST/SHOULD/COULD/WON'T)
  → Non-functional requirements (performance, security, availability)

Phase 3: Behavior Specification
  → User stories (As a / I want / So that)
  → Acceptance criteria (Given / When / Then)
  → Edge cases and error conditions

Phase 4: Risk & Dependency Analysis
  → Technical risks
  → External dependencies
  → Assumptions

Phase 5: Assembly
  → Compiled spec with REQ-NNNN IDs
  → Traceability matrix
  → Output in chosen format
```

## Story Format

Stories from the `req-analyst` follow the INVEST criteria:

```
[STORY-001] User can reset password via email link

As a registered user,
I want to receive a password reset link via email
So that I can regain access to my account when I forget my password.

Acceptance Criteria:
- Given a valid email, When I request a reset, Then I receive an email within 2 minutes
- Given an expired link (>15 min), When I click it, Then I see a clear error message
- Given a used link, When I click it again, Then it is rejected

Priority: MUST
Dependencies: [STORY-002 — Email service integration]
Estimated Complexity: M
```

## Integration: Jira

```bash
# After stories are defined and estimated
/jira-sync
# Creates: epic + stories in Jira with acceptance criteria pre-populated

# Link to existing Jira issue
/jira-context PROJ-123
# Pulls issue details into the session for context-aware spec building
```

## Integration: Jama Connect (Regulated Projects)

For projects subject to DO-178C, IEC 62304, or ISO 26262:

```bash
/jama-context REQ-456
# Pulls upstream stakeholder needs and system requirements

/jama-trace
# After implementation — verifies requirements are covered by code + tests
```

## Integration: Confluence

```bash
/confluence-publish
# Publishes completed spec to Confluence as a structured requirements page
```

## Output Artifacts

| Artifact | Location |
|---------|---------|
| Specification (Markdown) | `artifacts/plans/{feature}/spec.md` |
| Jama JSON | `artifacts/plans/{feature}/spec-jama.json` |
| Story list | `artifacts/plans/{feature}/stories.md` |
| Estimates | `artifacts/plans/{feature}/estimates.md` |

## Handoff to Design

When requirements are complete, the handoff package for the next stage includes:
- Approved spec in `artifacts/plans/{feature}/spec.md`
- Story list with priorities and dependencies
- Open questions resolved (or explicitly deferred)
- Risk register seeded with identified concerns

The architect and planner will read this context when producing the design and implementation plan.
