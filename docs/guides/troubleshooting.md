# Troubleshooting

Common issues and solutions for the Claude Code orchestrator.

## Installation Issues

### "Agent not found" when using /conduct

**Symptom:** Claude Code doesn't recognize orchestrator commands or agents.

**Cause:** Assets not deployed to the correct location.

**Fix:**
```bash
# Check if agents exist
ls ~/.claude/agents/          # macOS/Linux
Get-ChildItem ~/.claude/agents/   # Windows

# Re-deploy
bash scripts/deploy-user.sh       # macOS/Linux
powershell -File scripts/deploy-user.ps1  # Windows

# Validate
bash scripts/validate-assets.sh
powershell -File scripts/validate-assets.ps1
```

### "pwsh not found" on Windows

**Symptom:** Scripts fail with "pwsh is not recognized."

**Cause:** PowerShell 7 (pwsh) not installed. The scripts support PowerShell 5.1.

**Fix:** Use `powershell` instead of `pwsh`:
```powershell
powershell -File scripts/validate-assets.ps1
powershell -File scripts/run-smoke-tests.ps1
```

### Settings not taking effect

**Symptom:** Model tiers or environment variables are ignored.

**Cause:** Settings may be overridden at the wrong level, or the file has syntax errors.

**Fix:**
```bash
# Check which settings file is active
claude config list

# Validate JSON syntax
node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8')); console.log('Valid JSON')"

# Check for duplicate keys (common with copy-paste)
```

## Plugin Issues

### MCP server not starting

**Symptom:** Plugin tools (e.g., `mcp__cc_jira__get_issue`) are not available.

**Cause:** Missing dependencies or incorrect environment variables.

**Fix:**
```bash
# Install dependencies (each MCP server has its own package.json)
cd plugins/cc-jira/mcp && npm install && cd -
cd plugins/cc-confluence/mcp && npm install && cd -
cd plugins/cc-jama/mcp && npm install && cd -

# Check env vars are set
echo $JIRA_BASE_URL          # macOS/Linux
$env:JIRA_BASE_URL           # Windows

# Test server manually
node plugins/cc-jira/mcp/server.js
# Should wait for stdin (MCP protocol). Ctrl+C to exit.
```

### "HTTPS required" error from plugins

**Symptom:** Plugin returns "must use HTTPS for non-localhost connections."

**Cause:** Base URL uses `http://` instead of `https://`.

**Fix:** Ensure all cloud URLs use HTTPS:
```bash
export JIRA_BASE_URL="https://your-domain.atlassian.net"    # Not http://
export CONFLUENCE_BASE_URL="https://your-domain.atlassian.net"
export JAMA_BASE_URL="https://your-instance.jamacloud.com"
```

### Authentication failures (401/403)

**Symptom:** Plugin returns "401 Unauthorized" or "403 Forbidden."

**Causes and fixes:**

| Service | Auth Method | Common Issue | Fix |
|---------|------------|-------------|-----|
| Jira | Basic (email:token) | Wrong email or expired token | Regenerate at https://id.atlassian.com/manage-profile/security/api-tokens |
| Confluence | Basic (email:token) | Same as Jira | Same as Jira |
| Jama | OAuth client credentials | Wrong client ID/secret or insufficient scopes | Contact Jama admin for new credentials |

## Hook Issues

### Hooks not firing

**Symptom:** Secret detection, bash safety, or other hooks don't trigger.

**Cause:** Hook paths may be incorrect after deployment.

**Fix:**
```bash
# Check hooks in settings
cat .claude/settings.json | grep -A5 "hooks"

# Verify hook scripts exist
# Source repo checkout:
ls plugins/cc-sdlc-core/hooks/scripts/

# Installed project/user layout:
ls hooks/scripts/

# Test a hook manually
echo '{"prompt":"test"}' | node plugins/cc-sdlc-core/hooks/scripts/secret-detector.js
# Should exit 0 (no secrets found)
```

