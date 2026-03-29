# Artifact Index

> Session artifacts organized by type. Updated automatically by hooks and manually by agents.

## Plans

| Date | Name | Status | Path |
|------|------|--------|------|
| {date} | {plan-name} | Draft/Approved/Complete | `artifacts/plans/{feature}/` |

## Reviews

| Date | Scope | Verdict | Path |
|------|-------|---------|------|
| {date} | {files reviewed} | APPROVE/REQUEST_CHANGES/NEEDS_DISCUSSION | `artifacts/reviews/{name}.md` |

## Research

| Date | Topic | Confidence | Path |
|------|-------|------------|------|
| {date} | {topic} | HIGH/MEDIUM/LOW | `artifacts/research/{name}.md` |

## Security

| Date | Scope | Verdict | Path |
|------|-------|---------|------|
| {date} | {scope} | SECURE/NEEDS_REMEDIATION | `artifacts/security/{name}.md` |

## Decisions

| Date | Decision | Rationale | Path |
|------|----------|-----------|------|
| {date} | {short description} | {why} | `artifacts/decisions/{name}.md` |

## Sessions

Session logs are stored in `artifacts/sessions/` as JSONL files.
Delegation logs: `artifacts/sessions/delegation-log.jsonl`