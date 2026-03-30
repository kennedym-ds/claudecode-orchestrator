## Skill Routing

When the user's request matches a pattern below, invoke the corresponding command instead of answering directly. The command has specialized workflows, checklists, and quality gates that produce better results.

| Pattern | Command | Purpose |
|---------|---------|---------|
| Plan, design, architecture, "build this" | `/conduct` | Full lifecycle orchestration |
| Complex multi-step task | `/conduct` | Complexity-routed delegation |
| Break down, plan, scope, phases | `/plan` | Multi-phase planning |
| Architecture, system design, ADR | `/architect` | Architecture decisions |
| Spec, requirements, "what should we build" | `/spec` | Requirements elicitation |
| Fix, add, update, implement, change | `/implement` | TDD implementation |
| Review, audit, check quality | `/review` | Severity-tagged code review |
| Test, coverage, TDD | `/test` | Test writing |
| Security, vulnerability, OWASP | `/secure` | Security audit |
| Threat model, attack surface | `/threat-model` | STRIDE/DREAD analysis |
| Bug, error, crash, broken, "why is this" | `/incident` | Root cause analysis |
| Research, investigate, compare, evaluate | `/research` | Evidence gathering |
| Estimate, size, effort, story points | `/estimate` | Effort estimation |
| Pair, help me code, work together | `/pair` | Pair programming |
| Deploy, ship, release, CI/CD | `/deploy-check` | Deployment readiness |
| Document, docs, update README | `/doc` | Documentation sync |
| Jira, sprint, story, ticket | `/jira-context` | Jira integration |
| Confluence, wiki, publish, knowledge base | `/confluence-search` | Confluence integration |
