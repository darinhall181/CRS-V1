---
title: Add role-based UI gating (not just logged-in-or-not)
status: done
severity: medium
type: task
component: www/src/middleware.ts, www/src/lib/db/queries.ts
found_by: claude-code
found_date: 2026-08-05
completed_date: 2026-08-08
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

## Summary (2026-08-08) — superseded, closed without building
T0006 (the thing this was blocked on) closed superseded rather than landing — the
2026-08-08 workshop confirmed one shared UI, not per-role pages. This task's own scope
was independently absorbed by `docs/tasks/incoming/T0017-viewer-context-role-helper.md`,
filed the same day, which explicitly states it "supersedes the query half of T0007" (the
`getProductionMember`/role-resolution query work) while the UI-gating half closes
progressively via T0026 (coordinator-only Send quote), T0030 (rate visibility), and T0032
(RFQ sides) as those get built. Nothing left here to build standalone — closed in favor
of T0017.
