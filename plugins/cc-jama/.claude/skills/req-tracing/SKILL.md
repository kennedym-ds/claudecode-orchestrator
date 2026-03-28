---
name: "req-tracing"
description: "Traces requirements through Jama's relationship graph — upstream to stakeholder needs, downstream to test cases and design items."
---

# Requirements Tracing

## When to Use

During planning or review phases when you need to understand the full traceability chain for a requirement, feature, or test case.

## Workflow

1. Identify the target item (by ID, document key, or search)
2. Get upstream relationships — traces to parent requirements, stakeholder needs, epics
3. Get downstream relationships — traces to child requirements, test cases, design elements
4. Build a traceability matrix showing the full chain

## Output Format

```markdown
## Traceability Report: {item_name} ({document_key})

### Upstream (traces to)
| Item | Type | Name | Status |
|------|------|------|--------|
| REQ-123 | Stakeholder Need | User authentication | Approved |

### Downstream (traced from)
| Item | Type | Name | Status |
|------|------|------|--------|
| TC-456 | Test Case | Login flow test | Active |
| DES-789 | Design Element | Auth module design | Draft |

### Coverage Summary
- Upstream requirements: {count} ({covered}% with approved status)
- Test coverage: {count} test cases ({passed}% passing)
- Gaps: {items without downstream test coverage}
```

## CLI Example

```bash
# Trace a requirement
claude -p "trace requirement item 1234 in Jama — show upstream needs and downstream test cases" \
  --tool mcp__cc_jama__get_item --tool mcp__cc_jama__get_relationships

# Find untested requirements
claude -p "find all requirements in Jama project 5 that have no downstream test case relationships" \
  --tool mcp__cc_jama__get_items --tool mcp__cc_jama__get_relationships
```