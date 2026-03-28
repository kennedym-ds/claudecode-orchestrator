---
name: sql-standards
description: SQL coding standards with severity-tiered rules. Use when writing, reviewing, or generating SQL code.
---

# SQL Standards

## ERROR (mandatory)
- Use parameterized queries from application code — never string interpolation
- Explicit column lists in `SELECT` — no `SELECT *` in production queries
- Explicit column lists in `INSERT` — no reliance on column order
- All tables must have a primary key
- Foreign keys must have `ON DELETE`/`ON UPDATE` clauses specified
- Never `DROP TABLE`, `TRUNCATE`, or `DELETE` without `WHERE` in scripts (use transactions)

## WARNING (recommended)
- Use meaningful aliases — no single letters (`o` → `orders`)
- Qualify all column references with table alias in JOINs
- Use `EXISTS` over `IN` for correlated subqueries (performance)
- Use CTEs (`WITH`) for readability — avoid deeply nested subqueries
- Index columns used in `WHERE`, `JOIN`, and `ORDER BY` clauses
- Use `COALESCE` over `ISNULL`/`NVL` for portability
- Prefer `UNION ALL` over `UNION` when duplicates are acceptable

## RECOMMENDATION (optional)
- Use window functions over self-joins for running totals/rankings
- Consider materialized views for expensive aggregate queries
- Use `EXPLAIN`/`EXPLAIN ANALYZE` to validate query plans
- Use database-specific partitioning for large tables
- Consider column-level encryption for PII

## Migration Safety
- All schema changes must be backward-compatible (online migrations)
- Add columns as nullable first, backfill, then add constraints
- Never rename columns in production — add new, migrate, drop old
- Include rollback scripts for every migration
- Test migrations against production-sized datasets
