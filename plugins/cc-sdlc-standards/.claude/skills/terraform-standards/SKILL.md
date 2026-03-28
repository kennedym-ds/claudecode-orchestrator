---
name: terraform-standards
description: Terraform coding standards with severity-tiered rules. Use when writing, reviewing, or generating Terraform code.
---

# Terraform Standards

## ERROR (mandatory)
- Pin provider versions with exact constraints (`=` or `~>` minor)
- Use remote state backend — never local state in shared environments
- No hardcoded secrets — use `sensitive = true` variables and secret managers
- All resources must have meaningful names (not `resource`, `main`, `this`)
- Lock state files during operations (enable backend locking)
- Tag all resources with: `environment`, `project`, `owner`, `managed-by = terraform`

## WARNING (recommended)
- Use modules for reusable patterns (3+ resources or 2+ environments)
- One resource type per file for large modules, grouped by concern for small ones
- Use `terraform fmt` and `terraform validate` in CI
- Use `for_each` over `count` for collections (stable identity)
- Use `moved` blocks for refactoring (Terraform 1.1+)
- Separate environments with workspaces or directory structure — never variable flags
- Maximum module depth: 3 levels (root → module → submodule)

## RECOMMENDATION (optional)
- Use `check` blocks (Terraform 1.5+) for continuous validation
- Use `import` blocks (Terraform 1.5+) for declarative imports
- Consider `terraform test` (Terraform 1.6+) for module testing
- Use `precondition`/`postcondition` blocks for input validation
- Consider Terragrunt for DRY multi-environment configurations

## Plan Review Checklist
- Review `terraform plan` output before every apply
- Verify no unexpected destroys or replacements
- Check for state drift before making changes
- Validate costs using Infracost or similar
- Ensure blast radius is limited (target specific resources)
