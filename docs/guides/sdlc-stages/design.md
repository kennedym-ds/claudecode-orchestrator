# SDLC Stage: Design & Architecture

Translating requirements into implementation blueprints, architectural decisions, and threat models.

## Agents at This Stage

| Agent | Role | Model |
|-------|------|-------|
| `architect` | Architecture decisions, ADRs, component design | Opus |
| `planner` | Phased implementation plans | Opus |
| `threat-modeler` | STRIDE threat analysis, pre-implementation security | Opus |
| `researcher` | Background research, pattern investigation | Sonnet |

## Entry Points

**Architecture decision needed:**
```bash
claude --agent architect
/architect <decision or design question>
```

**Implementation plan needed:**
```bash
claude --agent planner
/plan <feature or task>
```

**Security threat model needed:**
```bash
claude --agent threat-modeler
/threat-model <feature with security surface>
```

**Research a pattern or approach first:**
```bash
claude --agent researcher
/research <technical question>
```

## Architecture Decisions

The `architect` produces Architecture Decision Records (ADRs) — the authoritative record of what was decided and why.

```bash
claude --agent architect
/architect Should we use WebSockets or Server-Sent Events for real-time notifications?

# Architect will:
# 1. Explore the current system — understand existing patterns and constraints
# 2. Evaluate 2-3 approaches (minimal, clean, pragmatic trade-offs)
# 3. Recommend one approach with rationale
# 4. Produce an ADR with:
#    - Context: what triggered this decision
#    - Options evaluated: with pros/cons
#    - Decision: chosen approach
#    - Consequences: what changes, what breaks
#    - Component diagram (ASCII or Mermaid)
#    - Migration path from current state
```

**ADR output:** `artifacts/decisions/{date}-{slug}.md`

### Architect Principles

- Extend before you invent — prefer existing patterns
- Every abstraction needs 3+ concrete use cases
- Design for the problem you have, not the one you might have
- If the change is simple enough not to need architecture — say so

## Implementation Planning

The `planner` breaks work into ordered phases that a developer (or implementer agent) can execute independently.

```bash
claude --agent planner
/plan Add multi-factor authentication with TOTP and SMS fallback

# Plan includes:
# - Objective: what and why
# - Phases: ordered steps with scope, files affected, acceptance criteria
# - Risk register: severity + mitigation per risk
# - Open questions: needs human input before proceeding
# - Success criteria: measurable, verifiable
# - Model recommendation: which tier suits each phase
```

**Plan output:** `artifacts/plans/{feature}/plan.md`

Each phase should be completable in one implementer session. Phases exceeding ~500 lines of changes should be broken down further.

### Reviewing a Plan

Plans are read-only artifacts until you approve them. At the pause point after planning:

1. Read `artifacts/plans/{feature}/plan.md`
2. Check: Is the scope right? Are the phases in the right order? Are the risks identified?
3. Edit the plan if needed (add context, adjust scope, resolve open questions)
4. Approve → implementation begins

## Threat Modeling

Run threat modeling before implementation on any feature with a security surface — auth, file I/O, external APIs, user-controlled data.

```bash
claude --agent threat-modeler
/threat-model JWT token issuance and validation for the new SSO integration

# STRIDE applied to each trust boundary crossing:
# | Threat | STRIDE | DREAD Score | Mitigation |
# | Token forgery | Spoofing | 8.2 | JWT RS256 + short expiry |
# | Token replay | Tampering | 6.1 | JTI claim + blacklist |
# | Missing audit | Repudiation | 5.0 | Log all issuance events |
# ...

# Output: threat model with residual risks identified
```

**Threat model output:** `artifacts/security/threat-model-{feature}.md`

Share this with the planner so mitigations are built into the implementation plan phases, not retrofitted.

## Research Before Design

When the right approach is uncertain:

```bash
claude --agent researcher
/research What are the production failure modes of TOTP-based MFA and how do mature implementations handle them?

# Output: evidence-based analysis with citations
# Every claim has a source (official docs, source code, or peer-reviewed reference)
# Confidence level: HIGH / MEDIUM / LOW
```

**Research output:** `artifacts/research/{topic}.md`

## Design Stage Workflow

Recommended sequence for non-trivial features:

```
1. Research      → /research     → understand problem space, existing patterns
2. Threat model  → /threat-model → identify security surface before design
3. Architecture  → /architect    → structural decision if cross-cutting
4. Plan          → /plan         → phased implementation blueprint
5. PAUSE         → human review and approval
6. → Hand off to Implementation stage
```

For simpler features (STANDARD complexity), skip to step 4.

## Handoff to Implementation

When design is complete, hand off:
- Approved plan at `artifacts/plans/{feature}/plan.md`
- Threat model at `artifacts/security/threat-model-{feature}.md` (if produced)
- ADR at `artifacts/decisions/` (if an architectural decision was made)
- Research at `artifacts/research/` (if relevant)

The implementer agent reads the plan. The security-reviewer reads the threat model. Both use the ADR to understand constraints.
