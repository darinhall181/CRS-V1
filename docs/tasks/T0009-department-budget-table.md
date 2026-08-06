---
title: Build package_department_budget table
status: open
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-05
verified_live: false
github_issue: null
---

## Summary
No table holds per-department approved budget (e.g. "camera approved for
$22,000"). Needed before the Gaffer role view's "camera budget hidden" /
department envelope concept works for real, not just visually in Figma.

## Notes
Related: `production_members.department` column already exists as of the
gaffer-role migration (2026-08-05) — this table should key off the same
department string convention.
