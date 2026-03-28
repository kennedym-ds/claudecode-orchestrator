# Guides by SDLC Stage

Start here based on where you are in the development lifecycle. Each guide covers the agents, commands, and outputs for that stage.

| Stage | Guide | Primary Agents |
|-------|-------|----------------|
| Requirements | [requirements.md](requirements.md) | spec-builder, req-analyst, estimator |
| Design & Architecture | [design.md](design.md) | architect, planner, threat-modeler, researcher |
| Implementation | [implementation.md](implementation.md) | implementer, tdd-guide, pair-programmer |
| Testing | [testing.md](testing.md) | test-architect, tdd-guide, e2e-tester |
| Security Review | [security-review.md](security-review.md) | security-reviewer, red-team, threat-modeler |
| Deployment | [deployment.md](deployment.md) | deploy-engineer, doc-updater |
| Incident Response | [incident-response.md](incident-response.md) | incident-responder |

## Stage Flow

```
Requirements → Design → Implementation → Testing → Security Review → Deployment
                                                                          ↓
                                                               Incident Response
                                                               (if issues arise)
```

## Which Stage Am I In?

- **Defining what to build** → Requirements
- **Deciding how to build it** → Design & Architecture
- **Writing code** → Implementation
- **Verifying the code works** → Testing
- **Verifying the code is secure** → Security Review
- **Shipping the code** → Deployment
- **Recovering from a production issue** → Incident Response

## Automatic Routing

The conductor handles stage sequencing automatically based on complexity tier:

| Tier | Stages Involved |
|------|----------------|
| INSTANT | Direct response — no stages |
| STANDARD | Implementation → Review |
| DEEP | Design → Implementation → Testing → Security Review |
| ULTRADEEP | Design → Implementation → Testing → Trilateral Review |
