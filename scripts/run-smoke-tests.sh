#!/usr/bin/env bash
# run-smoke-tests.sh — Basic smoke tests for orchestrator assets
set -euo pipefail

PASS=0
FAIL=0

test_pass() { echo "  ✓ $1"; ((PASS++)); }
test_fail() { echo "  ✗ $1" >&2; ((FAIL++)); }

echo "=== Smoke Tests ==="

# Test 1: All agent files exist
echo "Agents:"
for agent in conductor planner implementer reviewer researcher security-reviewer tdd-guide red-team doc-updater; do
  if [ -f ".claude/agents/$agent.md" ]; then
    test_pass "$agent"
  else
    test_fail "$agent — missing"
  fi
done

# Test 2: All skill directories exist
echo "Skills:"
for skill in tdd-workflow security-review coding-standards plan-workflow review-workflow delegation-routing budget-gatekeeper strategic-compact verification-loop session-continuity; do
  if [ -f ".claude/skills/$skill/SKILL.md" ]; then
    test_pass "$skill"
  else
    test_fail "$skill — missing SKILL.md"
  fi
done

# Test 3: All commands exist
echo "Commands:"
for cmd in conduct plan implement review research secure test deploy-check doc red-team audit route; do
  if [ -f ".claude/commands/$cmd.md" ]; then
    test_pass "$cmd"
  else
    test_fail "$cmd — missing"
  fi
done

# Test 4: All rules exist
echo "Rules:"
for rule in persona quality security lifecycle delegation budget; do
  if [ -f ".claude/rules/$rule.md" ]; then
    test_pass "$rule"
  else
    test_fail "$rule — missing"
  fi
done

# Test 5: Hooks
echo "Hooks:"
if [ -f "hooks/hooks.json" ]; then
  test_pass "hooks.json exists"
else
  test_fail "hooks.json missing"
fi

for script in session-start session-end pre-compact post-compact pre-bash-safety post-edit-validate subagent-stop-gate stop-summary secret-detector; do
  if [ -f "hooks/scripts/$script.js" ]; then
    test_pass "$script.js"
  else
    test_fail "$script.js — missing"
  fi
done

# Test 6: Settings
echo "Settings:"
if [ -f ".claude/settings.json" ]; then
  test_pass "settings.json exists"
  if grep -q "ORCH_MODEL_HEAVY" .claude/settings.json; then
    test_pass "model tier config present"
  else
    test_fail "model tier config missing"
  fi
else
  test_fail "settings.json missing"
fi

# Summary
echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  echo "ALL SMOKE TESTS PASSED"
  exit 0
fi
