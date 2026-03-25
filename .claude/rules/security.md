---
paths:
  - "**/*"
---

Security baseline for all changes:

- Never hardcode secrets, API keys, tokens, or credentials
- Validate and sanitize all external input at system boundaries
- Use parameterized queries — never string-concatenate SQL
- Encode output for the target context (HTML, JS, URL, SQL)
- No shell command construction from user input
- No eval/exec of dynamic strings
- Use TLS for all external communication
- Log security events without sensitive data
- Default deny for access control — require explicit grants
- Pin dependency versions and review for known vulnerabilities
