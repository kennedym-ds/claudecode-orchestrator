---
name: spec-elicitation
description: Structured requirements elicitation through interactive dialogue — guides the spec-builder agent through 5 phases of discovery, scoping, behavior definition, risk analysis, and assembly.
user-invocable: false
---

# Spec Elicitation

## 5-Phase Dialogue Protocol

### Phase 1: Problem Discovery (3-5 questions)
Ask about:
- The problem being solved and why it matters
- Primary users and their context
- What success looks like (measurable outcomes)
- Hard constraints (deadline, tech stack, compliance)
- Existing systems this replaces or integrates with

**Summarize understanding before moving on.**

### Phase 2: Scope Definition (3-5 questions)
Establish:
- Explicit in-scope items
- Explicit out-of-scope items (prevents scope creep)
- Functional requirements using MoSCoW (Must/Should/Could/Won't)
- Non-functional requirements (performance, security, availability, accessibility)
- Integration boundaries

**Present scope table for confirmation.**

### Phase 3: Behavior Specification (per feature)
For each functional requirement:
- User story in As a / I want / So that format
- Acceptance criteria in Given / When / Then format
- Edge cases and error conditions
- State transitions (if stateful)
- Data flow diagram (if data moves between systems)

**Walk through each story with the user.**

### Phase 4: Risk & Dependency Analysis
Identify:
- Technical risks (complexity, unknowns, new tech)
- External dependencies (APIs, services, teams)
- Assumptions that must hold true
- Compliance or regulatory requirements
- Fallback plans for key risks

### Phase 5: Assembly
Compile into structured spec with:
- Requirement IDs (REQ-NNNN)
- Traceability matrix (requirement → story → acceptance criteria → test)
- Priority ordering
- Format for target system (Jama JSON, Confluence wiki, or Markdown)

## Dialogue Rules

- Never ask more than 5 questions at once
- Summarize understanding after each phase
- If the user says "you decide," make a recommendation with rationale
- Flag contradictions between earlier and later answers
- Don't move to the next phase until the current one is confirmed
