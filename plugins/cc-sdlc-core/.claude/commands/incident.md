# /incident — Incident Response

Investigate and respond to: $ARGUMENTS

## Instructions

1. Classify severity (SEV1-4) based on blast radius and user impact
2. Gather evidence: logs, error messages, recent changes, metrics
3. Execute investigation protocol: triage → isolate → diagnose → fix → verify
4. Apply 5-why root cause analysis
5. Categorize fix: HOTFIX (immediate), PROPER (scheduled), SYSTEMIC (architectural)
6. Generate post-mortem using template to `artifacts/plans/`

Use the incident-responder agent with incident-response skill.
