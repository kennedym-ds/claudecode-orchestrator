#!/usr/bin/env bash
# analyze-sessions.sh — Analyze session logs and produce a usage summary
set -euo pipefail

BASE="${1:-.}"
SESSIONS_DIR="$BASE/artifacts/sessions"

# Check if any logs exist
has_data=false
for f in "$SESSIONS_DIR"/session-log.jsonl "$SESSIONS_DIR"/delegation-log.jsonl "$SESSIONS_DIR"/audit-log.jsonl; do
  if [ -f "$f" ] && [ -s "$f" ]; then
    has_data=true
    break
  fi
done

if ! $has_data; then
  echo "No session data found. Run some sessions first."
  exit 0
fi

echo ""
echo "--- Session Metrics ---"

# Session count
session_count=0
first_date="N/A"
last_date="N/A"
if [ -f "$SESSIONS_DIR/session-log.jsonl" ]; then
  session_count=$(grep -c '"session_start"' "$SESSIONS_DIR/session-log.jsonl" 2>/dev/null || echo 0)
  if [ "$session_count" -gt 0 ]; then
    first_date=$(grep '"session_start"' "$SESSIONS_DIR/session-log.jsonl" | head -1 | sed 's/.*"timestamp":"\([^"]*\)".*/\1/' | cut -c1-10)
    last_date=$(grep '"session_start"' "$SESSIONS_DIR/session-log.jsonl" | tail -1 | sed 's/.*"timestamp":"\([^"]*\)".*/\1/' | cut -c1-10)
  fi
fi

if [ "$first_date" = "$last_date" ]; then
  echo "Sessions:    $session_count ($first_date)"
else
  echo "Sessions:    $session_count ($first_date to $last_date)"
fi

# Delegation summary
delegation_count=0
if [ -f "$SESSIONS_DIR/delegation-log.jsonl" ]; then
  delegation_count=$(grep -c '"subagent_start"' "$SESSIONS_DIR/delegation-log.jsonl" 2>/dev/null || echo 0)
fi

if [ "$delegation_count" -gt 0 ]; then
  unique_agents=$(grep '"subagent_start"' "$SESSIONS_DIR/delegation-log.jsonl" | sed 's/.*"agent":"\([^"]*\)".*/\1/' | sort -u | wc -l | tr -d ' ')
  echo "Delegations: $delegation_count total across $unique_agents agents"
  echo ""
  echo "--- Agent Usage ---"
  echo "| Agent | Delegations | % of Total |"
  echo "|-------|-------------|------------|"
  grep '"subagent_start"' "$SESSIONS_DIR/delegation-log.jsonl" \
    | sed 's/.*"agent":"\([^"]*\)".*/\1/' \
    | sort | uniq -c | sort -rn | head -10 \
    | while read -r count agent; do
        pct=$(echo "scale=1; $count * 100 / $delegation_count" | bc 2>/dev/null || echo "?")
        echo "| $agent | $count | ${pct}% |"
      done

  if [ "$session_count" -gt 0 ]; then
    avg=$(echo "scale=1; $delegation_count / $session_count" | bc 2>/dev/null || echo "?")
    echo ""
    echo "Avg delegations/session: $avg"
  fi
else
  echo "Delegations: 0"
fi

# File activity
edit_count=0
if [ -f "$SESSIONS_DIR/audit-log.jsonl" ]; then
  edit_count=$(wc -l < "$SESSIONS_DIR/audit-log.jsonl" | tr -d ' ')
fi

if [ "$edit_count" -gt 0 ]; then
  echo ""
  echo "--- Most Edited Files ---"
  echo "| File | Edits |"
  echo "|------|-------|"
  sed 's/.*"file":"\([^"]*\)".*/\1/' "$SESSIONS_DIR/audit-log.jsonl" \
    | sort | uniq -c | sort -rn | head -10 \
    | while read -r count file; do
        echo "| $file | $count |"
      done
  echo ""
  echo "Total file edits: $edit_count"
else
  echo ""
  echo "File edits: 0"
fi

echo ""
