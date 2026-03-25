# Example CLAUDE.md for Consuming Projects

> Copy this to your project root and customize for your stack.

# My Project

> [Project description here]

## Tech Stack
- Language: [e.g., TypeScript, Python, Go]
- Framework: [e.g., Next.js, FastAPI, Gin]
- Database: [e.g., PostgreSQL, MongoDB]
- Testing: [e.g., Jest, pytest, go test]

## Build & Test
```bash
npm run build    # Build
npm test         # Test
npm run lint     # Lint
```

## Conventions
- [List project-specific conventions here]
- [e.g., "All API endpoints must have integration tests"]
- [e.g., "Use conventional commits"]

## Model Tiers
This project uses claudecode-orchestrator model tiers:
- Heavy (Opus): Architecture decisions, security reviews
- Default (Sonnet): Feature implementation, research
- Fast (Haiku): Quick fixes, routing, triage

Customize in `.claude/settings.json` → `env.ORCH_MODEL_*`
