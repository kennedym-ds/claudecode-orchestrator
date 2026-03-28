---
name: bicep-standards
description: Azure Bicep coding standards with severity-tiered rules. Use when writing, reviewing, or generating Bicep code.
---

# Bicep Standards

## ERROR (mandatory)
- Use parameters with `@allowed`, `@minLength`, `@maxLength`, `@minValue`, `@maxValue` decorators for validation
- No hardcoded secrets — use `@secure()` decorator on parameters and Key Vault references
- All resources must have tags: `environment`, `project`, `owner`
- Use `existing` keyword for referencing pre-existing resources — no hardcoded resource IDs
- Enable diagnostic settings on all supported resources

## WARNING (recommended)
- Use modules for reusable patterns — one resource type per module
- Use `targetScope` explicitly at file top
- Prefer user-defined types (Bicep 0.12+) over loose parameter objects
- Use `resource` symbolic names that describe purpose, not type
- Use conditions (`if`) over separate templates for optional resources
- Maximum module nesting: 3 levels
- Use `@description()` decorator on all parameters and outputs

## RECOMMENDATION (optional)
- Use Azure Verified Modules from the registry when available
- Consider using deployment stacks for lifecycle management
- Use `batch` deployment mode for parallel resource creation
- Use `union` types for constrained string parameters
- Consider `extensibility` providers for Kubernetes/GitHub resources

## Deployment Safety
- Always use `what-if` before deployment
- Validate templates with `az bicep build` and `bicep lint` in CI
- Use parameter files per environment — no inline parameter values
- Test with deployment validation mode before actual deployment
