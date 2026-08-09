---
title: Build package_department_budget table
status: done
severity: medium
type: task
component: www/src/lib/db/schema.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-09
verified_live: true
github_issue: null
---

## Summary
**Done 2026-08-09:** Built `package_department_budget` (packageId + department, unique
together) plus `getPackageDepartmentBudgets`/`setPackageDepartmentBudget` (upsert) in
`queries.ts`. Verified live against the real `dev-darin` Neon branch: inserted a "camera"
envelope, re-set it to a new amount, confirmed the row updated in place (same id) rather
than erroring or duplicating — the unique-constraint/upsert path works.

No table holds per-department approved budget (e.g. "camera approved for
$22,000"). Needed before the Gaffer role view's "camera budget hidden" /
department envelope concept works for real, not just visually in Figma.

## Notes
Related: `production_members.department` column already exists as of the
gaffer-role migration (2026-08-05) — this table should key off the same
department string convention.

**2026-08-09 — one premise here was stale, worth flagging.** This task's original framing
("needed before the Gaffer role view... works") assumed a separate Gaffer page, per
T0006's original scope. T0006 closed *superseded* on 2026-08-08 — the workshop settled on
one shared Package Builder UI, not per-role pages — so there's no "Gaffer view" this is
unblocking. The underlying need (a real per-department budget envelope) is still valid,
so the table got built anyway as schema-only groundwork; a future budget-visibility rule
would be a query-level scope on this table (same pattern as T0030's rate visibility,
T0032's client_note/internal_note split), not a new page. No UI consumes this yet —
that's intentionally out of scope here, same reasoning as T0045's items 2/3.