**Path convention note:** In this repository, `.claude/settings.json` uses repo-relative paths such as `plugins/cc-sdlc-core/hooks/scripts/session-start.js` so hooks run directly from the source tree. The packaged plugin file `plugins/cc-sdlc-core/hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/...` so the same hooks resolve correctly after installation.

### Hook blocks a legitimate command

**Symptom:** Pre-bash-safety hook blocks a command you need to run.

**Cause:** The safety hook blocks patterns like `rm -rf`, `DROP TABLE`, etc.

**Fix:** The hook is intentionally conservative. For legitimate destructive operations:
1. Run the command outside Claude Code
2. Or modify `hooks/scripts/pre-bash-safety.js` to allowlist the specific pattern

### Post-edit validation slowing things down

**Symptom:** Edits take a long time because lint/format runs after every file change.

**Cause:** `post-edit-validate.js` runs async but may be slow on large files.

**Fix:** The hook runs asynchronously, so it shouldn't block. If it does:
```bash
# Check if the hook is synchronous in settings
# Look for "async": true in the hook config
```

## Agent Issues

### Agent stuck in a loop

**Symptom:** An agent keeps repeating the same action without progress.

**Fix:**
1. Press Ctrl+C to interrupt
2. Use `/compact` to save state and clear context
3. Resume with `/status` to check where you left off
4. Re-run the command with more specific instructions

### Conductor doesn't delegate

**Symptom:** The conductor tries to implement directly instead of delegating.

**Cause:** Context may be unclear about the task complexity.

**Fix:**
```bash
# Use /route first to force complexity assessment
# /route <your task description>

# Then use /conduct with the assessed tier
# /conduct <task>
```

### Reviewer finds no issues

**Symptom:** Review comes back with zero findings on code that has obvious issues.

**Cause:** Insufficient context or scope too broad.

**Fix:** Be specific about what to review:
```bash
# Too broad
# /review src/

# Better — specific scope
# /review src/auth/login.ts — focus on input validation and SQL injection
```

## Budget Issues

### Session running out of budget

**Symptom:** Claude Code stops mid-task due to budget limits.

**Fix:**
```bash
# Check current spend
# /status

# Compact to save tokens
# /compact

# Restart with higher budget
claude --max-budget-usd 10 --resume

# Switch to budget profile for remaining work
# Copy examples/settings-budget.json → .claude/settings.json
```

### Heavy-tier usage too high

**Symptom:** Budget drain from Opus being used for routine tasks.

**Fix:** Check which agents are running on heavy tier:
- Conductor, Planner, Reviewer, Security-Reviewer, Red-Team → heavy (expected)
- Implementer, Researcher, TDD-Guide, Doc-Updater → should be default

If default agents are using Opus, check `.claude/settings.json` env vars.

## Artifact Issues

### activeContext.md not updating

**Symptom:** `/status` shows stale information.

**Cause:** Pre/post-compact hooks may not have run.

**Fix:**
```bash
# Initialize artifacts directory
bash scripts/init-artifacts.sh

# Check hook registration
cat .claude/settings.json | grep -A10 "PreCompact"
```

### Plans not persisting

**Symptom:** Plans disappear between sessions.

**Cause:** Artifacts directory may not exist.

**Fix:**
```bash
# Create directory structure
mkdir -p artifacts/plans artifacts/reviews artifacts/research
mkdir -p artifacts/security artifacts/sessions artifacts/decisions
mkdir -p artifacts/memory

# Or use init script
bash scripts/init-artifacts.sh
```

## Validation

Always run validation to catch configuration issues:

```bash
# Full validation
powershell -File scripts/validate-assets.ps1    # Windows
bash scripts/validate-assets.sh                  # macOS/Linux

# Smoke tests
powershell -File scripts/run-smoke-tests.ps1    # Windows
bash scripts/run-smoke-tests.sh                  # macOS/Linux
```

Expected results:
- **Validation:** 0 errors, 0-2 warnings (audit/status commands may warn about no `$ARGUMENTS` — this is normal)
- **Smoke tests:** 59/59 passed