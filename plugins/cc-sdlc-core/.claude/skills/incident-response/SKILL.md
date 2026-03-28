---
name: incident-response
description: Incident investigation protocol — structured debugging with 5-why analysis, evidence gathering, and post-mortem documentation.
user-invocable: false
---

# Incident Response

## Severity Classification

| Level | Impact | Response Time | Escalation |
|-------|--------|--------------|------------|
| SEV1 | Service down, data loss | Immediate | Architect + Security |
| SEV2 | Major feature broken | < 1 hour | Lead + Reviewer |
| SEV3 | Minor feature degraded | < 4 hours | Implementer |
| SEV4 | Cosmetic, non-blocking | Next sprint | Doc in backlog |

## Investigation Protocol

### 1. Triage (5 minutes)
- What is the symptom?
- What is the impact radius?
- When did it start?
- Is it ongoing or resolved?

### 2. Evidence Gathering
- Error logs and stack traces
- Recent deployments or changes (git log)
- System metrics (CPU, memory, latency)
- User reports or reproduction steps

### 3. Root Cause Analysis (5 Whys)
```
Why did the service fail? → {direct cause}
  Why did that happen? → {contributing factor}
    Why wasn't it caught? → {detection gap}
      Why wasn't it prevented? → {process gap}
        What systemic change prevents this? → {root cause fix}
```

### 4. Fix Categorization
- **Hotfix:** Minimal change to restore service (deploy immediately)
- **Proper fix:** Correct solution with tests (deploy in next cycle)
- **Systemic fix:** Process or architecture change (plan and schedule)

### 5. Post-Mortem Template
```markdown
## Incident: {title}
**Date:** {date}
**Severity:** {level}
**Duration:** {start} → {end}
**Impact:** {who/what affected}

### Timeline
- {HH:MM} — {event}

### Root Cause
{5-why chain}

### Resolution
{what was done}

### Action Items
- [ ] {preventive action} — Owner: {name} — Due: {date}
```

## Debugging Guardrail

If 3 fix attempts fail → stop and escalate to architecture review. Don't keep trying random fixes.
