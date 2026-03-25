---
name: issue-context
description: Pull Jira issue details into the current session as working context. Use before starting implementation to understand requirements.
argument-hint: <issue-key>
---

# Issue Context

## Process

1. **Fetch the issue** using the Jira MCP `get_issue` tool
2. **Extract key context:**
   - Summary and description (the requirement)
   - Acceptance criteria (from description or linked test cases)
   - Current status and assignee
   - Linked issues (blockers, related work)
   - Recent comments (discussion context)
3. **Format as working context** for the conductor or implementer
4. **Check for sub-tasks** that break down the work
5. **Note any blockers** from linked issues

## Output Format

```
--- Jira Context: {ISSUE-KEY} ---
Title:    {summary}
Status:   {status}
Priority: {priority}
Assignee: {assignee}

Requirements:
{description, formatted as bullet points}

Acceptance Criteria:
- {criterion 1}
- {criterion 2}

Linked Issues:
- {ISSUE-KEY}: {relationship} - {summary}

Recent Discussion:
- {author} ({date}): {comment summary}

Blockers: {none | list of blocking issues}
```

## Usage

```
claude /cc-jira:issue-context PROJ-123
```