---
name: shell-standards
description: Shell scripting standards with severity-tiered rules. Use when writing, reviewing, or generating Bash/Shell scripts.
---

# Shell Standards

## ERROR (mandatory)
- Start every script with `#!/usr/bin/env bash` (or specific shell)
- Use `set -euo pipefail` at the top of every script
- Quote all variable expansions: `"$var"` not `$var`
- Never use `eval` with user input
- Use `mktemp` for temporary files — never hardcoded `/tmp/myfile`
- Clean up temp files with `trap 'rm -f "$tmpfile"' EXIT`

## WARNING (recommended)
- Use `[[ ]]` over `[ ]` for conditionals (Bash-specific)
- Use `$(command)` over backticks for command substitution
- Use `local` for function variables — no global pollution
- Maximum function length: 40 lines
- Use `readonly` for constants
- Prefer `printf` over `echo` for portable output
- Use `shellcheck` for static analysis

## RECOMMENDATION (optional)
- Use associative arrays (Bash 4+) for key-value data
- Use `mapfile`/`readarray` for reading files into arrays
- Consider here-docs for multi-line strings
- Use `getopt`/`getopts` for argument parsing
- Use `#!/usr/bin/env bash` for portability over `#!/bin/bash`

## Testing
- Use BATS (Bash Automated Testing System) for unit tests
- Test exit codes explicitly
- Use `setup`/`teardown` functions for test isolation
- Mock external commands with PATH manipulation
