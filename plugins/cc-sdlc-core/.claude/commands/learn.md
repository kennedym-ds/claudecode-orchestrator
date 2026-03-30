# /learn — Cross-Session Learnings

Manage learnings: $ARGUMENTS

## Instructions

Parse the subcommand from `$ARGUMENTS`:

### `add <note>` (or just text with no subcommand)

Add a new learning to `artifacts/memory/learnings.jsonl`.

1. Generate an `id`: `learn-` + current Unix epoch milliseconds
2. Set `timestamp` to current ISO 8601
3. Infer `category` from context: `pattern`, `pitfall`, `convention`, `decision`, or `tooling`
4. Set `source` to `user`
5. Append the JSON line to `artifacts/memory/learnings.jsonl` (create file if absent)
6. Confirm: "Learning saved: {id}"

### `list`

Show the most recent learnings.

1. Read `artifacts/memory/learnings.jsonl`
2. Filter out entries where `deleted` is `true`
3. Show the last 20 entries, newest first
4. Format as a table: ID | Date | Category | Note (truncated to 80 chars)

### `search <query>`

Search learnings by keyword.

1. Read `artifacts/memory/learnings.jsonl`
2. Filter out deleted entries
3. Filter where `note` contains `<query>` (case-insensitive)
4. Display matching entries with full note text

### `remove <id>`

Soft-delete a learning.

1. Read `artifacts/memory/learnings.jsonl`
2. Find the line with matching `id`
3. Set `deleted: true` on that entry
4. Rewrite the file with the updated line
5. Confirm: "Learning {id} removed"

### `export`

Export learnings to Markdown.

1. Read all non-deleted entries from `artifacts/memory/learnings.jsonl`
2. Group by `category`
3. Write to `artifacts/memory/learnings-export.md` with category headings, timestamps, and full notes
4. Confirm: "Exported {N} learnings to artifacts/memory/learnings-export.md"

## Notes

- If no subcommand is recognized, treat the entire `$ARGUMENTS` as an `add` command
- Use the `learnings-mgmt` skill for schema details and lifecycle rules
- This is a read-only-safe command — the worst it can do is append a line or rewrite the JSONL file
