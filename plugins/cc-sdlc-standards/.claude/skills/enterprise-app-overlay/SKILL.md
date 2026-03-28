---
name: enterprise-app-overlay
description: Domain overlay for enterprise application development. Extends language standards with architecture patterns, observability, and operational readiness rules.
---

# Enterprise App Overlay

> Activates when `sdlc-config.md` sets `domain.primary: enterprise-app` or `domain.secondary` includes it.

## Additional ERROR Rules
- All API endpoints must have authentication and authorization checks
- PII must be encrypted at rest and in transit — document data classification
- Database migrations must be backward-compatible (no breaking schema changes)
- Health check endpoints required: `/health` (liveness), `/ready` (readiness)
- All external service calls must have timeouts, retries, and circuit breaker patterns
- Structured logging with correlation IDs on all request paths

## Additional WARNING Rules
- Use dependency injection — no service locator or static service references
- API versioning strategy documented and enforced (URL, header, or content negotiation)
- Use pagination for all list endpoints — no unbounded result sets
- Cache strategy documented: what, where, TTL, invalidation
- Use feature flags for gradual rollouts — no big-bang deployments
- Rate limiting on all public-facing endpoints

## Additional RECOMMENDATION Rules
- Consider CQRS for read-heavy domains with complex queries
- Use event sourcing for audit-critical domains
- Implement distributed tracing (OpenTelemetry) across service boundaries
- Consider saga pattern for distributed transactions
- Use contract testing (Pact) between services

## Operational Readiness
- [ ] Runbooks for common failure scenarios
- [ ] Alerting thresholds defined for SLO indicators
- [ ] Capacity planning documented (expected load, scaling triggers)
- [ ] Disaster recovery plan tested
- [ ] Security scan (SAST + DAST) in CI pipeline
- [ ] Performance baseline established
