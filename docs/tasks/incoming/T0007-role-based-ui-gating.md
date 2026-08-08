---
title: Add role-based UI gating (not just logged-in-or-not)
status: open
severity: medium
type: task
component: www/src/middleware.ts, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: null
verified_live: false
github_issue: null
---

## Summary
Auth middleware currently only checks session existence (and is itself
temporarily disabled — see T0012). Need a `getProductionMember(productionId,
userId)` query plus per-role UI differences (e.g. coordinator-only Send RFQ
button) once the role views (T0006) exist to actually gate.

## Notes
No real payoff until T0006 lands — nothing differentiates by role yet.
