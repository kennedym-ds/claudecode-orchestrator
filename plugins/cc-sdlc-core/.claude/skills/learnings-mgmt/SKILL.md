---
name: learnings-mgmt
description: >
  Cross-session learnings lifecycle — schema, storage, retrieval, and pruning
  of lessons learned during orchestrator sessions. Use when managing learnings
  via the /learn command.
user-invocable: false
---

# Learnings Management

## Storage

Learnings persist to `artifacts/memory/learnings.jsonl` — one JSON object per line.

### Schema

```json
{
  "id": "learn-<timestamp-ms>",
  "timestamp": "2026-03-30T12:00:00.000Z",
  "category": "pattern | pitfall | convention | decision | tooling",
  "note": "Free-text lesson learned",
  "source": "session | user | review | incident",
  "deleted": false
}
```

### Field Rules

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | `learn-` prefix + Unix epoch milliseconds — unique per entry |
| `timestamp` | Yes | ISO 8601 |
| `category` | Yes | One of: `pattern`, `pitfall`, `convention`, `decision`, `tooling` |
| `note` | Yes | The lesson text — keep under 200 words |
| `source` | Yes | One of: `session`, `user`, `review`, `incident` |
| `deleted` | No | Defaults to `false`. Set `true` on soft-delete. |

## Operations

### Add

Append a new JSON line to `learnings.jsonl`. Auto-assign `id` and `timestamp`. Default `source` to `session` unless the user specifies otherwise.

### List

Read `learnings.jsonl`, filter out `deleted: true` entries, display the last 20 in reverse chronological order. Show: `id`, `timestamp` (date only), `category`, and truncated `note` (first 80 chars).

### Search

Read all non-deleted entries, filter where `note` contains the query string (case-insensitive). Display matching entries with full note text.

### Remove

Find the entry by `id`. Set `deleted: true` and rewrite the line in place. Do **not** physically delete — this preserves audit history.

### Export

Read all non-deleted entries. Write a Markdown summary to `artifacts/memory/learnings-export.md` grouped by category. Include timestamp and full note text.

## Auto-Learning Opportunities

Agents may suggest adding a learning when:
- A reviewer finds a recurring pattern or anti-pattern
- An implementer discovers a non-obvious project convention
- A researcher finds a key technical constraint
- An incident reveals a systemic issue

The agent should present the suggestion and let the user confirm via `/learn add <note>`.

## Pruning

Over time, learnings accumulate. Recommend pruning when `learnings.jsonl` exceeds 200 entries:
- Review entries older than 90 days
- Remove entries superseded by newer learnings
- Archive removed entries to `artifacts/memory/learnings-archive.jsonl`
