Model tier budget constraints:

- Default to the "default" tier (Sonnet) for implementation and routine tasks
- Use "heavy" tier (Opus) only for judgment-critical work: reviews, security, planning, architecture
- Use "fast" tier (Haiku) for triage, routing, and INSTANT-complexity tasks
- Target: ≤25% of session tokens on heavy tier
- Report tier usage at pause points
- If approaching budget limits, suggest tier downgrades or scope reduction
- Model IDs are configured via ORCH_MODEL_HEAVY, ORCH_MODEL_DEFAULT, ORCH_MODEL_FAST env vars
