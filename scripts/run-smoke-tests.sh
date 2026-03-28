#!/usr/bin/env bash
# run-smoke-tests.sh — Basic smoke tests for orchestrator assets
set -euo pipefail

PASS=0
FAIL=0

if [ -d "plugins/cc-sdlc-core/.claude/agents" ]; then
  AGENT_BASE="plugins/cc-sdlc-core/.claude/agents"
  SKILL_BASE="plugins/cc-sdlc-core/.claude/skills"
  COMMAND_BASE="plugins/cc-sdlc-core/.claude/commands"
  RULE_BASE="plugins/cc-sdlc-core/.claude/rules"
  HOOKS_JSON_PATH="plugins/cc-sdlc-core/hooks/hooks.json"
  HOOK_SCRIPT_BASE="plugins/cc-sdlc-core/hooks/scripts"
else
  AGENT_BASE=".claude/agents"
  SKILL_BASE=".claude/skills"
  COMMAND_BASE=".claude/commands"
  RULE_BASE=".claude/rules"
  HOOKS_JSON_PATH="hooks/hooks.json"
  HOOK_SCRIPT_BASE="hooks/scripts"
fi

test_pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
test_fail() { echo "  ✗ $1" >&2; FAIL=$((FAIL + 1)); }

echo "=== Smoke Tests ==="

# Test 1: All agent files exist
echo "Agents:"
for agent in conductor planner implementer reviewer researcher security-reviewer tdd-guide red-team doc-updater; do
  if [ -f "$AGENT_BASE/$agent.md" ]; then
    test_pass "$agent"
  else
    test_fail "$agent — missing"
  fi
done

# Test 2: All skill directories exist
echo "Skills:"
for skill in tdd-workflow security-review coding-standards plan-workflow review-workflow delegation-routing budget-gatekeeper strategic-compact verification-loop session-continuity; do
  if [ -f "$SKILL_BASE/$skill/SKILL.md" ]; then
    test_pass "$skill"
  else
    test_fail "$skill — missing SKILL.md"
  fi
done

# Test 3: All commands exist
echo "Commands:"
for cmd in conduct plan implement review research secure test deploy-check doc red-team audit route status compact; do
  if [ -f "$COMMAND_BASE/$cmd.md" ]; then
    test_pass "$cmd"
  else
    test_fail "$cmd — missing"
  fi
done

# Test 4: All rules exist
echo "Rules:"
for rule in persona quality security lifecycle delegation budget; do
  if [ -f "$RULE_BASE/$rule.md" ]; then
    test_pass "$rule"
  else
    test_fail "$rule — missing"
  fi
done

# Test 5: Hooks
echo "Hooks:"
if [ -f "$HOOKS_JSON_PATH" ]; then
  test_pass "hooks.json exists"
else
  test_fail "hooks.json missing"
fi

for script in session-start session-end pre-compact post-compact pre-bash-safety post-edit-validate subagent-stop-gate stop-summary secret-detector; do
  if [ -f "$HOOK_SCRIPT_BASE/$script.js" ]; then
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
