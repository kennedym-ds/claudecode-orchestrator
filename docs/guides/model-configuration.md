# Model Configuration Guide

## Overview

The orchestrator uses a **three-tier model system** that maps model capability to task complexity. This lets you control quality vs. cost across the entire SDLC workflow.

## Tiers

| Tier | Env Variable | Default Model | Role |
|------|-------------|---------------|------|
| **heavy** | `ORCH_MODEL_HEAVY` | claude-opus-4-6-20260320 | Judgment-heavy: reviews, security, planning, architecture |
| **default** | `ORCH_MODEL_DEFAULT` | claude-sonnet-4-6-20260320 | Execution: implementation, research, testing, documentation |
| **fast** | `ORCH_MODEL_FAST` | claude-haiku-4-5-20250315 | Lightweight: triage, routing, INSTANT tasks, prompt hooks |

## How to Configure

### Option 1: Edit settings.json

Edit `.claude/settings.json`:

```json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-4-6-20260320",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-4-6-20260320",
    "ORCH_MODEL_FAST": "claude-haiku-4-5-20250315"
  },
  "model": "claude-sonnet-4-6-20260320"
}
```

The `model` field sets the default model for the main session. Agent-level `model:` frontmatter overrides this per-subagent.

### Option 2: Use a Profile

Copy a pre-built profile from `examples/` to `.claude/settings.json`:

| Profile | Heavy | Default | Fast | Use Case |
|---------|-------|---------|------|----------|
| `settings-budget.json` | Sonnet | Haiku | Haiku | Cost-sensitive work |
| `settings-standard.json` | Opus | Sonnet | Haiku | Recommended balance |
| `settings-premium.json` | Opus | Opus | Sonnet | Maximum quality |

### Option 3: Per-Session Override

Override for a single session:
```bash
claude --model claude-opus-4-6-20260320
```

### Option 4: Per-Agent Override

Edit any agent file in `.claude/agents/<name>.md` to override its model:
```yaml
---
model: opus
---
```

Valid model shortnames: `opus`, `sonnet`, `haiku`, or full model IDs like `claude-opus-4-6-20260320`.

## Agent-to-Tier Mapping

| Agent | Tier | Rationale |
|-------|------|-----------|
| conductor | heavy | Orchestration requires judgment about complexity and routing |
| planner | heavy | Architecture and risk analysis need deep reasoning |
| implementer | default | Code execution is well-defined — reasoning depth isn't the bottleneck |
| reviewer | heavy | Quality assessment requires nuanced judgment |
| researcher | default | Evidence gathering is breadth-oriented, not depth |
| security-reviewer | heavy | Security analysis requires careful, thorough reasoning |
| tdd-guide | default | Test writing follows clear patterns |
| red-team | heavy | Adversarial thinking requires creative, deep reasoning |
| doc-updater | default | Documentation is execution work |

## Cost Optimization Tips

1. **Start with the standard profile** — it covers most needs
2. **Use `/route` before `/conduct`** — assess complexity to avoid over-provisioning
3. **Set `--max-budget-usd`** for hard cost caps: `claude --max-budget-usd 5`
4. **Monitor with `/cost`** during long sessions
5. **Compact at milestones** — `/compact` reduces token waste
6. **Use `/clear` between tasks** — don't let unrelated context accumulate
7. **Target ≤25% heavy-tier usage** — the budget-gatekeeper skill tracks this

## Upgrading Models

When new model versions are released, update the env vars in `.claude/settings.json`:

```json
{
  "env": {
    "ORCH_MODEL_HEAVY": "claude-opus-5-0-20261001",
    "ORCH_MODEL_DEFAULT": "claude-sonnet-5-0-20261001",
    "ORCH_MODEL_FAST": "claude-haiku-5-0-20261001"
  }
}
```

No other files need changing — agents reference tiers, not specific model IDs.
