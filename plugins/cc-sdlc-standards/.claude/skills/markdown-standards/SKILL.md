---
name: markdown-standards
description: Markdown authoring standards with severity-tiered rules. Use when writing, reviewing, or generating Markdown documentation.
---

# Markdown Standards

## ERROR (mandatory)
- One H1 (`#`) per document — used as the document title
- No broken links — verify all internal references exist
- Code blocks must specify language for syntax highlighting
- No trailing whitespace or inconsistent line endings
- Tables must have header row and alignment indicators

## WARNING (recommended)
- Use ATX-style headers (`#`) — not Setext (underline) style
- Use reference-style links for URLs used more than once
- Maximum line length: 120 characters (except URLs and code blocks)
- Use ordered lists only when sequence matters — unordered for everything else
- Consistent list indentation: 2 or 4 spaces, not mixed
- One blank line before and after headings, code blocks, and lists
- Use fenced code blocks (triple backtick) — not indented code blocks

## RECOMMENDATION (optional)
- Use admonitions (`> [!NOTE]`, `> [!WARNING]`) for callouts
- Use `<details>` blocks for collapsible sections
- Include a table of contents for documents > 500 words
- Use Mermaid diagrams for flowcharts and architecture diagrams
- Front matter (YAML) for metadata when supported by the platform
