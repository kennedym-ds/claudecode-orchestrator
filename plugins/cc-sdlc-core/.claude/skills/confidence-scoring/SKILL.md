---
name: confidence-scoring
description: Confidence-based scoring system for review findings — calibrates issue severity with evidence strength to filter false positives. Use when reviewing code, analyzing findings, or scoring issues.
user-invocable: false
---

# Confidence Scoring

## Scoring Scale

Rate every finding 0-100 based on evidence strength:

| Score | Level | Meaning | Action |
|-------|-------|---------|--------|
| 0-24 | Not confident | Likely false positive, insufficient evidence | Filter out |
| 25-49 | Somewhat confident | Might be real, needs investigation | Note only |
| 50-74 | Moderately confident | Real but minor, or real but context-dependent | Include if reviewer |
| 75-89 | Highly confident | Real and important, strong evidence | Always include |
| 90-100 | Certain | Verified issue with definitive evidence | Flag as critical |

## Default Threshold

**80** — only findings scored ≥80 are reported to the user by default. Configurable in `sdlc-config.md`.

## Scoring Criteria

For each finding, evaluate:
1. **Evidence strength** — Can you point to exact code that proves the issue?
2. **Context relevance** — Is this actually a problem in this codebase's context?
3. **Not pre-existing** — Was this introduced by the change, or was it already there?
4. **Not linter territory** — Will a linter catch this? If so, don't duplicate.
5. **Specificity** — Can you describe exactly what breaks and how?

## Applying Confidence Scores

```
### Finding: {description}
- **Confidence:** {score}/100
- **Evidence:** {exact code reference}
- **Category:** Bug | Security | Convention | Performance | Maintainability
- **Recommendation:** {specific fix}
```

## False Positive Indicators (lower score)

- Issue exists in unchanged code (pre-existing)
- Linter or type checker would catch it
- Pattern is intentional based on CLAUDE.md or codebase conventions
- Theoretical risk with no practical exploitation path
- Pedantic style preference
